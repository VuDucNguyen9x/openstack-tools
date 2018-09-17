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
hostnamectl set-hostname $CTL_HOSTNAME
echo -e "127.0.0.1\tlocahost\t`hostname`" > /etc/hosts
echo -e "$CTL_MANAGE_IP\t$CTL_HOSTNAME" >> /etc/hosts
echo -e "$COM_MANAGE_IP\t$COM_HOSTNAME" >> /etc/hosts
echo -e "$BLOCK_MANAGE_IP\t$BLOCK_HOSTNAME" >> /etc/hosts
echo -e "$OBJECT1_MANAGE_IP\t$OBJECT1_HOSTNAME" >> /etc/hosts
echo -e "$OBJECT2_MANAGE_IP\t$OBJECT2_HOSTNAME" >> /etc/hosts
}

# Function IP address
function config_ip () {

cat << EOF > /etc/network/interfaces
# The loopback network interface
auto lo
iface lo inet loopback

# The API + MGNT Network
auto $CTL_MANAGE_INTERFACE
iface $CTL_MANAGE_INTERFACE inet static
address $CTL_MANAGE_IP
netmask $MANAGE_NETMASK

# The Provider Network
auto $CTL_PROVIDER_INTERFACE
iface $CTL_PROVIDER_INTERFACE inet static
address $CTL_IP_PROVIDER
netmask $PROVIDER_NETMASK
gateway $PROVIDER_GATEWAY
dns-nameservers $PROVIDER_DNS

# The tenant interface
auto $CTL_TENANT_INTERFACE
iface $CTL_TENANT_INTERFACE inet static
address $CTL_TENANT_IP
netmask $NET_MASK_TENANT
EOF
}

#######################
###Execute functions###
#######################

# Config CONTROLLER node
echocolor "Config CONTROLLER node"
sleep 3

## Config hostname
echocolor "Configurate Hostname"
config_hostname

## IP address
echocolor "Configurate Ip address"
config_ip

## Reboot
echocolor "Reboot $CTL_HOSTNAME node"
init 6
