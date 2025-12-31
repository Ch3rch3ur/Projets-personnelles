#!/bin/bash
# Script d'installation et sécurisation Apache sur Raspberry Pi
# Testé sur Debian 12 (Raspberry Pi OS)

set -e

DOMAIN="" # configuration via no-ip
WEBROOT="/var/www/html"

echo "=== Mise à jour du système ==="
sudo apt update && sudo apt upgrade -y

echo "=== Installation Apache, PHP, Certbot ==="
sudo apt install -y apache2 php libapache2-mod-php certbot python3-certbot-apache

echo "=== Activation des modules Apache ==="
sudo a2enmod ssl headers rewrite expires

echo "=== Création VirtualHost pour $DOMAIN ==="
sudo tee /etc/apache2/sites-available/${DOMAIN}.conf > /dev/null <<EOF
# Redirection HTTP -> HTTPS
<VirtualHost *:80>
    ServerName ${DOMAIN}

    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}\$1 [R=301,L]
</VirtualHost>

# HTTPS
<VirtualHost *:443>
    ServerName ${DOMAIN}

    DocumentRoot ${WEBROOT}

    <Directory ${WEBROOT}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # --- SSL (Let’s Encrypt remplira ces chemins) ---
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/${DOMAIN}/privkey.pem

    # --- Sécurité des en-têtes ---
    <IfModule mod_headers.c>
        Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        Header always set X-Content-Type-Options "nosniff"
        Header always set X-Frame-Options "DENY"
        Header always set Referrer-Policy "strict-origin-when-cross-origin"
        Header always set Permissions-Policy "geolocation=(), microphone=(), camera=(), usb=(), payment=(), accelerometer=(), gyroscope=(), magnetometer=(), midi=(), fullscreen=(self)"
        Header always set Content-Security-Policy "default-src 'self'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'; upgrade-insecure-requests; connect-src 'self'; img-src 'self' data: blob: https:; font-src 'self' data:; style-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com; script-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com https://unpkg.com"
        Header always set Cross-Origin-Opener-Policy "same-origin"
        Header always set Cross-Origin-Embedder-Policy "require-corp"
        Header always set Cross-Origin-Resource-Policy "same-origin"
        Header always set X-XSS-Protection "1; mode=block"
    </IfModule>

    # --- Gestion du cache ---
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType text/html "access plus 0 seconds"
        ExpiresByType image/png "access plus 30 days"
        ExpiresByType image/jpeg "access plus 30 days"
        ExpiresByType image/gif "access plus 30 days"
        ExpiresByType image/webp "access plus 30 days"
        ExpiresByType text/css "access plus 7 days"
        ExpiresByType application/javascript "access plus 7 days"
        ExpiresByType application/font-woff2 "access plus 30 days"
    </IfModule>

    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN}_access.log combined
</VirtualHost>
EOF

echo "=== Activation du site et désactivation du défaut ==="
sudo a2ensite ${DOMAIN}.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2

echo "=== Obtention du certificat Let's Encrypt ==="
sudo certbot --apache -d ${DOMAIN} || echo "⚠️ Pense à configurer DynDNS/box et relancer certbot"

echo "=== Script terminé ==="
echo "Ton site est disponible sur : https://${DOMAIN}"

