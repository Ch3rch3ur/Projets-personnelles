# Déploiement d’un VPN WireGuard personnel

## 🎯 Objectif du projet
Déployer un serveur VPN personnel basé sur **WireGuard** afin de :
- sécuriser les connexions réseau lors de l’utilisation de Wi-Fi publics,
- permettre l’accès distant à des ressources locales (NAS, services internes).

---

## 🧠 Contexte
Ce projet a été réalisé dans un cadre d’autoformation après l’obtention de mon **BTS CIEL option IR**.  
Il vise à mettre en œuvre une solution VPN moderne, légère et sécurisée, utilisée dans des contextes professionnels pour l’accès distant.

---

## 🏗️ Architecture
- Serveur VPN **WireGuard**
- Hébergement sur **Raspberry Pi 5**
- Clients VPN :
  - PC portable
  - Smartphone
- Accès distant au réseau local et à Internet

📌 Un schéma de la topologie réseau est disponible dans le dossier `diagrammes/`.

---

## ⚙️ Réalisation

### Mise en place du serveur
- Installation de WireGuard via **PiVPN**
- Configuration du routage réseau et du **NAT**
- Activation du forwarding IP

### Configuration des clients
- Création de plusieurs profils clients
- Importation de la configuration via **QR code**
- Connexion depuis différents équipements (PC, mobile)

### Sécurisation de la machine
- Mise en place d’un pare-feu **UFW**
- Politique restrictive : seuls les flux nécessaires sont autorisés

---

## ⚠️ Problème rencontré
Après l’activation du pare-feu UFW, le trafic VPN ne transitait plus correctement.

### Analyse
- Le firewall bloquait :
  - le forwarding IP,
  - les flux nécessaires au fonctionnement de WireGuard.

### Solution
- Autorisation du port **UDP 51820**
- Ajout d’une règle de routage avec :
  - `ufw route allow`
- Vérification du forwarding réseau

---

## ✅ Résultats obtenus
- VPN pleinement fonctionnel et utilisable en mobilité
- Connexion sécurisée et chiffrée
- Accès distant aux ressources locales
- Machine protégée par un pare-feu configuré de manière restrictive

---

## 🧠 Compétences démontrées
- Déploiement et configuration d’un VPN sécurisé avec WireGuard
- Gestion du **NAT** et du **forwarding IP**
- Configuration et dépannage d’un pare-feu
- Analyse et résolution de problèmes réseau
- Mise en place d’une solution utilisée en conditions réelles

---

## 🚀 Améliorations possibles (vision entreprise)
- Journalisation et supervision du service VPN
- Gestion centralisée des clients
- Automatisation du déploiement
- Intégration dans une infrastructure multi-sites
