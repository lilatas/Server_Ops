#!/bin/bash
#: Title        : Apache installer
#: Date         : 20251215
#: Author       : lilatas
#: Version      : 1.0
#: Description  : Install Apache for WEB at Ubuntu

echo "Start to install Apache HTTP"

sudo apt install -y apache2

sudo systemctl start apache2

sudo ufw allow 'Apache Full'

if sudo ufw status | grep -q "inactive"; then
    sudo ufw --force enable
fi

if systemctl is-active --quiet apache2; then
    echo "Apache HTTP Complete!"
else
    echo "fail to install Apache HTTP"
    exit 1
fi

echo "The basic directory for Apache: /var/www/html/index.html"