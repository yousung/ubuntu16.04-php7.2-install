#!/usr/bin/env bash

#--------------------------------------------------------------------------
# Before run this script...
#--------------------------------------------------------------------------
#
# Get sudo permission
#   user@server:~$ sudo -s
#
# TROUBLESHOOTING.
#
#   If you encounter error message like "sudo: no tty present
#   and no askpass program specified ...", you can work around this error
#   by adding the following line on your production server's /etc/sudoers.
#
#   user@server:~# visudo
#
#   deployer ALL=(ALL:ALL) NOPASSWD: ALL
#   %www-data ALL=(ALL:ALL) NOPASSWD:/usr/sbin/service php7.0-fpm restart,/usr/sbin/service nginx restart
#
#--------------------------------------------------------------------------
# How to run
#--------------------------------------------------------------------------
#
#   user@server:~# bash serve.sh example.com /path/to/document-root
#

## Module Install
## php-local
block="location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
}

location ~ /\.ht {
        deny all;
    }


server_tokens off;
fastcgi_hide_header X-Powered-By;

index index.html index.htm index.php;
charset utf-8;

sendfile off;
client_max_body_size 100m;

location = /favicon.ico { access_log off; log_not_found off; }
location = /robots.txt  { access_log off; log_not_found off; }
"

echo "$block" > "/etc/nginx/module/php-local.conf"

## rewrite
block="location / {
    try_files \$uri \$uri/ /index.php?\$query_string;
}
"

echo "$block" > "/etc/nginx/module/rewrite.conf"

## expires
block="location ~* \.(?:css|js)$ {
    expires 1y;
    access_log off;
    add_header Cache-Control "public";
}
"
echo "$block" > "/etc/nginx/module/expires.conf"

## SSL
block="ssl on;
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;

    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;

    ### Dropping SSLv3, ref: POODLE
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';

    ### HSTS(HTTP Strict Transport Security)
    add_header Strict-Transport-Security \"max-age=86400; includeSubdomains; preload\";
"
echo "$block" > "/etc/nginx/module/ssl.conf"

## server
block="
#server {
#   listen 80;
#   server_name $1;
#
#   return 301 https://$host$request_uri;
#}

server {
    listen 80;
#    listen 443 ssl;
    server_name $1;
    root \"$2\";

#    include /etc/nginx/module/ssl.conf;
    include /etc/nginx/module/php-local.conf;
    include /etc/nginx/module/rewrite.conf;
    include /etc/nginx/module/expires.conf;

    access_log /var/log/nginx/$1.com-access.log;
    error_log  /var/log/nginx/$1-error.log error;

}
"
echo "$block" > "/etc/nginx/sites-available/$1"
service nginx stop && service php7.2-fpm stop
service nginx start && service php7.2-fpm start