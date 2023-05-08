#!/usr/bin/env bash
STAT=$?

function header(){
    clear
    echo "##################################"
    echo "#     APACHE AUTO SSL SCRIPT     #"
    echo "##################################"
    echo ""
}
function err(){
    echo -e "\e[0;31m$1\e[0m"
}
function success(){
    echo -e "\e[0;32m$1\e[0m"
}
function set_domain(){
    header
    echo "Enter the FQDN of the Domain you want to secure with Lets Encrypt:"
    read FQDN
}

if [[ $EUID -ne 0 ]]; then
    header
    error "Script needs root privileges to function!"
    sleep 3
    exit 1
else
    dpkg -l | grep apache2 &>/dev/null
    if [[ $STAT -ne 0 ]]; then
        header
        error "This script requires the Apache Web Server.."
        sleep 3
        echo "Install Apache and try again."
        sleep 2
        exit 2
    fi
fi

set_domain
host "$FQDN" &>/dev/null
while [[ $STAT -ne 0 ]]; do
    header
    error "The Domain you entered, $FQDN could not be validated."
    sleep 2
    echo "Check the spelling and try again."
    sleep 3
    set_domain
done

header
success "Domain Validated!"
sleep 2
echo "The Apache Auto SSL Install script will now begin. This may take a few minutes depending on the speed of the system.."

a2enmod ssl headers http2

apt install certbot -y

openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

mkdir -p /var/lib/letsencrypt/.well-known
chgrp www-data /var/lib/letsencrypt
chmod g+s /var/lib/letsencrypt

cat > /etc/apache2/conf-available/letsencrypt.conf <<- _EOF_
Alias /.well-known/acme-challenge/ "/var/lib/letsencrypt/.well-known/acme-challenge/"
<Directory "/var/lib/letsencrypt/">
    AllowOverride None
    Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
    Require method GET POST OPTIONS
</Directory>
_EOF_

cat > /etc/apache2/conf-available/ssl-params.conf <<- _EOF_
SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
SSLHonorCipherOrder     off
SSLSessionTickets       off
SSLUseStapling On
SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"
SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem"
Header always set Strict-Transport-Security "max-age=63072000"
_EOF_

a2enconf letsencrypt ssl-params

systemctl reload apache2

certbot certonly --agree-tos --non-interactive --email admin@"$FQDN" --webroot -w /var/lib/letsencrypt/ -d "$FQDN" -d www."$FQDN"

if [[ $STAT -ne 0 ]]; then
    header
    error "The SSL Certificate could not be issued for $FQDN.."
    sleep 3
    echo "Check your DNS Configuration and try again.."
    sleep 3
    exit 3
fi

if [[ -f /etc/letsencrypt/live/$FQDN/fullchain.pem ]] && [[ -f /etc/letsencrypt/live/$FQDN/privkey.pem ]]; then
    success "The SSL Certificate has been successfully installed for $FQDN!"
    sleep 3
    echo "Configuring the new Virtual Host.."
fi

if [[ -f /etc/apache2/sites-available/"$FQDN"]] && [[ -d /var/www/html ]]; then
    cat > /etc/apache2/sites-available/"$FQDN"-ssl.conf <<- _EOF_
<VirtualHost *:443>
    Protocols h2 http/1.1
    ServerName $FQDN
    DocumentRoot /var/www/html
    ErrorLog \${APACHE_LOG_DIR}/$FQDN-error.log
    CustomLog \${APACHE_LOG_DIR}/$FQDN-access.log combined
    SSLEngine On
    SSLCertificateFile /etc/letsencrypt/live/$FQDN/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$FQDN/privkey.pem
</VirtualHost>
_EOF_

a2ensite "$FQDN"-ssl.conf

if [[ $? -eq 0 ]]; then
    success "Script Finished Successfully!"
    systemctl reload apache2
    sleep 2
    exit 0
else
    error "There was a problem configuring the VirtualHost.."
    sleep 3
    exit 4
fi
