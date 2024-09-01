---
Title: Patroni Set up
date: 
categories:
- Patroni
tags:
- posgresql
- patroni
- ha
- etc
keywords:
- sql
summary: Patroni cluster for Postgresql databases
comments: false
showMeta: false
showActions: false
---

# ETCD Installation and Configuration

`wget https://github.com/etcd-io/etcd/releases/download/v3.5.0/etcd-v3.5.0-linux-amd64.tar.gz` 

Once downloaded unzip and copy binaries to your /usr/bin

```sh
gtar –xvf etcd-v3.5.0-linux-amd64.tar.gz
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


# Patroni and Postgres Installation

```sh
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql
```

1. Install Patroni service

`pip install patroni` 

You need to install extra package required for connecting to etcd

`pip3 install python-etcd` 

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

5. Start Patroni

`service patroni start` 

Repeat same procedure on all three nodes, for any issues you can set `log.level` and `log.traceback_level` to **DEBUG**.
Once all nodes are up and running you can check status of patroni cluster using patronictl utility.

`patronictl -c /etc/patroni/patroni.yml list` 

Now patroni cluster is ready to use, you can start playing around and do some replication and failover tests.

After this we need to setup load balancer to point it to active (Leader) Postgres database. For this you need two HAProxy servers or if you are setting this on cloud you can use load balancers provided by cloud provider.

# Install load balancer

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

# Application side Configuration:

As we have two HAProxy servers application should be configured in such a way that it should point to both servers, submit the request to available server and if application does not support such case then you need to set up virtual IP which will point to available HAProxy server.


