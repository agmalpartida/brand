---
Title: Patroni Set up
date: 2024-09-01
categories:
- Patroni
tags:
- postgresql
- patroni
- ha
- etcd
keywords:
- sql
summary: "Patroni cluster for Postgresql databases"
comments: false
showMeta: false
showActions: false
---

# ETCD Installation and Configuration

`wget https://github.com/etcd-io/etcd/releases/download/v3.5.0/etcd-v3.5.0-linux-amd64.tar.gz` 

Once downloaded unzip and copy binaries to your /usr/bin

```sh
tar xvzf etcd-v3.5.0-linux-amd64.tar.gz
cd etcd-v3.5.0-linux-amd64/
cp etcd etcdctl etcdutl /usr/bin
```

```sh
[root@etcd1 ~]# etcd --version
etcd Version: 3.5.0
Git SHA: 946a5a6f2
Go Version: go1.16.3
Go OS/Arch: linux/amd64
```
- Configure and run 3 node ETCD Cluster:

1. Create etcd user and group for etcd binaries to run:

```sh
groupadd --system etcd
useradd -s /bin/bash --system -g etcd etcd
```

2. Create two directories(data and configuration)

```sh
sudo mkdir -p /var/lib/etcd/
sudo mkdir /etc/etcd
sudo chown -R etcd:etcd /var/lib/etcd/ /etc/etcd
```

3. Login using etcd user and create .bash_profile file with below content

```sh
export ETCD_NAME=`hostname -s`
export ETCD_HOST_IP=`hostname -i`
```

4. Create Service etcd in /etc/systemd/system/etcd.service, replace IP addresses with your corresponding machine IPs

```
[Unit]
Description=etcd
Documentation=https://github.com/etcd-io/etcd

[Service]
Type=notify
User=etcd
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
ExecStart=/usr/bin/etcd \\
  --name ${ETCD_NAME} \\
  --data-dir=/var/lib/etcd \\
  --initial-advertise-peer-urls http://${ETCD_HOST_IP}:2380 \\
  --listen-peer-urls http://${ETCD_HOST_IP}:2380 \\
  --listen-client-urls http://${ETCD_HOST_IP}:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls http://${ETCD_HOST_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster etcd1=http://192.168.56.201:2380,etcd2=http://192.168.56.202:2380,etcd3=http://192.168.56.203:2380 \\
  --initial-cluster-state new \

[Install]
WantedBy=multi-user.target
```

5. Once Service created enable the service and start it on all three servers

```sh
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
```

- You can check cluster working by issuing following commands:

```sh
# etcdctl member list --write-out=table
# etcdctl cluster-health
```

- To check leader you can check endpoint status:

```sh
etcdctl endpoint status --write-out=table --endpoints=etcd1:2379,etcd2:2379,etcd3:2379
```

**Note** : By default etcd does not support v2 API, in case patroni fails to start with the api error, add --enable-v2 flag in etcd service

## Troubleshooting

- Check connection to etcd:

```sh
curl http://10.201.217.181:2379/version
```

- Failover: check if a node has the nofailover tag

```sh
curl -s http://127.0.0.1:8008/config | jq
```

Remove nofailover tag:

```sh
curl -XPATCH -d '{"tags": {"nofailover": false}}' http://127.0.0.1:8008/config
```



# Patroni and Postgres Installation

```sh
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql
```

1. Install Patroni service. You need to install extra package required for connecting to etcd.

```sh
apt install patroni
apt install python3-etcd3
```

2. Enable Patroni service

`systemctl enable patroni` 

3. Create configuration file and required directories for patroni:

```sh
mkdir -p /etc/patroni/logs/ #directory to store logs
chmod 777 /etc/patroni/logs 
```

4. Create config file for patroni as below (/etc/patroni/patroni.yml)

`touch /etc/patroni/patroni.yml` 

```sh
scope: bootvar_cluster
name: pgdb1

log:
  traceback_level: INFO
  level: INFO
  dir: /etc/patroni/logs/
  file_num: 5

restapi:
  listen: 0.0.0.0:8008
  connect_address: 192.168.56.201:8008

etcd:
  protocol: http
  hosts: 192.168.56.201:2379,192.168.56.203:2379,192.168.56.203:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout : 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_keep_segments: 100
        #add other postgres DB parameters to start with

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 0.0.0.0/0 md5
  - host all all 0.0.0.0/0 md5

postgresql:
  listen: 192.168.56.204:5432
  connect_address: 192.168.56.204:5432
  data_dir: /var/lib/pgsql/bootvar/pgdb1/data
  bin_dir: /usr/pgsql-12/bin
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
```

In the bootstrap section of your Patroni configuration, Patroni automatically creates the users defined under the users key when initializing the PostgreSQL cluster. You do not need to create these users manually before starting PostgreSQL; Patroni will handle it when the cluster starts.

- Cluster Initialization:

When Patroni runs for the first time, it creates the PostgreSQL cluster if it doesn’t already exist. During this process, it applies the configurations defined in the bootstrap section.

- User Creation:

The users defined under the users key in your configuration will be created automatically. If there are errors during Patroni startup, the users may not be created.

- User Verification:

Once the cluster is running, you can connect to PostgreSQL to verify that the users were created correctly:

```sh
psql -h 10.201.217.181 -U postgres -d postgres -c "\du"
```

This should display a list of users, including admin and replicator, that Patroni created during the initialization process.

4.1. Bootstrap Section
The bootstrap section in Patroni is used to define how the PostgreSQL cluster is initialized and to set up the initial configuration, including user creation.

Creating a post_bootstrap Script

To automate additional tasks after the bootstrap process, you can create a post_bootstrap script. This script will run automatically after the initial cluster setup and can be used to create necessary users, set permissions, or perform other configurations.

Example post_bootstrap Script

Create a script, for example, named post_bootstrap.sh:

```sh
#!/bin/bash

set -e

# connexion variables
PGUSER="postgres"
PGPASSWORD="postgres"
PGHOST="localhost"
PGPORT="5432"

# create user admin
psql -U $PGUSER -h $PGHOST -p $PGPORT -c "CREATE ROLE admin WITH LOGIN PASSWORD 'V/\$QjLxf2022.-' CREATEDB CREATEROLE;"

# create user replicator
psql -U $PGUSER -h $PGHOST -p $PGPORT -c "CREATE ROLE replicator WITH LOGIN PASSWORD 'fxN^vruL2022.-' REPLICATION;"

echo "Users created successfully."

```

Modify your Patroni configuration:

```sh
bootstrap:
  ...
  post_bootstrap: /etc/patroni/post_bootstrap.sh 
```


Or directly over patroni configuration file:

```yaml
users:  
  admin:  
    password: V/$QjLxf2022.-  
    options:  
      - createrole  
      - createdb  
  replicator:  
    password: fxN^vruL2022.-  
    options:  
      - replication  
```

•	admin: This user is created during cluster initialization and has permissions to create roles and databases. It is an administrative user typically used for management tasks.
•	replicator: This user is also created during initialization and is specifically used for replication tasks. The replication option grants it permission to connect as a replication user.

4.2. PostgreSQL Section

```yaml
authentication:  
  replication:  
    username: replicator  
    password: fxN^vruL2022.-  
  superuser:  
    username: postgres  
    password: postgres  
```

•	replication: This defines how the replicator user authenticates for replication. The password must match the one defined in the bootstrap section to ensure successful replication connections.


## Password Storage

The credentials are stored at runtime in the pgpass file specified in the Patroni configuration. This ensures the replication user’s authentication details are available for automatic processes.

```sh
root@psql01
 ~  $  cat /tmp/pgpass0
psql02.fullstep.cloud:5432:*:replicator:fxN^vruL2022.-
```

5. Start Patroni

`service patroni start` 

Repeat same procedure on all three nodes, for any issues you can set `log.level` and `log.traceback_level` to **DEBUG**.
Once all nodes are up and running you can check status of patroni cluster using patronictl utility.

`patronictl -c /etc/patroni/patroni.yml list` 

Now patroni cluster is ready to use, you can start playing around and do some replication and failover tests.

After this we need to setup load balancer to point it to active (Leader) Postgres database. For this you need two HAProxy servers or if you are setting this on cloud you can use load balancers provided by cloud provider.

## Troubleshooting

```sh
journalctl -xeu patroni.service -l --no-pager

tail -f /var/logs/patroni/patroni.log

patroni --version

apt install yamllint
yamllint /etc/patroni/config.yml

```


- Check health

```sh
$  curl -q http://10.201.217.181:8008|jq
{
  "state": "unknown",
  "role": "replica",
  "cluster_unlocked": true,
  "dcs_last_seen": 1728642083,
  "database_system_identifier": "7424449856666054686",
  "pending_restart": true,
  "pending_restart_reason": {
    "max_wal_senders": {
      "old_value": "10",
      "new_value": "5"
    }
  },
  "patroni": {
    "version": "4.0.2",
    "scope": "devpsql_cluster",
    "name": "devpsql01.fullstep.cloud"
  }
}
```

## Operations

- Apply Changes with Reload

If Patroni indicates that there is a pending_restart, you can apply the configuration changes by running the Patroni reload command.

```sh
$  curl -X POST http://10.201.217.181:8008/reload
reload scheduled
```

- Replication status on the leader: On the leader node (psql01), check if it correctly detects psql03 as a replica:

```sql
SELECT application_name, state, sync_state, client_addr, replay_lsn
FROM pg_stat_replication;
```

- Check ports:

```sh
nc -zv 10.201.217.181 2379
```


# Install load balancer

After this we need to setup load balancer to point it to active (Leader) Postgres database. For this you need two HAProxy servers or if you are setting this on cloud you can use load balancers provided by cloud provider.



1. Install HAProxy on both servers:

`apt install haproxy` 

2. Configure haproxy.cfg file to redirect all traffic to active postgres leader. 

```sh
global
    maxconn 100

defaults
    log global
    mode tcp
    retries 2
    timeout client 30m
    timeout connect 4s
    timeout server 30m
    timeout check 5s

listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /

listen boorvar_cluster
    bind *:5432
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server pgdb1_5432 192.168.56.204:5432 maxconn 100 check port 8008
    server pgdb2_5432 192.168.56.205:5432 maxconn 100 check port 8008
    server pgdb3_5432 192.168.56.206:5432 maxconn 100 check port 8008
```

**Note** : Haproxy will check 8008 port of pgdb servers and if it returns 200 status then it will redirect all traffic to the leader. This 8008 port is configured in Patroni.

3. Start haproxy on both nodes

`service haproxy start` 

Once haproxy is started you can check status by hitting url http://haproxy1:7000
You can see all connections on haproxy:5432 will be redirected to pgdb1:5432, you can check if pgdb1 is the leader or not.
Now try connecting to the cluster using haproxy host, it should get redirected to leader.

# Setting up software watchdog on Linux

Watchdog devices are software or hardware mechanisms that will reset the whole system when they do not get a keepalive heartbeat within a specified timeframe. This adds an additional layer of fail safe in case usual Patroni split-brain protection mechanisms fail.

While the use of a watchdog mechanism with Patroni is optional, you shouldn’t really consider deploying a PostgreSQL HA environment in production without it.

Patroni will be the component interacting with the watchdog device. Since Patroni is run by the postgres user, we need to either set the permissions of the watchdog device open enough so the postgres user can write to it or make the device owned by postgres itself, which we consider a safer approach (as it is more restrictive).

Default Patroni configuration will try to use /dev/watchdog on Linux if it is accessible to Patroni. For most use cases using software watchdog built into the Linux kernel is secure enough.

- Installation

```sh
apt install watchdog
```

- Create service

```
vi /etc/systemd/system/patroni_watchdog.service

[Unit]
Description=Makes kernel watchdog device available for Patroni
Before=patroni.service

[Service]
Type=oneshot

Environment=WATCHDOG_MODULE=softdog
Environment=WATCHDOG_DEVICE=/dev/watchdog
Environment=PATRONI_USER=postgres

ExecStart=/usr/sbin/modprobe ${WATCHDOG_MODULE}
ExecStart=/bin/chown ${PATRONI_USER} ${WATCHDOG_DEVICE}

[Install]
WantedBy=multi-user.target
```

- Apply

```sh
systemctl daemon-reload
systemctl enable patroni_watchdog.service
systemctl start patroni_watchdog.service
systemctl status patroni_watchdog.service
```

To enable software watchdog manually issue the following commands as root before starting Patroni:

`modprobe softdog` 

```sh
# Replace postgres with the user you will be running patroni under
chown postgres /dev/watchdog
```

Load at boot:

```sh
$  cat /etc/modules-load.d/softdog.conf
softdog
```

**REMOVE ENTRY** softdog in all blacklist (in order to start at boot... /lib/modprobe.d/blacklist_...

```sh
$ grep blacklist /lib/modprobe.d/* /etc/modprobe.d/* |grep softdog
/lib/modprobe.d/blacklist_linux_5.4.0-72-generic.conf:blacklist softdog

$  grep -i softdog /lib/modprobe.d/*
/lib/modprobe.d/blacklist_linux_6.8.0-41-generic.conf:blacklist softdog
```

For testing it may be helpful to disable rebooting by adding `soft_noboot=1`  to the modprobe command line. In this case the watchdog will just log a line in kernel ring buffer, visible via dmesg.

Patroni will log information about the watchdog when it is successfully enabled.

```sh
root@psqltest01
 ~  $  journalctl -b | grep softdog
Oct 05 20:00:42 psqltest01 systemd-modules-load[360]: Module 'softdog' is deny-listed (by kmod)
Oct 05 20:01:41 psqltest01 kernel: softdog: initialized. soft_noboot=0 soft_margin=60 sec soft_panic=0 (nowayout=0)
Oct 05 20:01:41 psqltest01 kernel: softdog:              soft_reboot_cmd=<not set> soft_active_on_boot=0
 root@psqltest01
 ~  $  dmesg | grep softdog
[   63.286320] softdog: initialized. soft_noboot=0 soft_margin=60 sec soft_panic=0 (nowayout=0)
[   63.286327] softdog:              soft_reboot_cmd=<not set> soft_active_on_boot=0
```

# Pgbouncer

PgBouncer can be configured to work with a Patroni cluster, and in fact, it is a common practice for managing connections to the PostgreSQL cluster. PgBouncer acts as a proxy and connection pooler that distributes client requests to the nodes of the cluster according to the configuration and logic of Patroni (i.e., to the leader or followers).

Configuring PgBouncer in a Patroni Cluster:

1. Install PgBouncer on each node in the cluster
On each node where Patroni manages a PostgreSQL instance, install PgBouncer.

```sh
apt install pgbouncer

systemctl enable pgbouncer
systemctl status pgbouncer
```

2. Configure pgbouncer.ini
On each node, edit the PgBouncer configuration file (/etc/pgbouncer/pgbouncer.ini or equivalent).
A typical configuration example for a Patroni cluster:

```ini
[databases]
# Redirige todas las conexiones al líder del clúster de Patroni
mydb = host=127.0.0.1 port=5432 dbname=mydb auth_user=pgbouncer_user

[pgbouncer]
listen_addr = 0.0.0.0        # Escucha en todas las interfaces
listen_port = 6432           # Puerto para PgBouncer
auth_type = md5              # Método de autenticación
auth_file = /etc/pgbouncer/userlist.txt  # Archivo de usuarios
pool_mode = transaction      # Usa el modo "transaction" para Patroni
max_client_conn = 500        # Máximo de conexiones cliente
default_pool_size = 20       # Tamaño del pool por base de datos
```

```ini
[databases]
powerbi = host=127.0.0.1 dbname=powerbi
prd_end_bi = host=127.0.0.1 dbname=prd_end_bi

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 500
default_pool_size = 20
admin_users = postgres
```

In this configuration:
	•	auth_user should be configured with a user that has access to the databases.
	•	Use transaction mode (pool_mode = transaction) to prevent connections from getting “stuck” during failovers or leader changes.

3. Create the userlist.txt file

Define the users that PgBouncer will use to authenticate with PostgreSQL. For example, in /etc/pgbouncer/userlist.txt:

- Example:

```sh
$  cat /etc/pgbouncer/userlist.txt
"postgres" "changeme"
"powerbi" "123456"
```

Relationship between users and databases:
	•	When a client connects to PgBouncer requesting a specific database, PgBouncer verifies the provided user credentials against userlist.txt.
	•	If the credentials are correct, PgBouncer opens a connection to the PostgreSQL server using the username provided by the client.

4. Configure Patroni to work with PgBouncer

Patroni needs to “inform” the load balancer (in this case, PgBouncer) about changes in node status. This is done through membership tags and custom scripts.
	•	Adjust the Patroni configuration in patroni.yml:

```sh
tags:
  nofailover: false
  noloadbalance: true  # Prevent redirecting traffic to followers if using PgBouncer only for the leader
```

	•	Optional: Use health scripts to monitor which node should receive traffic:
	•	Set up a script in PgBouncer or a health check to redirect traffic to the leader.
	•	You can query the Patroni REST endpoint (http://:8008/) to check which node is the leader.

5. Configure clients to connect to PgBouncer

Instead of connecting directly to PostgreSQL, configure your applications to point to PgBouncer. For example:
	•	Host: <IP or DNS of PgBouncer>
	•	Port: 6432
	•	Database: mydb

6. Load balancing between followers (Optional)

If you want to allow read-only connections to the followers of the cluster, you can configure multiple entries in pgbouncer.ini:

```ini
[databases]
mydb_rw = host=127.0.0.1 port=5432 dbname=mydb
mydb_ro = host=<follower_ip> port=5432 dbname=mydb
```

7. Restart PgBouncer

```sh
systemctl restart pgbouncer
```

Failover Scripts: To ensure a quick redirection after a failover in Patroni, it’s useful to integrate scripts that automatically update PgBouncer’s configuration.

PgBouncer on a dedicated node: In large implementations, it’s common to use a dedicated node for PgBouncer rather than installing it on the cluster nodes.

## STATISTICS

PgBouncer’s virtual tables are not accessible through traditional SQL queries like you would in a PostgreSQL database. Instead, PgBouncer uses specific SHOW commands to gather information.
	•	SHOW POOLS;: Information about the connection pools.
	•	SHOW STATS;: General statistics about connections and pools.
	•	SHOW CLIENTS;: Information about client connections.
	•	SHOW USERS;: Users connected to PgBouncer.
	•	SHOW CONFIG;: Current configuration parameters of PgBouncer.

## Connections

If you have PgBouncer configured and have also defined max_connections in Patroni, both configurations affect the system complementarily but independently.

Explanation of the behavior:
	•	max_connections in Patroni (PostgreSQL): This value limits the maximum number of connections PostgreSQL can accept directly, whether from PgBouncer or any external client. This is an absolute limit for PostgreSQL.
If max_connections = 200, PostgreSQL will not accept more than 200 active simultaneous connections, including those from PgBouncer.
	•	max_client_conn and default_pool_size in PgBouncer: These configurations control how PgBouncer handles client connections to PostgreSQL.
	•	max_client_conn: Defines how many connections PgBouncer can accept from clients (applications).
	•	default_pool_size: Defines how many connections PgBouncer keeps open with PostgreSQL for each database in the pool.

PgBouncer uses a pooling model, which means that multiple clients can share a single connection to PostgreSQL.

Which one takes precedence?

Both limits are important, but the effective limit is defined by max_connections in Patroni. PgBouncer can handle more clients (max_client_conn), but it can only open connections to PostgreSQL up to the limit defined in max_connections.

For example:
	•	If max_connections = 200 in Patroni and default_pool_size = 20 in PgBouncer, PgBouncer can only open 200 connections to PostgreSQL in total (if multiple databases are connected, the pool is distributed among them).
	•	If max_client_conn = 500 in PgBouncer, it can accept up to 500 client connections, but only 200 connections will be established to PostgreSQL at the same time.

How to optimize this configuration:
	•	Increase max_connections in Patroni if the server has enough capacity: Adjust the parameter in the patroni.yml file:

```yaml
postgresql:
  parameters:
    max_connections: 500
```

Restart Patroni to apply the changes.
	•	Configure default_pool_size in PgBouncer based on needs:
	•	Set a reasonable pool size based on the expected load.
	•	For example, if you expect 500 concurrent clients and have 200 available connections in PostgreSQL, a default_pool_size = 10 could be enough to distribute the load.
	•	Monitor connection usage: Use views like pg_stat_activity and PgBouncer statistics to ensure you’re not hitting the limits:

```sql
SELECT * FROM pg_stat_activity;
```

```sh
psql -h <host_pgBouncer> -p 6432 -U <user> pgbouncer
SHOW POOLS;
```

Conclusion:

The max_connections limit in Patroni takes precedence, as PostgreSQL cannot exceed this number of active connections. PgBouncer helps distribute and optimize client connections, but it must be properly configured to ensure it doesn’t exceed this limit. If you expect to handle many clients, it’s advisable to use PgBouncer with a high max_client_conn and adjust max_connections in Patroni according to available resources.

# HAProxy vs PgBouncer

While HAProxy handles distributing connections between the nodes of your Patroni cluster, PgBouncer remains useful as a connection pool to optimize the management of connections to PostgreSQL.

Here’s how HAProxy and PgBouncer interact and how to handle this combination.

Roles of HAProxy and PgBouncer in this context:
	•	HAProxy:
	•	Acts as the network-level load balancer, distributing incoming connections across the Patroni cluster nodes.
	•	Determines which node to send traffic to based on the node’s status (leader or follower).
	•	PgBouncer:
	•	Not a load balancer per se, but a connection pool manager.
	•	Reduces the load on PostgreSQL by reusing existing connections, especially in applications that generate many short-lived or burst connections.
	•	Complements HAProxy by optimizing the number of active connections on the cluster nodes.

Is it necessary to use both?

Yes, in many cases. Using PgBouncer alongside HAProxy is a common practice in high-load systems because they address different issues:
	•	HAProxy balances traffic between nodes.
	•	PgBouncer manages connections to a node, reducing the impact of many concurrent connections.

Without PgBouncer, every connection passing through HAProxy reaches PostgreSQL directly, which could overload the max_connections on the server.

Recommended Architecture
	•	HAProxy balances client connections to PgBouncer.
	•	PgBouncer resides on each PostgreSQL node, optimizing connection usage on that node.

The flow would be:

Clients → HAProxy → PgBouncer (on each node) → PostgreSQL

This allows:
	•	HAProxy to determine the correct node for connections.
	•	PgBouncer to limit and optimize connections to PostgreSQL.

Configuration in a Combined Environment
	1.	HAProxy Configuration

HAProxy is configured to route traffic to the leader or followers depending on usage:
	•	In the HAProxy configuration file (haproxy.cfg):

```
frontend pgsql_frontend
    bind *:5432
    mode tcp
    default_backend pgsql_backend

backend pgsql_backend
    mode tcp
    option tcp-check
    balance roundrobin
    server pg1 192.168.1.101:6432 check
    server pg2 192.168.1.102:6432 check
    server pg3 192.168.1.103:6432 check
```

In this example, HAProxy sends traffic to the PgBouncer port (6432) on each node.
	2.	PgBouncer Configuration

PgBouncer is configured to optimize connections on each PostgreSQL node.
	•	In the PgBouncer configuration file (pgbouncer.ini):

```ini
[databases]
mydb = host=127.0.0.1 port=5432 dbname=mydb auth_user=pgbouncer_user

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 500
default_pool_size = 50
```

	•	listen_port is the port where PgBouncer listens (matching the port configured in HAProxy).
	•	pool_mode is recommended as transaction for Patroni clusters, as it avoids issues with leader changes.

	3.	Ensuring Consistency in Failover

When a failover occurs in Patroni, HAProxy must automatically redirect traffic to the new leader. You can configure a health check in HAProxy to validate the leader node via Patroni’s REST endpoint:

```
backend pgsql_backend
    mode tcp
    option httpchk GET /master
    http-check expect status 200
    server pg1 192.168.1.101:6432 check
    server pg2 192.168.1.102:6432 check
    server pg3 192.168.1.103:6432 check
```

This ensures that only the leader node receives write traffic.

What about the current error?

The “This connection has been closed” error you mentioned likely occurs because:
	•	The number of simultaneous connections in PostgreSQL (max_connections) is insufficient:
	•	Increase max_connections in Patroni to support more connections.
	•	PgBouncer will help optimize the use of these connections.
	•	The connection timeout is too short:
	•	Increase timeout values in HAProxy and PgBouncer to prevent connections from closing prematurely.

In HAProxy, you can adjust the timeout with:

```
timeout client 60s
timeout server 60s
timeout connect 10s
```

In PgBouncer:

```
server_idle_timeout = 600
```

Conclusion
	•	Use PgBouncer to optimize connections at the node level.
	•	HAProxy remains the main load balancer between nodes.
	•	Adjust max_connections, timeouts, and pool sizes to support the load.

# Application side Configuration:

As we have two HAProxy servers application should be configured in such a way that it should point to both servers, submit the request to available server and if application does not support such case then you need to set up virtual IP which will point to available HAProxy server.


