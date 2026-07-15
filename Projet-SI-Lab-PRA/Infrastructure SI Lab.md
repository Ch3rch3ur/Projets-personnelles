# Infrastructure SI-Lab

## Introduction

Ce document décrit la conception, le déploiement et la sécurisation de l'infrastructure **SI-Lab**.

Ce projet a été réalisé dans le cadre d'une montée en compétences en administration systèmes et réseaux. Son objectif est de concevoir une infrastructure cohérente, automatisée et sécurisée en s'appuyant sur des technologies largement utilisées en entreprise.

L'ensemble du déploiement est automatisé avec Ansible afin de garantir la reproductibilité de l'infrastructure et de limiter les interventions manuelles.

Au-delà du simple déploiement des services, une attention particulière est portée à plusieurs aspects essentiels :

- l'automatisation des configurations ;
- la sécurisation des accès ;
- la supervision de l'infrastructure ;
- la sauvegarde locale et distante des données ;
- la restauration des services après incident.

Cette documentation présente les choix techniques réalisés, leur justification ainsi que les différentes étapes ayant conduit à l'architecture actuelle.

---

# Objectifs

Le projet poursuit plusieurs objectifs techniques.

## Automatisation

L'ensemble des services est déployé via Ansible afin de garantir une infrastructure reproductible et facilement maintenable.

Chaque composant est isolé dans un rôle dédié afin de limiter les dépendances entre services.

## Sécurisation

La sécurité est intégrée dès la conception.

L'objectif n'est pas uniquement de faire fonctionner les services mais également de limiter leur surface d'exposition.

Cela comprend notamment :

- limitation des privilèges ;
- filtrage réseau avec nftables ;
- authentification SSH par clé ;
- séparation des rôles entre les serveurs.

## Résilience

Une politique de sauvegarde est mise en place afin de limiter la perte de données en cas d'incident.

Deux niveaux de sauvegarde sont utilisés :

- sauvegarde locale pour une restauration rapide ;
- sauvegarde distante chiffrée pour assurer la reprise après sinistre.

## Documentation

Toutes les étapes importantes sont documentées.

Les erreurs rencontrées sont conservées afin de faciliter la maintenance et de constituer une base de connaissances.

---

# Architecture

L'infrastructure repose actuellement sur deux machines virtuelles Debian.

| Machine | Rôle |
|---------|------|
| PROD | Hébergement des services |
| BACKUP | Stockage des sauvegardes Restic |

Le serveur **PROD** centralise l'ensemble des services applicatifs.

Le serveur **BACKUP** est volontairement limité au stockage des sauvegardes.

Cette séparation permet d'isoler les données de sauvegarde du serveur de production et de limiter l'impact d'une compromission de celui-ci.

---

# Déploiement

Le déploiement de l'infrastructure est entièrement automatisé avec Ansible.

Chaque service est encapsulé dans un rôle indépendant.

Cette approche permet :

- un déploiement reproductible ;
- une maintenance simplifiée ;
- une évolution indépendante des différents services ;
- une reconstruction rapide d'un serveur.

Les principaux rôles actuellement utilisés sont :

- nginx
- bind9
- wireguard
- netdata
- nftables
- restic

---

# Services déployés

## DNS

Le serveur DNS est assuré par Bind9.

Il permet la résolution des noms de domaine internes du laboratoire et constitue la base de communication entre les différents services.

---

## Serveur Web

Le serveur Web est assuré par Nginx.

Il remplit plusieurs fonctions :

- hébergement de la page Web principale ;
- terminaison HTTPS ;
- reverse proxy vers Netdata.

Le choix de Nginx repose sur sa légèreté, sa stabilité et sa large utilisation en environnement Linux.

---

## VPN

L'accès distant est assuré par WireGuard.

Le VPN permet d'accéder aux différents services de manière sécurisée tout en limitant leur exposition directe sur le réseau local.

---

## Monitoring

La supervision est réalisée avec Netdata.

L'objectif est de disposer d'une vision en temps réel des ressources système ainsi que des principaux indicateurs de fonctionnement.

L'accès à Netdata est effectué via un reverse proxy Nginx afin de centraliser les accès HTTP.

---

# Sauvegardes

La stratégie de sauvegarde repose sur deux niveaux complémentaires.

## Sauvegarde locale

Le serveur de production réalise une sauvegarde Restic toutes les quatre heures.

Cette sauvegarde permet une restauration rapide après une erreur de manipulation ou une panne logicielle.

---

## Sauvegarde distante

Une seconde sauvegarde est réalisée quotidiennement vers un serveur dédié.

Les échanges sont effectués via SSH avec une clé dédiée.

Le dépôt Restic distant est chiffré côté client, garantissant que le serveur de sauvegarde ne puisse jamais accéder au contenu des données.

Cette architecture permet de conserver une copie des données même en cas de compromission complète du serveur de production.

---

# Sécurisation

Plusieurs mécanismes de sécurité sont mis en œuvre.

## SSH

L'accès au serveur de sauvegarde repose exclusivement sur une authentification par clé.

Un utilisateur dédié est utilisé afin d'appliquer le principe du moindre privilège.

---

## Pare-feu

Le filtrage réseau est assuré par nftables.

Seuls les services nécessaires sont exposés.

Le pare-feu est chargé automatiquement au démarrage du système afin de garantir une politique de filtrage persistante.

---

## Gestion des privilèges

Les automatisations sont exécutées avec des privilèges limités.

Lorsque l'élévation de privilège est nécessaire, elle est restreinte aux commandes indispensables.

Cette approche limite l'impact potentiel d'une compromission de l'utilisateur de maintenance.

---

# Validation

Chaque service a été testé individuellement après son déploiement.

Les principaux tests réalisés concernent notamment :

- résolution DNS ;
- disponibilité Web ;
- accès HTTPS ;
- fonctionnement du VPN ;
- supervision Netdata ;
- sauvegardes Restic ;
- restauration d'un fichier ;
- persistance du pare-feu.

Les incidents rencontrés au cours du projet sont détaillés dans le document **troubleshooting.md**.

---

# Évolutions prévues

Plusieurs améliorations sont prévues afin de poursuivre le développement du laboratoire.

Parmi elles :

- simulation d'une compromission du serveur de production ;
- validation complète du Plan de Reprise d'Activité (PRA) ;
- restauration complète des services depuis le dépôt distant ;
- renforcement de la sécurité après analyse de l'attaque ;
- amélioration continue des rôles Ansible.

---

# Conclusion

Ce projet ne se limite pas au déploiement de plusieurs services.

Il constitue une démarche complète d'administration systèmes et réseaux intégrant :

- l'automatisation ;
- la sécurisation ;
- la supervision ;
- la sauvegarde ;
- la restauration ;
- la documentation.

Les incidents rencontrés au cours du projet ont permis d'améliorer progressivement l'architecture et de renforcer sa robustesse, dans une logique proche de celle appliquée en environnement professionnel.
