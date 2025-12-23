# Homelab virtualisé – pfSense & environnements multi-OS

## 🎯 Objectif du projet
Concevoir et déployer un homelab réseau virtualisé afin de simuler une infrastructure d’entreprise, avec un pare-feu dédié, une séparation LAN/WAN et la possibilité d’intégrer plusieurs machines clientes et serveurs internes.

---

## 🧠 Contexte
Ce projet a été réalisé dans un cadre d’autoformation après l’obtention de mon **BTS CIEL option IR**, dans le but de développer mes compétences en administration systèmes et réseaux à travers un environnement de test proche des conditions réelles.

---

## 🏗️ Architecture
- Environnement virtualisé basé sur **VirtualBox**
- Système hôte : **Kali Linux**
- Pare-feu dédié : **pfSense**
- Séparation réseau :
  - **WAN** : connecté à la box Internet
  - **LAN** : réseau interne isolé

📌 Un schéma de la topologie réseau est disponible dans le dossier `diagrammes/`.

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
  - **Windows Server**
- Simulation d’un réseau interne d’entreprise derrière un pare-feu

---

## ⚠️ Problème rencontré
Par défaut, VirtualBox ne proposait pas automatiquement plusieurs adaptateurs réseau sur Kali Linux.

### Analyse
- Nécessité de comprendre et manipuler les différents modes réseau de VirtualBox :
  - NAT
  - Bridged
  - Internal network

### Solution
- Configuration manuelle des interfaces réseau via la commande :
  - `VBoxManage`
- Vérification du bon fonctionnement des interfaces côté pfSense

Cette étape a permis de mieux comprendre l’impact des modes réseau sur l’architecture globale.

---

## ✅ Résultats obtenus
- Réseau virtuel isolé derrière pfSense
- Accès Internet fonctionnel depuis le LAN
- Infrastructure stable et réutilisable
- Possibilité d’expérimenter différents scénarios :
  - règles de firewall
  - segmentation réseau
  - hébergement de services internes

---

## 🧠 Compétences mises en œuvre
- Déploiement et configuration d’un pare-feu pfSense
- Gestion de la segmentation réseau LAN / WAN
- Compréhension et configuration des modes réseau VirtualBox
- Conception d’une infrastructure réseau virtualisée
- Mise en place d’un environnement de test proche d’un réseau d’entreprise

---

## 🚀 Évolutions possibles (vision entreprise)
- Mise en place de VLAN
- Intégration d’un Active Directory
- Déploiement d’IDS / IPS
- Supervision réseau
- Centralisation des logs
