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

# Adjusting Operating System Resources

- Increase the Limit of Open Files

Each PostgreSQL connection consumes a file descriptor. Adjust the limits in /etc/security/limits.conf:

```
postgres  soft  nofile  10240  
postgres  hard  nofile  10240  
```

- Modify Kernel Parameters

Increase the maximum number of network connections and system semaphores in /etc/sysctl.conf:

```
fs.file-max = 100000  
kernel.sem = 250 32000 100 128  
net.core.somaxconn = 1024  
net.ipv4.ip_local_port_range = 1024 65000  
```

- Apply the Changes

```bash
sysctl -p  
```

# ETCD Installation and Configuration

[Reference](https://github.com/etcd-io/etcd) 

Etcd is a fault-tolerant, distributed key-value store used to store the state of the Postgres cluster. Using Patroni, all of the Postgres nodes make use of etcd to keep the Postgres cluster up and running. In production, it makes sense to use a larger etcd cluster so that if one etcd node fails, it doesn’t affect Postgres servers.

To form a cluster, etcd require a minimum 3 etcd nodes for to have high availability. An etcd cluster needs a majority a quorum, to agree on updates to the cluster state. For a cluster with n nodes, quorum is (n/2)+1.
3 nodes etcd can handle 1 node failure, 5 nodes etcd can handle 2 node failure, and so on. A 5 nodes etcd cluster can tolerate 2 nodes failures, which is enough in most cases. Although larger clusters provide better fault tolerance, the write performance will suffers because data must be replicated across more machines.

Prerequisite:

```
Minimum of 3 servers
Firewall open on port 2379 and 2380

       ____________              ____________
      |            |            |            |
      |   etcd 1   |------------|   etcd 2   |
      |____________|     |      |____________|
                         |
                    _____|______
                   |            |
                   |   etcd 3   |
                   |____________|
```

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

3. Config file per node

```sh
vim /etc/etcd/etcd.conf
```

```
ETCD_NAME=node1
ETCD_DATA_DIR="/var/lib/etcd/postgresql"
ETCD_INITIAL_CLUSTER="node1=http://172.20.20.211:2380,node2=http://172.20.20.212:2380,node3=http://172.20.20.213:2380"
ETCD_INITIAL_CLUSTER_STATE="existing"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_ADVERTISE_PEER_URLS=http://172.20.20.213:2380
ETCD_ADVERTISE_CLIENT_URLS=http://172.20.20.213:2379
ETCD_LISTEN_PEER_URLS=http://172.20.20.213:2380
ETCD_LISTEN_CLIENT_URLS=http://172.20.20.213:2379,http://127.0.0.1:2379
```

4. Create Service etcd in /etc/systemd/system/etcd.service, replace IP addresses with your corresponding machine IPs

```
[Unit]
Description=etcd key-value store
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
EnvironmentFile=/etc/etcd/etcd.conf
ExecStart=/usr/bin/etcd
Restart=always
RestartSec=5
LimitNOFILE=40000

[Install]
WantedBy=multi-user.target
```

5. Once Service created enable the service and start it on all three servers

```sh
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
```

- You can check cluster working by issuing following commands:

```sh
etcdctl member list --write-out=table
```

- To check leader you can check endpoint status:

```sh
etcdctl endpoint status --write-out=table --endpoints=etcd1:2379,etcd2:2379,etcd3:2379
```

**Note** : By default etcd does not support v2 API, in case patroni fails to start with the api error, add --enable-v2 flag in etcd service

6. Configuration

`/etc/etcd/etcd.conf` 

`ETCD_INITIAL_CLUSTER_STATE="new"` 

For new nodes that have not yet been added to the cluster, this value may be “new” during the initial setup, but once the node successfully joins, this value should be changed to “existing”.

In the configuration file (/etc/etcd/etcd.conf or similar), make sure that:
Nodes that are already part of the cluster have ETCD_INITIAL_CLUSTER_STATE set to “existing”.

Verify that all nodes have the same configuration for ETCD_INITIAL_CLUSTER and ETCD_INITIAL_CLUSTER_STATE.

It is necessary to initialize the etcd cluster from one of the nodes and we did that from node1 using the following configuration file:

```
ETCD_NAME=node1
ETCD_DATA_DIR="/var/lib/etcd/postgresql"
ETCD_INITIAL_CLUSTER="node1=http://10.201.217.181:2380,node2=http://10.201.217.182:2380,node3=http://10.201.217.183:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_ADVERTISE_PEER_URLS=http://10.201.217.181:2380
ETCD_ADVERTISE_CLIENT_URLS=http://10.201.217.181:2379
ETCD_LISTEN_PEER_URLS=http://10.201.217.181:2380
ETCD_LISTEN_CLIENT_URLS=http://10.201.217.181:2379,http://127.0.0.1:2379
```

We then restarted the service:

```bash
systemctl restart etcd
```

We can then move on to install etcd on node2. The configuration file follows the same structure as that of node1, except that we are adding node2 to an existing cluster so we should indicate the other node(s)

Before we restart the service, we need to formally add node2 to the etcd cluster by running the following command on node1:

```bash
etcdctl member add node2 http://10.201.217.182:2380
```

```bash
ETCDCTL_API=3 etcdctl endpoint status \
    --endpoints=http://10.201.217.181:2379,http://10.201.217.182:2379,http://10.201.217.183:2379 \
    --write-out=table

+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|          ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| http://10.201.217.181:2379 | c62a62b5d410be14 |  3.5.16 |   20 kB |      true |      false |         8 |         23 |                 23 |        |
| http://10.201.217.182:2379 | c7e57c04ee418bff |  3.5.16 |   20 kB |     false |      false |         8 |         23 |                 23 |        |
| http://10.201.217.183:2379 | 29ed4527ec2e0fef |  3.5.16 |   20 kB |     false |      false |         8 |         23 |                 23 |        |
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
```

## Concepts

- IS LEARNER: This column indicates whether the member is a “learner”. A learner node is a member of the cluster that can only replicate data, but cannot vote in Raft consensus decisions. This is useful for adding new nodes to the cluster without affecting the consensus.
Example: false means the node is a full voting member of the cluster. true would indicate that it is a learner.

## OPS

```bash
curl http://<etcdnode_ip>:2380/members
```

- List key

```bash
etcdctl --endpoints=http://10.201.217.181:2379 get / --prefix
etcdctl ls /service --recursive
```

- Remove key

```bash
etcdctl --endpoints=http://10.201.217.181:2379 get / --prefix
etcdctl --endpoints=http://10.201.217.181:2379 del /service/psqltest_cluster/members/psqltest01 --recursive
```

- Status

```bash
curl http://172.20.20.211:2379/health
etcdctl --endpoints=http://172.20.20.211:2379,http://172.20.20.212:2379,http://172.20.20.213:2379 endpoint status
etcdctl --endpoints=http://172.20.20.211:2379,http://172.20.20.212:2379,http://172.20.20.213:2379 endpoint health
```

- patroni

```bash
etcdctl --endpoints=http://172.20.20.211:2379,http://172.20.20.212:2379,http://172.20.20.213:2379 get /service/patroni/leader
etcdctl --endpoints=http://172.20.20.211:2379,http://172.20.20.212:2379,http://172.20.20.213:2379 lease list
etcdctl --endpoints=http://172.20.20.211:2379,http://172.20.20.212:2379,http://172.20.20.213:2379 lease revoke 72689339f34030a9

$  etcdctl --endpoints=http://10.201.217.181:2379 get / --prefix
/service/psqltest_cluster/config
{"loop_wait":2,"retry_timeout":14,"ttl":30}
/service/psqltest_cluster/initialize
7422315883286207519
```

- Patroni, initialize cluster

```bash
$  etcdctl --endpoints=http://10.201.217.181:2379 del /service/psqltest_cluster/initialize
1
```

- Force leader election

```bash
etcdctl election campaign /path/to/election-key
etcdctl --endpoints=http://10.201.217.181:2379 get /psqltest_cluster/leader
```

## Troubleshooting

- The “cluster ID mismatch” error occurs because the nodes have different cluster IDs, meaning they are not in the same cluster. To resolve this, make sure the nodes are configured correctly, delete old data if necessary, and verify that all nodes share the same cluster ID.
Verify the cluster ID. Ensure that all nodes belong to the same cluster by checking the cluster ID on all nodes.

- Logs

```bash
journalctl -xeu etcd.service -l --no-pager -f
```

- To obtain the Cluster ID, we need to view the output as “json”.

```bash
ETCDCTL_API=3 etcdctl endpoint status \
    --endpoints=http://10.201.217.181:2379,http://10.201.217.182:2379,http://10.201.217.183:2379 \
    --write-out=json | jq
```

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

### Replace a failed node with a new one

```sh
 ~  #  etcd --version
etcd Version: 3.5.16
Git SHA: f20bbad
Go Version: go1.22.7
Go OS/Arch: linux/amd64

 ~  #  etcdctl member list
1826af1ab9e8f268, started, psql02, http://172.20.20.212:2380, http://172.20.20.212:2379, false
4ce4c031681be159, started, psql01, http://172.20.20.211:2380, http://172.20.20.211:2379, false
8dafc4754417b6ab, started, psql03, http://172.20.20.213:2380, http://172.20.20.213:2379, false
```

If the node does not contain important data and can be removed:

From a healthy node (172.20.20.211 or 172.20.20.212), remove the node failed from the cluster:

```sh
etcdctl --endpoints=http://172.20.20.211:2379 member remove 8dafc4754417b6ab

 ~  #  etcdctl member remove 8dafc4754417b6ab
Member 8dafc4754417b6ab removed from cluster 84a78972d1659e7b

 ~  #  etcdctl member list
1826af1ab9e8f268, started, psql02, http://172.20.20.212:2380, http://172.20.20.212:2379, false
4ce4c031681be159, started, psql01, http://172.20.20.211:2380, http://172.20.20.211:2379, false
```

Stop the service:

```sh
systemctl stop etcd
```

Clean up local data:

```sh
rm -rf /var/lib/etcd/postgresql
```

Re-add the node to the cluster from a healthy node:

```sh
etcdctl --endpoints=http://172.20.20.211:2379 member add <node> --peer-urls="http://172.20.20.213:2380"

 ~  #  etcdctl member add psql03 --peer-urls=http://172.20.20.213:2380
Member 5a02ef771c6f4905 added to cluster 84a78972d1659e7b

ETCD_NAME="psql03"
ETCD_INITIAL_CLUSTER="psql02=http://172.20.20.212:2380,psql01=http://172.20.20.211:2380,psql03=http://172.20.20.213:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://172.20.20.213:2380"
ETCD_INITIAL_CLUSTER_STATE="existing"
```

Restart etcd on node:

```sh
systemctl restart etcd
```






# Postgres Set up

```bash
sudo apt-get update -y; sudo apt-get install -y wget gnupg2 lsb-release curl
```

Install the percona-release repository management tool to subscribe to Percona repositories:

```bash
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
sudo apt update
```

Enable repository:
Percona provides two repositories for Percona Distribution for PostgreSQL. Percona recommend enabling the Major release repository to timely receive the latest updates. 

```bash
sudo percona-release setup ppg-17
```

The meta package enables you to install several components of the distribution in one go.

```bash
sudo apt install percona-ppg-server-17

psql --version
sudo systemctl status postgresql.service
ss -lnt
```

**An important concept to understand** in a PostgreSQL HA environment like this one is that PostgreSQL should not be started automatically by systemd during the server initialization: we should leave it to Patroni to fully manage it, including the process of starting and stopping the server. Thus, we should disable the service:

```bash
systemctl disable postgresql
```

(all nodes) We want to start with a fresh new PostgreSQL setup and let Patroni bootstrap the cluster, so we stop the server and remove the data directory that has been created as part of the PostgreSQL installation:

```bash
sudo systemctl stop postgresql
sudo rm -fr /var/lib/postgresql/17/main
```

# Patroni 

When Patroni starts, it will take care of initializing PostgreSQL (because the service is not currently running and the data directory is empty) following the directives in the bootstrap section of Patroni’s configuration file. If everything went according to the plan, you should be able to connect to PostgreSQL using the credentials in the configuration file.

```sh
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql
```

1. Install Patroni service. You need to install extra package required for connecting to etcd.

```sh
apt install percona-patroni
apt install python3-etcd3

sudo mkdir -p /var/log/patroni
sudo chown postgres:postgres /var/log/patroni
sudo chmod 755 /var/log/patroni

sudo mkdir -p /var/run/postgresql
sudo chown postgres:postgres /var/run/postgresql
sudo chmod 775 /var/run/postgresql
```

2. Enable Patroni service

`systemctl enable patroni` 
`cat /usr/lib/systemd/system/patroni.service` 

3. Create configuration file and required directories for patroni:

```sh
mkdir -p /etc/patroni/logs/ #directory to store logs
chmod 777 /etc/patroni/logs 
```

4. Create config file for patroni as below (if you installed patroni from percona's repository, the config file should be called `/etc/patroni/patroni.yml`).

`touch /etc/patroni/patroni.yml` 

NOTE: Config to fresh install

```sh
scope: psqlcluster01
name: psql01

log:
  traceback_level: INFO
  level: INFO
  dir: /var/log/patroni
  file_num: 5

restapi:
  listen: 0.0.0.0:8008
  connect_address: psql01:8008

etcd3:
  protocol: http
  hosts: 172.20.20.211:2379,172.20.20.212:2379,172.20.20.213:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        logging_collector: 'on'
        max_wal_senders: 5
        max_replication_slots: 5
        wal_log_hints: "on"

  initdb:  # Needs to be a list
    - encoding: UTF8
    - locale: en_US.UTF-8
    - data-checksums

  pg_hba:  # Add to pg_hba.conf after running 'initdb'
    - host replication replicator 172.20.20.211/32 md5
    - host replication replicator 127.0.0.1/32 trust
    - host all all 172.20.20.211/32 md5
    - host all all 0.0.0.0/0 md5

  post_bootstrap: /etc/patroni/post_bootstrap.sh

postgresql:
  listen: 0.0.0.0:5432
  connect_address: psql01:5432
  data_dir: "/var/lib/postgresql/17/main"
  bin_dir: "/usr/lib/postgresql/17/bin"
  pgpass: /tmp/pgpass0
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
  parameters:
    unix_socket_directories: '/var/run/postgresql'

watchdog:
  mode: required  # Allowed values: off, automatic, required
  device: /dev/watchdog
  safety_margin: 5

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
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
    password: admin
    options:  
      - createrole  
      - createdb  
  replicator:  
    password: replicator
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
    password: replicator
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
psql02:5432:*:replicator:replicator
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
    "name": "devpsql01"
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

# HAProxy: Install load balancer

[Reference](https://patroni.readthedocs.io/en/latest/rest_api.html#health-check-endpoints) 

A common implementation of high availability in a PostgreSQL environment makes use of a proxy: instead of connecting directly to the database server, the application will be connecting to the proxy instead, which will forward the request to PostgreSQL. When HAproxy is used for this, it is also possible to route read requests to one or more replicas, for load balancing. However, this is not a transparent process: the application needs to be aware of this and split read-only from read-write traffic itself. With HAproxy, this is done by providing two different ports for the application to connect.

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

Note there are two sections: primary, using port 5000, and standbys, using port 5001. All three nodes are included in both sections: that’s because they are all potential candidates to be either primary or secondary. For HAproxy to know which role each node currently has, it will send an HTTP request to port 8008 of the node: Patroni will answer. Patroni provides a built-in REST API support for health check monitoring that integrates perfectly with HAproxy for this:


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

It is useful to use a connection pool to handle large numbers of users without overwhelming PostgreSQL.
PgBouncer can be configured to work with a Patroni cluster, and in fact, it is a common practice for managing connections to the PostgreSQL cluster. PgBouncer acts as a proxy and connection pooler that distributes client requests to the nodes of the cluster according to the configuration and logic of Patroni (i.e., to the leader or followers).

Configuring PgBouncer in a Patroni Cluster:

| **Column**               | **Description**                                                                                                       |
|--------------------------|-----------------------------------------------------------------------------------------------------------------------|
| **database**             | The name of the database managed by PgBouncer.                                                                        |
| **total_xact_count**     | Total number of completed transactions processed since PgBouncer started.                                            |
| **total_query_count**    | Total number of completed queries processed since PgBouncer started.                                                 |
| **total_received**       | Total bytes received from clients (incoming).                                                                         |
| **total_sent**           | Total bytes sent to clients (outgoing).                                                                               |
| **total_xact_time**      | Total time, in microseconds, that client connections spent processing transactions in the backend.                    |
| **total_query_time**     | Total time, in microseconds, that client connections spent processing queries in the backend.                         |
| **total_wait_time**      | Total time, in microseconds, that client connections spent waiting to acquire a connection from the pool.             |
| **avg_xact_count**       | Average number of transactions completed per second.                                                                  |
| **avg_query_count**      | Average number of queries completed per second.                                                                      |
| **avg_recv**             | Average number of bytes received per second from clients.                                                             |
| **avg_sent**             | Average number of bytes sent per second to clients.                                                                   |
| **avg_xact_time**        | Average transaction duration in microseconds.                                                                         |
| **avg_query_time**       | Average query duration in microseconds.                                                                               |
| **avg_wait_time**        | Average wait time to acquire a connection from the pool, in microseconds.                                            |

## View real-time statistics

```bash
watch -n 5 "PGPASSWORD='' psql -h 127.0.0.1 -p 6432 -U postgres -d pgbouncer -c 'SHOW STATS;'"
```

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
- auth_user should be configured with a user that has access to the databases.
- Use transaction mode (pool_mode = transaction) to prevent connections from getting “stuck” during failovers or leader changes.

3. Create the userlist.txt file

Define the users that PgBouncer will use to authenticate with PostgreSQL. For example, in /etc/pgbouncer/userlist.txt:

- Example:

```sh
$  cat /etc/pgbouncer/userlist.txt
"postgres" "changeme"
"powerbi" "123456"
```

Relationship between users and databases:
- When a client connects to PgBouncer requesting a specific database, PgBouncer verifies the provided user credentials against userlist.txt.
- If the credentials are correct, PgBouncer opens a connection to the PostgreSQL server using the username provided by the client.

4. Configure Patroni to work with PgBouncer

Patroni needs to “inform” the load balancer (in this case, PgBouncer) about changes in node status. This is done through membership tags and custom scripts.
- Adjust the Patroni configuration in patroni.yml:

```sh
tags:
  nofailover: false
  noloadbalance: true  # Prevent redirecting traffic to followers if using PgBouncer only for the leader
```

- Optional: Use health scripts to monitor which node should receive traffic:
-	Set up a script in PgBouncer or a health check to redirect traffic to the leader.
- You can query the Patroni REST endpoint (http://:8008/) to check which node is the leader.

5. Configure clients to connect to PgBouncer

Instead of connecting directly to PostgreSQL, configure your applications to point to PgBouncer. For example:
- Host: <IP or DNS of PgBouncer>
- Port: 6432
- Database: mydb

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
- SHOW POOLS;: Information about the connection pools.
- SHOW STATS;: General statistics about connections and pools.
- SHOW CLIENTS;: Information about client connections.
- SHOW USERS;: Users connected to PgBouncer.
- SHOW CONFIG;: Current configuration parameters of PgBouncer.

## Connections

If you have PgBouncer configured and have also defined max_connections in Patroni, both configurations affect the system complementarily but independently.

Explanation of the behavior:
-	max_connections in Patroni (PostgreSQL): This value limits the maximum number of connections PostgreSQL can accept directly, whether from PgBouncer or any external client. This is an absolute limit for PostgreSQL.

If max_connections = 200, PostgreSQL will not accept more than 200 active simultaneous connections, including those from PgBouncer.
-	max_client_conn and default_pool_size in PgBouncer: These configurations control how PgBouncer handles client connections to PostgreSQL.
-	max_client_conn: Defines how many connections PgBouncer can accept from clients (applications).
-	default_pool_size: Defines how many connections PgBouncer keeps open with PostgreSQL for each database in the pool.

PgBouncer uses a pooling model, which means that multiple clients can share a single connection to PostgreSQL.

Which one takes precedence?

Both limits are important, but the effective limit is defined by max_connections in Patroni. PgBouncer can handle more clients (max_client_conn), but it can only open connections to PostgreSQL up to the limit defined in max_connections.

For example:
- If max_connections = 200 in Patroni and default_pool_size = 20 in PgBouncer, PgBouncer can only open 200 connections to PostgreSQL in total (if multiple databases are connected, the pool is distributed among them).
- If max_client_conn = 500 in PgBouncer, it can accept up to 500 client connections, but only 200 connections will be established to PostgreSQL at the same time.

How to optimize this configuration:
- Increase max_connections in Patroni if the server has enough capacity: Adjust the parameter in the patroni.yml file:

```yaml
postgresql:
  parameters:
    max_connections: 500
```

Restart Patroni to apply the changes.
- Configure default_pool_size in PgBouncer based on needs:
- Set a reasonable pool size based on the expected load.
- For example, if you expect 500 concurrent clients and have 200 available connections in PostgreSQL, a default_pool_size = 10 could be enough to distribute the load.
- Monitor connection usage: Use views like pg_stat_activity and PgBouncer statistics to ensure you’re not hitting the limits:

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
- HAProxy:
- Acts as the network-level load balancer, distributing incoming connections across the Patroni cluster nodes.
- Determines which node to send traffic to based on the node’s status (leader or follower).
- PgBouncer:
- Not a load balancer per se, but a connection pool manager.
- Reduces the load on PostgreSQL by reusing existing connections, especially in applications that generate many short-lived or burst connections.
- Complements HAProxy by optimizing the number of active connections on the cluster nodes.

Is it necessary to use both?

Yes, in many cases. Using PgBouncer alongside HAProxy is a common practice in high-load systems because they address different issues:
- HAProxy balances traffic between nodes.
- PgBouncer manages connections to a node, reducing the impact of many concurrent connections.

Without PgBouncer, every connection passing through HAProxy reaches PostgreSQL directly, which could overload the max_connections on the server.

Recommended Architecture
- HAProxy balances client connections to PgBouncer.
- PgBouncer resides on each PostgreSQL node, optimizing connection usage on that node.

The flow would be:

  Clients →  HAProxy →  PgBouncer (on each node) →  PostgreSQL

This allows:
- HAProxy to determine the correct node for connections.
- PgBouncer to limit and optimize connections to PostgreSQL.

## Configuration in a Combined Environment

1.	HAProxy Configuration

HAProxy is configured to route traffic to the leader or followers depending on usage:
- In the HAProxy configuration file (haproxy.cfg):

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
- In the PgBouncer configuration file (pgbouncer.ini):

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

- listen_port is the port where PgBouncer listens (matching the port configured in HAProxy).
- pool_mode is recommended as transaction for Patroni clusters, as it avoids issues with leader changes.

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
- The number of simultaneous connections in PostgreSQL (max_connections) is insufficient:
- Increase max_connections in Patroni to support more connections.
- PgBouncer will help optimize the use of these connections.
- The connection timeout is too short:
- Increase timeout values in HAProxy and PgBouncer to prevent connections from closing prematurely.

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
- Use PgBouncer to optimize connections at the node level.
- HAProxy remains the main load balancer between nodes.
- Adjust max_connections, timeouts, and pool sizes to support the load.

# Application side Configuration:

As we have two HAProxy servers application should be configured in such a way that it should point to both servers, submit the request to available server and if application does not support such case then you need to set up virtual IP which will point to available HAProxy server.


