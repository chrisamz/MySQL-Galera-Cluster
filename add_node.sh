#!/bin/bash

# add_node.sh
# This script adds a new node to the MySQL Galera Cluster

# Define environment variables
NEW_NODE_IP=$1
CLUSTER_NODES="192.168.0.1,192.168.0.2,192.168.0.3"  # List existing cluster nodes
CLUSTER_NAME=my_galera_cluster
MYSQL_ROOT_PASSWORD=root_password
SST_USER=sstuser
SST_PASSWORD=password
NEW_NODE_NAME=$2

if [ -z "$NEW_NODE_IP" ] || [ -z "$NEW_NODE_NAME" ]; then
    echo "Usage: ./add_node.sh <new_node_ip> <new_node_name>"
    exit 1
fi

# Function to install MySQL and Galera on the new node
install_mysql_galera() {
    local node_ip=$1
    echo "Installing MySQL and Galera on node $node_ip..."
    ssh root@$node_ip <<EOF
    apt-get update
    apt-get install -y galera-3 galera-arbitrator-3 mysql-wsrep-5.7
    mkdir -p /etc/mysql/conf.d
EOF
}

# Function to configure MySQL and Galera on the new node
configure_new_node() {
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

    # Copy configuration files to the new node
    scp galera.cnf root@$node_ip:/etc/mysql/conf.d/
    scp config/my.cnf root@$node_ip:/etc/mysql/

    # Clean up local galera.cnf file
    rm galera.cnf

    # Start MySQL service on the new node
    ssh root@$node_ip "systemctl start mysql"
}

# Install MySQL and Galera on the new node
install_mysql_galera $NEW_NODE_IP

# Configure the new node
configure_new_node $NEW_NODE_IP $NEW_NODE_NAME "gcomm://$CLUSTER_NODES,$NEW_NODE_IP"

# Completion message
echo "New node $NEW_NODE_NAME ($NEW_NODE_IP) added to the MySQL Galera Cluster successfully."
