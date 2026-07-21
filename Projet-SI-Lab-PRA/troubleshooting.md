# 🛠️ Troubleshooting - Projet SI-Lab (Infrastructure & PRA)

## Contexte

Ce document recense les incidents réellement rencontrés lors de la conception de l'infrastructure SI-Lab (Ansible, réseau, DNS, VPN, firewall, supervision, sauvegarde), ainsi que les causes identifiées et les solutions appliquées.

> **Note de version** : ce document remplace une version précédente qui contenait deux points construits par extrapolation plutôt que documentés (le placement exact de `statistics-channels` et le statut de l'incident Netdata). Cette version se base uniquement sur les journaux de session et les notes centralisées.

---

## 📌 Synthèse rapide

| Domaine | Incidents | Statut |
|---|---|---|
| Installation Ansible | 1 | ✅ Résolu |
| Ansible — rôles & playbooks (général) | 5 | ✅ Résolu |
| nftables | 2 | ✅ Résolu |
| DNS / Bind9 | 6 | ✅ Résolu |
| WireGuard | 3 | ✅ Résolu |
| QR Code (client Android) | 1 | ✅ Résolu |
| Netdata (installation & rôle) | 2 | ✅ Résolu |
| Netdata (alertes personnalisées) | 1 | 🔄 **En cours d'investigation** |
| Nginx / HTTPS | 4 | ✅ Résolu |
| Restic — sauvegarde locale | 4 | ✅ Résolu |
| Restic — sauvegarde distante (SFTP) | 5 | ✅ Résolu |
| Ansible Vault | 3 | ✅ Résolu |
| Gestion des privilèges / utilisateurs | 3 | ✅ Résolu |

---

## 1. ⚙️ Installation d'Ansible

**Problème** : impossible d'installer Ansible via APT.

**Cause** : le gestionnaire de paquets Debian rencontrait des erreurs DPKG empêchant l'installation des dépendances.

**Solution** :
```bash
pip install ansible
```

**Bonne pratique** : vérifier l'état du gestionnaire de paquets avant toute installation, et prévoir une méthode alternative (pip) lorsque le dépôt système est inutilisable.

---

## 2. 🤖 Ansible — Rôles et playbooks (erreurs générales)

**Problème** : plusieurs erreurs empêchaient le déploiement complet des rôles :
- fautes de frappe (`scr` au lieu de `src`, `SavaConfig` au lieu de `SaveConfig`, `etho`/`wgo` au lieu du nom d'interface réel)
- variables absentes ou mal résolues
- chemins incorrects
- handlers exécutés trop tôt
- ordre des tâches incorrect
- absence de vérification des configurations avant application

**Cause** : les premiers rôles avaient été développés rapidement, sans mécanismes de validation.

**Solution** : ajout progressif de mécanismes de contrôle dans les rôles : `stat`, `register`, `fail`, `debug`, `creates`, vérification des fichiers avant création de liens symboliques, `nginx -t` avant rechargement.

**Bonne pratique** : toujours valider une configuration avant de redémarrer un service.

### 2.1 Variable Ansible jamais chargée

**Cause** : mauvais template `.j2` utilisé par la tâche (un ancien template resté référencé).

**Solution** : ajout d'une tâche `debug` pour vérifier les variables réellement chargées, puis suppression des anciens templates inutilisés.

### 2.2 Netdata non détecté par le rôle

**Cause** : le chemin testé dans la tâche `stat` (vérification de présence du binaire) était incorrect.

**Solution** : correction du chemin de vérification.

**Bonne pratique** : tester l'existence réelle du binaire installé, pas un chemin supposé.

---

## 3. 🧱 nftables

### 3.1 Service `failed` uniquement au redémarrage

**Symptôme** : `nftables.service` passait en `Active: failed`, mais uniquement après un reboot (jamais lors d'un `systemctl restart` manuel).

**Cause** : une règle référençant l'interface `wg0` (via `iifname "wg0"`) était chargée avant que WireGuard n'ait créé cette interface — problème d'ordre de démarrage (race condition au boot). Une faute de frappe (`wgo` au lieu de `wg0`) et un mauvais ordre des tâches Ansible aggravaient le diagnostic.

**Solution** : réorganisation du rôle nftables dans cet ordre strict :
1. Installer nftables
2. Déployer la configuration
3. Vérifier la configuration
4. Activer le service
5. Démarrer le service

**Bonne pratique** :
```bash
sudo nft list ruleset
```
Le statut `systemd` (`active`) ne garantit pas que les bonnes règles sont réellement chargées.

### 3.2 Une règle annulait la politique `drop` par défaut

**Symptôme** : lors d'un scan `nmap` externe, des ports qui auraient dû être filtrés par la politique `drop` par défaut apparaissaient accessibles.

**Cause** : une règle d'acceptation trop permissive (limitation de débit sur les paquets SYN, sans restriction de port de destination) acceptait de fait tout paquet TCP SYN sous le seuil de débit, quel que soit le port visé — neutralisant la politique `drop` pour l'essentiel du trafic.

**Solution** : réécriture complète de la chaîne `INPUT` avec un filtrage plus strict (ports explicitement listés), ajout de rate limiting correctement scopé et de journalisation.

**Bonne pratique** : toujours valider le firewall avec un scan actif depuis une autre machine (`nmap`) : ports autorisés → visibles, ports interdits → filtrés. La relecture du fichier de configuration seule ne suffit pas.

> **Décision de projet** : cette règle a été volontairement conservée un temps comme vecteur d'attaque réel pour le PRA, avant réécriture complète de la chaîne.

---

## 4. 🌐 DNS / Bind9

### 4.1 Bind9 refusait de démarrer — `statistics-channels` mal placé

**Cause** : le bloc `statistics-channels` était déclaré à l'intérieur de `options {}`, alors qu'il doit être une instruction de premier niveau.

**Solution** : déplacement du bloc au niveau global (racine du fichier), en dehors de `options {}`.

**Bonne pratique** :
```bash
named-checkconf
```
à exécuter systématiquement avant tout redémarrage de Bind9.

### 4.2 Ping ICMP entrant bloqué (Mint → Debian)

**Symptôme** : `ping` depuis le client Mint vers le serveur Debian en timeout, alors que le sens inverse fonctionnait.

**Cause** : nftables avait une `policy drop` sur la chaîne `input`, sans règle autorisant l'ICMP `echo-request` entrant. Seul le trafic `ct state established,related` était accepté.

**Solution** : ajout d'une règle nftables dédiée :
```nft
icmp type echo-request ip saddr 192.168.1.0/24 accept
```
Redéployée via Ansible.

### 4.3 Port 53 inaccessible depuis le client (dig en timeout)

**Cause** : aucune règle nftables n'autorisait le port 53 (TCP/UDP) en entrant. Les tests locaux (`nc -z`) passaient à tort via l'interface loopback, laissant croire que le port était ouvert depuis l'extérieur.

**Solution** :
```nft
udp dport 53 ip saddr 192.168.1.0/24 accept
tcp dport 53 ip saddr 192.168.1.0/24 accept
```

### 4.4 `dig lab.local` retourne `ANSWER: 0`

**Cause** : `lab.local` est la racine de la zone, sans enregistrement `A` explicite — comportement DNS normal, pas un bug. Bind9 répondait correctement (`NOERROR`) mais n'avait rien à retourner pour ce nom précis.

**Solution** : tester un nom disposant réellement d'un enregistrement A (ex. `ns.lab.local`), qui répond correctement.

### 4.5 `nslookup` en SERVFAIL malgré `dig` direct fonctionnel

**Cause** : double origine —
1. Absence de domaine de recherche (`ipv4.dns-search`) associé au DNS interne : systemd-resolved routait la requête vers d'autres résolveurs actifs (résolveurs IPv6 auto-assignés en parallèle) qui ne connaissent pas `lab.local`.
2. Un cache SERVFAIL résiduel persistait dans systemd-resolved malgré les reconnexions.

Le client Linux Mint cumulait par ailleurs une ancienne configuration DNS résiduelle et une priorité IPv6 gênant la résolution.

**Solution** :
```bash
sudo nmcli connection modify "Connexion filaire 1" ipv4.dns-search "lab.local"
sudo nmcli connection up "Connexion filaire 1"
sudo resolvectl flush-caches
```
Complétée par un nettoyage de l'ancienne configuration réseau et la désactivation d'IPv6 sur la connexion.

**Bonne pratique** :
```bash
resolvectl status
resolvectl query ns.lab.local
```

### 4.6 `monitor.lab.local` inaccessible depuis Kali

**Cause** : le client Kali utilisait le DNS du routeur (`192.168.1.1`) plutôt que le serveur Bind9 du lab.

**Solution** : reconfiguration du DNS client pour pointer vers le serveur Bind9 du lab.

**Remarque complémentaire** : sur le serveur lui-même, `systemd-resolved.service` était absent de l'installation Debian utilisée — la résolution y est gérée directement via `/etc/resolv.conf`.

---

## 5. 🔌 WireGuard

### 5.1 Aucun handshake établi

**Symptômes** :
- Ping client → serveur : paquets perdus, sans erreur explicite
- Ping serveur → client : `Destination Host Unreachable`
- `sudo wg show` : aucune ligne `latest handshake` ni `transfer` pour le peer

**Cause** : IP publique incorrecte dans le champ `Endpoint` du fichier de configuration client — le client tentait de joindre une adresse erronée, le serveur ne recevait donc jamais les paquets UDP d'initiation.

**Solution** :
```bash
curl ifconfig.me   # récupérer la vraie IP publique du serveur
```
puis mise à jour de `Endpoint = <IP_PUBLIQUE_RÉELLE>:47512` dans la configuration client.

**Bonne pratique** :
```bash
sudo wg show
```
à vérifier en premier — l'absence de `latest handshake` oriente directement vers un problème de connectivité UDP en amont, avant de suspecter le routage ou le firewall.

> **Fausses pistes écartées durant ce diagnostic** : IP forwarding (déjà actif), règles FORWARD/MASQUERADE (déjà correctes), port UDP ouvert côté serveur, redirection de port sur la box — tout était en réalité correctement configuré.

### 5.2 Bugs Ansible lors du déploiement du rôle WireGuard

Plusieurs erreurs rencontrées et corrigées itérativement :
- deux-points manquant après `dest` dans une tâche `template` → erreur `object of type 'dict' has no attribute 'file'`
- variables Jinja2 (`{{ wg_interface }}`) affichées telles quelles dans `wg0.conf` au lieu d'être résolues (PostUp/PostDown)
- mauvaise méthode de lecture de la clé privée (`slurp` + `b64decode` au lieu d'un simple `cat`) → `Key is not the correct length or format`
- paquet `iptables` non installé, nécessaire aux règles PostUp/PostDown
- mauvais nom d'interface réseau utilisé (`eth0` au lieu de `enp0s3`) → règles PostUp/PostDown sans effet
- IP forwarding (`net.ipv4.ip_forward`) non activé → pas de routage via le VPN

### 5.3 Optimisation du tunnel

**Constat** : tunnel fonctionnel mais performances perçues comme insuffisantes.

**Causes possibles identifiées** :
- Full-tunnel (`AllowedIPs = 0.0.0.0/0`) : tout le trafic transite par le VPN, y compris le trafic internet non destiné au LAN
- MTU non optimisé (valeur par défaut 1420, source de fragmentation selon le type de connexion)
- Absence de BBR comme algorithme de contrôle de congestion TCP côté serveur

**Pistes d'optimisation** :
- Split-tunnel (`AllowedIPs = 10.0.0.0/24`) si l'accès au LAN seul suffit
- Ajustement du MTU via `ping -M do -s <taille> <ip>`
- Activation de BBR : `net.ipv4.tcp_congestion_control=bbr` dans `/etc/sysctl.d/`
- Mesure objective avant/après avec `iperf3`

---

## 6. 📱 Génération du QR Code (client Android)

**Problème** : le QR Code affiché directement dans le terminal Debian (CLI) était illisible.

**Cause** : le terminal ne gérait pas correctement les caractères Unicode utilisés pour le rendu du QR Code en mode texte.

**Solution** : génération automatique du QR Code au format `.png`, publié ensuite via le serveur web du lab plutôt qu'affiché en CLI.

**Bonne pratique** : prévoir une méthode de restitution compatible avec un environnement sans interface graphique — le serveur web existant a permis cette solution ; en son absence, un envoi par email au demandeur aurait été l'alternative envisagée.

---

## 7. 📉 Netdata

### 7.1 Installation

Plusieurs blocages successifs lors de l'installation :
- `403 Forbidden` lors du téléchargement du script d'installation (restriction réseau egress vers `get.netdata.cloud`)
- `Failed to find required executable "apt-key"` (module déprécié/absent sur Debian récent)
- `gpg: cannot open '/dev/tty'` (nécessité de l'option `--batch` en contexte non interactif)
- `gpg: aucune donnée OpenPGP valable` (récupération de clé via `curl | gpg` peu fiable)
- Dépôt APT Netdata indisponible : `InRelease` introuvable, d'abord sur Debian Trixie (non supporté), puis toujours instable même en forçant Bookworm

**Résolution finale** : abandon des dépôts APT, installation via le script officiel `kickstart.sh` téléchargé avec `get_url`.

### 7.2 Rôle Ansible ne détectant pas Netdata installé

Voir [2.2](#22-netdata-non-détecté-par-le-rôle) — chemin de vérification (`stat`) incorrect, corrigé.

### 7.3 Reverse proxy Nginx pour Netdata

- `invalid URL prefix` dans la configuration générée : mauvais formatage du bloc `content:` (indentation incorrecte dans la tâche `copy`)
- `Unable to reload service nginx` : handler `Reload nginx` manquant, et tâches placées dans le mauvais rôle (`dns` au lieu de `nginx`)

### 7.4 Alertes de santé personnalisées ne se déclenchant pas 🔄 EN COURS

**Statut** : problème **non résolu** au moment de la rédaction.

**Pistes étudiées jusqu'à présent** :
- Syntaxe YAML des fichiers dans `health.d/`
- Chargement effectif des templates par Netdata
- Réponse de l'API `/api/v1/alarms`

Ce point sera documenté en détail une fois la résolution confirmée.

---

## 8. 🖥️ Nginx / HTTPS

### 8.1 Le site principal affichait Netdata

**Cause** : les VirtualHosts étaient mal séparés — celui de Netdata captait les requêtes destinées au site principal.

**Solution** : création d'un VirtualHost dédié à Netdata, distinct du site principal.

**Bonne pratique** : un VirtualHost = un service.

### 8.2 `nginx -t` en échec — liens symboliques cassés

**Cause** : les liens dans `sites-enabled` pointaient vers des fichiers de configuration inexistants.

**Solution** : réorganisation du rôle Ansible selon cet ordre :
1. Créer les fichiers de configuration
2. Vérifier leur présence
3. Créer les liens symboliques
4. Lancer `nginx -t`
5. Recharger Nginx

**Bonne pratique** : ne jamais créer un lien symbolique vers un fichier inexistant ; ne jamais valider (`nginx -t`) après activation des liens plutôt qu'avant (erreur d'ordre initialement présente dans le rôle).

### 8.3 HTTPS disparaissait après chaque redéploiement Ansible

**Cause** : le rôle Ansible ne gérait que la configuration HTTP — les certificats SSL n'étaient jamais recréés lors d'un redéploiement complet.

**Solution** : ajout dans le rôle de la création automatique du dossier SSL, de la génération automatique du certificat et de la clé privée.

**Bonne pratique** : un rôle Ansible doit pouvoir reconstruire entièrement un service, pas seulement le configurer une première fois.

---

## 9. 💾 Restic — Sauvegarde locale

### 9.1 Permissions refusées sur des fichiers sensibles

**Symptôme** : `permission denied` sur `/etc/.pwd.lock` et `/etc/wireguard/privatekey` lors de la sauvegarde.

**Cause** : sauvegarde exécutée par l'utilisateur non privilégié `machine`, sans sudo.

### 9.2 Permission refusée en listant les snapshots

**Cause** : fichiers de snapshots appartenant à `root` (créés via une exécution précédente avec sudo), lecture tentée sans sudo.

### 9.3 Fichier de log absent en exécution manuelle

**Cause** : `/var/log/restic-backup.log` n'est créé que par la redirection du cron ; une exécution manuelle sans redirection ne le génère pas.

### 9.4 `restic snapshots` demande de préciser le dépôt

**Cause** : options `-r` (repository) et `--password-file` non fournies dans la commande.

---

## 10. ☁️ Restic — Sauvegarde distante (SFTP)

### 10.1 Impossible d'initialiser le dépôt distant

**Symptômes** :
```
Permission denied (publickey)
unable to start sftp session
unexpected EOF
```

**Causes** :
- Sous-système SFTP non activé dans `/etc/ssh/sshd_config` sur le serveur de sauvegarde
- Permissions SSH incorrectes
- Mauvaise configuration de `authorized_keys`
- Mauvaise utilisation de `RESTIC_SFTP_COMMAND`

**Solution** :
- Activation du sous-système SFTP
- Vérification complète des permissions SSH
- Utilisation de la syntaxe correcte :
```bash
-o sftp.command="ssh ..."
```

**Bonne pratique** : toujours tester la connexion SSH manuellement avant de tester Restic.

### 10.2 Authentification SSH refusée

**Cause** : permissions incorrectes sur :
```text
~/.ssh            → 700
authorized_keys   → 600
/home/restic      → 755
```

**Solution** : correction des permissions ci-dessus.

**Bonne pratique** : toujours contrôler les permissions avant d'investiguer plus loin.

### 10.3 Hostname non résolu lors de l'exécution via sudo

**Cause** : le script s'exécutait en tant que `root` (via sudo), qui n'a pas accès au fichier `~/.ssh/config` de l'utilisateur `machine` où était défini l'alias `backup-restic`.

### 10.4 Avertissement `Warning: Permanently added ... to the list of known hosts`

**Cause** : comportement normal de SSH lors de la première connexion à un hôte — pas une erreur. Géré ensuite via `StrictHostKeyChecking=no` pour les exécutions automatisées.

---

## 11. 🔐 Ansible Vault

### 11.1 Mot de passe Restic en clair dans les scripts

**Fichier concerné** : `restic-backup-remote.sh`

**Cause** : la variable `RESTIC_PASSWORD` était définie directement dans le script shell.

**Solution** : remplacement par `RESTIC_PASSWORD_FILE`, pointant vers un fichier déployé via Ansible Vault avec permissions `0600`.

### 11.2 Template `.j2` redondant

**Cause** : un template `templates/restic-password-remote.j2` était utilisé alors qu'inutile — la tâche `ansible.builtin.copy` avec `content:` suffit à déployer directement le fichier de mot de passe.

**Solution** : suppression du template, utilisation exclusive de `ansible.builtin.copy`.

### 11.3 Erreur `[Errno 13] Permission non accordée` sur `vault.yml`

**Cause** : le fichier `group_vars/all/vault.yml` avait été créé avec `sudo ansible-vault create`, ce qui lui attribuait `root` comme propriétaire. Ansible, lancé sans sudo, ne pouvait pas le lire — indépendamment du mot de passe vault.

**Solution** :
```bash
sudo chown $(id -un):$(id -gn) /opt/si-lab/ansible/group_vars/all/vault.yml
chmod 600 /opt/si-lab/ansible/group_vars/all/vault.yml
```

**Bonne pratique** : toujours créer les fichiers Ansible Vault avec l'utilisateur qui exécutera les playbooks, jamais via sudo.

---

## 12. 👤 Gestion des privilèges et des utilisateurs

### 12.1 `machine` nécessitait `NOPASSWD: ALL`

**Risque identifié** : compromission complète du serveur en cas de compte `machine` compromis.

**Solution** : limitation du sudo aux seuls scripts nécessaires :
```text
machine ALL=(root) NOPASSWD:
/usr/local/bin/restic-backup.sh,
/usr/local/bin/restic-backup-remote.sh,
/usr/bin/restic
```

### 12.2 Ansible inexécutable après restriction des droits de `machine`

**Cause** : les droits sudo de `machine`, une fois volontairement restreints aux seuls scripts de sauvegarde, ne permettaient plus d'exécuter les playbooks Ansible.

**Solution** : création d'un utilisateur dédié `ansible` avec les droits complets nécessaires au déploiement, distinct de `machine` (droits limités à l'exploitation courante et aux sauvegardes) — application du principe du moindre privilège par séparation des comptes plutôt que par élargissement des droits existants.

### 12.3 `ansible-inventory` ouvrant un pager bloquant

**Cause** : comportement du terminal/pager dans la CLI VirtualBox utilisée, non lié à Ansible lui-même.

---

## 💡 Enseignements transverses

1. **Un service actif n'est pas un service correctement configuré** : plusieurs incidents (nftables, HTTPS, Netdata) montrent qu'un service démarré sans erreur peut malgré tout ne pas se comporter comme prévu — seul un test actif et ciblé (scan externe, requête réelle, `nginx -t`) le révèle.
2. **L'ordre d'exécution compte autant que le contenu** : plusieurs bugs (nftables au boot, `nginx -t` après activation des liens, handlers trop tôt) viennent d'un ordre de tâches incorrect plutôt que d'une configuration fausse en elle-même.
3. **Toujours tester la brique la plus basse en premier** : connexion SSH avant Restic, `wg show` avant de suspecter le firewall, `named-checkconf`/`nft list ruleset` avant tout redémarrage de service.
4. **La séparation des comptes de service est plus sûre qu'un compte unique élargi** : la solution retenue à chaque fois (Ansible Vault, sudoers, `ansible` vs `machine`) a été de cloisonner par un compte dédié plutôt que d'élargir les droits d'un compte existant.

---

**Note finale** : ce document est mis à jour au fil de l'avancement du projet. Le point Netdata (§7.4) sera complété dès sa résolution confirmée.
