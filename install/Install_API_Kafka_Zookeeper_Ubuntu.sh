#!/bin/bash
#: Title        : Kafka/Zookeeper installer
#: Date         : 20251215
#: Author       : lilatas
#: Version      : 1.0
#: Description  : Install Kafka and Zookeeper for API at Ubuntu

KAFKA_VERSION="3.6.1"              # Pls check the version Kafka
SCALA_VERSION="2.13"               # Pls check the Kafka Scala
KAFKA_ARCHIVE="kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
KAFKA_DOWNLOAD_URL="https://downloads.apache.org/kafka/${KAFKA_VERSION}/${KAFKA_ARCHIVE}"
INSTALL_DIR="/opt/kafka"

echo "=================================================="
echo "   Start to install Apache Kafka and ZooKeeper    "
echo "=================================================="

echo "Start to install JDK 17"

sudo apt install -y openjdk-17-jdk wget

echo "➡️ Kafka $KAFKA_VERSION 다운로드 및 설치 중..."
cd /tmp
wget -q "$KAFKA_DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "Fail to download Kafka. Pls check URL or version."
    exit 1
fi

sudo mkdir -p $INSTALL_DIR
sudo tar -xzf $KAFKA_ARCHIVE -C $INSTALL_DIR --strip-components 1

echo "Setting Kafka useradd privilege "
sudo useradd -r -m -s /bin/false kafka
sudo chown -R kafka:kafka $INSTALL_DIR

ZOOKEEPER_CONF="$INSTALL_DIR/config/zookeeper.properties"
KAFKA_CONF="$INSTALL_DIR/config/server.properties"

echo "making service file ZooKeeper Systemd"
sudo bash -c "cat > /etc/systemd/system/zookeeper.service <<EOF
[Unit]
Description=Apache ZooKeeper
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
User=kafka
Group=kafka
# Basic setting ZooKeeper
ExecStart=$INSTALL_DIR/bin/zookeeper-server-start.sh $ZOOKEEPER_CONF
ExecStop=$INSTALL_DIR/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF"

echo "making service file Kafka Systemd"

sudo bash -c "cat > /etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Apache Kafka Server
Requires=zookeeper.service
After=zookeeper.service

[Service]
Type=simple
User=kafka
Group=kafka
# Basic setting Kafka
ExecStart=$INSTALL_DIR/bin/kafka-server-start.sh $KAFKA_CONF
ExecStop=$INSTALL_DIR/bin/kafka-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF"

echo "enable ZooKeeper and Kafka service"
sudo systemctl daemon-reload
sudo systemctl enable zookeeper.service
sudo systemctl start zookeeper.service

sleep 7

sudo systemctl enable kafka.service
sudo systemctl start kafka.service

echo "Firewall setting Zookeeper(2181), Kafka(9092)"
sudo ufw allow 2181/tcp
sudo ufw allow 9092/tcp
if sudo ufw status | grep -q "inactive"; then
    sudo ufw --force enable
fi

if systemctl is-active --quiet zookeeper && systemctl is-active --quiet kafka; then
    echo "=================================================="
    echo "Kafka and ZooKeeper install complete"
    echo "Kafka broker: 9092 port"
    echo "ZooKeeper: 2181 port"
    echo "=================================================="
else
    echo "Fail to Install Kafka or ZooKeeper. Pls check your log."
    exit 1
fi


