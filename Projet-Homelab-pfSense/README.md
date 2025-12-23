# Homelab virtualisé – pfSense & environnements multi-OS

## 🎯 Objectif du projet
Concevoir et déployer un homelab virtualisé afin de comprendre le fonctionnement d’une infrastructure réseau et système proche d’un environnement professionnel, en mettant l’accent sur la sécurité, le cloisonnement et la gestion des flux réseau.

---

## 🧠 Contexte
Ce projet a été réalisé dans un cadre d’autoformation après l’obtention de mon **BTS CIEL option IR**.  
L’objectif était de mettre en pratique des notions vues en cours (firewall, NAT, segmentation, services systèmes) dans un environnement concret et maîtrisé.

---

## 🏗️ Architecture générale
- Infrastructure virtualisée
- Pare-feu **pfSense** en frontal
- Machines virtuelles :
  - Linux (Debian)
  - Windows Server 2022 (version d’évaluation 180 jours)
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
- Les concepts VLAN ont déjà été pratiqués en ligne de commande dans un autre contexte

📌 En environnement réel, des VLAN auraient été utilisés pour séparer :
- Utilisateurs
- Serveurs
- Administration
- DMZ

---

## 🖥️ Systèmes déployés
- **Linux (Debian)** :
  - Services systèmes
  - Tests d’intégration réseau
- **Windows Server 2022** :
  - Environnement serveur
  - Tests de rôles et services Windows

---

## ⚙️ Mise en œuvre
### Prérequis
- Hyperviseur (environnement virtualisé)
- pfSense
- Images ISO Linux et Windows Server
- Accès réseau contrôlé

Les étapes de configuration détaillées sont disponibles dans la documentation associée.

---

## ✅ Résultats obtenus
- Infrastructure fonctionnelle et isolée du réseau local
- Pare-feu pfSense opérationnel
- Communication contrôlée entre les machines virtuelles
- Compréhension concrète des flux réseau et des règles de filtrage

---

## ⚠️ Problèmes rencontrés
- Limitations liées à la présence d’une seule carte réseau
- Contraintes sur le NAT et la segmentation
- Ajustement des règles firewall pour éviter les blocages involontaires

Ces difficultés ont permis de mieux comprendre :
- l’impact du matériel sur l’architecture réseau
- l’importance de la segmentation
- le rôle central du pare-feu dans une infrastructure

---

## 🚀 Améliorations possibles (vision entreprise)
- Mise en place de VLAN avec matériel adapté
- Ajout d’une DMZ
- Supervision réseau
- Centralisation des logs
- Sauvegarde et restauration de la configuration pfSense

