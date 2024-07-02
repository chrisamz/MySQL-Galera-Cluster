#!/bin/bash

# remove_node.sh
# This script removes a node from the MySQL Galera Cluster

# Define environment variables
NODE_IP=$1
NODE_NAME=$2

if [ -z "$NODE_IP" ] || [ -z "$NODE_NAME" ]; then
    echo "Usage: ./remove_node.sh <node_ip> <node_name>"
    exit 1
fi

# Function to stop MySQL and remove the node from the cluster
remove_node() {
    local node_ip=$1
    local node_name=$2
    echo "Removing node $node_name ($node_ip) from the cluster..."

    # Stop MySQL service on the node
    ssh root@$node_ip "systemctl stop mysql"

    # Remove Galera configuration files
    ssh root@$node_ip "rm -rf /etc/mysql/conf.d/galera.cnf"
    ssh root@$node_ip "rm -rf /etc/mysql/my.cnf"

    # Remove MySQL data directory (optional)
    # Uncomment the following line if you want to remove the MySQL data directory
    # ssh root@$node_ip "rm -rf /var/lib/mysql"
}

# Remove the node from the cluster
remove_node $NODE_IP $NODE_NAME

# Completion message
echo "Node $NODE_NAME ($NODE_IP) removed from the MySQL Galera Cluster successfully."
