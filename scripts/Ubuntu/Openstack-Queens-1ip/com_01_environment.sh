#!/bin/bash
#Author Vu Duc Nguyen

source function.sh
source config.cfg

# Function update and upgrade for COMPUTE
function update_upgrade () {
	echocolor "Update and Update COMPUTE"
	sleep 3
	apt update -y && apt dist-upgrade -y
}

# Function install crudini
function install_crudini () {
	echocolor "Install crudini"
	sleep 3
	apt install -y crudini
}

# Function install and config NTP
function install_ntp () {
	echocolor "Install NTP"
	sleep 3

	apt install chrony -y
	ntpfile=/etc/chrony/chrony.conf

	sed -i 's|'"pool 2.debian.pool.ntp.org offline iburst"'| \
        '"server $CTL_IP iburst"'|g' $ntpfile

	service chrony restart
}

# Function install OpenStack packages (python-openstackclient)
function install_ops_packages () {
	echocolor "Install OpenStack client"
	sleep 3
	apt install software-properties-common -y
	add-apt-repository cloud-archive:queens -y
	apt update -y && apt dist-upgrade -y
	apt install python-openstackclient -y
}


#######################
###Execute functions###
#######################

# Update and upgrade for controller
update_upgrade

# Install crudini
install_crudini

# Install and config NTP
install_ntp

# OpenStack packages (python-openstackclient)
install_ops_packages