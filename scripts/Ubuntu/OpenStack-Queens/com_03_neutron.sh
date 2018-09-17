#!/bin/bash
#Author Vu Duc Nguyen

source function.sh
source config.cfg

function neutron_install () {
	echocolor "Install the components Neutron"
	sleep 3

	apt install -y neutron-linuxbridge-agent
}


# Function configure the common component
function neutron_config_server_component () {
	echocolor "Configure the common component"
	sleep 3

	neutronfile=/etc/neutron/neutron.conf
	neutronfilebak=/etc/neutron/neutron.conf.bak
	cp $neutronfile $neutronfilebak
	egrep -v "^$|^#" $neutronfilebak > $neutronfile

	ops_del $neutronfile database connection
	ops_add $neutronfile DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL_MANAGE_IP
	ops_add $neutronfile DEFAULT auth_strategy keystone
	#ops_add $neutronfile DEFAULT core_plugin ml2

	ops_add $neutronfile keystone_authtoken auth_uri http://$CTL_MANAGE_IP:5000
	ops_add $neutronfile keystone_authtoken auth_url http://$CTL_MANAGE_IP:5000
	ops_add $neutronfile keystone_authtoken memcached_servers $CTL_MANAGE_IP:11211
	ops_add $neutronfile keystone_authtoken auth_type password
	ops_add $neutronfile keystone_authtoken project_domain_name default
	ops_add $neutronfile keystone_authtoken user_domain_name default
	ops_add $neutronfile keystone_authtoken project_name service
	ops_add $neutronfile keystone_authtoken username neutron
	ops_add $neutronfile keystone_authtoken password $NEUTRON_PASS
}

# Function configure the Linux bridge agent (Self-service networks)
function neutron_config_linuxbridge () {
	echocolor "Configure the Linux bridge agent"
	sleep 3
	linuxbridgefile=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
	linuxbridgefilebak=/etc/neutron/plugins/ml2/linuxbridge_agent.ini.bak
	cp $linuxbridgefile $linuxbridgefilebak
	egrep -v "^$|^#" $linuxbridgefilebak > $linuxbridgefile

	ops_add $linuxbridgefile linux_bridge physical_interface_mappings provider:PROVIDER_INTERFACE_NAME
	ops_add $linuxbridgefile vxlan enable_vxlan true
	ops_add $linuxbridgefile vxlan local_ip $COM_OVERLAY_INTERFACE_IP
	ops_add $linuxbridgefile vxlan l2_population true

  	ops_add $linuxbridgefile securitygroup enable_security_group true
	ops_add $linuxbridgefile securitygroup \
		firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
}


# Function edit /etc/nova/nova.conf file
function nova_config () {
	echocolor "Edit /etc/nova/nova.conf file"
	sleep 3
	novafile=/etc/nova/nova.conf

	ops_add $novafile neutron url http://$CTL_MANAGE_IP:9696
	ops_add $novafile neutron auth_url http://$CTL_MANAGE_IP:5000
	ops_add $novafile neutron auth_type password
	ops_add $novafile neutron project_domain_name default
	ops_add $novafile neutron user_domain_name default
	ops_add $novafile neutron region_name RegionOne
	ops_add $novafile neutron project_name service
	ops_add $novafile neutron username neutron
	ops_add $novafile neutron password $NEUTRON_PASS
}

# Function finalize installation
function neutron_resart () {
	echocolor "Finalize installation"
	sleep 3
	service nova-compute restart
        service neutron-linuxbridge-agent restart
}


#######################
###Execute functions###
#######################

# Install the components Neutron
neutron_install

# Configure the common component
neutron_config_server_component

# Configure the Linux bridge agent
neutron_config_linuxbridge

# Edit /etc/nova/nova.conf file
nova_config

# Restart installation
neutron_restart