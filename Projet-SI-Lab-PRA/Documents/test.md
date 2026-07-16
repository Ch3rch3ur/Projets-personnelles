# Architecture de l'infrastructure

## 1. Présentation

L'objectif de ce projet est de concevoir une infrastructure système complète reposant exclusivement sur des solutions libres et open source, administrée sous Debian et entièrement déployée à l'aide d'Ansible.

L'infrastructure ne cherche pas à mettre en œuvre de la haute disponibilité (HA). Le choix retenu est celui d'une architecture reconstruisible rapidement grâce à l'automatisation des déploiements et à une stratégie de sauvegarde adaptée.

Le projet poursuit trois objectifs principaux :

- automatiser le déploiement des services ;
- limiter la surface d'administration manuelle ;
- garantir une reprise d'activité rapide après incident.

---

# 2. Architecture générale

L'infrastructure est composée de trois machines virtuelles.

## Serveur de production

Le serveur de production héberge l'ensemble des services nécessaires au fonctionnement du laboratoire :

- DNS (Bind9)
- Serveur Web (Nginx)
- VPN (WireGuard)
- Pare-feu (nftables)
- Supervision (Netdata)
- Sauvegardes locales (Restic)

Ce serveur constitue le point central de l'infrastructure.

---

## Serveur de sauvegarde

Le second serveur possède un rôle unique :

conserver une copie distante des sauvegardes Restic.

Il ne fournit aucun autre service.

Cette séparation permet de protéger les sauvegardes en cas de compromission du serveur principal.

---

## Poste d'attaque

Une machine Kali Linux est utilisée exclusivement pour :

- effectuer des phases de reconnaissance ;
- réaliser des tests d'intrusion ;
- valider le Plan de Reprise d'Activité.

Cette machine ne fait pas partie de l'infrastructure de production.

---

# 3. Architecture logique

Le fonctionnement général repose sur quatre couches.

Couche réseau
↓

Couche sécurité
↓

Couche services

↓

Couche supervision et sauvegarde

Chaque couche est indépendante des autres afin de limiter les impacts lors d'un incident.

---

# 4. Services déployés

## DNS

Le serveur DNS assure la résolution des noms internes du laboratoire.

Il permet aux différents services de communiquer sans dépendre directement des adresses IP.

---

## Nginx

Le serveur Web héberge la page principale du laboratoire.

Il sert également de reverse proxy pour Netdata.

---

## WireGuard

WireGuard permet l'administration distante du laboratoire.

Les accès VPN sont limités aux utilisateurs autorisés.

---

## nftables

Le pare-feu applique une politique restrictive.

Seuls les services nécessaires sont accessibles.

Toutes les autres communications sont rejetées.

---

## Netdata

Netdata assure la supervision temps réel :

- ressources système
- services
- réseau
- journaux

Il permet de détecter rapidement une anomalie de fonctionnement.

---

## Restic

Restic réalise les sauvegardes :

- locales
- distantes

Les sauvegardes sont chiffrées avant leur stockage.

---

# 5. Automatisation

L'ensemble des services est déployé à l'aide d'Ansible.

Chaque composant possède son propre rôle afin de garantir :

- une maintenance simplifiée ;
- une meilleure lisibilité ;
- une réutilisation des configurations.

Le déploiement est reproductible sur une nouvelle machine sans intervention manuelle importante.

---

# 6. Stratégie de sauvegarde

Deux niveaux de sauvegarde sont utilisés.

## Sauvegarde locale

Une sauvegarde est réalisée toutes les quatre heures.

Elle permet une restauration rapide en cas d'erreur de manipulation ou de panne logicielle.

---

## Sauvegarde distante

Une seconde sauvegarde est envoyée quotidiennement vers un serveur dédié.

Cette copie protège les données contre :

- une panne matérielle ;
- une corruption importante ;
- une compromission du serveur principal.

---

# 7. Sécurité

Plusieurs mesures de sécurité sont appliquées.

- authentification SSH par clé ;
- comptes dédiés aux services ;
- principe du moindre privilège ;
- filtrage réseau avec nftables ;
- sauvegardes chiffrées ;
- secrets protégés par Ansible Vault.

---

# 8. Philosophie du projet

L'objectif n'est pas d'empêcher tout incident.

L'objectif est de pouvoir reconstruire rapidement une infrastructure fonctionnelle.

Le laboratoire privilégie donc :

- l'automatisation ;
- la reproductibilité ;
- la documentation ;
- les tests réguliers de restauration.

Cette approche correspond davantage aux contraintes rencontrées dans une PME qu'à une architecture de haute disponibilité.
