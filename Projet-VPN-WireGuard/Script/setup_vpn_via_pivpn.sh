#!/bin/bash
# Script d'installation et configuration complète VPN WireGuard avec routage NAT

# Vérifier que le script est exécuté avec sudo
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté avec sudo" 
   exit 1
fi

# 1. Mise à jour du système
echo "Mise à jour du système..."
apt update && apt full-upgrade -y

# 2. Installer PiVPN
echo "Installation de PiVPN..."
curl -L https://install.pivpn.io | bash

# Après l'installation PiVPN, on configure le routage

# 3. Activer IP forwarding
echo "Activation de l'IP forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/' /etc/sysctl.conf
sysctl -p

# 4. Configurer NAT avec iptables pour interface wlan0 (changer si besoin)
echo "Configuration du NAT sur wlan0..."
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE

# Rendre la règle persistante
apt install netfilter-persistent -y
netfilter-persistent save
netfilter-persistent reload

# 5. Optionnel : ajouter un client VPN
read -p "Voulez-vous ajouter un client VPN maintenant ? (o/n) : " ADD_CLIENT
if [[ "$ADD_CLIENT" =~ ^[Oo]$ ]]; then
    read -p "Nom du client : " CLIENT_NAME
    pivpn add -n "$CLIENT_NAME"
    echo "Fichier de configuration du client créé dans /home/pi/configs/$CLIENT_NAME.conf"
fi

echo "Installation et configuration terminées. N'oubliez pas d'ouvrir le port UDP sur votre routeur."

