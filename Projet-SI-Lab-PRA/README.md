# 🛠️ SI-Lab Plan de Reprise d'Activité (PRA) — Infrastructure résiliente et restaurable

## 📋 Contexte

Projet autonome réalisé en laboratoire personnel visant à répondre à une problématique concrète rencontrée en entreprise :

-- Comment garantir la continuité minimale d’un système d’information **sans haute disponibilité** et avec des ressources limitées ?

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

- **Automatisation complète** du déploiement via Ansible (Infrastructure as Code)
- **Supervision en temps réel** avec système d'alertes
- **Sauvegarde chiffrée et versionnée**
- **Validation de la résilience** : simulation d'attaques réelles (DoS, brute-force SSH) et tests du PRA opérationnel
- **Documentation** des incidents et de la procédures de reprise

---

## 🏗️ Architecture

**Composants de l'infrastructure :**

#### 🖥️ Serveur de production (srv-prod)
- **OS** : Debian 12/13 (CLI)
- **Services hébergés** :
  - DNS (Bind9)
  - Web (Nginx)
  - VPN (WireGuard) – *Accès distant sécurisé*
  - Supervision (Netdata)
- **Sauvegarde** :
  - Outil : Restic (chiffrée)
  - Fréquence : **toutes les 4 heures**
  - Stockage : local
- **Rôle** :
  Fournir les services critiques et permettre une **restauration rapide** (PRA).

#### 💾 Serveur de sauvegarde distant (srv-backup)
- **OS** : Debian 12/13 (CLI)
- **Synchronisation** :
  - Quotidienne (1 fois par jour) via **Restic** (chiffrée)
- **Sécurité** :
  - SSH avec **authentification par clé uniquement** (pas de mot de passe)
- **Rôle** :
  - Stockage externalisé des sauvegardes.
  - Protection contre :
    - Perte du serveur principal.
    - Corruption des données.
    - **Attaques par ransomware**.

#### ⚔️ Machine d’attaque (kali-attacker)
- **OS** : Kali Linux
- **Rôle** :
  - Simuler des attaques pour **valider la résilience** du système.
  - Scénarios testés :
    - 🔥 Déni de service (DoS)
    - 🔑 Brute-force SSH
    - ❌ Suppression de services

---

### 🔁 Principe de fonctionnement

L’infrastructure repose sur un modèle **reconstructible à la demande** :

- Les services ne sont **pas réparés manuellement**
- Ils sont **redéployés automatiquement** via Ansible
- Les données sont **restaurées depuis les sauvegardes Restic**
- La **dissociation des sauvegardes** (locales et distantes) garantit la résilience face aux incidents majeurs, y compris les **attaques par ransomware**

---
