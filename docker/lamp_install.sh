#!/bin/bash
set -e

# LAMP stack installation script
# This script can be used for manual LAMP installation if needed

echo "Installing LAMP stack..."

apt-get update
apt-get install -y apache2 mysql-client php libapache2-mod-php php-mysql \
    php-curl php-gd php-mbstring php-xml php-xmlrpc php-zip

# Enable Apache modules
a2enmod rewrite

# Configure Apache
echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Start Apache
systemctl start apache2
systemctl enable apache2

echo "LAMP stack installation complete."

