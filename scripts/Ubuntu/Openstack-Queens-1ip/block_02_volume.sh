#!/bin/bash
#Author Vu Duc Nguyen

source function.sh
source config.cfg


function cinder_utility() {
	echocolor "Install the supporting utility packages"
	sleep 3
	apt install -y lvm2 thin-provisioning-tools
	pvcreate $VOLUME1
	pvcreate $VOLUME2
	vgcreate cinder-volumes $VOLUME1
	vgcreate cinder-volumes $VOLUME1

	sed -i '130i\	filter = ["a/xvda/","a/xvdb/","a/xvdc/", "r/.*/"]' /etc/lvm/lvm.conf
}

function cinder_install_config() {
	echocolor "Cai dat Cinder..."
	sleep 3
	apt install cinder-volume -y

	block_cinder_conf=/etc/cinder/cinder.conf
	cp $block_cinder_conf $block_cinder_conf.orig

	ops_conf_add $block_cinder_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL_IP
	ops_conf_add $block_cinder_conf DEFAULT auth_strategy keystone
	ops_conf_add $block_cinder_conf DEFAULT my_ip $CINDER_IP
	ops_conf_add $block_cinder_conf DEFAULT enabled_backends lvm
	ops_conf_add $block_cinder_conf DEFAULT glance_api_servers http://$CTL_IP:9292

        ops_conf_add $block_cinder_conf database connection mysql+pymysql://cinder:$CINDER_DBPASS@$CTL_IP/cinder

	ops_conf_add $block_cinder_conf keystone_authtoken auth_uri http://$CTL_IP:5000
	ops_conf_add $block_cinder_conf keystone_authtoken auth_url http://$CTL_IP:5000
        ops_conf_add $block_cinder_conf keystone_authtoken memcached_servers $CTL_IP:11211
        ops_conf_add $block_cinder_conf keystone_authtoken auth_type password
        ops_conf_add $block_cinder_conf keystone_authtoken project_domain_id default
        ops_conf_add $block_cinder_conf keystone_authtoken user_domain_id default
        ops_conf_add $block_cinder_conf keystone_authtoken project_name service
        ops_conf_add $block_cinder_conf keystone_authtoken username cinder
        ops_conf_add $block_cinder_conf keystone_authtoken password $CINDER_PASS

	ops_conf_add $block_cinder_conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
	#ops_conf_add $block_cinder_conf lvm volume_backend_name LVM
	ops_conf_add $block_cinder_conf lvm volume_group cinder-volumes
	ops_conf_add $block_cinder_conf lvm iscsi_protocol iscsi
	ops_conf_add $block_cinder_conf lvm iscsi_helper tgtadm

	ops_conf_add $block_cinder_conf oslo_concurrency lock_path /var/lib/cinder/tmp
}

function cinder_restart() {
	echocolor "Restart the Block Storage volume service including its dependencies"
	sleep 3
	service tgt restart
	service cinder-volume restart
}


#######################
###Execute functions###
#######################

echocolor "Cai dat va tao LVM"
sleep 3
cinder_utility

echocolor "Cai dat va cau hinh cinder"
sleep 3
cinder_install_config

echocolor "Restart dich vu CINDER"
sleep 3
cinder_restart

echocolor "Da cai dat xong CINDER"