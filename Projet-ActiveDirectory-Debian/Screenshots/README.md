# 📸 Screenshots - Projet Active Directory Linux

Ce dossier contient les captures d'écran démontrant le fonctionnement de l'infrastructure Active Directory avec clients Linux et Windows.

---

## 🔐 Authentification et résolution des identités

### 1. Résolution d'un utilisateur AD par SSSD

![id Administrateur@homelab.local](01_id_administrateur.png)

**Commande** : `id Administrateur@homelab.local`

**Démontre** : 
- SSSD résout correctement l'utilisateur Active Directory
- L'utilisateur appartient aux groupes AD (linux-users, linux-admins)
- Mapping uid/gid fonctionnel

---

### 2. Enregistrements DNS SRV - Kerberos

![dig SRV _kerberos._tcp.homelab.local](02_dig_srv_kerberos.png)

**Commande** : `dig SRV _kerberos._tcp.homelab.local`

**Démontre** :
- Enregistrements SRV Kerberos correctement configurés dans AD
- Le client Linux peut localiser le KDC (Key Distribution Center)
- Configuration DNS essentielle au fonctionnement de Kerberos

---

### 3. Enregistrements DNS SRV - LDAP

![dig SRV _ldap._tcp.homelab.local](03_dig_srv_ldap.png)

**Commande** : `dig SRV _ldap._tcp.homelab.local`

**Démontre** :
- Enregistrements SRV LDAP présents dans la zone DNS AD
- SSSD peut localiser les contrôleurs de domaine pour les requêtes LDAP
- Infrastructure DNS complète et fonctionnelle

---

### 4. Authentification Kerberos

![kinit et klist](04_kinit_klist.png)

**Commandes** :
```bash
kinit Administrateur@HOMELAB.LOCAL
klist
```

**Démontre** :
- Authentification Kerberos réussie
- Obtention d'un Ticket Granting Ticket (TGT) valide
- Communication fonctionnelle avec le KDC Active Directory

---

### 5. Configuration du domaine (realm)

![realm list](05_realm_list.png)

**Commande** : `realm list`

**Démontre** :
- Machine correctement jointe au domaine homelab.local
- Groupes autorisés : linux-users, linux-admins
- Configuration realmd/SSSD opérationnelle

---

## 🔑 Contrôle d'accès et privilèges

### 6. Connexion SSH avec utilisateur Active Directory

![SSH avec utilisateur AD](06_ssh_connexion_ad.png)

**Commande** : `ssh Administrateur@homelab.local@192.168.2.2`

**Démontre** :
- Accès SSH fonctionnel avec un compte Active Directory
- Authentification Kerberos validée
- Filtrage par groupe AD opérationnel (membre de linux-users)
- **Objectif principal du projet atteint** ✅

---

### 7. Droits sudo via Active Directory

![sudo -l pour linux-admins](07_sudo_l_admin.png)

**Commande** : `sudo -l`

**Démontre** :
- Droits sudo accordés via l'appartenance au groupe AD linux-admins
- Gestion des privilèges centralisée dans Active Directory
- Configuration PAM et SSSD correcte pour sudo

---

## 🖥️ Infrastructure Active Directory

### 8. Ordinateurs joints au domaine

![Vue AD - Ordinateurs](08_ad_computers.png)

**Source** : Active Directory Users and Computers (Windows Server)

**Démontre** :
- Clients Linux (Debian) et Windows (Windows 10 LTSC) visibles dans AD
- Infrastructure multi-OS fonctionnelle
- Gestion unifiée d'un parc mixte

---

### 9. Groupes de sécurité Linux

![Groupes linux-users et linux-admins](09_ad_groupes_linux.png)

**Source** : Active Directory Users and Computers (Windows Server)

**Démontre** :
- Groupes AD personnalisés pour le contrôle d'accès Linux
- Utilisateurs correctement affectés aux groupes
- Structure de sécurité organisée et claire

---

### 10. Windows 10 joint au domaine

![systeminfo Windows 10](10_windows10_domaine.png)

**Commande** : `systeminfo | findstr Domaine`

**Démontre** :
- Client Windows 10 LTSC correctement intégré au domaine
- Extension de l'infrastructure validée
- Interopérabilité Linux/Windows dans le même domaine AD

---

## 📊 Synthèse

Ces screenshots démontrent :

✅ **DNS** : Enregistrements A, PTR, SRV correctement configurés  
✅ **Kerberos** : Authentification centralisée fonctionnelle  
✅ **SSSD** : Résolution des identités et groupes Active Directory  
✅ **PAM** : Contrôle d'accès SSH et gestion sudo via AD  
✅ **Infrastructure mixte** : Clients Linux et Windows dans le même domaine  

**Résultat** : Infrastructure complète et opérationnelle reproduisant un environnement d'entreprise réaliste.

---

## 🔗 Documentation complète

* 📄 [Compte-rendu du projet](../Documents/Projet_Active_Directory_Linux_Compte_rendu.pdf)
* 🐛 [Guide de dépannage](../TROUBLESHOOTING.md)
* 💻 [Scripts d'installation](../Script/)
* 🗺️ [Schémas réseau](../Diagrammes/)