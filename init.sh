#! /bin/bash

VERSION=0.2.1

echo "Script to launch DOMA in dockers ! !"
echo "It's necesary run previously jwilder/nginx-proxy and jrcs/letsencrypt-nginx-proxy-companion"


MYSQL_ROOT_PASSWORD="$(date +%s | sha256sum | base64 | head -c 32)"
DOMA_ROOT_PASSWORD="$(date +%s | sha256sum | base64 | head -c 8)"

echo "MYSQL password: '$MYSQL_ROOT_PASSWORD'"
echo "DOMA 'admin' password: '$DOMA_ROOT_PASSWORD'"

echo "MYSQL password: '$MYSQL_ROOT_PASSWORD'" > passwords.txt
echo "DOMA 'admin' password: '$DOMA_ROOT_PASSWORD'" >>  passwords.txt


read -p "Route to store data (Ex: /media/blanco/doma): " store_route
read -p "Domain to deploy (Ex: man.ol.os): " url_route
read -p "Say the smtp server (Ex: smtp.gmail.com:587): " smtp_server
read -p "Say the email (Ex: your.email@your.domain): " smtp_email
read -s -p "Say the password: " smtp_password
echo -e ""

sed -i.bak "s/define('DB_PASSWORD', '.*/define('DB_PASSWORD', '$MYSQL_ROOT_PASSWORD');/g" PHP/config.php
sed -i.bak "s/define('ADMIN_PASSWORD', '.*/define('ADMIN_PASSWORD', '$DOMA_ROOT_PASSWORD');/g" PHP/config.php
sed -i.bak "s/define('ADMIN_EMAIL', '.*/define('ADMIN_EMAIL', '$smtp_email');/g" PHP/config.php

cat PHP/config.php

echo -e "\n Is it correct? If not, please modify it before resume"
echo "(File route: PHP/config.php)"

read -n1 -r -p "Press space to continue..." key


echo "First we build the dockers"
echo "Building php-doma...."

docker build -t doma-php:$VERSION PHP/.


echo "Launching containers..."

mkdir -p $store_route/mysql
mkdir -p $store_route/map_images

docker run --name doma-mysql \
    -v $store_route/mysql:/var/lib/mysql \
    --restart=always \
    -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    -e MYSQL_DATABASE="Doma" \
    -d mysql:5.7 \
    --bind-address=0.0.0.0
    
sleep 30

docker run --name doma-php \
    --link doma-mysql:mysql \
    -v $store_route/map_images:/var/www/html/map_images \
    --restart=always \
    -e VIRTUAL_HOST="$url_route" \
    -e VIRTUAL_PORT=80 \
    -e "LETSENCRYPT_HOST=$url_route" \
    -e "LETSENCRYPT_EMAIL=$smtp_email" \
    -d doma-php:$VERSION
    
sleep 5


echo "Now we are going to configure email"
docker exec -ti doma-php bash -c "
    sed -i.bak \"s/^.*root=.*$/root=doma/g\" /etc/ssmtp/ssmtp.conf
    sed -i.bak \"s/^.*mailhub=.*$/mailhub=$smtp_server/g\" /etc/ssmtp/ssmtp.conf
    sed -i.bak \"s/^.*FromLineOverride=.*$/FromLineOverride=YES/g\" /etc/ssmtp/ssmtp.conf
    sed -i.bak \"s/^.*mailhub=.*$/mailhub=$smtp_server/g\" /etc/ssmtp/ssmtp.conf

    echo -e \"\n\" >> /etc/ssmtp/ssmtp.conf
    echo \"# Use SSL/TLS before starting negotiation\" >> /etc/ssmtp/ssmtp.conf
    echo \"UseTLS=Yes\" >> /etc/ssmtp/ssmtp.conf
    echo \"UseSTARTTLS=Yes\" >> /etc/ssmtp/ssmtp.conf
    echo -e \"\n\" >> /etc/ssmtp/ssmtp.conf
    echo \"AuthUser=$smtp_email\" >> /etc/ssmtp/ssmtp.conf
    echo \"AuthPass=$smtp_password\" >> /etc/ssmtp/ssmtp.conf

    cat /etc/ssmtp/ssmtp.conf
"

echo -e "\n Is it correct? If not, please modify it before resume"
echo "(docker exec -ti doma-php bash -c \"apt-get install -y nano && nano /etc/ssmtp/ssmtp.conf\")"

read -n1 -r -p "Press space to continue..." key


echo "Finish !"
 
