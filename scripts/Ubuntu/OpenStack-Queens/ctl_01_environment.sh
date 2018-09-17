#!/bin/bash
#Author Vu Duc Nguyen

source function.sh
source config.cfg

# Function update and upgrade for CONTROLLER
function update_upgrade () {
	echocolor "Update and Update controller"
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

	sed -i 's/pool 2.debian.pool.ntp.org offline iburst/ \
pool 2.debian.pool.ntp.org offline iburst \
server 1.vn.poo.ntp.org iburst \
server 0.asia.pool.ntp.org iburst \
server 1.asia.pool.ntp.org iburst/g' $ntpfile

	echo "allow $MANAGE_SUBNET" >> $ntpfile

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

function install_database() {
	echocolor "Install and Config MariaDB"
	sleep 3

	echo mariadb-server-10.0 mysql-server/root_password $ROOT_DBPASS | \
	    debconf-set-selections
	echo mariadb-server-10.0 mysql-server/root_password_again $ROOT_DBPASS | \
	    debconf-set-selections

	apt install -y mariadb-server

	sed -r -i 's/127\.0\.0\.1/0\.0\.0\.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
	sed -i 's/character-set-server  = utf8mb4/character-set-server  = utf8/' \
	    /etc/mysql/mariadb.conf.d/50-server.cnf
	sed -i 's/collation-server/#collation-server/' /etc/mysql/mariadb.conf.d/50-server.cnf

	systemctl restart mysql

cat << EOF | mysql -uroot -p$ROOT_DBPASS
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$ROOT_DBPASS' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$ROOT_DBPASS' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

	sqlfile=/etc/mysql/mariadb.conf.d/99-openstack.cnf
	touch $sqlfile
	ops_add $sqlfile client default-character-set utf8
	ops_add $sqlfile mysqld bind-address 0.0.0.0
	ops_add $sqlfile mysqld default-storage-engine innodb
	ops_add $sqlfile mysqld innodb_file_per_table
	ops_add $sqlfile mysqld max_connections 4096
	ops_add $sqlfile mysqld collation-server utf8_general_ci
	ops_add $sqlfile mysqld character-set-server utf8

	echocolor "Restarting MYSQL"
	sleep 5
	systemctl restart mysql

}


# Function install message queue
function install_mq () {
	echocolor "Install Message queue (rabbitmq)"
	sleep 3

	apt install rabbitmq-server -y
	rabbitmqctl add_user openstack $RABBIT_PASS
	rabbitmqctl set_permissions openstack ".*" ".*" ".*"
}

# Function install Memcached
function install_memcached () {
	echocolor "Install Memcached"
	sleep 3

	apt-get install memcached python-memcache -y
	memcachefile=/etc/memcached.conf
	sed -i 's|-l 127.0.0.1|'"-l $CTL_MANAGE_IP"'|g' $memcachefile

	service memcached restart
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

# Install SQL database (Mariadb)
install_database

# Install Message queue (rabbitmq)
install_mq

# Install Memcached
install_memcached
