---
Title: Postgresql HA with Patroni
date: 
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

