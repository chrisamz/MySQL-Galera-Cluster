# MySQL Galera Cluster

## Overview

This project focuses on implementing a high-availability solution using MySQL Galera Cluster. Galera Cluster is a synchronous multi-master database cluster that provides high availability and scalability for MySQL databases.

## Technologies

- MySQL
- Galera Cluster

## Key Features

- Cluster setup
- Configuration files
- Load balancing
- Monitoring
- Failover mechanisms

## Project Structure

```
mysql-galera-cluster/
├── config/
│   ├── galera.cnf
│   ├── my.cnf
├── scripts/
│   ├── setup_cluster.sh
│   ├── add_node.sh
│   ├── remove_node.sh
│   ├── monitor_cluster.sh
├── docs/
│   ├── cluster_setup_guide.md
│   ├── load_balancing_guide.md
│   ├── monitoring_guide.md
│   ├── failover_guide.md
├── load_balancer/
│   ├── haproxy.cfg
│   ├── setup_haproxy.sh
├── README.md
└── LICENSE
```

## Instructions

### 1. Clone the Repository

Start by cloning the repository to your local machine:

```bash
git clone https://github.com/your-username/mysql-galera-cluster.git
cd mysql-galera-cluster
```

### 2. Set Up the MySQL Galera Cluster

#### Configuration Files

- **Galera Configuration (`galera.cnf`)**:
  - Contains the configuration settings specific to Galera Cluster.
  
- **MySQL Configuration (`my.cnf`)**:
  - Contains the general MySQL configuration settings.

#### Example: `galera.cnf`

```ini
# galera.cnf
# Galera Cluster configuration settings

[mysqld]
# Path to Galera library
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Cluster connection URL
wsrep_cluster_address="gcomm://node1,node2,node3"

# Node name
wsrep_node_name=node1

# Node address
wsrep_node_address="node1"

# SST method
wsrep_sst_method=rsync

# Authentication for SST method
wsrep_sst_auth="sstuser:password"
```

#### Example: `my.cnf`

```ini
# my.cnf
# General MySQL configuration settings

[mysqld]
# Basic settings
user=mysql
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock

# Logging
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

# Network settings
bind-address=0.0.0.0

# Galera settings
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
```

### 3. Cluster Setup

Use the `setup_cluster.sh` script to set up the MySQL Galera Cluster.

```bash
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

# Create MySQL configuration directories
mkdir -p /etc/mysql/conf.d

# Copy configuration files
cp config/galera.cnf /etc/mysql/conf.d/
cp config/my.cnf /etc/mysql/

# Start the first node
galera_new_cluster

# Start the other nodes
ssh root@$NODE2_IP "systemctl start mysql"
ssh root@$NODE3_IP "systemctl start mysql"

# Create the SST user on the first node
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER '$SST_USER'@'%' IDENTIFIED BY '$SST_PASSWORD';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO '$SST_USER'@'%';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"
```

### 4. Add or Remove Nodes

Use the `add_node.sh` and `remove_node.sh` scripts to manage nodes in the cluster.

#### Example: `add_node.sh`

```bash
# add_node.sh
# This script adds a new node to the MySQL Galera Cluster

# Define environment variables
NEW_NODE_IP=192.168.0.4

# Add the new node to the cluster
ssh root@$NEW_NODE_IP "systemctl start mysql"
```

#### Example: `remove_node.sh`

```bash
# remove_node.sh
# This script removes a node from the MySQL Galera Cluster

# Define environment variables
NODE_IP=192.168.0.4

# Remove the node from the cluster
ssh root@$NODE_IP "systemctl stop mysql"
```

### 5. Load Balancing

#### Example: `haproxy.cfg`

```ini
# haproxy.cfg
# HAProxy configuration for load balancing MySQL Galera Cluster

global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend mysql
    bind *:3306
    default_backend galera_cluster

backend galera_cluster
    mode tcp
    balance roundrobin
    option mysql-check user haproxy_check
    server node1 192.168.0.1:3306 check
    server node2 192.168.0.2:3306 check
    server node3 192.168.0.3:3306 check
```

#### Example: `setup_haproxy.sh`

```bash
# setup_haproxy.sh
# This script sets up HAProxy for load balancing the MySQL Galera Cluster

# Install HAProxy
apt-get update
apt-get install -y haproxy

# Copy HAProxy configuration file
cp load_balancer/haproxy.cfg /etc/haproxy/haproxy.cfg

# Restart HAProxy service
systemctl restart haproxy
```

### 6. Monitoring

Use the `monitor_cluster.sh` script to monitor the status of the MySQL Galera Cluster.

#### Example: `monitor_cluster.sh`

```bash
# monitor_cluster.sh
# This script monitors the status of the MySQL Galera Cluster

# Define environment variables
NODE1_IP=192.168.0.1
NODE2_IP=192.168.0.2
NODE3_IP=192.168.0.3

# Function to check the status of a node
check_node_status() {
    local node_ip=$1
    echo "Checking status of node $node_ip..."
    mysql -h $node_ip -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
}

# Check the status of each node
check_node_status $NODE1_IP
check_node_status $NODE2_IP
check_node_status $NODE3_IP
```

### 7. Documentation

#### Cluster Setup Guide

`docs/cluster_setup_guide.md`

```markdown
# MySQL Galera Cluster Setup Guide

## Overview

This guide provides step-by-step instructions for setting up a MySQL Galera Cluster.

## Steps

1. Configure the Galera and MySQL configuration files.
2. Use the `setup_cluster.sh` script to set up the cluster.
3. Add or remove nodes using the `add_node.sh` and `remove_node.sh` scripts.
4. Set up load balancing using HAProxy with the provided configuration.
5. Monitor the cluster status using the `monitor_cluster.sh` script.
```

#### Load Balancing Guide

`docs/load_balancing_guide.md`

```markdown
# Load Balancing Guide

## Overview

This guide provides instructions for setting up load balancing for the MySQL Galera Cluster using HAProxy.

## Steps

1. Configure the HAProxy configuration file (`haproxy.cfg`).
2. Use the `setup_haproxy.sh` script to set up HAProxy.
3. Verify the load balancing configuration and ensure traffic is distributed across the cluster nodes.
```

#### Monitoring Guide

`docs/monitoring_guide.md`

```markdown
# Monitoring Guide

## Overview

This guide provides instructions for monitoring the MySQL Galera Cluster.

## Steps

1. Use the `monitor_cluster.sh` script to check the status of each node in the cluster.
2. Verify the cluster size and node status using the MySQL `SHOW STATUS LIKE 'wsrep_cluster_size';` command.
```

#### Failover Guide



`docs/failover_guide.md`

```markdown
# Failover Guide

## Overview

This guide provides instructions for handling failover in the MySQL Galera Cluster.

## Steps

1. Detect node failures using the monitoring script.
2. Use HAProxy to redirect traffic to available nodes.
3. Restore failed nodes and rejoin them to the cluster using the appropriate scripts.
```

### Conclusion

By following these steps, you can implement a high-availability MySQL Galera Cluster. The provided scripts and configuration files will help you set up, manage, and monitor the cluster effectively.

## Contributing

We welcome contributions to improve this project. If you would like to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch.
3. Make your changes.
4. Submit a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.


---

Thank you for using the MySQL Galera Cluster project! We hope this guide helps you implement a robust high-availability solution for your MySQL databases.
