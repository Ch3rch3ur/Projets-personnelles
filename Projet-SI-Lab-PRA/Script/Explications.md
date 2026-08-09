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

Contient les fichiers déployés **tels quels**, sans traitement ni variable — à la différence de `templates/`, aucune substitution n'est effectuée.

Exemple dans le rôle `nginx` :

files/index.html → /var/www/html/index.html

Ce dossier est réservé aux fichiers statiques (pages HTML, scripts, clés publiques, binaires) qui ne dépendent d'aucune variable d'environnement.

---

### vars/

Contient les variables **propres à un rôle**, avec leurs valeurs par défaut. Elles sont ensuite réutilisées dans les tâches et les templates du même rôle.

Exemple pour le rôle `nginx` :

```yaml
# vars/main.yml
nginx_server_name: "srv-prod.lab.local"
nginx_root: "/var/www/html"
nginx_listen_port: 80
```

En centralisant ces valeurs à un seul endroit plutôt qu'en les codant en dur dans les tâches, un rôle reste réutilisable tel quel sur une autre machine ou un autre projet — il suffit de surcharger ces variables (via `group_vars/` ou `host_vars/`) sans toucher au rôle lui-même.

---

### group_vars/

Contient les variables **communes à un ensemble d'hôtes** (ou à tous, via `group_vars/all/`) — elles priment sur les valeurs par défaut définies dans `vars/` de chaque rôle.

C'est également ici que sont stockées les variables sensibles, chiffrées avec **Ansible Vault** :

group_vars/all/vault.yml

Exemple : le mot de passe utilisé par Restic pour chiffrer les sauvegardes y est stocké chiffré, plutôt qu'en clair dans un script ou un rôle.

---

### host_vars/

Contient les variables propres à **une seule machine**, avec la même logique de priorité que `group_vars/` mais à l'échelle d'un hôte précis.

Dans ce projet, ce dossier reste peu utilisé : l'infrastructure repose principalement sur une seule machine de production (`srv-prod`), ce qui limite le besoin de différencier les variables par hôte. Il prendrait davantage de sens avec l'ajout d'un second serveur (par exemple `srv-backup`) nécessitant des valeurs spécifiques (adresse IP, nom de domaine, rôle réseau).

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

