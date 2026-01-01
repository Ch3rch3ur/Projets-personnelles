# 🔧 Guide complet VBoxManage - Installation pfSense Homelab

Ce document détaille toutes les commandes VBoxManage utilisées pour configurer le homelab pfSense sur Kali Linux avec VirtualBox.

---

## 📋 Prérequis

* **Système hôte** : Kali Linux (ou distribution Debian-based)
* **Hyperviseur** : VirtualBox 6.1 ou supérieur
* **VMs créées** : pfSense, Debian, Windows Server (mais pas encore configurées réseau)

---

## 1️⃣ Installation de VirtualBox sur Kali Linux

### Étape 1 : Mise à jour du système

```bash
sudo apt update && sudo apt upgrade -y
```

### Étape 2 : Télécharger la clé publique Oracle

```bash
wget -q https://www.virtualbox.org/download/oracle_vbox.asc
sudo apt-key add oracle_vbox.asc
```

**Explication** : Cette clé permet de vérifier l'authenticité des paquets VirtualBox téléchargés depuis les dépôts Oracle.

### Étape 3 : Ajouter le dépôt VirtualBox

```bash
echo "deb http://download.virtualbox.org/virtualbox/debian kali-rolling contrib" | sudo tee -a /etc/apt/sources.list
```

**Explication** : Ajoute le dépôt officiel Oracle VirtualBox au fichier sources.list pour permettre l'installation via apt.

### Étape 4 : Installer VirtualBox

```bash
sudo apt update
sudo apt install virtualbox-6.1 -y
```

### Étape 5 : Redémarrer le système

```bash
sudo reboot
```

**Pourquoi redémarrer ?** VirtualBox installe des modules kernel qui nécessitent un redémarrage pour être chargés correctement.

### Étape 6 : Vérifier l'installation

```bash
virtualbox
```

L'interface graphique VirtualBox devrait s'ouvrir.

---

## 2️⃣ Création des VMs

> **Note** : Ce guide suppose que vous avez déjà créé les VMs via l'interface graphique VirtualBox. Nous allons maintenant configurer uniquement les interfaces réseau via VBoxManage.

**VMs nécessaires** :
* Firewall pfSense
* Debian (client Linux)
* Windows Server 2022 (serveur AD)

---

## 3️⃣ Configuration réseau de pfSense

### Étape 1 : Lister les VMs existantes

```bash
VBoxManage list vms
```

**Résultat attendu** :
```
"Debian" {a1b2c3d4-e5f6-7890-abcd-ef1234567890}
"Serveur-Windows" {11223344-5566-7788-99aa-bbccddeeff00}
"Firewall pfSense" {aabbccdd-eeff-0011-2233-445566778899}
```

**Explication** : Les identifiants entre accolades sont les UUID des VMs. Vous pouvez utiliser soit le nom, soit l'UUID dans les commandes VBoxManage.

---

### Étape 2 : Configuration de l'interface WAN (accès Internet)

#### Mettre l'adaptateur 1 en mode Bridged (pont)

```bash
VBoxManage modifyvm "Firewall pfSense" --nic1 bridged
```

**Explication** : Le mode bridged permet à la VM d'obtenir une IP sur le réseau physique de l'hôte, comme si c'était une machine physique connectée au réseau.

#### Spécifier l'interface physique à utiliser

```bash
VBoxManage modifyvm "Firewall pfSense" --bridgeadapter1 wlan0
```

**Explication** : 
* `wlan0` : Interface WiFi (si vous êtes connecté en WiFi)
* `eth0` : Interface Ethernet (si vous êtes connecté en câble)

Pour connaître votre interface active :
```bash
ip link show
# ou
ip addr
```

#### Activer l'interface (simuler un câble branché)

```bash
VBoxManage modifyvm "Firewall pfSense" --cableconnected1 on
```

**Explication** : Simule le branchement d'un câble réseau sur la carte réseau virtuelle.

---

### Étape 3 : Configuration de l'interface LAN (réseau interne)

#### Configurer l'adaptateur 2 en mode Internal Network

```bash
VBoxManage modifyvm "Firewall pfSense" --nic2 intnet
```

**Explication** : Le mode Internal Network crée un réseau privé isolé accessible uniquement aux VMs configurées sur ce réseau. Pas d'accès direct à l'hôte ni à Internet.

#### Définir le nom du réseau interne

```bash
VBoxManage modifyvm "Firewall pfSense" --intnet2 "LAN"
```

**Explication** : 
* `--intnet2` : Configure le réseau interne pour l'adaptateur 2
* `"LAN"` : Nom du réseau interne (vous pouvez choisir n'importe quel nom)
* **Important** : Toutes les VMs qui doivent communiquer entre elles doivent utiliser le **même nom** de réseau interne

#### Activer l'interface

```bash
VBoxManage modifyvm "Firewall pfSense" --cableconnected2 on
```

---

### Étape 4 : Vérifier la configuration de pfSense

```bash
VBoxManage showvminfo "Firewall pfSense" | grep -i nic
```

**Résultat attendu** :
```
NIC 1: MAC: 0800275F10C3, Attachment: Bridged Interface 'wlan0', Cable connected: on, Trace: off (file: none), Type: 82540EM, Reported speed: 0 Mbps, Boot priority: 0, Promisc Policy: deny, Bandwidth group: none

NIC 2: MAC: 08002739D57E, Attachment: Internal Network 'LAN', Cable connected: on, Trace: off (file: none), Type: 82540EM, Reported speed: 0 Mbps, Boot priority: 0, Promisc Policy: deny, Bandwidth group: none

NIC 3: disabled
NIC 4: disabled
NIC 5: disabled
NIC 6: disabled
NIC 7: disabled
NIC 8: disabled
```

**Vérifications** :
* ✅ NIC 1 : Bridged Interface 'wlan0' (ou eth0), Cable connected: on
* ✅ NIC 2 : Internal Network 'LAN', Cable connected: on
* ✅ NIC 3-8 : disabled

---

## 4️⃣ Configuration réseau des machines clientes

### Principe

Les machines clientes (Debian, Windows Server) doivent être connectées au **même réseau interne** que l'interface LAN de pfSense pour pouvoir communiquer avec lui et accéder à Internet via le pare-feu.

---

### Configuration de Debian

#### Étape 1 : Désactiver l'interface actuelle (si elle existe)

```bash
VBoxManage modifyvm "Debian" --nic1 none
```

**Pourquoi ?** Si Debian était configuré en NAT pour l'installation initiale, on désactive d'abord l'interface pour la reconfigurer proprement.

#### Étape 2 : Configurer en mode Internal Network

```bash
VBoxManage modifyvm "Debian" --nic1 intnet
```

#### Étape 3 : Définir le nom du réseau interne

```bash
VBoxManage modifyvm "Debian" --intnet1 "LAN"
```

**Important** : Le nom `"LAN"` doit être **identique** à celui configuré sur l'interface LAN de pfSense.

#### Étape 4 : Activer l'interface

```bash
VBoxManage modifyvm "Debian" --cableconnected1 on
```

#### Étape 5 : Vérifier la configuration

```bash
VBoxManage showvminfo "Debian" | grep -i nic
```

**Résultat attendu** :
```
NIC 1: MAC: 08002752C462, Attachment: Internal Network 'LAN', Cable connected: on, Trace: off (file: none), Type: 82540EM, Reported speed: 0 Mbps, Boot priority: 0, Promisc Policy: deny, Bandwidth group: none

NIC 2: disabled
NIC 3: disabled
...
```

---

### Configuration de Windows Server

**Commandes identiques à Debian** (remplacer "Debian" par "Serveur-Windows") :

```bash
# Désactiver l'interface actuelle
VBoxManage modifyvm "Serveur-Windows" --nic1 none

# Configurer en Internal Network
VBoxManage modifyvm "Serveur-Windows" --nic1 intnet

# Définir le réseau interne
VBoxManage modifyvm "Serveur-Windows" --intnet1 "LAN"

# Activer l'interface
VBoxManage modifyvm "Serveur-Windows" --cableconnected1 on

# Vérifier
VBoxManage showvminfo "Serveur-Windows" | grep -i nic
```

---

## 5️⃣ Démarrage et configuration de pfSense

### Étape 1 : Démarrer pfSense

```bash
VBoxManage startvm "Firewall pfSense"
```

Ou en mode headless (sans interface graphique) :
```bash
VBoxManage startvm "Firewall pfSense" --type headless
```

### Étape 2 : Assigner les interfaces dans pfSense

Au premier démarrage, pfSense affiche :
```
Valid interfaces are:
em0  00:08:27:XX:XX:XX (up)
em1  00:08:27:YY:YY:YY (up)

Enter an option:
```

**Choisir option 1 : Assign Interfaces**

```
Enter the WAN interface name: em0
Enter the LAN interface name: em1

Do you want to proceed [y|n]? y
```

**Correspondance** :
* `em0` = NIC 1 (Bridged / WAN)
* `em1` = NIC 2 (Internal Network / LAN)

### Étape 3 : Configurer l'IP du LAN

**Choisir option 2 : Set interface(s) IP address**

```
Available interfaces:
1 - WAN (em0 - dhcp)
2 - LAN (em1 - static)

Enter the number: 2

Enter the new LAN IPv4 address: 192.168.2.1
Subnet bit count: 24

Enable DHCP server on LAN? [y|n]: y
Start address: 192.168.2.10
End address: 192.168.2.100

Revert to HTTP for webConfigurator? [y|n]: n
```

**Configuration appliquée** :
* LAN IP : 192.168.2.1/24
* DHCP range : 192.168.2.10 - 192.168.2.100
* WebGUI : HTTPS sur 192.168.2.1

---

## 6️⃣ Test de connectivité

### Depuis une machine cliente (Debian)

```bash
# Vérifier l'IP obtenue (devrait être 192.168.2.x)
ip addr show

# Tester la passerelle (pfSense)
ping 192.168.2.1

# Tester Internet
ping 8.8.8.8
ping google.com
```

### Depuis Windows Server

```cmd
# Vérifier l'IP
ipconfig

# Tester la passerelle
ping 192.168.2.1

# Tester Internet
ping 8.8.8.8
```

---

## 📊 Récapitulatif des configurations

### pfSense (Firewall)

| Interface | Mode VirtualBox | Réseau | Rôle |
|-----------|----------------|--------|------|
| NIC 1 (em0) | Bridged (wlan0/eth0) | Réseau physique | WAN (Internet) |
| NIC 2 (em1) | Internal Network "LAN" | 192.168.2.0/24 | LAN (réseau interne) |

### Debian / Windows Server

| Interface | Mode VirtualBox | Réseau | Rôle |
|-----------|----------------|--------|------|
| NIC 1 | Internal Network "LAN" | 192.168.2.0/24 (DHCP) | Client LAN |

---

## 🔧 Commandes de gestion utiles

### Lister toutes les VMs

```bash
VBoxManage list vms
```

### Lister les VMs en cours d'exécution

```bash
VBoxManage list runningvms
```

### Arrêter proprement une VM

```bash
VBoxManage controlvm "Nom-VM" acpipowerbutton
```

### Forcer l'arrêt d'une VM

```bash
VBoxManage controlvm "Nom-VM" poweroff
```

### Voir toutes les infos d'une VM

```bash
VBoxManage showvminfo "Nom-VM"
```

### Voir uniquement la config réseau

```bash
VBoxManage showvminfo "Nom-VM" | grep -i nic
```

### Modifier une interface réseau

```bash
# Changer le mode
VBoxManage modifyvm "Nom-VM" --nic1 [nat|bridged|intnet|hostonly|none]

# Changer le réseau interne
VBoxManage modifyvm "Nom-VM" --intnet1 "Nom-Reseau"

# Brancher/débrancher le câble
VBoxManage modifyvm "Nom-VM" --cableconnected1 [on|off]
```

---

## 🎓 Comprendre les modes réseau VirtualBox

### NAT (Network Address Translation)

```bash
VBoxManage modifyvm "VM" --nic1 nat
```

**Utilité** :
* ✅ La VM peut accéder à Internet via l'hôte
* ✅ Simple à configurer
* ❌ La VM n'est pas accessible depuis le réseau physique
* ❌ Les VMs en NAT ne peuvent pas communiquer entre elles

**Cas d'usage** : Installation initiale d'une VM nécessitant Internet

---

### Bridged (Accès par pont)

```bash
VBoxManage modifyvm "VM" --nic1 bridged --bridgeadapter1 wlan0
```

**Utilité** :
* ✅ La VM obtient une IP sur le réseau physique de l'hôte
* ✅ La VM est accessible depuis le réseau physique
* ✅ Idéal pour WAN de pfSense
* ❌ Dépend de l'interface physique de l'hôte

**Cas d'usage** : Interface WAN de pfSense pour accès Internet

---

### Internal Network (Réseau interne)

```bash
VBoxManage modifyvm "VM" --nic1 intnet --intnet1 "Nom-Reseau"
```

**Utilité** :
* ✅ Réseau privé isolé entre VMs
* ✅ Pas d'accès à l'hôte ni à Internet directement
* ✅ Idéal pour créer un LAN sécurisé
* ✅ Toutes les VMs sur le même nom de réseau communiquent entre elles

**Cas d'usage** : Interface LAN de pfSense et machines clientes

---

### Host-only (Réseau hôte uniquement)

```bash
VBoxManage modifyvm "VM" --nic1 hostonly
```

**Utilité** :
* ✅ Communication entre VMs et hôte
* ✅ Isolation du réseau physique
* ❌ Pas d'accès Internet sans configuration supplémentaire

**Cas d'usage** : Administration de VMs depuis l'hôte uniquement

---

## 💡 Bonnes pratiques

### Nommage cohérent

Utilisez des noms de VMs clairs et cohérents :
* ✅ `Firewall-pfSense`
* ✅ `Debian-Client`
* ✅ `Windows-Server-AD`
* ❌ `VM1`, `Test`, `New`

### Nommage des réseaux internes

Utilisez des noms explicites :
* ✅ `"LAN"`, `"homelab-lan"`, `"DMZ"`
* ❌ `"reseau1"`, `"test"`

### Documentation

Documentez chaque configuration :
```bash
# Après chaque modif, vérifier et sauvegarder la config
VBoxManage showvminfo "VM" | grep -i nic > config-reseau-VM.txt
```

---

## 📚 Ressources complémentaires

* [VirtualBox Manual - Chapter 6: Virtual Networking](https://www.virtualbox.org/manual/ch06.html)
* [VBoxManage Reference](https://www.virtualbox.org/manual/ch08.html)
* [pfSense Documentation](https://docs.netgate.com/pfsense/en/latest/)

---

**Note** : Ce document reflète la configuration réelle utilisée dans le projet. Toutes les commandes ont été testées et validées sur Kali Linux avec VirtualBox 6.1.