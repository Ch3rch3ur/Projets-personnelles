# 🐛 Troubleshooting - Projet VPN WireGuard

Ce document détaille le problème technique majeur rencontré lors du déploiement du VPN WireGuard, ainsi que la méthodologie de diagnostic et la solution appliquée.

---

## 📋 Vue d'ensemble

Le projet VPN WireGuard repose sur :
1. **WireGuard** comme solution VPN moderne et performante
2. **PiVPN** pour faciliter l'installation et la gestion
3. **UFW** comme pare-feu pour sécuriser le Raspberry Pi
4. **NAT et IP forwarding** pour router le trafic VPN

**Problème principal** : Blocage du trafic VPN après activation du pare-feu UFW.

---

## 1. 🚫 Blocage du trafic VPN après activation d'UFW

### Symptôme

Après installation et configuration initiale de WireGuard, le VPN fonctionnait correctement. Cependant, **dès l'activation du pare-feu UFW**, les clients VPN ne pouvaient plus :
* Se connecter au serveur VPN
* Accéder à Internet via le tunnel VPN
* Joindre les ressources du réseau local

**Test effectué** :
```bash
# Depuis un client VPN connecté
ping 8.8.8.8
# Résultat : Request timeout
```

### Diagnostic

#### Étape 1 : Vérifier l'état du service WireGuard

```bash
sudo systemctl status wg-quick@wg0
```

**Résultat** :
```
● wg-quick@wg0.service - WireGuard via wg-quick(8) for wg0
     Loaded: loaded
     Active: active (exited)
```

✅ **Le service WireGuard est actif et fonctionnel.**

---

#### Étape 2 : Vérifier l'état du pare-feu UFW

```bash
sudo ufw status verbose
```

**Résultat** :
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
```

**Problème identifié** :
* ❌ Le port UDP 51820 (WireGuard) n'est **pas autorisé**
* ❌ Le routage (`routed`) est **désactivé** par défaut dans UFW
* ❌ Le forwarding IP est potentiellement bloqué

---

#### Étape 3 : Vérifier le forwarding IP

```bash
cat /proc/sys/net/ipv4/ip_forward
```

**Résultat** : `1` ✅ (Le forwarding est activé au niveau système)

**Mais** : UFW peut bloquer le forwarding même si le système l'autorise.

---

#### Étape 4 : Tester avec UFW désactivé temporairement

```bash
sudo ufw disable
```

**Test depuis un client VPN** :
```bash
ping 8.8.8.8
# Résultat : 64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=15.2 ms
```

✅ **Le VPN fonctionne quand UFW est désactivé.**

**Conclusion** : UFW bloque le trafic VPN.

---

### Analyse du problème

**Causes identifiées** :

1. **Port UDP 51820 non autorisé** : UFW bloque les connexions entrantes sur le port WireGuard
2. **Politique de routage par défaut désactivée** : UFW a une politique `disabled (routed)` qui empêche le forwarding de paquets entre interfaces
3. **Règles de forwarding absentes** : Aucune règle n'autorise explicitement le routage du trafic VPN

---

### Solution

#### Étape 1 : Autoriser le port WireGuard (UDP 51820)

```bash
sudo ufw allow 51820/udp
```

**Vérification** :
```bash
sudo ufw status
```

**Résultat** :
```
To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
51820/udp                  ALLOW       Anywhere
```

---

#### Étape 2 : Autoriser le routage VPN avec `ufw route allow`

```bash
# Autoriser le routage depuis l'interface WireGuard (wg0) vers Internet
sudo ufw route allow in on wg0 out on eth0

# Autoriser le routage inverse
sudo ufw route allow in on eth0 out on wg0
```

**Explication** :
* `in on wg0 out on eth0` : Autorise les paquets venant du tunnel VPN (wg0) à sortir vers Internet (eth0)
* `in on eth0 out on wg0` : Autorise les réponses d'Internet à revenir via le tunnel VPN

**Alternative (si nom d'interface inconnu)** :
```bash
# Autoriser tout le routage depuis wg0
sudo ufw route allow in on wg0
```

---

#### Étape 3 : Vérifier la configuration du forwarding IP

**Éditer `/etc/sysctl.conf`** :
```bash
sudo nano /etc/sysctl.conf
```

**S'assurer que cette ligne est présente et décommentée** :
```
net.ipv4.ip_forward=1
```

**Appliquer les changements** :
```bash
sudo sysctl -p
```

**Vérification** :
```bash
cat /proc/sys/net/ipv4/ip_forward
```
**Résultat attendu** : `1`

---

#### Étape 4 : Réactiver UFW et vérifier la configuration

```bash
# Réactiver UFW
sudo ufw enable

# Vérifier les règles
sudo ufw status verbose
```

**Résultat attendu** :
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
51820/udp                  ALLOW IN    Anywhere

Route                      Action      From
-----                      ------      ----
Anywhere on eth0           ALLOW FWD   Anywhere on wg0
Anywhere on wg0            ALLOW FWD   Anywhere on eth0
```

---

### Vérification finale

#### Test 1 : Connexion VPN depuis un client

```bash
# Sur le client, se connecter au VPN
wg-quick up wg0

# Vérifier l'interface VPN
ip addr show wg0
```

**Résultat attendu** :
```
wg0: <POINTOPOINT,NOARP,UP,LOWER_UP>
    inet 10.8.0.2/24 scope global wg0
```

---

#### Test 2 : Ping vers Internet via le VPN

```bash
ping -c 3 8.8.8.8
```

**Résultat attendu** :
```
64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=15.2 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=117 time=14.8 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=117 time=15.5 ms
```

✅ **La connectivité Internet via VPN fonctionne**

---

#### Test 3 : Accès aux ressources locales

```bash
# Tester un serveur local (exemple : NAS sur 192.168.1.50)
ping 192.168.1.50
```

✅ **L'accès au réseau local fonctionne**

---

#### Test 4 : Vérifier la connexion WireGuard côté serveur

```bash
# Sur le Raspberry Pi (serveur VPN)
sudo wg show
```

**Résultat attendu** :
```
interface: wg0
  public key: [SERVEUR_PUBLIC_KEY]
  private key: (hidden)
  listening port: 51820

peer: [CLIENT_PUBLIC_KEY]
  endpoint: 203.0.113.42:12345
  allowed ips: 10.8.0.2/32
  latest handshake: 1 minute, 30 seconds ago
  transfer: 5.12 MiB received, 15.87 MiB sent
```

✅ **Le handshake est récent et le transfert de données est actif**

---

## 📊 Synthèse : Checklist de vérification UFW + WireGuard

### Configuration UFW
- [ ] Port UDP 51820 autorisé dans UFW
- [ ] Règle `ufw route allow in on wg0` configurée
- [ ] Règle `ufw route allow in on eth0 out on wg0` configurée (optionnel)
- [ ] UFW actif avec `sudo ufw status` → Status: active

### Configuration système
- [ ] IP forwarding activé : `cat /proc/sys/net/ipv4/ip_forward` → 1
- [ ] Configuration persistante dans `/etc/sysctl.conf`

### Configuration WireGuard
- [ ] Service WireGuard actif : `systemctl status wg-quick@wg0`
- [ ] Interface wg0 présente : `ip addr show wg0`
- [ ] Clients connectés visibles dans `sudo wg show`

### Tests de connectivité
- [ ] Connexion VPN depuis un client réussie
- [ ] Ping vers 8.8.8.8 fonctionne via VPN
- [ ] Accès aux ressources locales fonctionne
- [ ] DNS fonctionne (ping google.com)

---

## 🔧 Commandes utiles de diagnostic

### WireGuard

```bash
# Voir l'état de la connexion WireGuard
sudo wg show

# Redémarrer WireGuard
sudo systemctl restart wg-quick@wg0

# Logs WireGuard
sudo journalctl -u wg-quick@wg0 -f

# Tester la configuration manuelle
sudo wg-quick down wg0
sudo wg-quick up wg0
```

### UFW

```bash
# Voir les règles actives
sudo ufw status verbose
sudo ufw status numbered

# Voir les règles de routage
sudo ufw status | grep -i route

# Logs UFW
sudo tail -f /var/log/ufw.log

# Recharger les règles
sudo ufw reload
```

### Réseau

```bash
# Vérifier le forwarding IP
cat /proc/sys/net/ipv4/ip_forward
sysctl net.ipv4.ip_forward

# Voir les tables de routage
ip route show
ip route show table all

# Voir les règles iptables (UFW utilise iptables en arrière-plan)
sudo iptables -L -v -n
sudo iptables -t nat -L -v -n
```

### Tests de connectivité depuis le client

```bash
# Test ping via VPN
ping -c 3 8.8.8.8

# Test DNS
nslookup google.com

# Tracer la route
traceroute 8.8.8.8

# Vérifier l'IP publique (doit être celle du serveur VPN)
curl ifconfig.me
```

---

## 💡 Leçons apprises

### 1. UFW bloque le routage par défaut
La politique `disabled (routed)` d'UFW empêche le forwarding de paquets entre interfaces, même si le système autorise `ip_forward=1`. Il faut **explicitement** autoriser le routage avec `ufw route allow`.

### 2. Différence entre INPUT et FORWARD
* **INPUT** : Trafic destiné à la machine elle-même (ex : connexion SSH)
* **FORWARD** : Trafic qui **traverse** la machine (ex : VPN qui route vers Internet)

UFW gère ces deux types de trafic séparément.

### 3. Ordre de diagnostic important
1. Vérifier que le service fonctionne sans firewall
2. Activer progressivement les règles firewall
3. Tester après chaque modification

### 4. Documentation essentielle
Sans documentation claire, reproduire la configuration UFW + WireGuard est complexe. Ce troubleshooting servira de référence pour de futurs déploiements.

---

## 📚 Ressources complémentaires

* [WireGuard Official Documentation](https://www.wireguard.com/)
* [PiVPN Documentation](https://docs.pivpn.io/)
* [UFW Ubuntu Guide](https://help.ubuntu.com/community/UFW)
* [DigitalOcean - WireGuard Setup Guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-20-04)

---

## 🔐 Bonnes pratiques de sécurité

### Configuration UFW restrictive

```bash
# Politique par défaut : tout bloquer
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Autoriser uniquement les services nécessaires
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 51820/udp # WireGuard

# Limiter les tentatives SSH (protection brute-force)
sudo ufw limit 22/tcp
```

### Surveillance et logs

```bash
# Activer les logs UFW
sudo ufw logging on

# Vérifier les logs régulièrement
sudo tail -f /var/log/ufw.log
```

### Sauvegarde de la configuration

```bash
# Sauvegarder les règles UFW
sudo cp /etc/ufw/user.rules /backup/ufw-user.rules.backup

# Sauvegarder la config WireGuard
sudo cp /etc/wireguard/wg0.conf /backup/wg0.conf.backup
```

---

**Note finale** : Ce problème de blocage UFW est **très courant** lors du déploiement de VPN. La solution documentée ici est applicable à d'autres configurations similaires (OpenVPN, autres pare-feu Linux).