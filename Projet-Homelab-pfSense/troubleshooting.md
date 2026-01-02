# 🐛 Troubleshooting - Projet Homelab pfSense

Ce document détaille les problèmes techniques rencontrés lors de la mise en place du homelab virtualisé avec pfSense, ainsi que les solutions appliquées.

---

## 📋 Vue d'ensemble

Le homelab pfSense repose sur une architecture virtualisée où :
1. **pfSense** agit comme pare-feu et passerelle entre LAN et WAN
2. **VirtualBox** fournit l'environnement de virtualisation
3. **Plusieurs machines virtuelles** simulent un réseau d'entreprise

**Contrainte principale** : Une seule carte réseau physique sur la machine hôte, nécessitant des adaptations.

---

## 1. 🖧 Configuration des interfaces réseau VirtualBox

### Symptôme

Sur Kali Linux, VirtualBox ne propose pas automatiquement la configuration de plusieurs adaptateurs réseau pour une machine virtuelle. L'interface graphique est limitée.

### Analyse du problème

**Causes identifiées** :
* VirtualBox sur Kali Linux ne configure pas automatiquement plusieurs adaptateurs
* L'interface graphique VirtualBox ne permet pas toujours d'ajouter facilement des cartes réseau supplémentaires
* Nécessité d'utiliser VBoxManage en ligne de commande

### Solution appliquée

J'ai configuré manuellement les interfaces réseau via la commande `VBoxManage` :

**Pour pfSense** :
- Interface 1 (WAN) : Mode Bridged vers `wlan0`
- Interface 2 (LAN) : Mode Internal Network `"LAN"`

**Pour les machines clientes** :
- Interface 1 : Mode Internal Network `"LAN"`

### Résultat

✅ Toutes les machines configurées correctement  
✅ Communication fonctionnelle entre LAN et WAN  
✅ pfSense accessible depuis les clients

### Documentation complète

👉 **Pour reproduire l'installation complète** :  
[Guide VBoxManage détaillé](Script/vboxmanage_commands.md)

👉 **Pour les commandes rapides** :  
[Scripts d'installation](Script/README.md)

---

## 2. 🚧 Contraintes matérielles : Une seule carte réseau physique

### Symptôme

Impossible de créer une véritable séparation physique entre WAN et LAN en utilisant deux cartes réseau physiques distinctes sur la machine hôte.

### Impact sur l'architecture

**Limitations** :
* Pas de connexion "Bridged" pour WAN et LAN simultanément
* Utilisation obligatoire du mode NAT pour WAN
* Performance réseau légèrement réduite (overhead NAT)
* Impossible d'implémenter des VLAN physiques

**Architecture adaptée** :
```
Internet
   │
   ├─ Box Internet (FAI)
   │
   └─ Machine hôte (Kali Linux) - 1 seule carte réseau physique
       │
       └─ VirtualBox
           │
           ├─ pfSense
           │   ├─ WAN (NAT) ──→ Internet via hôte
           │   └─ LAN (Internal) ──→ Réseau isolé
           │
           ├─ Debian (Internal "homelab-lan")
           └─ Windows Server (Internal "homelab-lan")
```

### Solution : Accepter et documenter la contrainte

**Décision prise** : Travailler avec cette limitation pour :
1. Comprendre l'impact du matériel sur l'architecture
2. Développer des compétences d'adaptation
3. Documenter les limites et les améliorations possibles

**En environnement professionnel idéal** :
* Utilisation de 2 cartes réseau physiques minimum
* WAN en Bridged sur interface physique 1
* LAN en Bridged sur interface physique 2
* Possibilité d'ajouter des VLAN sur switch manageable

---

## 3. 🔧 Configuration initiale de pfSense

### Symptôme

Après installation de pfSense, les interfaces réseau ne sont pas automatiquement assignées correctement.

### Solution : Configuration manuelle des interfaces

#### Étape 1 : Accéder à la console pfSense

Au premier démarrage, pfSense affiche :
```
Welcome to pfSense!

Valid interfaces are:
em0  00:0c:29:xx:xx:xx (up)
em1  00:0c:29:yy:yy:yy (up)

Enter an option:
1) Assign Interfaces
2) Set interface(s) IP address
...
```

#### Étape 2 : Assigner les interfaces

**Choisir option 1 : Assign Interfaces**

```
Enter the WAN interface name or 'a' for auto-detection: em0
Enter the LAN interface name or 'a' for auto-detection: em1

Do you want to proceed [y|n]? y
```

**Résultat** :
* WAN = em0 (interface connectée en NAT)
* LAN = em1 (interface sur Internal Network)

#### Étape 3 : Configurer l'IP du LAN

**Choisir option 2 : Set interface(s) IP address**

```
Available interfaces:
1 - WAN (em0 - dhcp)
2 - LAN (em1 - static)

Enter the number of the interface to configure: 2

Enter the new LAN IPv4 address: 192.168.2.1
Enter the new LAN IPv4 subnet bit count: 24

Do you want to enable the DHCP server on LAN? [y|n]: y
Enter the start address of the IPv4 client address range: 192.168.2.10
Enter the end address of the IPv4 client address range: 192.168.2.100

Do you want to revert to HTTP as the webConfigurator protocol? [y|n]: n
```

**Résultat** :
* LAN IP : 192.168.2.1/24
* DHCP range : 192.168.2.10 - 192.168.2.100
* WebGUI accessible via HTTPS sur 192.168.2.1

#### Étape 4 : Accéder à l'interface web

Depuis une machine sur le LAN (Debian ou Windows) :
```
https://192.168.2.1
```

**Identifiants par défaut** :
* Utilisateur : `admin`
* Mot de passe : `pfsense`

---

## 4. 🌐 Test de connectivité Internet depuis le LAN

### Symptôme

Les machines du LAN ne peuvent pas accéder à Internet malgré la configuration de pfSense.

### Diagnostic

#### Étape 1 : Vérifier que les machines obtiennent une IP

Sur Debian :
```bash
ip addr show
```

**Résultat attendu** :
```
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP>
    inet 192.168.2.10/24 brd 192.168.2.255 scope global dynamic enp0s3
```

Sur Windows Server :
```cmd
ipconfig
```

**Résultat attendu** :
```
Carte Ethernet :
   Adresse IPv4. . . . . . . . : 192.168.2.11
   Masque de sous-réseau . . . : 255.255.255.0
   Passerelle par défaut . . . : 192.168.2.1
```

#### Étape 2 : Tester la passerelle (pfSense)

```bash
ping 192.168.2.1
```

✅ Si ça répond → pfSense est accessible

#### Étape 3 : Tester une IP Internet

```bash
ping 8.8.8.8
```

❌ Si pas de réponse → Problème de routage ou de règles firewall

#### Étape 4 : Vérifier les règles firewall sur pfSense

**Via l'interface web pfSense** :
1. Aller dans **Firewall → Rules → LAN**
2. Vérifier qu'il existe une règle permettant le trafic sortant

**Règle par défaut nécessaire** :
```
Action: Pass
Interface: LAN
Source: LAN net
Destination: any
```

Si cette règle est absente, l'ajouter :
* Action : Pass
* Interface : LAN
* Protocol : any
* Source : LAN net
* Destination : any

#### Étape 5 : Vérifier le NAT outbound

**Via l'interface web pfSense** :
1. Aller dans **Firewall → NAT → Outbound**
2. Vérifier que le mode est sur **Automatic outbound NAT**

✅ En mode automatique, pfSense crée automatiquement les règles NAT pour le LAN.

---

### Solution finale

Une fois les règles firewall et le NAT configurés :

```bash
# Test DNS
ping google.com

# Test HTTP
curl -I https://www.google.com
```

✅ **Résultat** : Accès Internet fonctionnel depuis le LAN via pfSense.

---

## 📊 Synthèse : Checklist de vérification

### Configuration VirtualBox
- [ ] pfSense a 2 interfaces (NAT + Internal)
- [ ] Machines clientes sont sur Internal Network "homelab-lan"
- [ ] Câbles réseau virtuels sont "connectés"

### Configuration pfSense
- [ ] Interfaces assignées (WAN = em0, LAN = em1)
- [ ] LAN IP : 192.168.2.1/24
- [ ] DHCP activé sur LAN (range 192.168.2.10-100)
- [ ] WebGUI accessible depuis le LAN

### Connectivité
- [ ] Machines clientes obtiennent une IP DHCP
- [ ] Ping vers 192.168.2.1 fonctionne
- [ ] Ping vers 8.8.8.8 fonctionne
- [ ] Résolution DNS fonctionne (ping google.com)

---

## 🔧 Commandes utiles de diagnostic

### VirtualBox

```bash
# Lister les VMs
VBoxManage list vms

# Voir la config réseau d'une VM
VBoxManage showvminfo "pfSense" | grep NIC

# Modifier une interface réseau
VBoxManage modifyvm "VM-Name" --nic1 intnet --intnet1 "homelab-lan"

# Démarrer une VM en mode headless
VBoxManage startvm "pfSense" --type headless

# Arrêter une VM proprement
VBoxManage controlvm "pfSense" acpipowerbutton
```

### Réseau (depuis machines clientes)

```bash
# Vérifier l'IP
ip addr show       # Linux
ipconfig           # Windows

# Vérifier la route par défaut
ip route           # Linux
route print        # Windows

# Tester la passerelle
ping 192.168.2.1

# Tester Internet
ping 8.8.8.8
ping google.com
```

---

## 💡 Leçons apprises

### 1. L'importance de VBoxManage
L'interface graphique VirtualBox ne suffit pas toujours. La ligne de commande `VBoxManage` est essentielle pour des configurations réseau avancées.

### 2. Comprendre les modes réseau
Chaque mode a son utilité :
* **NAT** : Simple pour accès Internet depuis une VM
* **Internal** : Parfait pour créer un réseau isolé entre VMs
* **Bridged** : Nécessite une carte réseau physique mais offre le plus de flexibilité

### 3. Les contraintes matérielles sont pédagogiques
Travailler avec une seule carte réseau force à comprendre les limitations et à trouver des solutions adaptées, compétence utile en entreprise.

### 4. pfSense est sensible à l'ordre des interfaces
Il faut bien identifier quelle interface VirtualBox (em0, em1) correspond à quel rôle (WAN, LAN) avant d'assigner.

---

## 📚 Ressources complémentaires

* Documentation pfSense : [pfSense Documentation](https://docs.netgate.com/pfsense/en/latest/)
* VirtualBox Manual : [VBoxManage Reference](https://www.virtualbox.org/manual/ch08.html)
* Guide VirtualBox Networking : [Networking modes explained](https://www.virtualbox.org/manual/ch06.html)

---

**Note finale** : Ce document reflète mon expérience réelle du projet. Les commandes et solutions indiquées sont celles qui ont fonctionné dans mon environnement avec une seule carte réseau physique.
