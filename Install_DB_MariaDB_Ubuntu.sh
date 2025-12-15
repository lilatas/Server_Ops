#!/bin/bash
#: Title        : MariaDB installer
#: Date         : 20251215
#: Author       : lilatas
#: Version      : 1.0
#: Description  : Install MariaDB for DB at Ubuntu

echo "Start to install MariaDB"

sudo apt update -y
sudo apt install -y mariadb-server

sudo systemctl start mariadb

sudo ufw allow 3306/tcp
if sudo ufw status | grep -q "inactive"; then
    sudo ufw --force enable
fi

if systemctl is-active --quiet mariadb; then
    echo "MariaDB install Complete!"
else
    echo "fail to install MariaDB."
    exit 1
fi