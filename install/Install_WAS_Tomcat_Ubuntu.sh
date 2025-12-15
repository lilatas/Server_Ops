#!/bin/bash
#: Title        : Tomcat installer
#: Date         : 20251215
#: Author       : lilatas
#: Version      : 1.0
#: Description  : Install Tomcat for WAS at Ubuntu

echo "=================================================="
echo "   Start to install Apache HTTP Server and WAS    "
echo "=================================================="

echo "Start to install Apache2"
sudo apt install -y apache2

echo "Start to install penJDK JRE 17"
sudo apt install -y openjdk-17-jre

echo "Start to add environment variable JAVA_HOME"
JAVA_HOME_PATH=$(update-alternatives --query java | grep Value: | awk '{print $2}' | sed 's/\/bin\/java//')
if [ -n "$JAVA_HOME_PATH" ]; then
    echo "export JAVA_HOME=$JAVA_HOME_PATH" | sudo tee /etc/profile.d/java_home.sh
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" | sudo tee -a /etc/profile.d/java_home.sh
    source ~/.bashrc                                #Environment Variable Check
    source /etc/profile.d/java_home.sh              #Environment Variable Check
    echo "JAVA_HOME=$JAVA_HOME_PATH Environment Variable Complete!"
    echo $PATH
else
    echo "Don't find JAVA path. Failure Environment Variable Check"
fi

#Tomcat Version Must be check!

TOMCAT_VERSION="9"

echo "Start to install Tomcat $TOMCAT_VERSION"
sudo apt install -y tomcat${TOMCAT_VERSION} tomcat${TOMCAT_VERSION}-admin

echo "Connecting to Apache - Tomcat (Proxy Pass)"

sudo a2enmod proxy proxy_http

APACHE_CONF="/etc/apache2/sites-available/000-default.conf"

sudo sed -i '/<VirtualHost \*:80>/a\    ProxyRequests Off\n    ProxyPreserveHost On\n    ProxyPass /app/ http://localhost:8080/ \n    ProxyPassReverse /app/ http://localhost:8080/ ' $APACHE_CONF

#ProxyRequests Off                              : foward-proxy (Clients->Apache) off, only reverse-proxy (Apache -> others)
#ProxyPreserveHost On                           : Host header info -> Tomcat
#ProxyPass /app/ http://localhost:8080/         : Client Quary(/app/) -Apache-> Tomcat(default address)
#ProxyPassReverse /app/ http://localhost:8080/  : Client <- Tomcat (inner info hiding - IP, dir, ...)

echo "Starting service Tomcat"
sudo systemctl enable apache2 tomcat${TOMCAT_VERSION}
sudo systemctl start apache2 tomcat${TOMCAT_VERSION}

sudo ufw allow 'Apache Full'

if sudo ufw status | grep -q "inactive"; then
    sudo ufw --force enable
fi

if systemctl is-active --quiet apache2 && systemctl is-active --quiet tomcat${TOMCAT_VERSION}; then
    echo "Apache (80), Tomcat (8080) install Complete!"
    echo "The Client for Tomcat WAS: http://[APACHE_IP]/app/ "
    echo ""
    echo "--------------------------------------------------"
    echo "WAS Distribution dir info"
    echo "Copy the compiled WAR file to the following directory:"
    echo "--> /var/lib/tomcat${TOMCAT_VERSION}/webapps/"
    echo "--------------------------------------------------"

else
    echo "fail to install or excution for the Service"
    exit 1
fi
