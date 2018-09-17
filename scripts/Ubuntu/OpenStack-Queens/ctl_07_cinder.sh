#!/bin/bash
#Author Vu Duc Nguyen

source function.sh
source config.cfg

# Function create database for Cinder
function cinder_create_db () {
	echocolor "Create database for Cinder"
	sleep 3

cat << EOF | mysql -uroot -p$PASS_DATABASE_ROOT
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$CINDER_DBPASS';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$CINDER_DBPASS';
FLUSH PRIVILEGES;
EOF
}

function cinder_user_endpoint() {
	openstack user create  cinder --domain default --password $CINDER_PASS
	openstack role add --project service --user cinder admin

	openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
	openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

	openstack endpoint create --region RegionOne volumev2 public http://$CTL_MANAGE_IP:8776/v2/%\(tenant_id\)s
	openstack endpoint create --region RegionOne volumev2 internal http://$CTL_MANAGE_IP:8776/v2/%\(tenant_id\)s
	openstack endpoint create --region RegionOne volumev2 admin http://$CTL_MANAGE_IP:8776/v2/%\(tenant_id\)s

	openstack endpoint create --region RegionOne volumev3 public http://$CTL_MANAGE_IP:8776/v3/%\(tenant_id\)s
	openstack endpoint create --region RegionOne volumev3 internal http://$CTL_MANAGE_IP:8776/v3/%\(tenant_id\)s
	openstack endpoint create --region RegionOne volumev3 admin http://$CTL_MANAGE_IP:8776/v3/%\(tenant_id\)s


}

function cinder_install_config() {
	echocolor "Cai dat cinder"
	sleep 3
	apt install -y cinder-api cinder-scheduler
	ctl_cinder_conf=/etc/cinder/cinder.conf
	cp $ctl_cinder_conf $ctl_cinder_conf.orig

	ops_add $ctl_cinder_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL_MANAGE_IP
	ops_add $ctl_cinder_conf DEFAULT auth_strategy keystone
	ops_add $ctl_cinder_conf DEFAULT my_ip $CTL_MANAGE_IP

	ops_add $ctl_cinder_conf database connection  mysql+pymysql://cinder:$CINDER_DBPASS@$CTL_MANAGE_IP/cinder

	ops_add $ctl_cinder_conf keystone_authtoken auth_uri http://$CTL_MANAGE_IP:5000
	ops_add $ctl_cinder_conf keystone_authtoken auth_url http://$CTL_MANAGE_IP:5000
	ops_add $ctl_cinder_conf keystone_authtoken memcached_servers $CTL_MANAGE_IP:11211
	ops_add $ctl_cinder_conf keystone_authtoken auth_type password
	ops_add $ctl_cinder_conf keystone_authtoken project_domain_name Default
	ops_add $ctl_cinder_conf keystone_authtoken user_domain_name Default
	ops_add $ctl_cinder_conf keystone_authtoken project_name service
	ops_add $ctl_cinder_conf keystone_authtoken username cinder
	ops_add $ctl_cinder_conf keystone_authtoken password $CINDER_PASS

	ops_add $ctl_cinder_conf oslo_concurrency lock_path /var/lib/cinder/tmp
}

function cinder_syncdb() {
	su -s /bin/sh -c "cinder-manage db sync" cinder

}

function cinder_enable_restart() {
	sleep 3

    service nova-api restart
    service cinder-scheduler restart
    service apache2 restart
}


#######################
###Execute functions###
#######################

echocolor "Tao DB CINDER"
sleep 3
cinder_create_db

echocolor "Tao user va endpoint cho CINDER"
sleep 3
cinder_user_endpoint

echocolor "Cai dat va cau hinh CINDER"
sleep 3
cinder_install_config

echocolor "Dong bo DB cho CINDER"
sleep 3
cinder_syncdb

echocolor "Restart dich vu CINDER"
sleep 3
cinder_enable_restart

echocolor "Da cai dat xong CINDER"
