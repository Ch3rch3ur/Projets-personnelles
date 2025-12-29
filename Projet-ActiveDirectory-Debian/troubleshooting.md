# 🐛 Troubleshooting - Projet Active Directory Linux

Ce document détaille les problèmes rencontrés lors de l'intégration de systèmes Linux à Active Directory, ainsi que les méthodes de diagnostic et les solutions appliquées.

---

## 📋 Vue d'ensemble des incidents

L'authentification centralisée repose sur une **chaîne de dépendances strictes** :
1. Résolution DNS du domaine Active Directory
2. Authentification via Kerberos
3. Résolution des identités et groupes via LDAP/SSSD
4. Autorisation d'accès via PAM

**Tout dysfonctionnement sur un flux en amont empêche les étapes suivantes.**

---

## 1. 🌐 DNS : Résolution FQDN incomplète

### Symptôme

La résolution DNS du domaine Active Directory échoue ou est incomplète.

```bash
$ nslookup homelab.local
Server can't find homelab.local: NXDOMAIN
```

ou

```bash
$ dig SRV _kerberos._tcp.homelab.local
; <<>> DiG 9.18.28-1~deb12u2-Debian <<>> SRV _kerberos._tcp.homelab.local
;; status: NXDOMAIN
```

### Causes identifiées

* Enregistrements DNS manquants côté Active Directory :
  * Enregistrements **A** (résolution du nom du DC)
  * Enregistrements **PTR** (résolution inverse)
  * Enregistrements **SRV** (localisation des services Kerberos et LDAP)
* Configuration DNS incorrecte sur le client Linux (`/etc/resolv.conf`)
* Serveur DNS non accessible depuis le client

### Diagnostic

#### 1. Vérifier la configuration DNS du client Linux

```bash
cat /etc/resolv.conf
```

**Résultat attendu** :
```
nameserver 192.168.2.3  # IP du DC Windows
search homelab.local
```

#### 2. Tester la résolution du domaine

```bash
nslookup homelab.local
dig A homelab.local
```

#### 3. Vérifier les enregistrements SRV Kerberos

```bash
dig SRV _kerberos._tcp.homelab.local
dig SRV _ldap._tcp.homelab.local
```

**Résultat attendu** : Liste des contrôleurs de domaine avec leurs priorités et ports

#### 4. Vérifier la résolution inverse

```bash
dig -x 192.168.2.3  # IP du DC
```

#### 5. Vérifier les enregistrements DNS côté Windows Server

Sur le contrôleur de domaine Windows :

```powershell
# Lister tous les enregistrements de la zone
Get-DnsServerResourceRecord -ZoneName "homelab.local"

# Vérifier les enregistrements SRV Kerberos
Get-DnsServerResourceRecord -ZoneName "homelab.local" -RRType SRV | Where-Object {$_.HostName -like "*kerberos*"}
```

### Solution

#### Côté Windows Server (si enregistrements manquants)

1. **Ajouter l'enregistrement A du contrôleur de domaine** :

```powershell
Add-DnsServerResourceRecordA -Name "dc" -ZoneName "homelab.local" -IPv4Address "192.168.2.3"
```

2. **Ajouter l'enregistrement PTR** :

```powershell
Add-DnsServerResourceRecordPtr -Name "3" -ZoneName "2.168.192.in-addr.arpa" -PtrDomainName "dc.homelab.local"
```

3. **Forcer la réinscription DNS du DC** :

```powershell
ipconfig /registerdns
```

4. **Redémarrer le service DNS** :

```powershell
Restart-Service DNS
```

#### Côté Linux (si configuration incorrecte)

1. **Configurer le résolveur DNS** :

```bash
sudo nano /etc/resolv.conf
```

Ajouter :
```
nameserver 192.168.2.3
search homelab.local
```

2. **Rendre la configuration persistante** (si utilisation de NetworkManager) :

```bash
sudo nano /etc/NetworkManager/NetworkManager.conf
```

Ajouter dans la section `[main]` :
```
dns=none
```

Puis redémarrer NetworkManager :
```bash
sudo systemctl restart NetworkManager
```

### Vérification

```bash
# Test de résolution
nslookup homelab.local

# Test des enregistrements SRV
dig SRV _kerberos._tcp.homelab.local

# Test de résolution inverse
dig -x 192.168.2.3
```

**Résultat attendu** : Tous les enregistrements doivent être résolus correctement.

---

## 2. 🎫 Kerberos : Erreurs lors de kinit

### Symptôme

L'authentification Kerberos échoue malgré des identifiants valides.

```bash
$ kinit utilisateur@HOMELAB.LOCAL
kinit: Client 'utilisateur@HOMELAB.LOCAL' not found in Kerberos database
```

ou

```bash
kinit: Clock skew too great while getting initial credentials
```

### Causes identifiées

* **Désynchronisation horaire** entre le client Linux et le contrôleur de domaine
* **Compte Active Directory désactivé ou verrouillé**
* **Configuration krb5.conf incorrecte** :
  * Realm en minuscules au lieu de majuscules
  * KDC mal défini
  * Mapping realm/domaine incorrect
* **Problèmes DNS** (enregistrements SRV manquants)

### Diagnostic

#### 1. Vérifier la synchronisation horaire

```bash
# Afficher l'heure système
timedatectl status

# Comparer avec l'heure du DC
date && ssh administrateur@dc.homelab.local "date"
```

**Tolérance Kerberos** : Maximum **5 minutes** de différence

#### 2. Vérifier l'état du compte AD

Sur le contrôleur de domaine Windows :

```powershell
# Vérifier si le compte est actif
Get-ADUser utilisateur | Select-Object Enabled, LockedOut, AccountExpirationDate

# Vérifier les dernières tentatives d'authentification
Get-ADUser utilisateur -Properties LastLogonDate, BadLogonCount
```

#### 3. Vérifier la configuration Kerberos

```bash
cat /etc/krb5.conf
```

**Configuration correcte attendue** :

```ini
[libdefaults]
    default_realm = HOMELAB.LOCAL
    dns_lookup_realm = false
    dns_lookup_kdc = true
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true

[realms]
    HOMELAB.LOCAL = {
        kdc = dc.homelab.local
        admin_server = dc.homelab.local
    }

[domain_realm]
    .homelab.local = HOMELAB.LOCAL
    homelab.local = HOMELAB.LOCAL
```

**Points critiques** :
- Le realm doit être en **MAJUSCULES**
- Le domaine doit être en **minuscules**

#### 4. Tester manuellement l'authentification

```bash
# Test avec un utilisateur AD
kinit utilisateur@HOMELAB.LOCAL

# Vérifier le ticket obtenu
klist
```

### Solution

#### Si problème de synchronisation horaire

1. **Installer et configurer NTP** :

```bash
sudo apt install systemd-timesyncd
```

2. **Configurer le serveur NTP** :

```bash
sudo nano /etc/systemd/timesyncd.conf
```

Ajouter :
```ini
[Time]
NTP=dc.homelab.local
FallbackNTP=pool.ntp.org
```

3. **Activer et démarrer le service** :

```bash
sudo systemctl enable systemd-timesyncd
sudo systemctl start systemd-timesyncd
```

4. **Vérifier la synchronisation** :

```bash
timedatectl status
timedatectl timesync-status
```

#### Si compte AD désactivé/verrouillé

Sur le contrôleur de domaine Windows :

```powershell
# Activer le compte
Enable-ADAccount -Identity utilisateur

# Déverrouiller le compte
Unlock-ADAccount -Identity utilisateur

# Réinitialiser le compteur de tentatives échouées
Set-ADUser utilisateur -Replace @{badPwdCount=0}
```

#### Si configuration krb5.conf incorrecte

```bash
sudo nano /etc/krb5.conf
```

**Vérifier particulièrement** :
- `default_realm = HOMELAB.LOCAL` (en MAJUSCULES)
- `kdc = dc.homelab.local` (FQDN du DC)
- Section `[domain_realm]` correctement configurée

### Vérification

```bash
# Test d'authentification
kinit utilisateur@HOMELAB.LOCAL

# Vérifier le ticket Kerberos
klist

# Résultat attendu :
# Ticket cache: FILE:/tmp/krb5cc_1000
# Default principal: utilisateur@HOMELAB.LOCAL
#
# Valid starting       Expires              Service principal
# 29/12/2024 10:00:00  29/12/2024 20:00:00  krbtgt/HOMELAB.LOCAL@HOMELAB.LOCAL
```

---

## 3. 🔐 SSSD / PAM : Authentification réussie mais accès SSH refusé

### Symptôme

L'authentification Kerberos fonctionne (`kinit` réussit), mais la connexion SSH est refusée.

```bash
$ ssh utilisateur@homelab.local@debian-client
Password:
Access denied
Connection closed by 192.168.2.2 port 22
```

Dans les logs système (`/var/log/auth.log`) :

```
pam_sss(sshd:account): Access denied for user utilisateur@homelab.local: 6 (Permission denied)
```

### Causes identifiées

* **Filtrage par groupes AD mal configuré** dans SSSD
* **Utilisateur non membre du groupe autorisé** (`linux-users` ou `linux-admins`)
* **Cache SSSD obsolète** (anciennes informations d'appartenance aux groupes)
* **Configuration PAM incorrecte**

### Diagnostic

#### 1. Vérifier l'authentification Kerberos

```bash
# L'authentification Kerberos doit fonctionner
kinit utilisateur@HOMELAB.LOCAL
klist
```

#### 2. Vérifier la résolution de l'utilisateur par SSSD

```bash
# L'utilisateur doit être visible
id utilisateur@homelab.local

# Résultat attendu : uid, gid, groups
```

#### 3. Vérifier l'appartenance aux groupes AD

```bash
# Lister les groupes de l'utilisateur
groups utilisateur@homelab.local
```

**Résultat attendu** : L'utilisateur doit être membre de `linux-users` ou `linux-admins`

#### 4. Vérifier la configuration SSSD

```bash
sudo cat /etc/sssd/sssd.conf
```

**Section critique à vérifier** :

```ini
[domain/homelab.local]
access_provider = simple
simple_allow_groups = linux-users, linux-admins
```

#### 5. Consulter les logs SSSD

```bash
sudo tail -f /var/log/sssd/sssd_homelab.local.log
```

Tenter une connexion SSH et observer les logs.

#### 6. Vérifier l'appartenance AD côté Windows

Sur le contrôleur de domaine :

```powershell
# Lister les groupes d'un utilisateur
Get-ADPrincipalGroupMembership -Identity utilisateur | Select-Object Name
```

### Solution

#### Si l'utilisateur n'est pas dans le bon groupe AD

Sur le contrôleur de domaine Windows :

```powershell
# Ajouter l'utilisateur au groupe linux-users
Add-ADGroupMember -Identity "linux-users" -Members utilisateur

# Vérifier l'ajout
Get-ADGroupMember -Identity "linux-users" | Select-Object Name
```

#### Si configuration SSSD incorrecte

```bash
sudo nano /etc/sssd/sssd.conf
```

**Configuration correcte** :

```ini
[sssd]
domains = homelab.local
config_file_version = 2
services = nss, pam

[domain/homelab.local]
ad_domain = homelab.local
krb5_realm = HOMELAB.LOCAL
realmd_tags = manages-system joined-with-samba
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = True
fallback_homedir = /home/%u@%d
access_provider = simple
simple_allow_groups = linux-users, linux-admins
```

**Points critiques** :
- `access_provider = simple` : Active le filtrage par groupes
- `simple_allow_groups` : Liste des groupes AD autorisés

#### Si cache SSSD obsolète

```bash
# Arrêter SSSD
sudo systemctl stop sssd

# Purger le cache
sudo sss_cache -E

# Ou supprimer manuellement le cache
sudo rm -rf /var/lib/sss/db/*

# Redémarrer SSSD
sudo systemctl start sssd
```

#### Si configuration PAM incorrecte

Vérifier `/etc/pam.d/common-account` :

```bash
cat /etc/pam.d/common-account
```

**Ligne nécessaire** :
```
account [default=bad success=ok user_unknown=ignore] pam_sss.so
```

### Vérification

```bash
# 1. Vérifier la résolution de l'utilisateur
id utilisateur@homelab.local

# 2. Vérifier les groupes
groups utilisateur@homelab.local

# 3. Tester la connexion SSH
ssh utilisateur@homelab.local@debian-client

# 4. Vérifier les logs en temps réel
sudo tail -f /var/log/auth.log
```

**Résultat attendu** : Connexion SSH acceptée sans erreur.

---

## 4. 🏠 Home directories : Répertoires utilisateurs absents

### Symptôme

Après une connexion SSH réussie, le répertoire personnel de l'utilisateur n'existe pas.

```bash
$ ssh utilisateur@homelab.local@debian-client
Could not chdir to home directory /home/utilisateur@homelab.local: No such file or directory
-bash: /home/utilisateur@homelab.local/.bash_profile: No such file or directory
```

### Cause

La **création automatique des répertoires utilisateurs** n'est pas activée dans la configuration PAM.

### Solution

#### Activer la création automatique des home directories via PAM

1. **Éditer le fichier PAM pour les sessions** :

```bash
sudo nano /etc/pam.d/common-session
```

2. **Ajouter la ligne suivante** (si absente) :

```
session optional pam_mkhomedir.so skel=/etc/skel umask=0077
```

**Explication** :
- `pam_mkhomedir.so` : Module PAM qui crée automatiquement les répertoires
- `skel=/etc/skel` : Utilise le squelette par défaut pour les nouveaux comptes
- `umask=0077` : Droits d'accès restrictifs (rwx------ = 700)

3. **Redémarrer SSSD** :

```bash
sudo systemctl restart sssd
```

### Vérification

```bash
# Se connecter avec un nouvel utilisateur
ssh nouvel_utilisateur@homelab.local@debian-client

# Vérifier que le répertoire a été créé
ls -ld /home/nouvel_utilisateur@homelab.local

# Résultat attendu :
# drwx------ 2 nouvel_utilisateur@homelab.local domain users@homelab.local 4096 déc 29 10:00 /home/nouvel_utilisateur@homelab.local
```

---

## 📊 Synthèse : Ordre de diagnostic en cas d'échec

Si l'authentification ne fonctionne pas, suivre cet ordre de diagnostic :

```
1. DNS
   └─ Résolution du domaine OK ?
       ├─ ❌ → Corriger les enregistrements A/PTR/SRV
       └─ ✅ → Passer à l'étape 2

2. KERBEROS
   └─ kinit fonctionne ?
       ├─ ❌ → Vérifier NTP, config krb5.conf, compte AD
       └─ ✅ → Passer à l'étape 3

3. SSSD
   └─ id utilisateur@domaine fonctionne ?
       ├─ ❌ → Vérifier config SSSD, redémarrer le service
       └─ ✅ → Passer à l'étape 4

4. PAM / GROUPES AD
   └─ SSH fonctionne ?
       ├─ ❌ → Vérifier appartenance aux groupes, purger cache SSSD
       └─ ✅ → Authentification fonctionnelle ✅

5. HOME DIRECTORIES
   └─ Le répertoire /home/utilisateur@domaine existe ?
       ├─ ❌ → Activer pam_mkhomedir
       └─ ✅ → Configuration complète ✅
```

---

## 🔧 Commandes utiles de diagnostic

### Vérification rapide de l'état du système

```bash
# État des services
sudo systemctl status sssd
sudo systemctl status systemd-timesyncd

# Tester l'authentification complète
sudo realm list

# Vérifier les tickets Kerberos actifs
klist

# Purger les tickets Kerberos (si besoin)
kdestroy

# Vérifier les utilisateurs AD visibles
getent passwd | grep @homelab.local

# Vérifier les groupes AD visibles
getent group | grep @homelab.local

# Logs en temps réel
sudo journalctl -u sssd -f
sudo tail -f /var/log/auth.log
```

### Tests de connectivité réseau

```bash
# Ping du DC
ping dc.homelab.local

# Test des ports essentiels
nc -zv dc.homelab.local 88   # Kerberos
nc -zv dc.homelab.local 389  # LDAP
nc -zv dc.homelab.local 53   # DNS
```

---

## 📚 Ressources complémentaires

* Documentation Red Hat : [Integration with Active Directory](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/integrating_rhel_systems_directly_with_windows_active_directory/index)
* Wiki Debian : [SSSD and Active Directory](https://wiki.debian.org/AuthenticatingLinuxWithActiveDirectory)
* Documentation Microsoft : [Troubleshooting Kerberos](https://learn.microsoft.com/en-us/troubleshoot/windows-server/windows-security/kerberos-authentication-problems)

---

**Note** : Ce document est basé sur les incidents réellement rencontrés lors du projet. Tous les exemples de commandes ont été testés et validés.