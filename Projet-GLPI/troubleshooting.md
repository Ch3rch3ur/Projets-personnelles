# 🛠️ Troubleshooting - Projet GLPI ITSM

> **⏱️ Temps total de debug** : ~10-12 heures réparties sur 4 sessions  
> **🔥 Problèmes majeurs** : 6 (Extension disque/swap, PHP 8.4, droits fichiers, attribut LDAP, commandes incompatibles, wget)  
> **🎓 Apprentissages clés** : Gestion du stockage VirtualBox, compatibilité versions, importance de la casse LDAP, diagnostic méthodique

## 📌 Synthèse du document

**Problèmes rencontrés** :
1. **Extension disque VirtualBox et conflit swap** : Performances dégradées → Suppression ancienne référence swap
2. **Incompatibilité PHP 8.4** : GLPI ne supporte que PHP 8.2 → Downgrade via dépôt Sury
3. **Téléchargement GLPI échoue** : wget retourne 404 → Téléchargement manuel via navigateur
4. **Droits de fichiers GLPI** : Permissions refusées à l'installation → chmod 775 sur config/files/marketplace
5. **Import LDAP impossible** : Attribut `uid` au lieu de `sAMAccountName` → Correction critique

**Compétences démontrées** : Gestion du stockage virtualisé, diagnostic méthodique (logs, ldapsearch), résolution autonome d'incidents complexes, compréhension Active Directory/LDAP, gestion versions applicatives

**Temps de résolution moyen** : 2-3h par incident majeur

👉 **Détails techniques complets ci-dessous**

---

Ce document détaille les **problèmes réels rencontrés** lors du déploiement et de l'intégration de GLPI à Active Directory, ainsi que les **méthodes de diagnostic appliquées** et les **solutions mises en œuvre**.

> **Note** : Tous les incidents décrits ici ont été réellement rencontrés et résolus lors du projet. Les commandes et solutions sont celles qui ont effectivement fonctionné.

---

## 📋 Vue d'ensemble des incidents

Le déploiement de GLPI intégré à Active Directory repose sur une **chaîne de dépendances** :

1. Infrastructure virtualisée fonctionnelle (stockage, ressources)
2. Réseau fonctionnel (DNS, DHCP, connectivité)
3. Stack applicative (Apache, PHP, MariaDB)
4. Application GLPI correctement installée
5. Connexion LDAP à Active Directory
6. Import et synchronisation des utilisateurs

**Tout dysfonctionnement sur une étape en amont empêche les étapes suivantes.**

---

## 1. 💾 Extension du disque VirtualBox et conflit swap

### Contexte

**Situation initiale** :
- VM Debian 12 sur VirtualBox
- Disque virtuel trop petit pour installer GLPI et ses dépendances
- Machine hôte limitée : 8 Go RAM, 3 VM simultanées maximum

**Nécessité** : Extension du disque virtuel pour accueillir GLPI

### Symptôme initial

Après extension du disque via VirtualBox et reconfiguration de la partition swap, le swap est désactivé à chaque redémarrage de la VM.

```bash
free -h
```

**Résultat** :

```
              total        used        free      shared  buff/cache   available
Mem:          1.0Gi       450Mi       200Mi        10Mi       350Mi       400Mi
Swap:            0B          0B          0B
```

**Impact critique** : Avec 3 VM actives simultanément et seulement 8 Go RAM sur l'hôte, l'absence de swap provoque des ralentissements importants et des risques de freeze de la VM.

### Diagnostic

#### Hypothèse initiale

Le swap existe physiquement mais **n’est pas activé automatiquement** au démarrage.

---

#### Étape 1 : Vérifier l'état du swap

```bash
swapon --show
```

**Résultat** : Aucune sortie (pas de swap actif)

---

#### Étape 2 : Vérifier /etc/fstab

```bash
cat /etc/fstab
```

**Contenu problématique trouvé** :

```
# /etc/fstab: static file system information.
UUID=xxxx-xxxx-xxxx / ext4 errors=remount-ro 0 1
UUID=yyyy-yyyy-yyyy none swap sw 0 0    ← Ancienne partition swap (n'existe plus)
UUID=zzzz-zzzz-zzzz none swap sw 0 0    ← Nouvelle partition swap
```

**Problème identifié** : Deux références de swap dans `/etc/fstab`, dont une pointant vers une partition qui n'existe plus.

---

#### Étape 3 : Lister les partitions disponibles

```bash
lsblk
```

**Résultat** :

```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   30G  0 disk 
├─sda1   8:1    0   28G  0 part /
└─sda2   8:2    0    2G  0 part [SWAP]    ← Nouvelle partition swap
```

**Constat** : La nouvelle partition swap existe bien (`sda2`), mais n'est pas activée automatiquement au démarrage à cause du conflit dans `/etc/fstab`.

---

#### Étape 4 : Identifier l'UUID de la nouvelle partition swap

```bash
sudo blkid | grep swap
```

**Résultat** :

```
/dev/sda2: UUID="zzzz-zzzz-zzzz" TYPE="swap"
```

---

### Solution appliquée

#### Étape 1 : Identification

Lister les partitions et confirmer l’existence de la partition swap :

```bash
lsblk -f
```

Constat:
- `/dev/sda5` est bien de type `swap`
- Aucun swap actif

Vérification:

```bash
sudo swapon --show
```

Résultat: **aucune sortie** → aucun swap utilisé.

---

#### Étape 2 : Nettoyage (ancienne configuration)

Désactivation complète de tout swap déclaré :

```bash
sudo swapoff -a
```

Nettoyage du fichier `/etc/fstab`:

```bash
sudo nano /etc/fstab
```

Action:
- Commenter (`#`) de **l'ancienne ligne swap avec UUID invalide**
- Aucune modification sur `/dev/sr0` (lecteur CD-ROM virtuel)

---

#### Étape 3 : Préparation du swap

Recréation du swap pour forcer une configuration saine :

```bash
sudo mkswap -f /dev/sda5
```

Effet:
- Nouveau header swap
- **Nouvel UUID généré (noter-le !)**

---

#### Étape 4 : Activation

Activation manuelle :

```bash
sudo swapon /dev/sda5
```

Vérification:

```bash
swapon --show
```

Résultat attendu:
- `/dev/sda5` visible 
- Taille ~ 1.1G
- Swap fonctionnel

---

#### Étape 5 : Persistance 

Récupération de l’UUID :

```bash
blkid /dev/sda5
```

Ajout dans `/etc/fstab`:

```bash
sudo nano /etc/fstab
```

Ligne ajoutée:

```bash
UUID= (noter dans l'étape 3) none swap sw 0 0
```

Test:

```bash
sudo swapoff -a
sudo swapon -a
```

→ **Aucune erreur = fstab valide**

---


#### Étape 6 : Vérification des modifications

```bash
reboot
```

Après reboot:

```bash
free -h
# ou
swapon --show
```

Résultat attendu:

```bash
Swap:       1.1Gi       0B      1.1Gi
```



---

#### Cas particulier : démarrage lent après correction

Symptôme :

- Écran noir ~1 min au boot

Cause :

- Ancien UUID encore présent dans l’initramfs

Correction :

```bash
sudo update-initramfs -u
```

---

### Leçons apprise

- Un swap existant ≠ swap fonctionnel
- `mkswap` régénère l’UUID → **fstab doit être mis à jour**
- Toujours tester avec `swapoff -a && swapon -a`
- En environnement RAM contraint, le swap est **structurel**, pas optionnel
- VirtualBox n’automatise **jamais** la cohérence Linux (fstab / initramfs)

✅ **Lors de l'extension d'un disque virtuel, toujours vérifier `/etc/fstab`** après modification des partitions  
✅ **Les anciennes références de partitions supprimées peuvent causer des conflits**  
✅ **En environnement contraint (8 Go RAM, 3 VM), le swap est CRITIQUE pour la stabilité**  
✅ **VirtualBox permet l'extension de disques, mais la gestion des partitions reste manuelle**

**Ce problème a été le plus impactant** car il affectait directement les performances de toute l'infrastructure de lab (3 VM simultanées).

---

## 2. 🐍 Incompatibilité PHP 8.4 avec GLPI 10.0.16

### Symptôme initial

Lors de l'accès à l'interface d'installation de GLPI via le navigateur :

```
https://192.168.2.x/glpi
```

**Message d'erreur affiché** :

```
Erreur : PHP 7.4.0 - 8.4.0 (exclusive) require
```

### Diagnostic

#### Étape 1 : Vérifier la version de PHP installée

```bash
php -v
```

**Résultat obtenu** :

```
PHP 8.4.16 (cli) (built: Jan 14 2026 10:23:45) ( NTS )
Copyright (c) The PHP Group
Zend Engine v4.4.16, Copyright (c) Zend Technologies
```

**Constat** : Debian 12 installe PHP 8.4 par défaut, mais GLPI 10.0.16 supporte uniquement PHP 7.4 à 8.3 (8.4 exclu).

---

#### Étape 2 : Tentative d'installation de PHP 8.2

**Commande testée** :

```bash
sudo apt install php8.2
```

**Erreur rencontrée** :

```
Lecture des listes de paquets... Fait
Construction de l'arbre des dépendances... Fait
Lecture des informations d'état... Fait
E: Impossible de trouver le paquet php8.2
```

**Cause** : Debian 12 ne propose pas PHP 8.2 dans les dépôts officiels standards.

---

### Solution appliquée : Ajout du dépôt Sury

Le dépôt Sury est le dépôt officiel PHP pour Debian, maintenu par Ondřej Surý (mainteneur Debian PHP).

#### Étape 1 : Ajout du dépôt Sury

```bash
# Installation des prérequis
sudo apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2

# Ajout de la clé GPG
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg

# Ajout du dépôt
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list

# Mise à jour des dépôts
sudo apt update
```

---

#### Étape 2 : Installation de PHP 8.2 et extensions

```bash
sudo apt install -y \
  php8.2 \
  php8.2-cli \
  php8.2-common \
  php8.2-mysql \
  php8.2-gd \
  php8.2-curl \
  php8.2-mbstring \
  php8.2-xml \
  php8.2-intl \
  php8.2-ldap \
  php8.2-apcu \
  php8.2-zip \
  php8.2-bz2 \
  libapache2-mod-php8.2
```

**Point important** : Les paquets Debian 12 utilisent le préfixe de version explicite (`php8.2-mysql`) au lieu de noms génériques (`php-mysql`).

---

#### Étape 3 : Désactivation de PHP 8.4 et activation de PHP 8.2 dans Apache

```bash
# Désactiver PHP 8.4
sudo a2dismod php8.4

# Activer PHP 8.2
sudo a2enmod php8.2

# Définir PHP 8.2 comme version par défaut du système
sudo update-alternatives --set php /usr/bin/php8.2

# Redémarrer Apache
sudo systemctl restart apache2
```

---

#### Étape 4 : Vérification

```bash
# Vérifier la version PHP système
php -v
```

**Résultat attendu** :

```
PHP 8.2.x (cli) ...
```

**Vérifier que PHP 8.2 est bien utilisé par Apache** :

```bash
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/phpinfo.php
```

**Accéder via le navigateur** : `https://192.168.2.x/phpinfo.php`

**Vérifier** : La page doit afficher **PHP Version 8.2.x**

**Supprimer le fichier de test** (sécurité) :

```bash
sudo rm /var/www/html/phpinfo.php
```

---

### Leçon apprise

✅ **Toujours vérifier la matrice de compatibilité** des versions avant installation  
✅ **Debian 12 utilise des préfixes de version explicites** pour les paquets PHP  
✅ **Le dépôt Sury est la solution officielle** pour installer des versions PHP spécifiques sur Debian

---

## 3. 🔐 Droits de fichiers refusés lors de l'installation GLPI

### Symptôme

Lors de l'installation web de GLPI, après sélection de la langue et acceptation de la licence, un message d'erreur bloque la progression.

**Message exact affiché** :

```
Accès en écriture refusé sur les fichiers de configuration

Un accès temporaire en écriture est nécessaire pour les fichiers suivants :
'/var/www/glpi/config/config_db.php'
'/var/www/glpi/config/glpicrypt.key'

L'accès en écriture sur ces fichiers pourra être supprimé une fois l'opération terminée.
```

### Diagnostic

#### Étape 1 : Vérifier les permissions du dossier config

```bash
ls -ld /var/www/glpi/config
```

**Résultat** :

```
drwxr-xr-x 2 www-data www-data 4096 Jan 26 14:00 /var/www/glpi/config
```

**Constat** : Permissions `755` = le propriétaire (www-data) peut écrire, mais GLPI a besoin de permissions plus permissives pendant l'installation.

---

### Solution appliquée

#### Étape 1 : Donner les droits en écriture sur les dossiers critiques

```bash
# Dossier config
sudo chmod -R 775 /var/www/glpi/config

# Dossier files (où GLPI stocke les documents)
sudo chmod -R 775 /var/www/glpi/files

# Dossier marketplace (pour les plugins)
sudo chmod -R 775 /var/www/glpi/marketplace
```

---

#### Étape 2 : Vérifier les permissions

```bash
ls -ld /var/www/glpi/config
ls -ld /var/www/glpi/files
ls -ld /var/www/glpi/marketplace
```

**Résultat attendu** :

```
drwxrwxr-x 2 www-data www-data 4096 Jan 26 14:00 /var/www/glpi/config
drwxrwxr-x 2 www-data www-data 4096 Jan 26 14:00 /var/www/glpi/files
drwxrwxr-x 2 www-data www-data 4096 Jan 26 14:00 /var/www/glpi/marketplace
```

---

#### Étape 3 : Relancer l'installation web

**Recharger la page dans le navigateur** : `https://192.168.2.x/glpi`

**Résultat** : ✅ **L'installation peut continuer sans erreur**

---

### Leçon apprise

✅ **GLPI nécessite des permissions `775` pendant l'installation** sur certains dossiers  
✅ **Ces permissions peuvent être réduites après installation** (`chmod 755` sur config/, `chmod 640` sur les fichiers sensibles)  
✅ **Toujours vérifier les messages d'erreur GLPI**, ils indiquent précisément les fichiers/dossiers problématiques

---

## 4. 🔍 Import LDAP : "Aucun utilisateur à importer" (PROBLÈME CRITIQUE)

### Symptôme

**Situation** :
- Test de connexion LDAP dans GLPI : ✅ **"Connexion réussie"**
- Import des utilisateurs : ❌ **"Aucun utilisateur à importer"**

### Diagnostic étape par étape

#### Étape 1 : Vérifier que les utilisateurs existent dans Active Directory

Sur Windows Server (PowerShell) :

```powershell
Get-ADUser -Filter {SamAccountName -like "*dupont*" -or SamAccountName -like "*martin*" -or SamAccountName -like "*leroy*"} | Select Name, Enabled, DistinguishedName
```

**Résultat** :

```
Name         Enabled DistinguishedName
----         ------- -----------------
Jean Dupont  True    CN=Jean Dupont,OU=GLPI_Users,DC=homelab,DC=local
Marie Martin True    CN=Marie Martin,OU=GLPI_Users,DC=homelab,DC=local
Pierre Leroy True    CN=Pierre Leroy,OU=GLPI_Users,DC=homelab,DC=local
```

✅ **Les utilisateurs existent et sont activés**

---

#### Étape 2 : Test ldapsearch depuis Debian

```bash
ldapsearch -x -H ldap://192.168.2.3:389 \
  -D "CN=Service GLPI,CN=Users,DC=homelab,DC=local" \
  -w "ServiceGLPI2025!" \
  -b "OU=GLPI_Users,DC=homelab,DC=local" \
  "(&(objectClass=user)(objectCategory=person))" \
  cn sAMAccountName givenName sn
```

**Résultat** : ✅ **Les 3 utilisateurs sont retournés avec tous leurs attributs**

---

#### Étape 3 : Vérifier la configuration LDAP dans GLPI

Dans GLPI : Configuration → Authentification → Annuaires LDAP → Active Directory Lab

**Configuration vérifiée** :

```
Serveur : 192.168.2.3
Port : 389
BaseDN : DC=homelab,DC=local
Bind DN : CN=Service GLPI,CN=Users,DC=homelab,DC=local
Filtre : (&(objectClass=user)(objectCategory=person))
```

✅ **Tout semble correct**

---

#### Étape 4 : Vérifier le champ "Champ de l'identifiant"

Dans GLPI : Configuration → Authentification → Annuaires LDAP → Active Directory Lab → Correspondance des champs

**Champ trouvé** :

```
Champ de l'identifiant : uid
```

### 🔥 Problème CRITIQUE identifié

**`uid` est l'attribut utilisé par OpenLDAP, PAS par Active Directory !**

Active Directory utilise **`sAMAccountName`** comme identifiant unique des utilisateurs.

---

### Solution appliquée : Correction de l'attribut d'identifiant

#### Étape 1 : Modifier le champ dans GLPI

Configuration → Authentification → Annuaires LDAP → Active Directory Lab → Correspondance des champs

**Modifier** :

```
Champ de l'identifiant : sAMAccountName
```

**⚠️ IMPORTANT** : **Respecter la casse exacte** : `sAMAccountName` ≠ `samaccountname`

**Sauvegarder**

---

#### Étape 2 : Tester l'import

Administration → Utilisateurs → Liaison annuaire LDAP → Importation de nouveaux utilisateurs

**Mode expert** :

```
Base DN : OU=GLPI_Users,DC=homelab,DC=local
Filtre : (&(objectClass=user)(objectCategory=person))
```

**Cliquer sur "Rechercher"**

**Résultat** : ✅ **3 utilisateurs trouvés !**

```
- Jean Dupont (jdupont)
- Marie Martin (mmartin)
- Pierre Leroy (pleroy)
```

---

#### Étape 3 : Importer les utilisateurs

**Sélectionner les 3 utilisateurs** → **Actions** → **Importer**

**Résultat** : ✅ **Import réussi**

**Vérification** : Administration → Utilisateurs

Les 3 utilisateurs apparaissent maintenant dans la liste.

---

### Leçon apprise

✅ **Active Directory utilise `sAMAccountName`, PAS `uid`**  
✅ **La casse est CRITIQUE en LDAP** : `sAMAccountName` ≠ `samaccountname`  
✅ **Tester avec `ldapsearch` permet de valider la configuration** avant de l'appliquer dans GLPI  
✅ **Cette erreur est très courante** lors de l'intégration LDAP entre applications et Active Directory

**Cette erreur a été la plus difficile à diagnostiquer** car :
- Le test de connexion LDAP réussissait
- Les utilisateurs existaient bien dans AD
- Le problème ne venait ni du réseau, ni des permissions, mais d'un simple attribut mal configuré

---

## 5. ⚙️ Commandes incompatibles selon les versions

### Symptômes

Plusieurs commandes classiques retournent des erreurs "commande introuvable" lors de l'installation.

### Problèmes rencontrés

#### Problème 1 : mysql_secure_installation introuvable

**Commande tentée** :

```bash
sudo mysql_secure_installation
```

**Erreur** :

```
sudo: mysql_secure_installation: commande introuvable
```

**Cause** : Depuis MariaDB 10.6+, la commande a été renommée.

**Solution** :

```bash
sudo mariadb-secure-installation
```

---

#### Problème 2 : Paquets PHP avec préfixe de version

**Commandes tentées** :

```bash
sudo apt install php-mysql
sudo apt install php-ldap
```

**Erreur** :

```
E: Impossible de trouver le paquet php-mysql
E: Impossible de trouver le paquet php-ldap
```

**Cause** : Debian 12 utilise des préfixes de version explicites pour PHP.

**Solution** :

```bash
sudo apt install php8.2-mysql
sudo apt install php8.2-ldap
# Etc. pour toutes les extensions
```

---

### Leçon apprise

✅ **Les commandes évoluent entre les versions** : toujours vérifier la documentation de la version exacte utilisée  
✅ **MariaDB 10.6+ utilise `mariadb-*` au lieu de `mysql-*`**  
✅ **Debian 12 utilise des préfixes de version explicites** pour les paquets PHP

---

## 6. 📦 Téléchargement GLPI échoue avec wget

### Symptôme

Lors de la tentative de téléchargement de GLPI avec `wget`, l'erreur 404 Not Found est retournée pour toutes les versions testées.

**Commandes tentées** :

```bash
wget https://github.com/glpi-project/glpi/releases/download/10.0.17/glpi-10.0.17.tgz
wget https://github.com/glpi-project/glpi/releases/download/10.0.16/glpi-10.0.16.tgz
wget https://github.com/glpi-project/glpi/releases/download/10.0.15/glpi-10.0.15.tgz
```

**Erreur systématique** :

```
--2026-01-26 14:30:15--  https://github.com/glpi-project/glpi/releases/download/10.0.16/glpi-10.0.16.tgz
Resolving github.com (github.com)... 140.82.121.4
Connecting to github.com (github.com)|140.82.121.4|:443... connected.
HTTP request sent, awaiting response... 404 Not Found
2026-01-26 14:30:16 ERROR 404: Not Found.
```

### Diagnostic

#### Étape 1 : Vérifier la connectivité Internet

```bash
ping -c 4 8.8.8.8
```

**Résultat** : ✅ Connectivité OK

---

#### Étape 2 : Vérifier la résolution DNS

```bash
nslookup github.com
```

**Résultat** : ✅ Résolution OK

---

#### Étape 3 : Tester l'accès HTTPS à GitHub

```bash
curl -I https://github.com
```

**Résultat** : ✅ Connexion HTTPS fonctionne

---

### Solution appliquée : Téléchargement manuel

**Cause probable** : URLs obsolètes ou structure GitHub modifiée

**Solution** :

1. **Ouvrir Firefox dans la VM Debian**
2. **Aller sur** : https://github.com/glpi-project/glpi/releases
3. **Trouver la version 10.0.16**
4. **Télécharger** : `glpi-10.0.16.tgz`
5. **Le fichier est téléchargé dans** : `~/Téléchargements/`

**Installation depuis le fichier téléchargé** :

```bash
cd ~/Téléchargements
sudo tar -xzf glpi-10.0.16.tgz -C /var/www/
sudo chown -R www-data:www-data /var/www/glpi
sudo chmod -R 755 /var/www/glpi
```

---

### Leçon apprise

✅ **Les URLs GitHub peuvent changer ou être obsolètes**  
✅ **En cas d'échec de `wget`, le téléchargement manuel via navigateur est une solution viable**  
✅ **Toujours vérifier les releases officielles** sur la page GitHub du projet

---

## 📊 Synthèse : Ordre de diagnostic en cas d'échec

Si le déploiement ne fonctionne pas, suivre cet ordre :

```
1. INFRASTRUCTURE VIRTUALBOX
   └─ Espace disque suffisant ? Swap activé ?
       ├─ ❌ → Vérifier /etc/fstab, étendre le disque si nécessaire
       └─ ✅ → Passer à l'étape 2

2. RÉSEAU ET DNS
   └─ pfSense distribue les IP ? AD résout les noms externes ?
       ├─ ❌ → Vérifier les forwarders DNS sur l'AD, /etc/resolv.conf sur Debian
       └─ ✅ → Passer à l'étape 3

3. STACK APPLICATIVE
   └─ Apache, PHP 8.2, MariaDB installés et actifs ?
       ├─ ❌ → Vérifier versions, systemctl status, logs
       └─ ✅ → Passer à l'étape 4

4. GLPI INSTALLÉ
   └─ Interface web accessible ? Droits de fichiers corrects ?
       ├─ ❌ → Vérifier permissions (775 sur config/files/marketplace)
       └─ ✅ → Passer à l'étape 5

5. CONNEXION LDAP
   └─ Test de connexion LDAP réussi ?
       ├─ ❌ → Vérifier bind DN, mot de passe, tester avec ldapsearch
       └─ ✅ → Passer à l'étape 6

6. IMPORT UTILISATEURS
   └─ Utilisateurs AD importés ?
       ├─ ❌ → Vérifier attribut sAMAccountName, BaseDN, filtre LDAP
       └─ ✅ → Configuration complète ✅
```

---

## 🔧 Commandes essentielles de diagnostic

### Infrastructure VirtualBox et swap

```bash
# Vérifier l'espace disque
df -h

# Vérifier le swap
free -h
swapon --show

# Lister les partitions
lsblk

# Vérifier /etc/fstab
cat /etc/fstab

# Activer le swap
sudo swapon -a
```

### Réseau et DNS

```bash
# Vérifier la résolution DNS
cat /etc/resolv.conf
ping homelab.local
nslookup homelab.local

# Tester la connectivité AD
ping 192.168.2.3
nc -vz 192.168.2.3 389  # Test port LDAP
```

### Stack applicative

```bash
# Versions
php -v
mysql --version
apache2 -v

# Statuts services
sudo systemctl status apache2
sudo systemctl status mariadb

# Logs
sudo tail -f /var/log/apache2/error.log
```

### GLPI et LDAP

```bash
# Permissions
ls -ld /var/www/glpi/config
ls -l /var/www/glpi/config/config_db.php

# Test bind LDAP
ldapsearch -x -H ldap://192.168.2.3:389 \
  -D "CN=Service GLPI,CN=Users,DC=homelab,DC=local" \
  -w "Password" \
  -b "DC=homelab,DC=local" \
  "(objectClass=user)"

# Recherche utilisateur spécifique
ldapsearch -x -H ldap://192.168.2.3:389 \
  -D "CN=Service GLPI,CN=Users,DC=homelab,DC=local" \
  -w "Password" \
  -b "OU=GLPI_Users,DC=homelab,DC=local" \
  "(sAMAccountName=jdupont)" \
  cn sAMAccountName givenName sn
```

---

## 💡 Leçons globales apprises

### 1. Gestion du stockage virtualisé

L'extension d'un disque VirtualBox nécessite une gestion manuelle des partitions et du fichier `/etc/fstab`. Les anciennes références peuvent causer des conflits silencieux.

### 2. Toujours vérifier la matrice de compatibilité

L'erreur PHP 8.4 aurait pu être évitée en consultant la documentation GLPI avant installation.

### 3. Active Directory ≠ OpenLDAP

`sAMAccountName` (AD) vs `uid` (OpenLDAP) : cette confusion est très courante et difficile à diagnostiquer.

### 4. La casse compte en LDAP

`sAMAccountName` ≠ `samaccountname`. Active Directory est sensible à la casse pour les attributs.

### 5. ldapsearch est ton meilleur ami

Tester les requêtes LDAP en ligne de commande AVANT de les configurer dans l'application évite beaucoup de pertes de temps.

### 6. Les logs sont essentiels

`/var/log/apache2/error.log` et `systemctl status` ont été déterminants pour identifier les problèmes.

### 7. Les versions applicatives évoluent

MariaDB 10.6+ et Debian 12 ont introduit des changements dans les noms de commandes et de paquets. Toujours consulter la documentation de la version exacte utilisée.

### 8. En environnement contraint, le swap est critique

Avec 3 VM simultanées et 8 Go RAM sur l'hôte, le swap est indispensable pour la stabilité. Une mauvaise configuration peut dégrader drastiquement les performances.

---

## 📚 Commandes de vérification complète

```bash
# 1. Infrastructure
free -h
df -h
lsblk
cat /etc/fstab

# 2. Réseau
ping homelab.local
ping 192.168.2.3
nslookup homelab.local

# 3. Services
sudo systemctl status apache2
sudo systemctl status mariadb

# 4. PHP
php -v
php -m | grep -E "ldap|mysqli|gd"

# 5. LDAP bind
ldapsearch -x -H ldap://192.168.2.3:389 \
  -D "CN=Service GLPI,CN=Users,DC=homelab,DC=local" \
  -w "ServiceGLPI2025!" \
  -b "DC=homelab,DC=local" \
  "(objectClass=user)"

# 6. Utilisateurs AD
ldapsearch -x -H ldap://192.168.2.3:389 \
  -D "CN=Service GLPI,CN=Users,DC=homelab,DC=local" \
  -w "ServiceGLPI2025!" \
  -b "OU=GLPI_Users,DC=homelab,DC=local" \
  "(sAMAccountName=jdupont)"

# 7. Permissions GLPI
ls -ld /var/www/glpi
ls -ld /var/www/glpi/config/
ls -ld /var/www/glpi/files/

# 8. Logs
sudo tail -20 /var/log/apache2/error.log
```

---

**Note finale** : Ce document reflète mon expérience réelle du projet. Tous les problèmes décrits ont été rencontrés et résolus. Les commandes indiquées sont celles qui ont effectivement fonctionné dans mon environnement.
