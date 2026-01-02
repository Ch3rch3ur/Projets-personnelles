# 🐛 Troubleshooting - Projet Serveur Web Apache

Ce document détaille le problème technique principal rencontré lors du déploiement du serveur web Apache sécurisé, ainsi que la méthodologie de diagnostic et la solution appliquée.

---

## 📋 Vue d'ensemble

Le projet serveur web Apache repose sur :
1. **Apache HTTP Server** comme serveur web
2. **Let's Encrypt** pour les certificats SSL/TLS
3. **No-IP** pour la gestion du DNS dynamique
4. **En-têtes de sécurité HTTP** pour le durcissement (HSTS, CSP, X-Frame-Options)

**Problème principal** : Politique CSP (Content Security Policy) trop restrictive bloquant le chargement de ressources essentielles au site.

---

## 1. 🚫 Content Security Policy bloquant les ressources du site

### Symptôme

Après avoir activé les en-têtes de sécurité HTTP, notamment la **Content Security Policy (CSP)**, le site ne s'affichait plus correctement :

* Tailwind CSS ne se chargeait pas → Site sans style
* Scripts JavaScript bloqués → Fonctionnalités interactives cassées
* Certaines images ne s'affichaient pas

**Observation visuelle** : Page blanche ou site complètement désorganisé (texte brut sans mise en forme).

### Diagnostic

#### Étape 1 : Ouvrir la console du navigateur

**Chrome/Firefox** : F12 → Console

**Erreurs affichées** :
```
Refused to load the stylesheet 'https://cdn.tailwindcss.com/...' 
because it violates the following Content Security Policy directive: 
"style-src 'self'". Note that 'style-src-elem' was not explicitly set...

Refused to execute inline script because it violates the following 
Content Security Policy directive: "script-src 'self'". 
Either the 'unsafe-inline' keyword...
```

**Identification du problème** : La CSP bloque les ressources externes (CDN Tailwind) et les styles/scripts inline.

---

#### Étape 2 : Consulter les logs Apache

```bash
sudo tail -f /var/log/apache2/error.log
```

**Logs observés** :
```
[Tue Jan 02 14:23:45.123456 2026] [csp:warn] [pid 12345] 
Content-Security-Policy violation: 
Blocked loading resource from 'https://cdn.tailwindcss.com'
```

✅ **Confirmation que la CSP bloque les ressources.**

---

#### Étape 3 : Vérifier la configuration Apache

```bash
sudo nano /etc/apache2/sites-available/portfolio-ssl.conf
```

**Configuration CSP trouvée** :
```apache
Header set Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; font-src 'self';"
```

**Analyse** :
* `default-src 'self'` : Autorise uniquement les ressources provenant du même domaine
* `script-src 'self'` : Bloque tous les scripts externes et inline
* `style-src 'self'` : Bloque tous les CSS externes (CDN Tailwind) et inline

**Problème identifié** : La politique est **trop restrictive** pour un site utilisant des CDN externes.

---

### Analyse du problème

**Causes identifiées** :

1. **Utilisation de CDN externes** : Tailwind CSS hébergé sur `cdn.tailwindcss.com` est bloqué par `style-src 'self'`
2. **Styles inline dans le HTML** : Attributs `style=""` bloqués sans `'unsafe-inline'`
3. **Scripts inline** : Balises `<script>` dans le HTML bloquées
4. **Compromis nécessaire** : Une CSP trop stricte casse la fonctionnalité, une CSP trop laxiste réduit la sécurité

---

### Solution

#### Approche 1 : CSP en mode Report-Only (diagnostic)

**Objectif** : Identifier toutes les ressources bloquées sans casser le site.

```apache
Header set Content-Security-Policy-Report-Only "default-src 'self'; script-src 'self'; style-src 'self';"
```

**Redémarrer Apache** :
```bash
sudo systemctl restart apache2
```

**Résultat** : Le site fonctionne normalement, mais les violations CSP sont logguées dans la console du navigateur.

**Analyser les violations** : F12 → Console → Noter toutes les ressources bloquées.

---

#### Approche 2 : Adapter progressivement la CSP

##### Étape 1 : Autoriser les CDN externes spécifiques

```apache
Header set Content-Security-Policy "default-src 'self'; \
  script-src 'self' https://cdn.tailwindcss.com; \
  style-src 'self' https://cdn.tailwindcss.com; \
  img-src 'self' data:; \
  font-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com;"
```

**Explication** :
* `script-src 'self' https://cdn.tailwindcss.com` : Autorise Tailwind JS
* `style-src 'self' https://cdn.tailwindcss.com` : Autorise Tailwind CSS
* `img-src 'self' data:` : Autorise les images locales et data-URI (base64)
* `font-src` : Autorise Google Fonts si utilisé

**Redémarrer Apache** :
```bash
sudo systemctl restart apache2
```

**Tester le site** : Vérifier que Tailwind CSS se charge correctement.

---

##### Étape 2 : Gérer les styles et scripts inline (si nécessaire)

**Problème** : Si le site utilise des `<style>` ou `<script>` inline, ils seront toujours bloqués.

**Option A : Externaliser les styles/scripts (recommandé)**

Déplacer tous les styles inline vers un fichier CSS externe :
```html
<!-- Avant -->
<div style="color: red;">Texte</div>

<!-- Après -->
<div class="text-red">Texte</div>
```

Et créer `styles.css` :
```css
.text-red { color: red; }
```

**Option B : Autoriser unsafe-inline (moins sécurisé)**

```apache
Header set Content-Security-Policy "default-src 'self'; \
  script-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com; \
  style-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com;"
```

⚠️ **Note** : `'unsafe-inline'` réduit la protection contre les attaques XSS. À utiliser en dernier recours.

---

##### Étape 3 : Configuration finale appliquée

**Fichier** : `/etc/apache2/sites-available/portfolio-ssl.conf`

```apache
<VirtualHost *:443>
    ServerName monportfolio.ddns.net
    DocumentRoot /var/www/html/portfolio

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/monportfolio.ddns.net/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/monportfolio.ddns.net/privkey.pem

    # En-têtes de sécurité
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    
    # Content Security Policy adaptée
    Header always set Content-Security-Policy "default-src 'self'; \
      script-src 'self' https://cdn.tailwindcss.com; \
      style-src 'self' https://cdn.tailwindcss.com 'unsafe-inline'; \
      img-src 'self' data: https:; \
      font-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com; \
      connect-src 'self'; \
      frame-ancestors 'self';"

    ErrorLog ${APACHE_LOG_DIR}/portfolio-error.log
    CustomLog ${APACHE_LOG_DIR}/portfolio-access.log combined
</VirtualHost>
```

**Redémarrer Apache** :
```bash
sudo systemctl restart apache2
```

---

### Vérification finale

#### Test 1 : Vérifier le chargement du site

Accéder au site : `https://monportfolio.ddns.net`

**Résultat attendu** :
* ✅ Site s'affiche correctement avec styles Tailwind
* ✅ Aucune erreur dans la console navigateur (F12)

---

#### Test 2 : Vérifier les en-têtes HTTP

```bash
curl -I https://monportfolio.ddns.net
```

**Résultat attendu** :
```
HTTP/1.1 200 OK
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
Content-Security-Policy: default-src 'self'; script-src 'self' https://cdn.tailwindcss.com; ...
```

✅ **Tous les en-têtes de sécurité sont présents**

---

#### Test 3 : Analyser la sécurité avec Security Headers

**Site** : https://securityheaders.com

Entrer l'URL du site et analyser.

**Score attendu** : A ou A+ (selon la configuration CSP)

---

#### Test 4 : Tester le certificat SSL

**Site** : https://www.ssllabs.com/ssltest/

Entrer l'URL du site et analyser.

**Score attendu** : A ou A+

---

## 📊 Synthèse : Checklist de vérification

### Configuration Apache
- [ ] HTTPS activé avec certificat Let's Encrypt
- [ ] Renouvellement automatique configuré (Certbot cron)
- [ ] En-têtes de sécurité configurés (HSTS, X-Frame-Options, CSP)
- [ ] CSP adaptée aux ressources du site (pas trop restrictive)

### Certificat SSL/TLS
- [ ] Certificat valide : `openssl s_client -connect monportfolio.ddns.net:443`
- [ ] Renouvellement automatique : `sudo certbot renew --dry-run`

### DNS Dynamique
- [ ] No-IP configuré et à jour
- [ ] Résolution DNS fonctionne : `nslookup monportfolio.ddns.net`

### Tests de sécurité
- [ ] Score Security Headers : A ou A+
- [ ] Score SSL Labs : A ou A+
- [ ] Site accessible en HTTPS sans erreur
- [ ] Aucune ressource bloquée par CSP

---

## 🔧 Commandes utiles de diagnostic

### Apache

```bash
# Vérifier la syntaxe de la configuration
sudo apache2ctl configtest

# Redémarrer Apache
sudo systemctl restart apache2

# Voir les logs en temps réel
sudo tail -f /var/log/apache2/error.log
sudo tail -f /var/log/apache2/access.log

# Lister les modules actifs
apache2ctl -M

# Activer un module
sudo a2enmod ssl
sudo a2enmod headers
```

### Certificats SSL/TLS

```bash
# Tester le renouvellement Certbot
sudo certbot renew --dry-run

# Lister les certificats
sudo certbot certificates

# Renouveler manuellement
sudo certbot renew

# Vérifier un certificat
openssl s_client -connect monportfolio.ddns.net:443 -showcerts
```

### DNS

```bash
# Résolution DNS
nslookup monportfolio.ddns.net

# Vérifier l'IP publique actuelle
curl ifconfig.me

# Tester la résolution depuis différents DNS
dig @8.8.8.8 monportfolio.ddns.net
```

### Tests de sécurité en ligne de commande

```bash
# Tester les en-têtes HTTP
curl -I https://monportfolio.ddns.net

# Vérifier la configuration SSL
openssl s_client -connect monportfolio.ddns.net:443 -tls1_2

# Scanner les ports ouverts (depuis une autre machine)
nmap -p 80,443 monportfolio.ddns.net
```

---

## 💡 Leçons apprises

### 1. La CSP doit être adaptée au site
Une CSP copiée d'un tutoriel ne fonctionnera pas forcément. Il faut l'adapter aux ressources réellement utilisées (CDN, fonts, scripts).

### 2. Mode Report-Only est essentiel pour le diagnostic
Utiliser `Content-Security-Policy-Report-Only` permet de tester la CSP sans casser le site en production.

### 3. Compromis sécurité vs fonctionnalité
Une sécurité maximale avec `'self'` uniquement n'est pas toujours réaliste. Autoriser des CDN spécifiques de confiance (Tailwind, Google Fonts) est un compromis acceptable.

### 4. Les logs sont indispensables
Les logs Apache (`error.log`) et la console navigateur (F12) sont les deux sources principales pour diagnostiquer les problèmes CSP.

### 5. Tester après chaque modification
Redémarrer Apache et tester le site après chaque changement de configuration évite de perdre du temps sur des erreurs de syntaxe ou des conflits.

---

## 🔐 Bonnes pratiques de sécurité web

### Configuration CSP progressive

**Étape 1** : CSP en mode Report-Only
```apache
Header set Content-Security-Policy-Report-Only "default-src 'self';"
```

**Étape 2** : Analyser les violations et adapter

**Étape 3** : Activer la CSP en mode enforce
```apache
Header set Content-Security-Policy "default-src 'self'; script-src 'self' https://trusted-cdn.com;"
```

---

### En-têtes de sécurité recommandés

```apache
# HSTS : Force HTTPS
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"

# X-Frame-Options : Protection contre clickjacking
Header always set X-Frame-Options "DENY"

# X-Content-Type-Options : Évite le MIME sniffing
Header always set X-Content-Type-Options "nosniff"

# Referrer-Policy : Contrôle les informations de référence
Header always set Referrer-Policy "strict-origin-when-cross-origin"

# Permissions-Policy : Contrôle les fonctionnalités du navigateur
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
```

---

### Surveillance et maintenance

```bash
# Vérifier les logs Apache quotidiennement
sudo tail -100 /var/log/apache2/error.log

# Vérifier l'expiration du certificat SSL
sudo certbot certificates

# Tester le renouvellement automatique (tous les mois)
sudo certbot renew --dry-run

# Mettre à jour le système régulièrement
sudo apt update && sudo apt upgrade
```

---

## 📚 Ressources complémentaires

* [MDN - Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)
* [OWASP - Secure Headers Project](https://owasp.org/www-project-secure-headers/)
* [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
* [Apache Security Tips](https://httpd.apache.org/docs/2.4/misc/security_tips.html)
* [Security Headers Checker](https://securityheaders.com/)
* [SSL Labs Test](https://www.ssllabs.com/ssltest/)

---

**Note finale** : Le problème de CSP trop restrictive est **très fréquent** lors du durcissement d'un serveur web. La solution documentée ici (mode Report-Only → adaptation progressive) est la méthodologie recommandée par l'OWASP.