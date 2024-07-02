#!/bin/bash

# monitor_cluster.sh
# This script monitors the status of the MySQL Galera Cluster

# Define environment variables
CLUSTER_NODES=("192.168.0.1" "192.168.0.2" "192.168.0.3")
MYSQL_USER=root
MYSQL_PASSWORD=root_password
LOG_FILE=/var/log/galera_cluster_monitor.log

# Function to check the status of a node
check_node_status() {
    local node_ip=$1
    echo "Checking status of node $node_ip..."
    ssh root@$node_ip <<EOF
    mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW STATUS LIKE 'wsrep_%';"
EOF
}

# Function to log monitoring results
log_result() {
    local node_ip=$1
    local result=$2
    echo "$(date): Node $node_ip - $result" >> $LOG_FILE
}

# Create or clear the log file
echo "Galera Cluster Monitoring Log" > $LOG_FILE

# Check the status of each node
for node_ip in "${CLUSTER_NODES[@]}"; do
    result=$(check_node_status $node_ip)
    log_result $node_ip "$result"
done

# Completion message
echo "Galera Cluster monitoring completed successfully. Results logged to $LOG_FILE."
