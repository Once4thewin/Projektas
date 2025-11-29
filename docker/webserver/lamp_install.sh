#!/bin/bash
set -e

# LAMP stack installation script (from UNIX course)
# This script installs Apache, MySQL client, PHP and required extensions

echo "Installing LAMP stack..."

apt-get update
apt-get install -y \
    apache2 \
    mysql-client \
    php \
    libapache2-mod-php \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-xmlrpc \
    php-zip

# Enable Apache modules
a2enmod rewrite
a2enmod php8.3

# Configure Apache
echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Start Apache
service apache2 start

echo "LAMP stack installation complete."

