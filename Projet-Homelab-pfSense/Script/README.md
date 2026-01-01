# 📜 Scripts d'installation - Homelab pfSense

Ce dossier contient les scripts et commandes nécessaires pour reproduire le homelab pfSense avec VirtualBox sur Kali Linux.

---

## 📋 Contenu

* **`vboxmanage-commands.md`** : Guide complet avec toutes les commandes VBoxManage pas à pas
* **`setup-pfsense.sh`** : Script bash automatisé pour configurer les interfaces réseau
* **Compte-rendu d'installation (PDF)** : Document original dans `../docs/`

---

## 🚀 Démarrage rapide

### Prérequis

* Kali Linux (ou Debian-based)
* VirtualBox installé
* VM pfSense créée (mais pas encore configurée)
* Au moins une machine cliente (Debian ou Windows)

### Installation en 3 étapes

#### 1. Installer VirtualBox

```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Télécharger la clé publique Oracle
wget -q https://www.virtualbox.org/download/oracle_vbox.asc
sudo apt-key add oracle_vbox.asc

# Ajouter le dépôt VirtualBox
echo "deb http://download.virtualbox.org/virtualbox/debian kali-rolling contrib" | sudo tee -a /etc/apt/sources.list

# Installer VirtualBox
sudo apt install virtualbox-6.1

# Redémarrer
sudo reboot
```

#### 2. Configurer les interfaces réseau

**Option A : Script automatisé (recommandé)**

```bash
# Éditer le script pour mettre vos noms de VM
nano setup-pfsense.sh

# Rendre exécutable
chmod +x setup-pfsense.sh

# Lancer le script
./setup-pfsense.sh
```

**Option B : Commandes manuelles**

Voir le fichier `vboxmanage-commands.md` pour toutes les commandes détaillées.

#### 3. Démarrer et configurer pfSense

```bash
# Démarrer pfSense
VBoxManage startvm "Firewall-pfSense"

# Se connecter à la console pfSense et suivre les instructions
# 1) Assign Interfaces → WAN: em0, LAN: em1
# 2) Set interface IP → LAN: 192.168.2.1/24
```

---

## 🔧 Configuration rapide des interfaces

### Pour pfSense (2 interfaces)

```bash
# WAN (accès Internet via pont/bridged)
VBoxManage modifyvm "Firewall-pfSense" --nic1 bridged --bridgeadapter1 wlan0 --cableconnected1 on

# LAN (réseau interne)
VBoxManage modifyvm "Firewall-pfSense" --nic2 intnet --intnet2 "LAN" --cableconnected2 on

# Vérifier
VBoxManage showvminfo "Firewall-pfSense" | grep -i nic
```

### Pour machines clientes (Debian, Windows)

```bash
# Debian
VBoxManage modifyvm "Debian" --nic1 intnet --intnet1 "LAN" --cableconnected1 on

# Windows Server
VBoxManage modifyvm "Windows-Server" --nic1 intnet --intnet1 "LAN" --cableconnected1 on

# Vérifier
VBoxManage showvminfo "Debian" | grep -i nic
```

---

## ⚠️ Points d'attention

### Interface bridged (wlan0 vs eth0)

**Si vous êtes en WiFi** :
```bash
--bridgeadapter1 wlan0
```

**Si vous êtes en Ethernet** :
```bash
--bridgeadapter1 eth0
```

Pour connaître votre interface :
```bash
ip link show
```

### Nom du réseau interne

Toutes les machines doivent utiliser **le même nom** pour communiquer :
```bash
--intnet1 "LAN"  # Ou "homelab-lan", peu importe tant que c'est cohérent
```

---

## 📊 Vérification de la configuration

### Lister toutes les VMs

```bash
VBoxManage list vms
```

### Vérifier la configuration réseau d'une VM

```bash
VBoxManage showvminfo "Nom-VM" | grep -i nic
```

**Résultat attendu pour pfSense** :
```
NIC 1: Attachment: Bridged Interface 'wlan0', Cable connected: on
NIC 2: Attachment: Internal Network 'LAN', Cable connected: on
```

**Résultat attendu pour machines clientes** :
```
NIC 1: Attachment: Internal Network 'LAN', Cable connected: on
```

---

## 🐛 Dépannage rapide

### Les machines ne se voient pas

1. Vérifier qu'elles sont sur le même réseau interne :
   ```bash
   VBoxManage showvminfo "VM1" | grep "Internal Network"
   VBoxManage showvminfo "VM2" | grep "Internal Network"
   ```
   → Les noms doivent être identiques

2. Vérifier que les câbles sont connectés :
   ```bash
   VBoxManage showvminfo "VM" | grep "Cable connected"
   ```
   → Doit afficher "on"

### pfSense ne voit qu'une interface

Vérifier que les deux interfaces sont configurées :
```bash
VBoxManage showvminfo "Firewall-pfSense" | grep -i nic | grep -v disabled
```

Si une interface est manquante, la reconfigurer avec les commandes ci-dessus.

---

## 📚 Documentation complète

* **Guide pas à pas** : Voir `vboxmanage-commands.md`
* **Résolution de problèmes** : Voir `../TROUBLESHOOTING.md`
* **Compte-rendu complet** : Voir `../docs/Projet_Homelab_Compte_rendu.pdf`

---

## 🎓 Ressources utiles

* [Documentation VirtualBox Networking](https://www.virtualbox.org/manual/ch06.html)
* [Documentation pfSense](https://docs.netgate.com/pfsense/en/latest/)
* [VBoxManage Reference](https://www.virtualbox.org/manual/ch08.html)