# Hébergement d’un portfolio sécurisé – Serveur Apache

## 🎯 Objectif du projet
Déployer un serveur web auto-hébergé afin de rendre un portfolio personnel accessible publiquement sur Internet, tout en garantissant un niveau de sécurité adapté à une exposition en production.

---

## 🧠 Contexte
Ce projet a été réalisé dans un cadre d’autoformation après l’obtention de mon **BTS CIEL option IR**.  
L’objectif était de mettre en œuvre un service web exposé publiquement, en appliquant des bonnes pratiques de sécurité et de durcissement adaptées à un environnement réel.

Le serveur est hébergé sur une **Raspberry Pi 5**, choisie pour son faible coût, sa consommation énergétique réduite et sa flexibilité.

---

## 🏗️ Architecture
- Serveur web **Apache**
- Hébergement sur **Raspberry Pi 5**
- Site web : portfolio personnel
- Accès public via Internet

📌 Un schéma de la topologie réseau est disponible dans le dossier `diagrammes/`.

---

## 🌐 Accessibilité
- Adresse IP publique dynamique
- Utilisation de **No-IP** pour associer un nom de domaine à l’adresse IP
- Exposition contrôlée du service web vers Internet

---

## 🔒 Sécurisation HTTPS
- Mise en place du chiffrement **HTTPS**
- Utilisation de **Let’s Encrypt**
- Gestion et renouvellement automatique des certificats SSL/TLS

---

## 🛡️ Durcissement du serveur web
- Ajout d’en-têtes de sécurité HTTP :
  - HSTS
  - Content-Security-Policy (CSP)
  - X-Frame-Options
  - Autres headers de protection
- Objectif : limiter les risques liés aux attaques web courantes (XSS, clickjacking, etc.)

---

## ⚠️ Problème rencontré
Une politique **CSP trop restrictive** bloquait le chargement de certaines ressources nécessaires au bon fonctionnement du site (ex. Tailwind CSS).

### Analyse
- Analyse des logs Apache
- Tests via les outils de développement du navigateur
- Identification des ressources bloquées par la CSP

### Solution
- Adaptation progressive des règles CSP
- Recherche d’un compromis entre **sécurité** et **fonctionnalité**
- Validation du bon fonctionnement du site après modification

---

## ✅ Résultats obtenus
- Portfolio accessible publiquement via HTTPS
- Communication chiffrée et sécurisée
- Configuration orientée sécurité et performance
- Plateforme fonctionnelle et régulièrement mise à jour

---

## 🧠 Compétences mises en œuvre
- Déploiement d’un service web exposé en production
- Gestion du chiffrement SSL/TLS
- Mise en place de mécanismes de durcissement web
- Analyse de logs et dépannage applicatif
- Arbitrage entre sécurité et accessibilité

---

## 🚀 Améliorations possibles (vision entreprise)
- Reverse proxy
- Surveillance et journalisation centralisée
- Déploiement d’un WAF
- Automatisation des mises à jour
- Séparation front-end / back-end

