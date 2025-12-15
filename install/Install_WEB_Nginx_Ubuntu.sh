#!/bin/bash
#: Title        : Nginx installer
#: Date         : 20251215
#: Author       : 1.0
#: Description  : Install Nginx for WEB at Ubuntu

echo "Start to install Nginx"

sudo apt install -y nginx

sudo systemctl start nginx

sudo ufw allow 'Nginx Full'
sudo ufw --force enable

if systemctl is-active --quiet nginx; then
    echo "Nginx install Complete!"
else
    echo "fail to install Nginx."
    exit 1
fi

echo "The basic directory for Nginx: /var/www/html/index.nginx-debian.html"