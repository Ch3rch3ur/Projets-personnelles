# 🛠️ SI-Lab Plan de Reprise d'Activité (PRA) — Infrastructure résiliente et restaurable

## 📋 Contexte

Projet autonome réalisé en laboratoire personnel visant à répondre à une problématique concrète rencontrée en entreprise :

Comment garantir la continuité minimale d’un système d’information **sans haute disponibilité** et avec des ressources limitées ?

Dans de nombreuses PME ou environnements de test, les infrastructures reposent sur une seule machine, où toute panne devient critique. Ce projet propose une solution réaliste basée sur la reconstruction rapide (PRA), une alternative efficace à la tolérance de panne.

---

## 🎯 Objectif du projet

Mettre en place une infrastructure complète capable d’être :

- Déployée automatiquement
- Supervisée en temps réel
- Sauvegardée de manière sécurisée
- Restaurée rapidement après incident

### Objectif principal

Assurer une **restauration fonctionnelle complète en moins de 10 minutes** après une panne ou une compromission.

### Objectifs techniques

- **Automatiser complète** du déploiement via Ansible (Infrastructure as Code)
- **Supervision temps réel** avec système d'alertes
- **Sauvegarde chiffrée et versionnée**
- **Validation de la résilience** : simulation d'attaques réelles et tests du PRA opérationnel
- **Documentation** des incidents et de la procédures de reprise

---

## 🏗️ Architecture

### Vue globale de l’infrastructure

#### 🖥️ Serveur de production (srv-prod)

- Debian 12/13 (CLI)
- Services hébergés :
  - DNS (Bind9)
  - Web (Nginx)
  - VPN (WireGuard)
  - Supervision (Netdata)
- Sauvegarde :
  - Restic
  - Fréquence : **toutes les 4 heures**
  - Stockage local

**Rôle :**
- Fournir les services critiques
- Permettre une restauration rapide (PRA)

---

#### 💾 Serveur de sauvegarde distant (srv-backup)

- Debian 12/13 (CLI)
- Synchronisation :
  - Quotidienne (**1 fois par jour**)
- Accès sécurisé :
  - SSH avec **authentification par clé uniquement**
  - Aucun accès par mot de passe

**Rôle :**
- Stockage externalisé des sauvegardes
- Protection contre :
  - Perte du serveur principal
  - Corruption des données
  - **Attaques de type ransomware**

---

#### ⚔️ Machine d’attaque (kali-attacker)

- Kali Linux

**Rôle :**
- Simulation d’attaques
- Validation de la résilience du système

**Scénarios :**
- Déni de service (HTTP)
- Bruteforce SSH
- Suppression de services

---

### ⚙️ Orchestration et automatisation

- Ansible
  - Déploiement automatisé de l’infrastructure
  - Gestion des configurations (Infrastructure as Code)
  - Playbooks :
    - `site.yml` (déploiement)
    - `restore.yml` (PRA)

---

### 🌐 Détails des services

#### DNS
- Bind9
- Résolution locale
- Configuration de zones
- Forwarders publics

#### Web
- Nginx
- Serveur HTTP
- Hébergement d’une page de test

#### VPN
- WireGuard
- Tunnel sécurisé
- Accès distant au système

---

### 📊 Supervision

- Netdata
  - Monitoring en temps réel :
    - CPU
    - RAM
    - disque
    - services
  - Alertes intégrées

---

### 💾 Sauvegarde

- Restic
  - Sauvegarde :
    - chiffrée
    - incrémentale
    - automatisée (cron toutes les 4h)
  - Données critiques :
    - `/etc`
    - `/var/www`
    - `/etc/wireguard`

---

### 🔁 Principe de fonctionnement

L’infrastructure repose sur un modèle **reconstructible à la demande** :

- Les services ne sont pas réparés manuellement
- Ils sont redéployés automatiquement via Ansible
- Les données sont restaurées depuis les sauvegardes Restic
- La dissociation des sauvegardes (locales et distantes) garantit la résilience face aux incidents majeurs, y compris les attaques de type ransomware

---

















---

#### 🖥️ Serveur de production (srv-prod)
- Debian 12/13 (CLI)
- Services hébergés :
  - DNS (Bind9)
  - Web (Nginx)
  - VPN (WireGuard)
  - Supervision (Netdata)
- Sauvegarde :
  - Restic
  - Fréquence : **toutes les 4 heures**
  - Stockage local
Rôle :
  - Fournir les services + être restauré rapidement
  
#### 💾 Serveur de sauvegarde distant (srv-backup)
- Debian 12/13 (CLI)
- Synchronisation :
  - Quotidienne (**1 fois par jour**)
- Accès sécurisé :
  - SSH avec **authentification par clé uniquement**
  - Aucun accès par mot de passe 
- Rôle :
  - Stockage externalisé des sauvegardes
  - Protection contre :
    - Perte du serveur principal
    - Corruption des données
    - **Attaques de types Ransomware**
    
#### ⚔️ Machine d’attaque (kali-attacker)
- Kali Linux
- Rôle :
  - Simulation d'attaques
  - Tests de résilience
- Scénarios :
  - Déni de service
  - Brute-force SSH
  - Suppression de services
Rôle :
  - Tester la résilience réelle du système
  
---

Tu peux formuler comme ça :

Backup local → rapide (RTO)
Backup distant → sécurité (RPO)

👉 Traduction pro :

local = restauration rapide
distant = résilience

--- 






