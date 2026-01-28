# 📸 Screenshots - Projet GLPI ITSM

Ce dossier contient les captures d'écran démontrant le fonctionnement de l'infrastructure GLPI intégrée à Active Directory.

---

## 🎫 Interface et exploitation GLPI

### 1. Dashboard GLPI (Interface Technicien)

![Dashboard GLPI](01-dashboard-glpi.png)

**Connecté en tant que** : Jean Dupont (Technicien)

**Démontre** :
- Interface GLPI 10.0.16 opérationnelle
- Vue d'ensemble des tickets en cours
- Statistiques d'activité
- Navigation complète accessible

---

### 2. Liste des tickets traités

![Liste des tickets](05-liste-tickets.png)

**Source** : Assistance → Tickets

**Démontre** :
- **20+ tickets d'incidents** créés et traités
- Répartition par catégories (Matériel, Réseau, Accès, Logiciels, Périphériques)
- Gestion des priorités (Haute, Moyenne, Basse)
- Statuts de résolution
- **Objectif principal du projet atteint** ✅

---

### 3. Exemple de ticket complet - Incident mot de passe AD

![Ticket détaillé](04-ticket-exemple-complet.png)

![Ticket détaillé suite](04-ticket-exemple-complet-next.png)

**Ticket** : "Impossible de me connecter à ma session"

**Démontre** :
- **Demandeur** : Greg Hollande (utilisatrice AD)
- **Technicien assigné** : Jean Dupont
- **Catégorie** : Accès et comptes
- **Priorité** : Haute
- **Description utilisateur** : problème formulé de manière non technique
- **Diagnostic technicien** : méthodologie appliquée (vérification AD, identification cause)
- **Actions réalisées** : étapes de résolution documentées
- **Solution** : résolution claire et vérifiable
- **Méthodologie support N1** : prise en charge → diagnostic → action → résolution ✅

---

### 3b. Exemple de ticket complet - VIP

![Ticket détaillé VIP](04-ticket-exemple-complet-vip.png)

![Ticket détaillé VIP suite](04b-ticket-exemple-complet-vip.png)

**Ticket** : "Impossible d'accéder au portail"

**Démontre** :
- **Demandeur** : Marie Martin (utilisatrice AD - client VIP)
- **Technicien assigné** : Jean Dupont
- **Catégorie** : Réseau - Accès à Internet
- **Priorité** : Haute
- **Description utilisateur** : problème formulé de manière non technique
- **Diagnostic technicien** : méthodologie appliquée (vérification AD, identification cause)
- **Actions réalisées** : étapes de résolution documentées
- **Solution** : résolution claire et vérifiable
- **Méthodologie support N1** : prise en charge → diagnostic → action → résolution ✅

---

### 4. Statistiques et métriques

![Statistiques tickets](06-statistiques-tickets.png)

**Source** : Rapports GLPI ou graphique généré depuis glpi_export.csv

**Démontre** :
- **Répartition par catégorie** :
  - Accès et comptes : 5 tickets (25%)
  - Réseau - Connectivité : 4 tickets (20%)
  - Matériel - Poste de travail : 4 tickets (20%)
  - Logiciels et applications : 4 tickets (20%)
  - Périphériques : 3 tickets (15%)
- **Temps moyen de résolution** : 10-20 minutes
- **Taux de respect des SLA** : 100%
- **Approche professionnelle** avec métriques quantifiables ✅

---

## 🔐 Intégration Active Directory

### 5. Configuration LDAP Active Directory

![Configuration LDAP](02-configuration-ldap.png)

**Source** : Configuration → Authentification → Annuaires LDAP → Active Directory Lab

**Démontre** :
- **Serveur LDAP** : 192.168.2.3 (Windows Server 2022)
- **Port** : 389 (LDAP standard)
- **BaseDN** : DC=homelab,DC=local
- **Bind DN** : CN=Service GLPI,CN=Users,DC=homelab,DC=local
- **Champ de l'identifiant** : `sAMAccountName` ← Correction critique (était `uid` initialement)
- **Test de connexion** : Réussi ✅
- **Intégration LDAP/AD fonctionnelle** ✅

---

### 6. Utilisateurs Active Directory importés

![Utilisateurs importés](03-utilisateurs-importes.png)

**Source** : Administration → Utilisateurs

**Démontre** :
- **3 utilisateurs AD importés** :
  - Jean Dupont (Technicien) - Source : Active Directory Lab
  - Marie Martin (Self-Service) - Source : Active Directory Lab
  - Pierre Leroy (Self-Service) - Source : Active Directory Lab
- **Import automatique** depuis l'OU `GLPI_Users` dans Active Directory
- **Authentification centralisée** opérationnelle
- **Gestion des profils** selon les rôles (Technicien vs Utilisateur)

---

## 📚 Base de connaissances et procédures

### 7. Base de connaissances - Liste des procédures

![Base de connaissances](07-base-connaissance.png)

**Source** : Outils → Base de connaissances

**Démontre** :
- **4 procédures support N1** documentées :
  - 1. Réinitialisation mot de passe Active Directory
  - 2. Diagnostic connectivité réseau (approche OSI)
  - 3. Résolution DNS défaillante
  - 4. Procédure d'escalade N1 → N2
- **Documentation professionnelle** des interventions courantes
- **Capitalisation des connaissances** pour le support ✅

---

### 8. Exemple de procédure - Réinitialisation mot de passe AD

![Procédure détaillée](07b-procedure-exemple.png)

**Procédure** : "Réinitialisation mot de passe Active Directory"

**Démontre** :
- **Structure claire** : Symptômes → Procédure → Vérification
- **Étapes détaillées** : actions concrètes à effectuer
- **Commandes PowerShell** : outils techniques référencés
- **Temps estimé** : 5-10 minutes
- **Niveau** : N1
- **Documentation exploitable** par d'autres techniciens ✅

---

## ⚙️ Configuration et gestion

### 9. Configuration des SLA

![Configuration SLA](08-sla-configuration.png)

**Source** : Configuration → Niveaux de services → SLAs

**Démontre** :
- **SLA selon priorité** :
  - Urgence Haute : TTR 2 heures
  - Urgence Moyenne : TTR 4 heures
  - Urgence Basse : TTR 8 heures
- **Gestion des délais** de résolution
- **Règles métier** pour application automatique des SLA
- **Approche ITIL** dans la gestion des incidents ✅

---

### 9b. Configuration des SLA VIP

![SLA vip](08b-sla-vip.png)

**Source** : Configuration → Niveaux de services → SLAs

**Démontre** :
- **SLA selon priorité** :
  - TTR : 2 heures → escalade automatique vers le support N2 **40 minutes avant l'échéance** du ticket.
  - TTO : 1 heure → ajout automatique du ticket au **groupe d'observation Direction 30 minutes avant l'échéance**.
- **Gestion des délais** de résolution
- **Règles métier** pour application automatique des SLA **pour les clients VIP**.
- **Approche ITIL** dans la gestion des incidents ✅

---

### 10. Règle métier SLA

![règles metier sla](10-regles-metier-sla.png)

**Source** : Administration → Règles → Règles métier pour un les tickets

**Démontre** :
- Règles d'application automatiques des SLA selon priorité :
   - Basse
   - Moyenne
   - Haute
   - VIP
- Action mise en place en fonction du niveau de priorité :
   - Ticket assigner
   - Durée du TTR
   - Durée du TTO 

---

### 11. Profils et habilitations

![Profils utilisateurs](09-profils-utilisateurs.png)

**Source** : Administration → Profils - Technicien → Utilisateurs

**Démontre** :
- **Profils GLPI** :
  - Super-Admin (glpi)
  - Technicien (jdupont, bgirare, jlegrand)
  - Self-Service (mmartin (VIP), pleroy)
- **Séparation des privilèges** selon les rôles
- **Gestion des droits** : techniciens peuvent traiter les tickets, utilisateurs peuvent uniquement créer
- **Sécurité** : accès limité selon les responsabilités ✅

---

### 12. Interface utilisateur

![Interface utilisateur](11-interface-utilisateur.png)

**Connecté en tant que** : Marie Martin (Self-Service)

**Démontre** :
- Vue simplifiée Self-Service
- Interface de création de ticket utilisateur

---

## 📊 Synthèse

Ces screenshots démontrent :

✅ **GLPI opérationnel** : Interface fonctionnelle, navigation complète  
✅ **Intégration LDAP/AD** : Authentification centralisée, import automatique des utilisateurs  
✅ **Exploitation réaliste** : 20+ tickets d'incidents traités avec méthodologie N1  
✅ **Documentation professionnelle** : 4 procédures support, base de connaissances exploitable  
✅ **Gestion des priorités** : SLA configurés selon urgence, respect des délais  
✅ **Métriques quantifiables** : Statistiques, répartition par catégorie, temps de résolution  

**Résultat** : Environnement ITSM complet et opérationnel reproduisant un service support d'entreprise.

---

## 🔗 Documentation complète

* 📄 [Compte-rendu du projet](../Documents/compte_rendu.pdf)
* 📄 [Procédure technicien N1](../Documents/Procedure_base_de_connaissance_technicien/)
* 🐛 [Guide de dépannage](../troubleshooting.md)
* 🗺️ [Topologie réseau](../Diagrammes/)
* 📊 [Données brutes tickets (CSV)](../Documents/glpi.csv)
