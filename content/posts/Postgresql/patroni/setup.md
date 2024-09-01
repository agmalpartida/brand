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


