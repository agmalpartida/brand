---
Title: PSQL Percona Monitoring and Management
date: 2025-04-13
categories:
- Postgresql
tags:
- postgresql
- percona
keywords:
- postgresql
- pmm
- percona
summary: ""
comments: false
showMeta: false
showActions: false
---

# Overview

- [PMM](https://docs.percona.com/percona-monitoring-and-management/index.html) 
- [Quickstart](https://www.percona.com/software/pmm/quickstart) 
- [PMM HAProxy](https://docs.percona.com/percona-monitoring-and-management/setting-up/client/haproxy.html) 

# OPS

## Change the password for the default admin user.

```bash
docker exec -t pmm-server change-admin-password <new_password>
```

## Update 
- With Watchtower:
[watchtower](https://containrrr.dev/watchtower/) 

```bash
docker run -v /var/run/docker.sock:/var/run/docker.sock -e WATCHTOWER_HTTP_API_UPDATE=1 -e WATCHTOWER_HTTP_API_TOKEN=your_watchtower_token --hostname=your_watchtower_host --network=pmm_default docker.io/perconalab/watchtower
```

- PMM and clients:

```bash
pmm-admin update
```

## Check version

```bash
$  curl -ku admin:admin2024 https://localhost/v1/version
{
  "version": "2.43.1",
  "server": {
    "version": "2.43.1",
    "full_version": "2.43.1-20.2409250957.c8d4286.el9",
    "timestamp": "2024-09-25T09:57:50Z"
  },
  "managed": {
    "version": "2.43.1",
    "full_version": "c8d42862bd09e5c72f96d08a4368e8d4774db564",
    "timestamp": "2024-09-25T09:57:52Z"
  },
  "distribution_method": "DOCKER"
```

## Migrate from data container to host directory/volume

To migrate your PMM from data container to host directory or volume run the following command:

```bash
docker cp <containerId>:/srv /target/host/directory

$  docker inspect pmm-server | grep Destination
                "Destination": "/srv",
```

# PMM Client

## Install

[Reference](https://docs.percona.com/percona-monitoring-and-management/quickstart/index.html#install-pmm) 

```bash
wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb
dpkg -i percona-release_latest.generic_all.deb
apt update
apt install -y pmm2-client
```

## Register PMM Client:

```bash
pmm-admin config --server-insecure-tls --server-url=https://admin:admin@172.20.20.200:443 --force
```

## HAProxy

- Register PMM Client:

```bash
pmm-admin config --server-insecure-tls --server-url=https://admin:admin2024@10.201.217.184:443
```

- (over haproxy.cfg)

```
listen stats
    mode http
    bind *:7000
    http-request use-service prometheus-exporter if { path /metrics }
    stats enable
    stats uri /stats
    stats refresh 10s
```

Run the command below, specifying the `listen-port`` as the port number where HAProxy is running. (This flag is mandatory.)

```bash
pmm-admin add haproxy --listen-port=7000
pmm-admin add haproxy --listen-port=7000 --metrics-path=/metrics --scheme=http psqlhaproxy01
pmm-admin add haproxy --listen-port=7000 --metrics-path=/metrics --scheme=http psqlhaproxy02
```

## PostgreSQL

To connect a PostgreSQL database:

Create a PMM-specific user for monitoring:

```sql
CREATE USER pmm WITH SUPERUSER ENCRYPTED PASSWORD 'changeme';
```

Ensure that PMM can log in locally as this user to the PostgreSQL instance. To enable this, edit the pg_hba.conf file. If not already enabled by an existing rule, add:

```
host    all             pmm         10.201.217.184/32        md5
# TYPE  DATABASE        USER        ADDRESS                METHOD
```

```bash
sudo pmm-admin add postgresql --username=<usuario_postgres> --password=<contraseña> --host=<host_postgres> --port=<puerto_postgres>

$  sudo pmm-admin add postgresql --username=postgres --password=postgres --host=10.201.217.181 --port=5432
PostgreSQL Service added.
Service ID  : /service_id/9b25e086-cf8a-4aa6-8d2b-fed27ecc7c5f
Service name: psqltest01-postgresql
```

- Before over database (CREATE EXTENSION pg_stat_monitor;)

```bash
pmm-admin add postgresql --username=postgres --password=postgres --host=10.201.217.181 --port=5432 --database=<db_name> --service-name=<service name>
```

- For pg_stat_monitor

```bash
pmm-admin add postgresql --username=postgres --password=postgres --host=10.201.217.181 --port=5432 --database=<db_name> --query-source=pgstatmonitor --service-name=<service name>
```

- Specify the source of queries: If you want to use the pg_stat_statements extension to track queries, make sure to include the -–query-source=pgstatstatements parameter.

```bash
sudo pmm-admin add postgresql --username=postgres --password=<contraseña> --host=localhost --port=5432 --query-source=pgstatstatements
```

# Patroni: Adding the Patroni metrics to PMM

Since version 2.1.0, Patroni exposes metrics in a Prometheus-compatible way via the /metrics endpoint:

This means that we can instantly benefit from them by using the PMM External Exporters feature:

https://docs.percona.com/percona-monitoring-and-management/setting-up/client/external.html

In a nutshell, we just need to run the following in each client node:

```bash
pmm-admin add external --listen-port=8008 --service-name=pg-nodeX-patroni
```

Where -–service-name can be whatever naming scheme you want that lets you easily know which Patroni node it refers to.

After running these commands and waiting some seconds, we should see metrics incoming in the Advanced Data Exploration dashboard, like the patroni_primary one.

In the headers, we can see information about a node in particular (the one selected in the service_name drop-down list):

Patroni information like version, communication with the DCS, if it’s the current leader, etc.
PostgreSQL information like version, if it’s running, its timeline number, etc.

Then we have the Patroni section, with graphs showing which were the Patroni primary and replica nodes at any time.

Finally, we have a PostgreSQL section, with graphs showing which were the PostgreSQL primary and replica nodes at any time and information on WAL generation and application.


# Troubleshooting

```bash
$  pmm-admin list
Service type        Service name              Address and port           Service ID
PostgreSQL          testing-postgresql        10.201.217.180:5000        /service_id/30dbd3f5-7ce6-4f7b-84ab-696bd49ad7f8

Agent type                            Status           Metrics Mode        Agent ID                                              Service ID                                              Port
pmm_agent                             Connected                            /agent_id/67817e23-11d1-45d9-b6bc-441535e91ab6                                                                0
node_exporter                         Running          push                /agent_id/bcfb4feb-f7b4-4bb3-887c-44284c40fa68                                                                42001
postgres_exporter                     Running          push                /agent_id/acd04a31-14c2-4ac2-92da-ae2ef201be7b        /service_id/30dbd3f5-7ce6-4f7b-84ab-696bd49ad7f8        42002
postgresql_pgstatmonitor_agent        Running                              /agent_id/d0cb977e-0281-4fcc-80db-37ac425c6d65        /service_id/30dbd3f5-7ce6-4f7b-84ab-696bd49ad7f8        0
vmagent                               Running          push                /agent_id/689dda00-53de-458a-a537-b8fdb1f533a8                                                                42000
```

```bash
$  pmm-admin status
Agent ID : /agent_id/16d2e0be-5e4d-4500-814b-b90ca526aff7
Node ID  : /node_id/18a92504-13f6-44f8-a81d-75cedf97de70
Node name: psqltest01

PMM Server:
        URL    : https://10.201.217.184:443/
        Version: 2.43.1

PMM Client:
        Connected        : true
        Time drift       : 3.84701ms
        Latency          : 382.929µs
        Connection uptime: 100
        pmm-admin version: 2.43.1
        pmm-agent version: 2.43.1
Agents:
        /agent_id/b9485cab-1118-4a38-b7d0-cada847e89b4 vmagent Running 42000
        /agent_id/e56de27c-6606-42fa-ad66-a83f376be9d0 postgresql_pgstatmonitor_agent Waiting 0
        /agent_id/f32a3c89-c047-448d-9e3e-86132e07f7b0 node_exporter Running 42001
        /agent_id/f45b74f5-bea3-46a0-8d9c-fb53a6389f82 postgres_exporter Running 42002


systemctl status pmm-agent
journalctl -u pmm-agent

sudo pmm-admin check-network
```

# SMTP

## SMTP

[Reference](https://docs.percona.com/percona-monitoring-and-management/get-started/alerting.html#configure-email-smtp-server-settings) 

SMTP settings can be found inside the container of pmm-server. Connect to the container as below:

```bash
docker ps
CONTAINER ID   IMAGE                  COMMAND                CREATED          STATUS                    PORTS                                           NAMES
acc4046ec4ba   percona/pmm-server:2   "/opt/entrypoint.sh"   36 minutes ago   Up 36 minutes (healthy)   80/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp   pmm-server

docker exec -it pmm-server bash

[root@acc4046ec4ba opt] # cd /etc/grafana/
[root@acc4046ec4ba grafana] # ls
grafana.ini  ldap.toml

enabled=true
host=smtp.gmail.com:587
user=<user@email-id>
password=<app-password>
skip_verify=false
from_address=<from-address@mail-id>
from_name=<Name of the alert, could be any>
```

Once, done, restart the PMM-Server container with:

```bash
docker restart pmm-server
```

- Configure Email (SMTP) server settings

To use SMTP with a PMM Docker installation:

Create an .env file and populate it with your SMTP credentials (and other environment variables) as follows: 

```
GF_SMTP_ENABLED=true  
GF_SMTP_HOST=smtp.gmail.com:587
GF_SMTP_USER=email@domain.com
GF_SMTP_PASSWORD=<YOUR_SMTP_PASSWORD>
GF_SMTP_SKIP_VERIFY=false
GF_SMTP_FROM_ADDRESS=email@domain.com
GF_SMTP_FROM_NAME=Percona Alerting
```

Pass in the .env file to Docker run using the --env-file flag:

```bash
docker run --env-file=.env -p 443:443 -p 80:80 percona/pmm-server:2
```
