#!/bin/bash
# Author  Vu Duc Nguyen

source function.sh
source config.cfg

# Function create the swift service credentials
function swift_user_endpoint () {
	echocolor "Set environment variable for admin user"
	source /root/admin-openrc

	echocolor "Create the swift service credentials"
	sleep 3

	openstack user create --domain default --password $SWIFT_PASS swift
	penstack role add --project service --user swift admin
	openstack service create --name swift --description "OpenStack Object Storage" object-store
	openstack endpoint create --region RegionOne object-store public http://$CTL_IP:8080/v1/AUTH_%\(project_id\)s
	openstack endpoint create --region RegionOne object-store internal http://$CTL_IP:8080/v1/AUTH_%\(project_id\)s
	openstack endpoint create --region RegionOne object-store admin http://$CTL_IP:8080/v1/AUTH_%\(project_id\)s
}

# Function install the components
function swift_install () {
	echocolor "Install the components"
	sleep 3
	apt install swift swift-proxy python-swiftclient \
  	python-keystoneclient python-keystonemiddleware \
  	memcached -y
}

# Function configure the proxy server component
function swift_config_proxy_server () {
	echocolor "Create the swift directory"
	sleep 3
	mkdir /etc/swift

	echocolor "Configure the swift proxy server"
	sleep 3
	curl -o /etc/swift/proxy-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/proxy-server.conf-sample?h=stable/queens
	swiftfile=/etc/swift/proxy-server.conf
	cp $swiftfile $swiftfile.orig

	ops_add $swiftfile DEFAULT bind_port 8080
	ops_add $swiftfile DEFAULT user swift
	ops_add $swiftfile DEFAULT swift_dir /etc/swift

	#ops_del $swiftfile pipeline:main pipeline
	ops_add $swiftfile "pipeline:main" pipeline \
		"catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server"

	ops_add $swiftfile "app:proxy-server" use "egg:swift#proxy"
	ops_add $swiftfile "app:proxy-server" account_autocreate True

	#ops_add $swiftfile filter:keystoneauth
	ops_add $swiftfile "filter:keystoneauth" use "egg:swift#keystoneauth"
	ops_add $swiftfile "filter:keystoneauth" operator_roles "admin,user"

	ops_add $swiftfile "filter:authtoken" paste.filter_factory keystonemiddleware.auth_token:filter_factory
	ops_add $swiftfile "filter:authtoken" www_authenticate_uri http://CTL_IP:5000
	ops_add $swiftfile "filter:authtoken" auth_url http://CTL_IP:5000
	ops_add $swiftfile "filter:authtoken" memcached_servers CTL_IP:11211
	ops_add $swiftfile "filter:authtoken" auth_type password
	ops_add $swiftfile "filter:authtoken" project_domain_id default
	ops_add $swiftfile "filter:authtoken" user_domain_id default
	ops_add $swiftfile "filter:authtoken" project_name service
	ops_add $swiftfile "filter:authtoken" username swift
	ops_add $swiftfile "filter:authtoken" password SWIFT_PASS
	ops_add $swiftfile "filter:authtoken" delay_auth_decision True

	ops_add $swiftfile "filter:cache" use "egg:swift#memcache"
	ops_add $swiftfile "filter:cache" memcache_servers controller:11211
}

# Function Create and distribute initial rings
function swift_ring () {
	echocolor "Create and distribute initial rings"
	sleep 3
	cd /etc/swift

	echocolor "Create account ring"
	sleep 3
	swift-ring-builder account.builder create 10 3 1
	swift-ring-builder account.builder \
		add --region 1 --zone 1 --ip $OBJECT1_IP --port 6202 \
		--device $DEVICE_NAME1 --weight $DEVICE_WEIGHT1
        swift-ring-builder account.builder \
        	add --region 1 --zone 1 --ip $OBJECT1_IP --port 6202 \
        	--device $DEVICE_NAME2 --weight $DEVICE_WEIGHT2
        swift-ring-builder account.builder \
        	add --region 1 --zone 2 --ip $OBJECT2_IP --port 6202 \
        	--device $DEVICE_NAME1 --weight $DEVICE_WEIGHT1
        swift-ring-builder account.builder \
        	add --region 1 --zone 2 --ip $OBJECT2_IP --port 6202 \
        	--device $DEVICE_NAME2 --weight $DEVICE_WEIGHT2
	swift-ring-builder account.builder
	swift-ring-builder account.builder rebalance

	echocolor "Create container ring"
	sleep 3
	swift-ring-builder container.builder create 10 3 1
	swift-ring-builder container.builder \
  		add --region 1 --zone 1 --ip $OBJECT1_IP --port 6201 \
  		--device $DEVICE_NAME1 --weight $DEVICE_WEIGHT1
  	swift-ring-builder container.builder \
  		add --region 1 --zone 1 --ip $OBJECT1_IP --port 6201 \
  		--device $DEVICE_NAME2 --weight $DEVICE_WEIGHT2
  	swift-ring-builder container.builder \
  		add --region 1 --zone 2 --ip $OBJECT2_IP --port 6201 \
  		--device $DEVICE_NAME1 --weight $DEVICE_WEIGHT1
  	swift-ring-builder container.builder \
  		add --region 1 --zone 2 --ip $OBJECT2_IP --port 6201 \
  		--device $DEVICE_NAME2 --weight $DEVICE_WEIGHT2
  	swift-ring-builder container.builder
  	swift-ring-builder container.builder rebalance

  	echocolor "Create object ring"
  	sleep 3
  	swift-ring-builder object.builder create 10 3 1
	swift-ring-builder object.builder \
  		add --region 1 --zone 1 --ip $OBJECT1_IP --port 6201 \
  		--device $DEVICE_NAME1 --weight $DEVICE_WEIGHT1
  	swift-ring-builder object.builder \
  		add --region 1 --zone 1 --ip $OBJECT1_IP --port 6201 \
  		--device $DEVICE_NAME2 --weight $DEVICE_WEIGHT2
  	swift-ring-builder object.builder \
  		add --region 1 --zone 2 --ip $OBJECT2_IP --port 6201 \
  		--device $DEVICE_NAME1 --weight $DEVICE_WEIGHT1
  	swift-ring-builder object.builder \
  		add --region 1 --zone 2 --ip $OBJECT2_IP --port 6201 \
  		--device $DEVICE_NAME2 --weight $DEVICE_WEIGHT2
  	swift-ring-builder object.builder
  	swift-ring-builder object.builder rebalance

  	echocolor "Distribute ring configuration files to swift node"
  	sleep 3
  	scp /etc/swift/*.ring.gz root@$OBJECT1_IP:/etc/swift
        scp /etc/swift/*.ring.gz root@$OBJECT2_IP:/etc/swift
        cd /root/
}

# Function config swift
function swift_config () {
	echocolor "Configure the swift"
	sleep 3

	curl -o /etc/swift/swift.conf \
  		https://git.openstack.org/cgit/openstack/swift/plain/etc/swift.conf-sample?h=stable/queens
  	ctl_swift_conf=/etc/swift/swift.conf
  	cp $ctl_swift_conf $ctl_swift_conf.orig

        ops_add $ctl_swift_conf swift-hash swift_hash_path_suffix  $HASH_PATH_SUFFIX
        ops_add $ctl_swift_conf swift-hash swift_hash_path_prefix $HASH_PATH_SUFFIX
        ops_add $ctl_swift_conf "storage-policy:0" name Policy-0
        ops_add $ctl_swift_conf "storage-policy:0" default yes

        scp $ctl_swift_conf root@$OBJECT1_IP:/etc/swift
        scp $ctl_swift_conf root@$OBJECT2_IP:/etc/swift
        chown -R root:swift /etc/swift

        #ssh root@$OBJECT1_IP 'chown -R root:swift /etc/swift'
        #ssh root@$OBJECT2_IP 'chown -R root:swift /etc/swift'
}

function swift_restart () {
	echocolor "Swift services restart "
	sleep 3
	service memcached restart
	service swift-proxy restart
}



#######################
###Execute functions###
#######################


# create the swift service credentials
swift_user_endpoint

# Function install the components
swift_install

# Function configure the proxy server component
swift_config_proxy_server

# Function Create and distribute initial rings
swift_ring

# Function config swift
swift_config

# restart swift service
swift_restart