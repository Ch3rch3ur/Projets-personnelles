# 🔐 Active Directory Linux - Authentification centralisée

Intégration de systèmes Debian dans un domaine Active Directory avec authentification Kerberos et contrôle d'accès par groupes AD.

---

## 📋 Contexte

Projet autonome réalisé dans un laboratoire personnel après l'obtention d'un BTS CIEL option IR. L'objectif est de maîtriser l'intégration Linux/Active Directory, un besoin réel en entreprise pour la gestion centralisée des accès aux serveurs.

---

## 🎯 Objectif du projet

Mettre en place une **authentification centralisée Active Directory** pour des systèmes Linux, en reproduisant un cas réel d'infrastructure d'entreprise :

* Gestion centralisée des comptes utilisateurs
* Contrôle strict des accès SSH par groupes AD
* Gestion des droits administrateurs (sudo) via AD
* Maîtrise des mécanismes sous-jacents (DNS, Kerberos, SSSD, PAM)

**Aucune solution propriétaire tierce utilisée** - uniquement des outils open source.

---

## 🏗️ Architecture

**Composants de l'infrastructure :**

* **Windows Server 2022**
  * Active Directory Domain Services
  * DNS
  * Kerberos (KDC)
* **Debian GNU/Linux** (clients du domaine)
  * realmd, SSSD, PAM, NSS
* **pfSense** (routeur/firewall)
* **Domaine** : `homelab.local`

**Principe** : Windows Server agit comme autorité d'authentification. Les systèmes Linux délèguent l'authentification et le contrôle d'accès à Active Directory.

### 📸 Topologie réseau

![Schéma réseau](Diagrammes/Topologie-Réseau-Active-Directory-Linux.png)

📁 [Voir les schémas détaillés →](Diagrammes/)

---

## ⚙️ Fonctionnalités réalisées

✅ Authentification Linux via Kerberos  
✅ Résolution des identités et groupes via SSSD  
✅ Contrôle d'accès SSH par groupes Active Directory  
✅ Gestion des droits sudo via Active Directory  
✅ Création automatique des répertoires utilisateurs  
✅ Séparation stricte utilisateurs standards / administrateurs

### Groupes Active Directory utilisés

* **`linux-users`** : accès SSH uniquement
* **`linux-admins`** : accès SSH + droits sudo
* **Aucun accès implicite** pour `Domain Users`

---

## 🔧 Technologies utilisées

`Kerberos` `SSSD` `PAM` `NSS` `realmd` `DNS` `LDAP` `Windows Server 2022` `Debian 12` `pfSense`

---

## 🐛 Principaux défis techniques

Au cours du projet, plusieurs incidents ont permis de distinguer clairement les rôles de chaque composant (authentification, autorisation, résolution de noms) :

### DNS
* **Problème** : Résolution FQDN incomplète, enregistrements AD manquants
* **Solution** : Correction des enregistrements A, PTR et SRV côté Active Directory

### Kerberos
* **Problème** : Erreurs lors de `kinit` malgré des identifiants valides
* **Causes** : Incohérences DNS/realm, comptes AD désactivés, configuration `krb5.conf` incorrecte

### SSSD / PAM
* **Problème** : Authentification réussie mais accès SSH refusé
* **Causes** : Filtrage par groupes AD mal appliqué, cache SSSD non purgé

### Répertoires utilisateurs
* **Problème** : Home directories absents après première connexion
* **Solution** : Activation de la création automatique via PAM

👉 **Détails et commandes de résolution** : [TROUBLESHOOTING.md](troubleshooting.md)

---

## 📊 Résultats

* ✅ Intégration complète et fonctionnelle entre Active Directory et Linux
* ✅ Infrastructure stable et reproductible
* ✅ Tests validés avec comptes autorisés et non autorisés
* ✅ Accès SSH et droits sudo vérifiés et conformes

---

## 📚 Documentation

* 📄 [Compte-rendu complet (PDF)](Documents/Projet_Active_Directory_Linux_Compte_rendu.pdf) - Analyse détaillée avec flux réseau OSI
* 💻 [Scripts d'installation](Script/) - Scripts Bash avec notes d'installation
* 🗺️ [Schémas réseau](Diagrammes/) - Topologie de l'infrastructure
* 🐛 [Guide de dépannage](TROUBLESHOOTING.md) - Problèmes rencontrés et solutions détaillées
* 💻 [Screenshoots](Screenshoots/) - Scripts Bash avec notes d'installation

---

## 🎓 Compétences démontrées

* Administration Active Directory (DNS, Kerberos)
* Configuration DNS avancée (enregistrements A, PTR, SRV)
* Intégration multi-OS (Linux/Windows)
* Gestion des accès et des privilèges
* Diagnostic et résolution d'incidents systèmes
* Documentation technique professionnelle

---

## 🔄 Améliorations possibles

* Automatisation de l'intégration via Ansible
* Centralisation et exploitation des logs
* Supervision des services d'authentification (Nagios/Zabbix)
* Déploiement sur plusieurs clients Linux avec gestion centralisée
