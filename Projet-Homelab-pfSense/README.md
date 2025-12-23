# Homelab virtualisé – pfSense & environnements multi-OS

## 🎯 Objectif du projet
Concevoir et déployer un homelab réseau virtualisé afin de simuler une infrastructure d’entreprise, avec un pare-feu dédié, une séparation LAN/WAN et la possibilité d’intégrer plusieurs machines clientes et serveurs internes.

---

## 🧠 Contexte
Ce projet a été réalisé dans un cadre d’autoformation après l’obtention de mon **BTS CIEL option IR**, dans le but de développer mes compétences en administration systèmes et réseaux à travers un environnement de test proche des conditions réelles.

---

## 🏗️ Architecture générale
- Infrastructure virtualisée
- Système hôte : **Kali Linux**
- Hyperviseur : **VirtualBox**
- Pare-feu dédié : **pfSense**
- Séparation réseau :
  - **WAN** : connecté à la box Internet
  - **LAN** : réseau interne isolé
- Machines virtuelles :
  - **Debian**
  - **Windows Server 2022** (version d’évaluation 180 jours)
- Réseau séparé du réseau local principal

📌 Un schéma de l’architecture est disponible dans le dossier `diagrammes/`.

---

## 🌐 Réseau & sécurité

### Pare-feu
- pfSense utilisé comme pare-feu principal
- Règles de filtrage configurées pour contrôler les flux entrants et sortants
- Accès restreint entre les machines selon leur rôle

### NAT
- NAT fonctionnel mais **limité** en raison de contraintes matérielles
- Une seule carte réseau physique disponible sur la machine hôte

👉 Cette contrainte a été prise en compte volontairement afin de travailler malgré un environnement non idéal, comme cela peut arriver en entreprise.

---

## 🔌 VLAN
Les VLAN ne sont **pas implémentés dans ce homelab** pour les raisons suivantes :
- Limitation matérielle (une seule interface réseau)
- Les concepts VLAN ont déjà été pratiqués dans un autre contexte

📌 En environnement réel, des VLAN auraient été utilisés pour séparer :
- Utilisateurs
- Serveurs
- Administration
- DMZ

---

## ⚙️ Déroulement du projet

### Environnement de virtualisation
- Choix de **VirtualBox** comme hyperviseur
- Objectif : conserver un poste de travail léger et polyvalent tout en permettant des tests réseau avancés

### Configuration réseau
- pfSense configuré avec deux interfaces réseau :
  - WAN : accès Internet
  - LAN : réseau interne isolé
- Mise en place des règles de base pour permettre la communication contrôlée entre LAN et WAN

### Extension du lab
- Intégration de plusieurs machines virtuelles dans le LAN :
  - **Debian**
  - **Windows Server 2022**
- Simulation d’un réseau interne d’entreprise derrière un pare-feu

---

## ⚠️ Problèmes rencontrés

### Contraintes matérielles
- Présence d’une seule carte réseau physique
- Limitations sur le NAT et la segmentation

Ces contraintes ont permis de mieux comprendre :
- l’impact du matériel sur l’architecture réseau
- l’importance de la segmentation
- le rôle central du pare-feu dans une infrastructure

---

### Configuration des interfaces VirtualBox
Par défaut, VirtualBox ne proposait pas automatiquement plusieurs adaptateurs réseau sur Kali Linux.

#### Analyse
- Nécessité de comprendre et manipuler les différents modes réseau :
  - NAT
  - Bridged
  - Internal Network

#### Solution
- Configuration manuelle des interfaces réseau via la commande :
  - `VBoxManage`
- Vérification du bon fonctionnement des interfaces côté pfSense

Cette étape a permis de mieux comprendre l’impact des modes réseau sur l’architecture globale.

---

## ✅ Résultats obtenus
- Infrastructure fonctionnelle et isolée du réseau local
- Pare-feu pfSense opérationnel
- Communication contrôlée entre les machines virtuelles
- Compréhension concrète des flux réseau et des règles de filtrage

---

## 🧠 Compétences mises en œuvre
- Déploiement et configuration d’un pare-feu pfSense
- Gestion de la segmentation réseau LAN / WAN
- Compréhension et configuration des modes réseau VirtualBox
- Conception d’une infrastructure réseau virtualisée
- Mise en place d’un environnement de test proche d’un réseau d’entreprise

---

## 🚀 Améliorations possibles (vision entreprise)
- Mise en place de VLAN avec matériel adapté
- Ajout d’une DMZ
- Supervision réseau
- Centralisation des logs
- Sauvegarde et restauration de la configuration pfSense
