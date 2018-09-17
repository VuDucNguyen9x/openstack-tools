#!/bin/bash
# Author  Vu Duc Nguyen

source function.sh
source config.cfg

# Function install prerequisites
function swift_prerequisites () {
	echocolor "Install the components"
	sleep 3
	apt install apt-get install xfsprogs rsync -y

	mkfs.xfs $VOLUME1
	mkfs.xfs $VOLUME2
	mkdir -p /srv/node/$DEVICES1
	mkdir -p /srv/node/$DEVICES2

	echo "$VOLUME1 /srv/node/$DEVICES1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 2" >> /etc/fstab
        echo "$VOLUME2 /srv/node/$DEVICES2 xfs noatime,nodiratime,nobarrier,logbufs=8 0 2" >> /etc/fstab

        mount /srv/node/$DEVICES1
        mount /srv/node/$DEVICES2

	cat << EOF > /etc/rsyncd.conf
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = $OBJECT1_IP

[account]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/account.lock

[container]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/container.lock

[object]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/object.lock_path
EOF

	sed -i '9i\RSYNC_ENABLE=true' /etc/default/rsync
	service rsync start
}

function swift_install_config() {
	echocolor "Install and config SWIFT..."
	sleep 3
	apt install swift swift-account swift-container swift-object -y

	swift_file_account=/etc/swift/account-server.conf
	swift_file_container=/etc/swift/container-server.conf
	swift_file_object=/etc/swift/object-server.conf
	curl -o $swift_file_account \
		https://git.openstack.org/cgit/openstack/swift/plain/etc/account-server.conf-sample?h=stable/queens
	curl -o $swift_file_container \
		https://git.openstack.org/cgit/openstack/swift/plain/etc/container-server.conf-sample?h=stable/queens
	curl -o $swift_file_object \
		https://git.openstack.org/cgit/openstack/swift/plain/etc/object-server.conf-sample?h=stable/queens

	cp $swift_file_account $swift_file_account.orig
	cp $swift_file_container $swift_file_container.orig
	cp $swift_file_object $swift_file_object.orig

	## swift_file_account
	ops_add $swift_file_account DEFAULT bind_ip $OBJECT1_IP
	ops_add $swift_file_account DEFAULT bind_port 6202
	ops_add $swift_file_account DEFAULT user swift
	ops_add $swift_file_account DEFAULT swift_dir /etc/swift
	ops_add $swift_file_account DEFAULT devices /srv/node
	ops_add $swift_file_account DEFAULT mount_check True

	ops_add $swift_file_account "pipeline:main" pipeline healthcheck recon account-server

	ops_add $swift_file_account "filter:recon" use "egg:swift#recon"
	ops_add $swift_file_account "filter:recon" recon_cache_path /var/cache/swift

	## swift_file_container
	ops_add $swift_file_container DEFAULT bind_ip $OBJECT1_IP
	ops_add $swift_file_container DEFAULT bind_port 6201
	ops_add $swift_file_container DEFAULT user swift
	ops_add $swift_file_container DEFAULT swift_dir /etc/swift
	ops_add $swift_file_container DEFAULT devices /srv/node
	ops_add $swift_file_container DEFAULT mount_check True

	ops_add $swift_file_container "pipeline:main" pipeline healthcheck recon container-server

	ops_add $swift_file_container "filter:recon" use "egg:swift#recon"
	ops_add $swift_file_container "filter:recon" recon_cache_path /var/cache/swift

	## swift_file_object
	ops_add $swift_file_object DEFAULT bind_ip $OBJECT1_IP
	ops_add $swift_file_object DEFAULT bind_port 6200
	ops_add $swift_file_object DEFAULT user swift
	ops_add $swift_file_object DEFAULT swift_dir /etc/swift
	ops_add $swift_file_object DEFAULT devices /srv/node
	ops_add $swift_file_object DEFAULT mount_check True

	ops_add $swift_file_object "pipeline:main" pipeline healthcheck recon object-server

	ops_add $swift_file_object "filter:recon" use "egg:swift#recon"
	ops_add $swift_file_object "filter:recon" recon_cache_path /var/cache/swift
	ops_add $swift_file_object "filter:recon" recon_lock_path /var/lock

	chown -R swift:swift /srv/node

	mkdir -p /var/cache/swift
	chown -R root:swift /var/cache/swift
	chmod -R 775 /var/cache/swift

	chown -R root:swift /etc/swift
}

function swift_restart () {
	echocolor "Swift Object1 services restart"
	sleep 3
	swift-init all start
}


#######################
###Execute functions###
#######################


# Install prerequisites
swift_prerequisites

# Install and config swift
swift_install_config

# restart swift service
swift_restart