#!/bin/bash
# Author: Vu Duc Nguyen

function echocolor {
    echo "#######################################################################"
    echo "$(tput setaf 3)##### $1 #####$(tput sgr0)"
    echo "#######################################################################"

}

source config.cfg

# Function config hostname
function config_hostname () {
hostnamectl set-hostname $OBJECT1_HOSTNAME
echo -e "127.0.0.1\tlocahost\t`hostname`" > /etc/hosts
echo -e "$CTL_IP\t$CTL_HOSTNAME" >> /etc/hosts
echo -e "$COM_IP\t$COM_HOSTNAME" >> /etc/hosts
echo -e "$BLOCK_IP\t$BLOCK_HOSTNAME" >> /etc/hosts
echo -e "$OBJECT1_IP\t$OBJECT1_HOSTNAME" >> /etc/hosts
echo -e "$OBJECT2_IP\t$OBJECT2_HOSTNAME" >> /etc/hosts
}

# Function IP address
function config_ip () {

cat << EOF > /etc/network/interfaces
# The loopback network interface
auto lo
iface lo inet loopback

# The Object1 Network
auto $OBJECT1_INTERFACE
iface $OBJECT1_INTERFACE inet static
address $OBJECT1_IP
netmask $NETMASK
gateway $GATEWAY
dns-nameservers $DNS
EOF
}

#######################
###Execute functions###
#######################

# Config OBJECT1 node
echocolor "Config OBJECT1 node"
sleep 3

## Config hostname
echocolor "Configurate Hostname"
config_hostname

## IP address
echocolor "Configurate Ip address"
config_ip

## Reboot
echocolor "Reboot $OBJECT1_HOSTNAME node"
init 6
