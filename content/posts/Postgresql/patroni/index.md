---
Title: Postgresql HA with Patroni
date: 
categories:
- Postgresql
tags:
- postgresql
- ha
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

# What does Patroni do

