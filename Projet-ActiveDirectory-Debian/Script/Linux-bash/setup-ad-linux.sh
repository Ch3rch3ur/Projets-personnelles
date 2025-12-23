#!/bin/bash
set -e

DOMAIN="homelab.local"
REALM="HOMELAB.LOCAL"
DC="srv-win.homelab.local"

echo "=== Installation des paquets ==="
apt update
apt install -y \
  realmd sssd sssd-tools \
  libnss-sss libpam-sss \
  adcli samba-common-bin \
  oddjob oddjob-mkhomedir \
  krb5-user

echo "=== Jointure au domaine ==="
realm join $DOMAIN

echo "=== Configuration SSSD ==="
cat > /etc/sssd/sssd.conf <<EOF
[sssd]
domains = $DOMAIN
config_file_version = 2
services = nss, pam

[domain/$DOMAIN]
id_provider = ad
access_provider = ad
ad_domain = $DOMAIN
krb5_realm = $REALM
use_fully_qualified_names = True
ldap_id_mapping = True
cache_credentials = True
fallback_homedir = /home/%u
default_shell = /bin/bash

ad_access_filter = (|(memberOf=CN=linux-users,CN=Users,DC=homelab,DC=local)(memberOf=CN=linux-admins,CN=Users,DC=homelab,DC=local))
EOF

chmod 600 /etc/sssd/sssd.conf

echo "=== PAM mkhomedir ==="
grep -q pam_mkhomedir.so /etc/pam.d/common-session || \
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0077" >> /etc/pam.d/common-session

echo "=== Sudo AD ==="
cat > /etc/sudoers.d/linux-admins <<EOF
%linux-admins@$DOMAIN ALL=(ALL) ALL
EOF

chmod 440 /etc/sudoers.d/linux-admins

echo "=== Redémarrage services ==="
systemctl restart sssd
systemctl restart ssh

echo "=== Vérifications ==="
realm list
echo "Terminé."

