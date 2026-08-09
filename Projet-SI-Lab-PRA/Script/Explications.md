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

Dans ce projet, nous avons intégré ce fichier car les tâches Ansible s'exécutent **localement** sur la machine, afin de répondre aux besoins spécifiques du projet.

Exemple avec SSH, si la machine était distante :

```
serveur_prod ansible_host=192.168.1.32 ansible_user=ansible
```
---

### roles/

Chaque rôle correspond à un service indépendant.

```

/opt/si-lab/ansible/roles/
│
├── bind9/
├── nginx/
├── wireguard/
├── nftables/
├── netdata/
├── restic/

```

Chaque rôle possède sa propre configuration.

```
tasks/
templates/
handlers/
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

### templates/

Contient les fichiers **Jinja2** (`.j2`), c'est-à-dire des fichiers de configuration dans lesquels certaines valeurs sont remplacées dynamiquement par des variables au moment du déploiement.

Exemple avec le rôle `nginx` :

```
templates/nginx.conf.j2  →  /etc/nginx/sites-available/site.conf
```

```jinja2
server {
    listen {{ nginx_listen_port }};
    server_name {{ nginx_server_name }};
    root {{ nginx_root }};
}
```

Un même template peut ainsi générer des configurations différentes selon la machine ou l'environnement, simplement en changeant les variables associées — c'est ce qui permet, par exemple, au rôle `wireguard` de générer un fichier de configuration client différent pour chaque pair sans dupliquer le fichier lui-même.

---

### handlers/

Un handler évite de redémarrer inutilement un service.

Un handler est une tâche qui ne s'exécute **que si une autre tâche a provoqué un changement** — jamais de manière systématique. Il est déclenché via `notify` depuis une tâche classique.

Exemple concret dans le rôle `nginx` :

```yaml
- name: Déployer la configuration du VirtualHost
  template:
    src: site.conf.j2
    dest: /etc/nginx/sites-available/site.conf
  notify: Restart nginx
```

```yaml
# handlers/main.yml
- name: Restart nginx
  service:
    name: nginx
    state: restarted
```

Si le fichier généré est identique à celui déjà en place, la tâche `template` ne remonte aucun changement, et le handler ne se déclenche pas — Nginx n'est donc jamais redémarré inutilement. C'est ce mécanisme qui permet de relancer `site.yml` en confiance sans provoquer de coupures de service à chaque exécution.

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

