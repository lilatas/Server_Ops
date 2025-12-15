#!/bin/bash
#: Title        : MariaDB installer
#: Date         : 20251215
#: Author       : lilatas
#: Version      : 1.0
#: Description  : Install MariaDB for DB at RHEL

echo "Start to install MariaDB"

sudo dnf install -y mariadb-server

sudo systemctl enable mariadb
sudo systemctl start mariadb

sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload

if systemctl is-active --quiet mariadb; then
    echo "MariaDB install Complete!"
else
    echo "fail to install MariaDB."
    exit 1
fi