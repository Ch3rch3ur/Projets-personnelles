# Serveur VPN WireGuard – Raspberry Pi

## 🎯 Objectif du projet
Mettre en place un serveur VPN sécurisé basé sur **WireGuard**, permettant un accès distant chiffré à une infrastructure personnelle tout en garantissant la confidentialité et l’intégrité des communications.

---

## 🧠 Contexte
Ce projet a été réalisé dans un cadre d’autoformation après l’obtention de mon **BTS CIEL option IR**.  
L’objectif était de comprendre le fonctionnement d’un VPN moderne utilisé en entreprise, ainsi que les problématiques liées à l’accès distant sécurisé.

---

## 🏗️ Architecture
- 1 serveur VPN **WireGuard**
- Déployé sur **Raspberry Pi 5**
- Clients VPN : postes distants (PC)
- Accès sécurisé à certains services internes

📌 Le serveur VPN est isolé du réseau local afin de limiter les risques de sécurité.

---

## 🔐 Principe de fonctionnement
- WireGuard utilise un chiffrement moderne basé sur des clés publiques / privées
- Chaque client possède une paire de clés unique
- Seuls les pairs autorisés peuvent établir une connexion avec le serveur

👉 Aucune authentification par mot de passe :  
la sécurité repose sur la cryptographie asymétrique.

---

## ⚙️ Mise en œuvre

### Prérequis
- Raspberry Pi avec Linux
- Accès réseau
- WireGuard installé
- Redirection de ports configurée sur la box/routeur

### Étapes principales
- Génération des clés serveur et client
- Configuration de l’interface WireGuard
- Définition des pairs autorisés
- Activation du routage et du pare-feu
- Test de connexion depuis un client distant

Les fichiers de configuration sont documentés dans le dossier `docs/`.

---

## 🔒 Sécurité
- Accès limité aux pairs connus
- Clés privées stockées uniquement sur les machines concernées
- Aucun service exposé inutilement
- Chiffrement natif des communications

---

## ✅ Résultats obtenus
- Connexion VPN stable et fonctionnelle
- Accès distant sécurisé aux ressources autorisées
- Chiffrement complet du trafic
- Performances adaptées à l’usage personnel et aux tests

---

## ⚠️ Problèmes rencontrés
- Configuration du routage réseau
- Gestion des règles firewall
- Tests de connectivité selon les clients

Ces difficultés ont permis de mieux comprendre :
- le fonctionnement du tunneling
- la gestion des flux réseau
- l’importance du firewall dans un contexte VPN

---

## 🚀 Améliorations possibles (vision entreprise)
- Gestion centralisée des clients
- Journalisation avancée
- Supervision du service VPN
- Automatisation du déploiement
- Haute disponibilité

