# 🔒 VPN WireGuard personnel sur Raspberry Pi

Serveur VPN sécurisé pour accès distant au réseau local et protection sur Wi-Fi publics.

---

## 📋 Contexte

Projet autonome réalisé après l'obtention d'un BTS CIEL option IR. L'objectif est de déployer une solution VPN moderne et performante pour sécuriser les connexions distantes et accéder aux ressources locales en mobilité.

---

## 🎯 Objectif du projet

Construire un **VPN personnel** pour se connecter à des Wi-Fi publics tout en gardant le contrôle sur ses données :

* Sécuriser les connexions réseau sur Wi-Fi publics non fiables
* Chiffrer l'ensemble du trafic pour protéger les données personnelles
* Éviter l'interception et l'espionnage sur réseaux publics
* Accéder de manière sécurisée à Internet depuis n'importe où
* Permettre l'accès distant aux ressources locales (bonus)

**But pédagogique** : Maîtriser les concepts de VPN, NAT, forwarding IP et configuration de pare-feu.

---

## 🏗️ Architecture

**Infrastructure matérielle :**

* **Serveur VPN** : Raspberry Pi 5
* **Solution VPN** : WireGuard (via PiVPN)
* **Pare-feu** : UFW (Uncomplicated Firewall)
* **Clients VPN** :
  * PC portable (Linux/Windows)
  * Smartphone (Android/iOS)

**Principe** : Le Raspberry Pi agit comme passerelle VPN chiffrée entre les clients distants et le réseau local/Internet.

### 📸 Topologie réseau

![Schéma réseau](diagrammes/topologie.png)

📁 [Voir les schémas détaillés →](diagrammes/)

---

## ⚙️ Fonctionnalités réalisées

✅ Serveur WireGuard opérationnel sur Raspberry Pi 5  
✅ Configuration du routage réseau et du NAT  
✅ Forwarding IP activé pour le transit des paquets  
✅ Plusieurs clients configurés (PC, smartphone)  
✅ Import de configuration via QR code  
✅ Pare-feu UFW avec politique restrictive  
✅ Connexion sécurisée et chiffrée en conditions réelles

---

## 🔧 Technologies utilisées

`WireGuard` `PiVPN` `UFW` `NAT` `IP Forwarding` `Raspberry Pi 5` `QR Code` `Chiffrement`

---

## 🐛 Principaux défis techniques

### Blocage du trafic VPN après activation du pare-feu

**Problème** : Après activation d'UFW, le trafic VPN ne passait plus

**Analyse** :
* Le firewall bloquait le forwarding IP entre les interfaces
* Le port UDP 51820 (WireGuard) n'était pas autorisé
* Les règles de routage n'étaient pas configurées pour le VPN

**Solution** :
* Autorisation du port UDP 51820 dans UFW
* Ajout d'une règle de routage : `ufw route allow`
* Vérification du forwarding IP dans `/etc/sysctl.conf`

👉 **Détails techniques et commandes** : [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 📊 Résultats

* ✅ VPN pleinement fonctionnel et utilisé en mobilité
* ✅ Connexion sécurisée et chiffrée depuis Wi-Fi publics
* ✅ Accès distant aux ressources locales validé
* ✅ Machine protégée par pare-feu restrictif
* ✅ Solution testée en conditions réelles (déplacements, Wi-Fi public)

---

## 📚 Documentation

* 📄 [Compte-rendu complet (PDF)](docs/Projet_VPN_Compte_rendu.pdf) - Documentation détaillée du projet
* 🗺️ [Schémas réseau](diagrammes/) - Topologie de l'infrastructure
* 🐛 [Guide de dépannage](TROUBLESHOOTING.md) - Configuration UFW et résolution de problèmes
* 💻 [Scripts de configuration](scripts/) - Scripts d'installation et de configuration

---

## 🎓 Compétences démontrées

* Déploiement et configuration d'un VPN moderne (WireGuard)
* Gestion du NAT et du forwarding IP
* Configuration et dépannage de pare-feu (UFW)
* Analyse et résolution de problèmes réseau
* Sécurisation des flux réseau (chiffrement, politique restrictive)
* Mise en place d'une solution utilisée en conditions réelles

---

## 🔄 Améliorations possibles

**Monitoring et supervision** :
* Journalisation centralisée des connexions VPN
* Alertes en cas de connexion suspecte
* Statistiques d'utilisation (bande passante, clients connectés)

**Gestion avancée** :
* Automatisation du déploiement de nouveaux clients
* Gestion centralisée des certificats et clés
* Révocation de clients compromis

**Haute disponibilité** :
* Configuration failover avec second Raspberry Pi
* Sauvegarde automatique des configurations
* Plan de reprise d'activité (PRA)

**Intégration entreprise** :
* Connexion multi-sites (site-to-site VPN)
* Intégration avec Active Directory pour l'authentification
* Politique de sécurité centralisée (firewall distribué)