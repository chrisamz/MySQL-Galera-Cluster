#!/bin/bash

# setup_cluster.sh
# This script sets up the MySQL Galera Cluster

# Define environment variables
NODE1_IP=192.168.0.1
NODE2_IP=192.168.0.2
NODE3_IP=192.168.0.3
CLUSTER_NAME=my_galera_cluster
MYSQL_ROOT_PASSWORD=root_password
SST_USER=sstuser
SST_PASSWORD=password

# Function to install MySQL and Galera on a node
install_mysql_galera() {
    local node_ip=$1
    echo "Installing MySQL and Galera on node $node_ip..."
    ssh root@$node_ip <<EOF
    apt-get update
    apt-get install -y galera-3 galera-arbitrator-3 mysql-wsrep-5.7
    mkdir -p /etc/mysql/conf.d
EOF
}

# Function to configure MySQL and Galera on a node
configure_node() {
    local node_ip=$1
    local node_name=$2
    local cluster_address=$3
    echo "Configuring MySQL and Galera on node $node_ip..."

    # Create galera.cnf content
    cat <<EOT > galera.cnf
# Galera configuration for $node_name

[mysqld]
# Path to Galera library
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Cluster connection URL
wsrep_cluster_address="$cluster_address"

# Node name
wsrep_node_name=$node_name

# Node address
wsrep_node_address="$node_ip"

# SST method
wsrep_sst_method=rsync

# Authentication for SST method
wsrep_sst_auth="$SST_USER:$SST_PASSWORD"

# Cluster name
wsrep_cluster_name="$CLUSTER_NAME"

# InnoDB settings
innodb_autoinc_lock_mode=2
default_storage_engine=InnoDB

# Replication settings
wsrep_on=ON
wsrep_causal_reads=ON

# Node-internal settings
binlog_format=row
log_slave_updates=ON

# Galera performance settings
wsrep_slave_threads=4
wsrep_log_conflicts=ON

# Diagnostics settings
wsrep_provider_options="gcache.size=512M"

# Ensure MySQL listens on all interfaces
bind-address=0.0.0.0

# General settings
user=mysql
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-error=/var/log/mysql/error.log
pid-file=/var/run/mysqld/mysqld.pid
EOT

    # Copy configuration files to the node
    scp galera.cnf root@$node_ip:/etc/mysql/conf.d/
    scp config/my.cnf root@$node_ip:/etc/mysql/

    # Clean up local galera.cnf file
    rm galera.cnf

    # Start MySQL service on the node
    ssh root@$node_ip "systemctl start mysql"
}

# Step 1: Install MySQL and Galera on all nodes
install_mysql_galera $NODE1_IP
install_mysql_galera $NODE2_IP
install_mysql_galera $NODE3_IP

# Step 2: Configure the first node
configure_node $NODE1_IP "node1" "gcomm://$NODE1_IP,$NODE2_IP,$NODE3_IP"

# Step 3: Bootstrap the first node
echo "Bootstrapping the first node..."
ssh root@$NODE1_IP "galera_new_cluster"

# Step 4: Configure and start the remaining nodes
configure_node $NODE2_IP "node2" "gcomm://$NODE1_IP,$NODE2_IP,$NODE3_IP"
configure_node $NODE3_IP "node3" "gcomm://$NODE1_IP,$NODE2_IP,$NODE3_IP"

# Step 5: Create the SST user on the first node
echo "Creating the SST user on the first node..."
ssh root@$NODE1_IP <<EOF
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER '$SST_USER'@'%' IDENTIFIED BY '$SST_PASSWORD';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO '$SST_USER'@'%';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"
EOF

# Completion message
echo "MySQL Galera Cluster setup completed successfully."
