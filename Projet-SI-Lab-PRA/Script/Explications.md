# 1. Création de l'arborescence

## Objectif

Structurer le projet Ansible afin de séparer clairement les rôles, les variables, les fichiers de configuration et les playbooks.

L'utilisation d'une arborescence normalisée facilite la maintenance, l'évolution du projet et la réutilisation des rôles.

---

## Arborescence

```
ansible/
│
├── inventory/
├── group_vars/
├── host_vars/
├── roles/
├── site.yml
```

---

### inventory/

Contient la liste des machines gérées par Ansible.

Exemple :

```
localhost ansible_connection=local
```
Dans notre cas 

---

### roles/

Chaque rôle correspond à un service indépendant.

Exemple :

```
roles/

bind9/

nginx/

wireguard/

nftables/

netdata/

restic/
```

Chaque rôle possède sa propre configuration.

```
tasks/
handlers/
templates/
files/
vars/
```

Cette organisation permet de modifier un service sans impacter les autres.

---

### tasks/

Contient les tâches exécutées par le rôle.

Exemple :

- installer un paquet
- copier un fichier
- créer un utilisateur
- démarrer un service

---

### handlers/

Contient les actions exécutées uniquement lorsqu'un changement est détecté.

Exemple :

```
Restart nginx
```

Un handler évite de redémarrer inutilement un service.

---

### templates/

Contient les fichiers Jinja2.

Ils permettent de générer automatiquement les fichiers de configuration.

Exemple :

```
nginx.conf.j2
```

qui devient

```
/etc/nginx/sites-available/site.conf
```

---

### files/

Contient les fichiers copiés tels quels.

Exemple :

```
index.html
```

---

### vars/

Contient les variables propres au rôle.

Exemple :

```
nginx_server_name

nginx_root

nginx_listen_port
```

Ces variables rendent le rôle facilement réutilisable.

---

### group_vars/

Variables communes à tous les hôtes.

Ce dossier est également utilisé pour stocker les variables chiffrées avec Ansible Vault.

---

### host_vars/

Variables spécifiques à une machine.

Dans ce projet, ce dossier est peu utilisé car l'infrastructure repose principalement sur une seule machine de production.

# 2. Premier playbook

## Objectif

Centraliser le déploiement de tous les services dans un point d'entrée unique.

---

## Pourquoi un playbook ?

Un playbook décrit les actions à exécuter sur une ou plusieurs machines.

Dans ce projet, le fichier principal est :

```
site.yml
```

Son rôle est d'appeler successivement chacun des rôles de l'infrastructure.

Exemple :

```yaml
- hosts: localhost
  become: true

  roles:
    - bind9
    - nginx
    - wireguard
    - nftables
    - netdata
    - restic
```

---

## Pourquoi utiliser des rôles ?

Chaque rôle représente un service indépendant.

Cette approche permet :

- une meilleure lisibilité ;
- une maintenance simplifiée ;
- la réutilisation d'un rôle dans un autre projet ;
- un débogage ciblé.

Par exemple, pour modifier uniquement le serveur Web, seul le rôle `nginx` est concerné.

---

## Pourquoi utiliser des handlers ?

Un handler est une tâche particulière qui ne s'exécute que lorsqu'un changement est détecté.

Exemple :

```
Déploiement d'un nouveau VirtualHost

↓

notify: Restart nginx

↓

Le handler redémarre Nginx uniquement si la configuration a changé.
```

Cela évite les redémarrages inutiles et limite les interruptions de service.

---

## Vérification

Une fois le premier playbook exécuté, les services peuvent être contrôlés avec :

```bash
systemctl status <service>
```

Par exemple :

```bash
systemctl status nginx
systemctl status bind9
systemctl status wireguard
```

