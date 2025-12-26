# Intégration Linux ↔ Active Directory  
Authentification centralisée Debian via Kerberos, SSSD et PAM

## Objectif du projet
Mettre en place une authentification centralisée Active Directory pour des systèmes Linux Debian, avec :
- un contrôle strict des accès SSH,
- une gestion centralisée des droits administrateurs (sudo),
- aucune dépendance à des solutions propriétaires tierces.

Le projet vise à reproduire un cas réel d’infrastructure d’entreprise et à comprendre les mécanismes sous-jacents (DNS, Kerberos, SSSD, PAM), au-delà d’un simple fonctionnement « clé en main ».

---

## Contexte
Projet réalisé de manière autonome dans un laboratoire personnel après l’obtention d’un **BTS CIEL option IR**.  
Il s’inscrit dans une démarche de montée en compétences en administration systèmes et en intégration d’environnements Windows / Linux en contexte professionnel.

---

## Architecture
- Windows Server 2022  
  - Active Directory Domain Services  
  - DNS  
  - Kerberos (KDC)
- Debian GNU/Linux (client du domaine)
- pfSense (routage)
- Domaine : `homelab.local`

Le serveur Windows agit comme autorité d’authentification.  
Les systèmes Linux délèguent l’authentification et le contrôle d’accès à Active Directory.

📌 Schéma réseau : dossier `diagrammes/` 
[Diagrammes détaillé](Diagrammes/Topologie-Réseau-Active-Directory-Linux.png) 

---

## Principe de fonctionnement
- Authentification des utilisateurs Linux via **Kerberos**
- Résolution des identités et groupes Active Directory via **SSSD**
- Contrôle des accès assuré par **PAM**
- Filtrage explicite des accès par groupes AD

Groupes utilisés :
- `linux-users` : accès SSH
- `linux-admins` : accès SSH + sudo
- Aucun accès implicite pour `Domain Users`

Cette séparation permet de distinguer clairement :
- authentification,
- autorisation,
- gestion des privilèges.

---

## Mise en œuvre technique
### Composants principaux
- `realmd`
- `sssd`
- `krb5`
- `pam`
- `nss`

### Pré-requis essentiels
- Résolution DNS fonctionnelle (enregistrements AD complets)
- Synchronisation horaire (NTP)
- Connectivité réseau entre les machines

Les scripts et fichiers de configuration sont disponibles dans le dossier `scripts/`.
[Scripts détaillé](Scripts/)

---

## Problèmes rencontrés et résolution
- **DNS**
  - Résolution FQDN incomplète, enregistrements SRV manquants
  - Correction des enregistrements A / PTR / SRV côté Active Directory

- **Kerberos**
  - Échecs de `kinit` malgré des identifiants valides
  - Causes : incohérences DNS / realm, comptes AD désactivés, configuration `krb5.conf`

- **SSSD / PAM**
  - Authentification réussie mais accès SSH refusé
  - Filtrage par groupes mal appliqué et cache SSSD non purgé

- **Répertoires utilisateurs**
  - Absence de home directories
  - Activation de la création automatique via PAM

Ces incidents ont permis de distinguer clairement les rôles de chaque composant dans la chaîne d’authentification.

---

## Résultats
- Intégration fonctionnelle entre Active Directory et Linux
- Accès SSH contrôlé par groupes AD
- Droits sudo gérés via Active Directory
- Création automatique des répertoires utilisateurs
- Infrastructure stable et reproductible

Les tests ont été réalisés avec des comptes autorisés et non autorisés afin de valider les contrôles d’accès.

---

## Améliorations possibles
- Automatisation de l’intégration via Ansible
- Centralisation et exploitation des logs
- Supervision des services d’authentification
- Déploiement sur plusieurs clients Linux

---

## Compétences démontrées
- Administration Active Directory
- DNS (A, PTR, SRV)
- Kerberos
- Intégration Linux / AD (SSSD, PAM, NSS)
- Gestion des accès et des privilèges
- Diagnostic et résolution d’incidents systèmes
