---
Title: PSQL Percona Monitoring and Management
date: date
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
pmm-admin config --server-insecure-tls --server-url=https://admin:admin@172.20.20.200:443
```

## HAProxy

Run the command below, specifying the `listen-port`` as the port number where HAProxy is running. (This flag is mandatory.)

```bash
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

