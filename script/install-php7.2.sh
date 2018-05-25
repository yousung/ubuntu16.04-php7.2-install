#!/usr/bin/env bash

# adduser user-id
# usermod -G www-data user-id
# id user-id
# // uid=xxx(user-id) gid=xxx(user-id) groups=xxx(user-id),xx(www-data)
# sudo -s
# bash install-php7.2.sh user-id

export DEBIAN_FRONTEND=noninteractive
USERID=$1

# 패지키 업데이트
apt-get update

# 시스템 패키지 업데이트
apt-get -y upgrade

# 강제 지역설정
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8

# 기본적인 ETC 설치 및 ppa 추가
apt-get install -y software-properties-common curl
apt-add-repository ppa:nginx/stable -y
#apt-add-repository ppa:rwky/redis -y
apt-add-repository ppa:ondrej/php -y


# 패지키 리스트 업데이트
apt-get update

# 기본 패지키 설치
apt-get install -y --force-yes \
    build-essential \
    dos2unix \
    gcc \
    git \
    libmcrypt4 \
    libpcre3-dev \
    make \
    python2.7-dev \
    python-pip \
    re2c \
    supervisor \
    unattended-upgrades \
    whois \
    libnotify-bin;

# 시간설정
# ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# PHP 및 관련 모듈 설치
apt-get install -y --force-yes \
    php7.2-cli \
    php7.2-dev \
    php-gd \
    php-apcu \
    php-curl \
    php-mysql \
    php-memcached \
    php7.2-readline \
    php-mbstring \
    php-xml \
    php7.2-zip \
    php7.2-intl \
    php-pecl \
    libmcrypt-dev \
    libreadline-dev \
    php7.2-bcmath;

# 7.2 모듈을 아직 못찾은 것들..
#    php7.2-mcrypt \
#    php-sqlite3 \
#    php-pgsql \
#    php-imap \
#    php-xdebug \

# composer 설치
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# PHP CLI 설정
sed -i "s/expose_php = .*/expose_php = Off/" /etc/php/7.2/cli/php.ini
#sed -i "s/error_reporting = .*/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/" /etc/php/7.2/cli/php.ini
sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/7.2/cli/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.2/cli/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.2/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.2/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/cli/php.ini

# NGINX 및 PHP-FPM 설치
apt-get install -y --force-yes nginx php7.2-fpm

rm /etc/nginx/sites-enabled/default
rm  -rvf /etc/nginx/sites-available
ln -nfs /etc/nginx/sites-enabled /etc/nginx/sites-available
mkdir -p /etc/nginx/module/
service nginx restart

# PHP-FPM 옵션
sed -i "s/expose_php = .*/expose_php = Off/" /etc/php/7.2/fpm/php.ini
#sed -i "s/error_reporting = .*/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/" /etc/php/7.2/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/7.2/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.2/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.2/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.2/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.2/fpm/php.ini

cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param   QUERY_STRING        \$query_string;
fastcgi_param   REQUEST_METHOD      \$request_method;
fastcgi_param   CONTENT_TYPE        \$content_type;
fastcgi_param   CONTENT_LENGTH      \$content_length;
fastcgi_param   SCRIPT_FILENAME     \$request_filename;
fastcgi_param   SCRIPT_NAME         \$fastcgi_script_name;
fastcgi_param   REQUEST_URI         \$request_uri;
fastcgi_param   DOCUMENT_URI        \$document_uri;
fastcgi_param   DOCUMENT_ROOT       \$document_root;
fastcgi_param   SERVER_PROTOCOL     \$server_protocol;
fastcgi_param   GATEWAY_INTERFACE   CGI/1.1;
fastcgi_param   SERVER_SOFTWARE     nginx/\$nginx_version;
fastcgi_param   REMOTE_ADDR         \$remote_addr;
fastcgi_param   REMOTE_PORT         \$remote_port;
fastcgi_param   SERVER_ADDR         \$server_addr;
fastcgi_param   SERVER_PORT         \$server_port;
fastcgi_param   SERVER_NAME         \$server_name;
fastcgi_param   HTTPS               \$https if_not_empty;
fastcgi_param   REDIRECT_STATUS     200;
EOF

# Set The Nginx & PHP-FPM User
sed -i "s/user www-data;/user ${USERID};/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

sed -i "s/user = www-data/user = ${USERID}/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = ${USERID}/" /etc/php/7.2/fpm/pool.d/www.conf

sed -i "s/listen\.owner.*/listen.owner = ${USERID}/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/listen\.group.*/listen.group = ${USERID}/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.2/fpm/pool.d/www.conf

service nginx restart
service php7.2-fpm restart

pecl install mcrypt-snapshot

apt-get install -y --force-yes memcached #beanstalkd redis-server

# 메모리 스왑
/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
/sbin/mkswap /var/swap.1
/sbin/swapon /var/swap.1