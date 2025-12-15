#!/bin/bash
#: Title        : MySQL installer
#: Date         : 20251215
#: Author       : lilatas
#: Version      : 1.0
#: Description  : Install MySQL for DB at RHEL

echo "Start to install MySQL."

sudo dnf install -y mysql-server

sudo systemctl enable mysqld
sudo systemctl start mysqld

sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload

if systemctl is-active --quiet mysqld; then
    echo "MySQL install Complete!"
else
    echo "fail to install MySQL."
    exit 1
fi