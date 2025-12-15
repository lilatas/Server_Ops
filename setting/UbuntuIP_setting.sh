#!/bin/bash
#: Title        : Ubuntu IP setting
#: Date         : 20251215
#: Author       : lilatas
#: Version      : 1.0
#: Description  : IP Setting for Network at Ubuntu

echo "=================================================="
echo "            Ubuntu Networker setting              "
echo "=================================================="

echo "--------------------------------------------------"
echo "A list of network interfaces detected on the current system"

IFS=$'\n' INTERFACES=($(ip -o link show | awk -F': ' '$2 != "lo" && $2 !~ /docker|br|veth/ {print $2}'))
unset IFS

if [ ${#INTERFACES[@]} -eq 0 ]; then
    echo "We didn't find Network Interface Card. Exit."
    exit 1
fi

for i in "${!INTERFACES[@]}"; do
    echo "  - ${INTERFACES[$i]}"
done

echo "--------------------------------------------------"
read -p "Pls write the name of NIC to be set (ex: ens33, eth0): " INTERFACE_NAME

if [ -z "$INTERFACE_NAME" ]; then
    echo "Pls write accurate Network Interface Card name. Exit."
    exit 1
fi

echo "The Network Interface Card name: $INTERFACE_NAME"
echo "--------------------------------------------------"

echo "Select your network allocation method:"
echo "1) Static IP - manual "
echo "2) DHCP - Auto"
read -p "What you want 1(Static IP) or 2(DHCP)? : " CHOICE

NETPLAN_FILE="/etc/netplan/50-cloud-init.yml" #netplan was 3 type path - /etc/netplan/01-netcfg.yaml, /etc/netplan/00-installer-config.yaml, /etc/netplan/50-cloud-init.yml
NETPLAN_CONTENT=""
APPLY_MESSAGE=""

case "$CHOICE" in
    1)
        # ----------------------------------
        # Static IP setting logic
        # ----------------------------------
        echo "--------------------------------------------------"
        echo "Write your address information to set up a static IP."
        read -p "1. Static IP address (ex: 192.168.1.100): " IP_ADDRESS
        read -p "2. Netmask (CIDR/24 : 24): " NETMASK
        read -p "3. Gateway address (ex: 192.168.1.1): " GATEWAY
        read -p "4. DNS server address (ex: 8.8.8.8,168.126.63.1): " DNS_SERVERS

        if [ -z "$IP_ADDRESS" ] || [ -z "$NETMASK" ] || [ -z "$GATEWAY" ]; then
            echo "Required fields were not entered. Exit."
            exit 1
        fi
        
        NETPLAN_CONTENT=$(cat <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE_NAME:
      dhcp4: no
      addresses:
        - $IP_ADDRESS/$NETMASK
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
          addresses: [$DNS_SERVERS]
EOF
)
        APPLY_MESSAGE="Static IP set."
        ;;

    2)
        # ----------------------------------
        # DHCP setting logic
        # ----------------------------------
        echo "--------------------------------------------------"
        echo "Start DHCP setting."
        
        NETPLAN_CONTENT=$(cat <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE_NAME:
      dhcp4: yes
EOF
)
        APPLY_MESSAGE="DHCP set."
        ;;
        
    *)
        echo "Pls write 1 os 2. Exit."
        exit 1
        ;;
esac

echo "--------------------------------------------------"
echo "      Netplan setting file ($NETPLAN_FILE)        "

sudo bash -c "echo '$NETPLAN_CONTENT' > $NETPLAN_FILE"

echo "Netplan setting. Network may be temporarily down."

sudo netplan try
if [ $? -ne 0 ]; then
    echo "Fail to Netplan setting. Rolling back to previous settings."
    echo "Netplan try have a problem. Check the file manually: $NETPLAN_FILE"
    exit 1
fi

sudo netplan apply

echo "===================================+==============="
echo "$APPLY_MESSAGE"
echo "Setting Network Interface Card name: $INTERFACE_NAME"
echo "====================================+=============="
echo "Pls check yout IP: ip a show $INTERFACE_NAME"



