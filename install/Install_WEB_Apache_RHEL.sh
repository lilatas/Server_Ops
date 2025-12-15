#!/bin/bash
#: Title        : Apache installer
#: Date         : 20251215
#: Author       : lilatas
#: Version      : 1.0
#: Description  : Install Apache for WEB at RHEL

echo "Start to install Apache HTTP"

sudo dnf install -y httpd

sudo systemctl enable httpd
sudo systemctl start httpd

sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

if systemctl is-active --quiet httpd; then
    echo "Apache HTTP Complete!"
else
    echo "fail to install Apache HTTP"
    exit 1
fi

echo "The basic directory for Apache: /var/www/html/index.html"