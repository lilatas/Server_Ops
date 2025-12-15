#!/bin/bash
#: Title        : MySQL installer
#: Date         : 20251215
#: Author       : lilatas
#: Version      : 1.0
#: Description  : Install MySQL for DB at Ubuntu

echo "Start to install MySQL."

sudo apt install -y mysql-server

sudo systemctl start mysql

sudo ufw allow 3306/tcp
if sudo ufw status | grep -q "inactive"; then
    sudo ufw --force enable
fi

if systemctl is-active --quiet mysql; then
    echo "MySQL install Complete!"
else
    echo "fail to install MySQL."
    exit 1
fi