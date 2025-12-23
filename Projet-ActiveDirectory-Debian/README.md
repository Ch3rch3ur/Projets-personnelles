# Active Directory Linux – Debian / PAM / SSSD / Kerberos

## 🎯 Objectif
Mettre en place une infrastructure d’authentification centralisée permettant à des machines Linux Debian de s’authentifier sur un domaine Active Directory, avec une gestion fine des droits utilisateurs et administrateurs.

---

## 🧠 Contexte
Ce projet a été réalisé dans un cadre d’autoformation après l’obtention de mon **BTS CIEL option IR**.  
L’objectif était de comprendre le fonctionnement réel de l’authentification en environnement professionnel, notamment dans des infrastructures mixtes Windows / Linux.

---

## 🏗️ Architecture
- 1 contrôleur de domaine Active Directory
- 1 machine cliente Debian
- Authentification basée sur Kerberos
- Gestion des identités via SSSD
- PAM utilisé pour l’authentification système

📌 Schéma réseau disponible dans le dossier `diagrammes/`.

---

## 🔐 Principe de fonctionnement
- **PAM** gère les mécanismes d’authentification côté système Linux
- **SSSD** interroge l’Active Directory pour récupérer les identités et les droits
- **Kerberos** fournit un ticket d’authentification permettant l’accès aux ressources sans saisie répétée du mot de passe

Les utilisateurs standards n’ont **aucun accès sudo**, contrairement aux comptes administrateurs.

---

## ⚙️ Mise en œuvre
### Prérequis
- Debian 11 ou 12
- Accès réseau au contrôleur de domaine
- Synchronisation horaire (NTP)
- Résolution DNS fonctionnelle

### Paquets utilisés
- sssd
- krb5-user
- libpam-sss

Les fichiers de configuration et scripts sont disponibles dans le dossier `scripts/`.

---

## ✅ Résultats
- Authentification réussie des utilisateurs du domaine sur Debian
- Séparation effective des rôles utilisateurs / administrateurs
- Accès sudo limité aux groupes administrateurs

---

## ⚠️ Problèmes rencontrés
- Erreurs Kerberos liées à la synchronisation horaire
- Mauvaise résolution DNS initiale
- Droits incorrects sur certains groupes

Ces problèmes ont permis de mieux comprendre les dépendances entre Kerberos, DNS et NTP.

---

## 🚀 Améliorations possibles
- Automatisation de l’intégration avec Ansible
- Centralisation des logs
- Supervision des services d’authentification
- Déploiement sur plusieurs machines clientes


