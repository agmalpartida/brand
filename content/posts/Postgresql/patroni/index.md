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
summary: High Availability Postgresql cluster
comments: false
showMeta: false
showActions: false
---

# Overview
[Reference](https://patroni.readthedocs.io/en/latest/) 

Patroni is best candidate to choose for HA and DR setup. Also if you know little bit of Python you can easily read the code and change it according to your needs. Patroni also provides REST APIs to automate things on top of the existing functionalities.

Patroni is open source HA template for PostgreSQL written in Python which can be deployed easily on Kubernetes or VMs. It can be integrated with ETCD, Consul or Zookeeper as consensus store.

When the leader is down, one of the replicas will be chosen as the new leader with the help of etcd.
This configuration may be extended to include more replicas, and pgbouncer can be used to pool connections to the database.

Patroni is open source library and does not come with enterprise support, you need to depend on open source community for any unforeseen issues or bugs. Although there are managed services available for Patroni.

Solution Architecture:
Here we have used 8 VMs to avoid SPOF and achieve High Availability on Postgres.

![patroni](./images/patroni-architecture.png) 

# What does Patroni do?

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

# Software & Hardware

## [ETCD](https://etcd.io/) 

- Distributed Consensus Store (DCS): Patroni requires a DCS system, such as ETCD, Consul, or Zookeeper, to store vital configuration data and real-time status information of the nodes. We will use odd number (>1) of servers here we are using 3 nodes with minimum configuration.

Etcd stores the state of the PostgreSQL cluster. When any changes in the state of any PostgreSQL node are found, Patroni updates the state change in the ETCD key-value store. ETCD uses this information to elect the master node and keep the cluster up and running.
The process of electing a leader involves making an attempt in Etcd to set an expired key. The primary database is determined to be the PostgreSQL instance that, via its bot, sets the Etcd key first. Etcd utilizes a Raft-based consensus method to guard against the occurrence of race situations. Following the receipt of confirmation that it is in possession of the key, a bot will configure the PostgreSQL instance to function as the primary database. The election of a primary will be visible to all other nodes, at which point their bots will configure their PostgreSQL instances to function as replicas.

- Use a larger Etcd cluster to improve availability: if one Etcd node fails, it will not affect our Postgres servers.
- Use **PgBouncer** to pool connections.

## HAProxy
- Load Balancer (e.g., HAProxy): A crucial element in the setup is a load balancer, like HAProxy. It plays a pivotal role in distributing incoming traffic across the PostgreSQL instances, ensuring all traffic should go to only master node. We will use two machines with minimum configuration - you can also utilize 1 HAProxy server but in this case we need to compromise on single point of failure.

HAProxy monitors changes in the master/slave nodes and connects to the appropriate master node when clients request a connection. HAProxy determines which node is the master by calling the Patroni REST API. The Patroni REST API is configured to run on port 8008 in each database node.
Failover Times: Failover times may not always be instantaneous, depending on the cluster’s state and the reasons for failover. There may be a short period of unavailability while a new leader is elected and the cluster is reconfigured.

## PostgreSQL 

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


