#!/bin/bash
#: Title        : Nginx installer
#: Date         : 20251215
#: Author       : 1.0
#: Description  : Install Nginx for WEB at RHEL

echo "Start to install Nginx"

sudo dnf install -y nginx

sudo systemctl enable nginx
sudo systemctl start nginx

sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

if systemctl is-active --quiet nginx; then
    echo "Nginx Complete!"
else
    echo "fail to install Nginx."
    exit 1
fi

echo "The basic directory for Nginx: /usr/share/nginx/html/index.html"
