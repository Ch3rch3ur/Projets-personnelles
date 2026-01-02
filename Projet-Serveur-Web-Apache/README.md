# 🖥️ Portfolio sécurisé - Serveur Web Apache

Hébergement auto-hébergé d'un portfolio personnel avec HTTPS et durcissement de la sécurité web.

---

## 📋 Contexte

Projet autonome réalisé après l'obtention d'un BTS CIEL option IR. L'objectif est de déployer un service web exposé publiquement sur Internet en appliquant les bonnes pratiques de sécurité et de durcissement adaptées à un environnement de production.

---

## 🎯 Objectif du projet

Déployer un **serveur web auto-hébergé** pour rendre un portfolio personnel accessible publiquement sur Internet :

* Héberger un site web professionnel accessible 24/7
* Garantir la sécurité avec HTTPS (chiffrement SSL/TLS)
* Appliquer les bonnes pratiques de durcissement web
* Gérer une IP dynamique avec DNS dynamique
* Protéger contre les attaques web courantes (XSS, clickjacking)

**But pédagogique** : Maîtriser le déploiement, la sécurisation et le durcissement d'un service web en production.

---

## 🏗️ Architecture

**Infrastructure matérielle :**

* **Serveur web** : Apache HTTP Server
* **Hébergement** : Raspberry Pi 5
* **Site web** : Portfolio personnel statique
* **Accès** : Public via Internet

**Services complémentaires :**

* **DNS dynamique** : No-IP (gestion IP publique dynamique)
* **Certificat SSL/TLS** : Let's Encrypt (renouvellement automatique via Certbot)
* **Sécurité** : En-têtes HTTP de sécurité (HSTS, CSP, X-Frame-Options)

**Principe** : Le Raspberry Pi héberge un site web accessible publiquement avec chiffrement HTTPS et protection contre les attaques web courantes.

### 📸 Topologie réseau

![Schéma réseau](diagrammes/topologie.png)

📁 [Voir les schémas détaillés →](diagrammes/)

---

## ⚙️ Fonctionnalités réalisées

✅ Serveur Apache configuré et optimisé  
✅ Portfolio personnel hébergé et accessible 24/7  
✅ DNS dynamique No-IP configuré (gestion IP publique)  
✅ HTTPS activé avec certificat Let's Encrypt  
✅ Renouvellement automatique des certificats SSL/TLS  
✅ En-têtes de sécurité HTTP configurés (HSTS, CSP, X-Frame-Options)  
✅ Protection contre XSS, clickjacking et autres attaques web  
✅ Site accessible publiquement via nom de domaine

---

## 🔧 Technologies utilisées

`Apache` `HTTPS` `Let's Encrypt` `Certbot` `No-IP` `HSTS` `CSP` `SSL/TLS` `Raspberry Pi 5` `Headers de sécurité`

---

## 🐛 Principaux défis techniques

### Politique CSP trop restrictive bloquant les ressources

**Problème** : Après mise en place de la Content Security Policy (CSP), certaines ressources nécessaires au site (Tailwind CSS, scripts) ne se chargeaient plus

**Analyse** :
* Consultation des logs Apache (`/var/log/apache2/error.log`)
* Utilisation des outils de développement du navigateur (Console F12)
* Identification des ressources bloquées par la CSP

**Solution** :
* Adaptation progressive des règles CSP
* Recherche d'un compromis entre sécurité stricte et fonctionnalité du site
* Tests itératifs pour valider chaque modification

👉 **Détails techniques et configuration CSP** : [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 📊 Résultats

* ✅ Portfolio accessible publiquement via HTTPS
* ✅ Communication chiffrée et sécurisée (certificat SSL/TLS valide)
* ✅ Configuration orientée sécurité avec en-têtes HTTP
* ✅ Score de sécurité élevé (vérifiable via SSL Labs)
* ✅ Plateforme fonctionnelle et régulièrement mise à jour
* ✅ Renouvellement automatique des certificats (cron Certbot)

---

## 📚 Documentation

* 📄 [Compte-rendu complet (PDF)](docs/Projet_ServeurWeb_Compte_rendu.pdf) - Documentation détaillée du projet
* 🗺️ [Schémas réseau](diagrammes/) - Topologie de l'infrastructure
* 🐛 [Guide de dépannage](TROUBLESHOOTING.md) - Configuration CSP et résolution de problèmes
* 💻 [Configuration Apache](scripts/) - Fichiers de configuration et scripts

---

## 🎓 Compétences démontrées

* Déploiement d'un service web en production
* Gestion du chiffrement SSL/TLS (Let's Encrypt, Certbot)
* Configuration avancée Apache (VirtualHosts, modules de sécurité)
* Mise en place de mécanismes de durcissement web (HSTS, CSP, headers)
* Gestion DNS dynamique (No-IP)
* Analyse de logs et dépannage applicatif
* Arbitrage sécurité vs fonctionnalité (pragmatisme)

---

## 🔄 Améliorations possibles

**Infrastructure** :
* Déploiement d'un reverse proxy (Nginx devant Apache)
* Mise en cache (Varnish ou Redis)
* CDN pour distribution de contenu statique
* Load balancing pour haute disponibilité

**Sécurité avancée** :
* Déploiement d'un WAF (ModSecurity)
* Fail2ban pour protection contre brute-force
* IDS/IPS (Snort ou Suricata)
* Monitoring de sécurité (OSSEC, Wazuh)

**Automatisation** :
* Conteneurisation (Docker)
* CI/CD pour déploiement automatique
* Infrastructure as Code (Ansible, Terraform)
* Sauvegarde automatisée

**Monitoring** :
* Surveillance avec Prometheus + Grafana
* Journalisation centralisée (ELK Stack)
* Alerting en cas d'incident
* Métriques de performance (temps de réponse, uptime)