---
Title: Postgresql HA with Patroni
date: 2024-09-01
categories:
- Postgresql
tags:
- postgresql
- ha
- etcd
keywords:
- sql
summary: "High Availability Postgresql cluster"
comments: false
showMeta: false
showActions: false
---

# High Availability in PostgreSQL with Patroni

## Overview

[Reference](https://patroni.readthedocs.io/en/latest/) 

PostgreSQL has been widely adopted as a modern, high-performance transactional database. A highly available PostgreSQL cluster can withstand failures caused by network outages, resource saturation, hardware failures, operating system crashes or unexpected reboots. Such cluster is often a critical component of the enterprise application landscape, where four nines of availability is a minimum requirement. 

Is a template for you to create your own customized, high-availability solution using Python and - for maximum accessibility - a distributed configuration store like ZooKeeper, etcd, Consul or Kubernetes.

Patroni is best candidate to choose for HA and DR setup. Also if you know little bit of Python you can easily read the code and change it according to your needs. Patroni also provides REST APIs to automate things on top of the existing functionalities.

Patroni is open source HA template for PostgreSQL written in Python which can be deployed easily on Kubernetes or VMs. It can be integrated with ETCD, Consul or Zookeeper as consensus store.

When the leader is down, one of the replicas will be chosen as the new leader with the help of etcd.
This configuration may be extended to include more replicas, and pgbouncer can be used to pool connections to the database.

Patroni is open source library and does not come with enterprise support, you need to depend on open source community for any unforeseen issues or bugs. Although there are managed services available for Patroni.

- Solution Architecture:
Here we have used 8 VMs to avoid SPOF and achieve High Availability on Postgres.

![patroni](./images/patroni-architecture.png) 

Key benefits of Patroni:

- Continuous monitoring and automatic failover
- Manual/scheduled switchover with a single command
- Built-in automation for bringing back a failed node to cluster again.
- REST APIs for entire cluster configuration and further tooling.
- Provides infrastructure for transparent application failover
- Distributed consensus for every action and configuration.
- Integration with Linux watchdog for avoiding split-brain syndrome.

- Architecture layout

The following diagram shows the architecture of a three-node PostgreSQL cluster with a single-leader node.

![](./images/ha-architecture-patroni.png) 

- Components

The components in this architecture are:

- PostgreSQL nodes
- Patroni - a template for configuring a highly available PostgreSQL cluster.
- etcd - a Distributed Configuration store that stores the state of the PostgreSQL cluster.
- HAProxy - the load balancer for the cluster and is the single point of entry to client applications.
- pgBackRest - the backup and restore solution for PostgreSQL
- Percona Monitoring and Management (PMM) - the solution to monitor the health of your cluster

- How components work together

Each PostgreSQL instance in the cluster maintains consistency with other members through streaming replication. Each instance hosts Patroni - a cluster manager that monitors the cluster health. Patroni relies on the operational etcd cluster to store the cluster configuration and sensitive data about the cluster health there.

Patroni periodically sends heartbeat requests with the cluster status to etcd. etcd writes this information to disk and sends the response back to Patroni. If the current primary fails to renew its status as leader within the specified timeout, Patroni updates the state change in etcd, which uses this information to elect the new primary and keep the cluster up and running.

The connections to the cluster do not happen directly to the database nodes but are routed via a connection proxy like HAProxy. This proxy determines the active node by querying the Patroni REST API.

```py
$  pip show patroni
Name: patroni
Version: 4.0.1
Summary: PostgreSQL High-Available orchestrator and CLI
Home-page: https://github.com/patroni/patroni
Author: Alexander Kukushkin, Polina Bungina
Author-email: akukushkin@microsoft.com, polina.bungina@zalando.de
License: The MIT License
Location: /usr/lib/python3/dist-packages
```


## What does Patroni do?

Basically, everything you need to run highly available PostgreSQL clusters!
Patroni creates the cluster, initiates streaming replication, handles synchronicity requirements, monitors liveliness of primary and replica, can change the configuration of all cluster members, issues reload commands and restarts selected cluster members, handles planned switchovers and unplanned failovers, rewinds a failed primary to bring it back in line and reinitiates all replication connections to point to the newly promoted primary.

Patroni is engineered to be very fault tolerant and stable; By design, split-brain scenarios are avoided. Split-brain occurs when two members of the same cluster accept writing statements.
It guarantees that certain conditions are always fulfilled and despite the automation of so many complex tasks, it shouldn't corrupt the database cluster nor end in a situation where recovery is impossible.
**For example** , Patroni can be told never to promote a replica that is lagging behind the primary by more than a configurable amount of log.

It also fulfils several additional requirements; for example, certain replicas should never be considered for promotion if they exist only for the purpose of archiving or data lake applications and not business operations.

The architecture of Patroni is such that every PostgreSQL instance is accompanied by a designated Patroni instance that monitors and controls it.

All of the data that Patroni collects is mirrored in a distributed key-value store, and based on the information present in the store, all Patroni instances agree on decisions, such as which replica to promote if the primary has failed.
The distributed key-value store, for example etcd or consul, enables atomic manipulation of keys and values. This forwards the difficult problem of cluster consensus (which is critical to avoid the split-brain scenario) to battle tested components, proven to work correctly even under the worst circumstances.

Some of the data collected by Patroni is also exhibited through a ReST interface, which can be useful for monitoring purposes as well as for applications to select which PostgreSQL instance to connect to.

## High availability methods

Why native streaming replication is not enough

Although the native streaming replication in PostgreSQL supports failing over to the primary node, it lacks some key features expected from a truly highly-available solution. These include:

- No consensus-based promotion of a “leader” node during a failover
- No decent capability for monitoring cluster status
- No automated way to bring back the failed primary node to the cluster
- A manual or scheduled switchover is not easy to manage

To address these shortcomings, there are a multitude of third-party, open-source extensions for PostgreSQL. The challenge for a database administrator here is to select the right utility for the current scenario.

Percona Distribution for PostgreSQL solves this challenge by providing the Patroni extension for achieving PostgreSQL high availability.

There are several native methods for achieving high availability with PostgreSQL:

- shared disk failover,
- file system replication,
- trigger-based replication,
- statement-based replication,
- logical replication,
- Write-Ahead Log (WAL) shipping, and
- streaming replication


![](./images/4nines.png) 

# Software & Hardware

# [ETCD](https://etcd.io/) 

- Distributed Consensus Store (DCS): Patroni requires a DCS system, such as ETCD, Consul, or Zookeeper, to store vital configuration data and real-time status information of the nodes. We will use odd number (>1) of servers here we are using 3 nodes with minimum configuration.

Etcd stores the state of the PostgreSQL cluster. When any changes in the state of any PostgreSQL node are found, Patroni updates the state change in the ETCD key-value store. ETCD uses this information to elect the master node and keep the cluster up and running.
The process of electing a leader involves making an attempt in Etcd to set an expired key. The primary database is determined to be the PostgreSQL instance that, via its bot, sets the Etcd key first. Etcd utilizes a Raft-based consensus method to guard against the occurrence of race situations. Following the receipt of confirmation that it is in possession of the key, a bot will configure the PostgreSQL instance to function as the primary database. The election of a primary will be visible to all other nodes, at which point their bots will configure their PostgreSQL instances to function as replicas.

- Use a larger Etcd cluster to improve availability: if one Etcd node fails, it will not affect our Postgres servers.
- Use **PgBouncer** to pool connections.

# HAProxy
- Load Balancer (e.g., HAProxy): A crucial element in the setup is a load balancer, like HAProxy. It plays a pivotal role in distributing incoming traffic across the PostgreSQL instances, ensuring all traffic should go to only master node. We will use two machines with minimum configuration - you can also utilize 1 HAProxy server but in this case we need to compromise on single point of failure.

HAProxy monitors changes in the master/slave nodes and connects to the appropriate master node when clients request a connection. HAProxy determines which node is the master by calling the Patroni REST API. The Patroni REST API is configured to run on port 8008 in each database node.
Failover Times: Failover times may not always be instantaneous, depending on the cluster’s state and the reasons for failover. There may be a short period of unavailability while a new leader is elected and the cluster is reconfigured.

# PostgreSQL 

Version 9.5 and Above: Patroni seamlessly integrates with PostgreSQL versions 9.5 and higher, providing advanced features and reliability enhancements. This compatibility ensures that you can leverage the latest capabilities of PostgreSQL while maintaining high availability. Hardware configuration for these nodes is dependent on the database size. For setting up you can start with 2 cores and 8GB RAM.

Deploying three PostgreSQL servers instead of two adds an extra layer of protection, safeguarding against multi-node failures and bolstering system reliability.

![patroni](./images/patroni-architecturei2.png) 

# Patroni common operations

Patroni comes with CLI utility called as **patronictl** . One can perform any admin operation related to Postgres database or cluster using this command line utility.

## patronictl edit-config

To edit postgres configuration parameters you can use edit-config command. It will open configuration file in editor, make the required changes and Patroni will validate all parameters before saving configuration file.

You can also add pg_hba entries to the configuration so these will be reflected all over the cluster.

💡If you directly update parameter values in Postgres configuration files it will be overwritten via Patroni configuration if same parameter is explicitly defined in patroni config.

- `/etc/patroni/patroin.yaml` is configuration file for patroni

`patronictl -c /etc/patroni/patroni.yaml edit-config` 

## patronictl reload

This command will reload parameters from configuration file and takes required action like restart on cluster nodes.
**When to use** : If you have changed parameters in configuration file using edit-config you can use reload command for parameters to take effect

```sh
# patroni_cluster is name of your cluster
patronictl -c /etc/patroni/patroni.yaml reload patroni_cluster
```

## patronictl switchover

It will make selected replica as master node basically will switch all traffic to new selected node. We can have planned switchover at particular time as well.
**When to use** : If you have maintenance for master node you can switchover master to another node in the cluster.

```sh
# It will ask for node to switchover and also time for switchover
patronictl -c /etc/patroni/patroni.yaml switchover
```

```sh
$  patronictl -c /etc/patroni/patroni.yml switchover

Current cluster topology
+ Cluster: psqlcluster01 (7438272857781061312) -+---------+-----------+----+-----------+
| Member                | Host                  | Role    | State     | TL | Lag in MB |
+-----------------------+-----------------------+---------+-----------+----+-----------+
| psql01.fullstep.cloud | psql01.fullstep.cloud | Replica | streaming | 39 |         0 |
| psql02.fullstep.cloud | psql02.fullstep.cloud | Leader  | running   | 39 |           |
| psql03.fullstep.cloud | psql03.fullstep.cloud | Replica | streaming | 39 |         0 |
+-----------------------+-----------------------+---------+-----------+----+-----------+
Primary [psql02.fullstep.cloud]:
Candidate ['psql01.fullstep.cloud', 'psql03.fullstep.cloud'] []: psql01.fullstep.cloud
When should the switchover take place (e.g. 2024-12-03T15:20 )  [now]:
Are you sure you want to switchover cluster psqlcluster01, demoting current leader psql02.fullstep.cloud? [y/N]: y
2024-12-03 14:20:54.93003 Successfully switched over to "psql01.fullstep.cloud"
+ Cluster: psqlcluster01 (7438272857781061312) -+---------+----------+----+-----------+
| Member                | Host                  | Role    | State    | TL | Lag in MB |
+-----------------------+-----------------------+---------+----------+----+-----------+
| psql01.fullstep.cloud | psql01.fullstep.cloud | Leader  | running  | 40 |           |
| psql02.fullstep.cloud | psql02.fullstep.cloud | Replica | stopping |    |   unknown |
| psql03.fullstep.cloud | psql03.fullstep.cloud | Replica | running  | 39 |         0 |
+-----------------------+-----------------------+---------+----------+----+-----------+
```


## patronictl pause

Patroni will stop managing postgres cluster and will turn on the maintenance mode. If you want to do some manual activities for maintenance you need to stop patroni from auto managing cluster.
**When to use** : If you want to put cluster in maintenance mode and manage Postgres database manually for some time, you can use pause command so that Patroni will stop managing the cluster

```sh
patronictl -c /etc/patroni/patroni.yaml pause
```

## patronictl resume

It will start the paused cluster management and remove the cluster from maintenance mode
**When to use** : If you want to turn off maintenance mode, you can use resume command and patroni will start managing the cluster

```sh
patronictl -c /etc/patroni/patroni.yaml resume
```

## patronictl list

List all nodes and it's role, status. You can use it for checking status of all nodes, which is the master and which all are slaves/replicas.
**When to use** : To check list and status of all nodes in the cluster, you can get all the information about nodes including if any restart is required for any node

```sh
patronictl -c /etc/patroni/patroni.yaml list
```

## patronictl restart

It will restart single node in the postgres cluster or all nodes(complete cluster). Patroni will do the rolling restart for postgres on all nodes.
**When to use** : Sometimes you need to restart all nodes in the cluster without downtime, you can use this command for rolling restart

```sh
# Restart particular node in cluster
patronictl -c /etc/patroni/patroni.yaml restart <CLUSTER_NAME> <NODE_NAME>
```

```sh
# Restart whole cluster(all nodes in cluster)
patronictl -c /etc/patroni/patroni.yaml restart <CLUSTER_NAME>
```

## patronictl reinit

It will reinitialize node in the cluster. If you want to reinitialize particular replica or slave node you can reinitialize node using reinit command.
**When to use** : patronictl reinit command allows you to reinitialize a specific node and can be utilized when a cluster node experiences failure in starting or displays an unknown status for the node in the cluster . It is often useful in cases where a node has corrupt data.

```sh
patronictl -c /etc/patroni/patroni.yaml reinit <CLUSTER_NAME> <NODE_NAME>
```

# 💡Pro-Tip:

Instead of using `-c /etc/patroni/patroni.yaml`  with patronictl you can set alias in your .profile file

`alias patronictl='patronictl -c /etc/patroni/patroni.yaml'` 


# API

Patroni’s API typically has an endpoint (/health) that allows you to check if a node is healthy, and within its response, it indicates whether the node is a leader or a replica.

Check the status of Patroni’s HTTP API on each node:
Use curl to manually check how each node (leader and replicas) responds on port 8008.

```sh
curl http://10.201.217.181:8008
```

Manual verification: Use curl to check the /leader and /replica endpoints or any other endpoints exposed by Patroni.

```sh
curl http://10.201.217.181:8008/leader
curl http://10.201.217.182:8008/replica
```

It is useful to verify that Patroni’s /health endpoint works correctly on each node.

```sh
curl http://172.20.20.211:8008/health|jq
curl http://172.20.20.212:8008/health|jq
curl http://172.20.20.213:8008/health|jq
```

# Cluster Node Status Overview

- Role:
	•	Description: This column indicates the node’s role within the cluster. Typical roles include:
	•	Leader: The leader node handles writes and coordinates with replicas.
	•	Replica: Nodes that replicate data from the leader.

- State:
	•	Description: Displays the current state of each node. Common states include:
	•	running: The node is operational and available.
	•	streaming: The node is receiving real-time data from the leader.

- TL (Timeline):
	•	Description: Indicates the current timeline of the node, crucial for data recovery and replication. In PostgreSQL, a new timeline is created when data divergence occurs. All nodes in the cluster must share the same timeline for replication to work.
	•	Example: If all nodes have a TL of 2, they are synchronized on the same timeline.

- Lag in MB:
	•	Description: Shows the amount of lag in megabytes that a replica has compared to the leader. A value of 0 means the replica is fully up-to-date.
	•	Example: If both replicas show 0 MB lag, they are receiving real-time data and are synchronized with the leader.

# Time-Line. Common Scenarios Involving Timelines

1.	Timeline Change Due to Failover or Bootstrap:
After a failover or cluster restart where a new leader is designated, a new timeline may be created. The new leader initiates this new timeline.
	
2.	Cluster Reinitialization:
If you initialize a new cluster using a bootstrap command after configuration changes, the process may create a new timeline, especially if the previous cluster state was deleted.

3.	Hot Standby and Replication Rules:
When a node is configured as a standby (replica), it synchronizes its timeline with the leader upon connection. If the leader changes timelines, the replicas adopt the new timeline.

4.	Database Snapshot:
During recovery or after a system crash, reverting to a previous state may lead to a timeline change.

5.	Diverging Timelines in Replicas:
If nodes sync with a leader that has a different database state, timeline changes may occur.
	•	Example: If all nodes now display TL = 3, they are synchronized on the same timeline.
	


# Troubleshooting

In Replica nodes, we cannot create anything; it will return an error.

```sh
$  psql -U postgres -h psql01 -p 5432 -c "CREATE ROLE admin WITH LOGIN PASSWORD 'V/\$QjLxf2022.-' CREATEDB CREATEROLE;"
Password for user postgres:
ERROR:  cannot execute CREATE ROLE in a read-only transaction
```

If we do it on the Leader:

```sh
psql -U postgres -h psql03 -p 5432 -c "CREATE ROLE admin WITH LOGIN PASSWORD 'V/\$QjLxf2022.-' CREATEDB CREATEROLE;"
Password for user postgres:
CREATE ROLE
```
