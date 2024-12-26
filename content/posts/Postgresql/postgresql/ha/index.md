---
Title: PSQL High Availability
date: 2024-12-26
categories:
- Postgresql
tags:
- postgresql
- ha
- patroni
keywords:
- postgresql
- patroni
- ha
summary: ""
comments: false
showMeta: false
showActions: false
---

# PostgreSQL HA With Patroni

Percona Distribution for PostgreSQL provides the best and most critical enterprise components from the open-source community, in a single distribution, designed and tested to work together.

[Reference](https://docs.percona.com/postgresql/17/) 

![HA](./assets/PostgreSQL_High_Availability.png) 

Components include:

- PostGIS support for geographic objects.
- pg_repack rebuilds PostgreSQL database objects. 
- pgAudit provides detailed session or object audit logging via the standard PostgreSQL logging facility.
- pgAudit set_user – The set_user part of pgAudit extension provides an additional layer of logging and control when unprivileged users must escalate themselves to superuser or object owner roles in order to perform needed maintenance tasks.
- pgBackRest is a backup and restore solution for PostgreSQL.
- Patroni is an HA (High Availability) solution for PostgreSQL.
- pg_stat_monitor collects and aggregates statistics for PostgreSQL and provides histogram information.
- PgBouncer – a lightweight connection pooler for PostgreSQL.
- pgBadger – a fast PostgreSQL Log Analyzer.
- wal2json – a PostgreSQL logical decoding JSON output plugin.
- HAProxy – a high-availability and load-balancing solution.
- etcd– a distributed, reliable key-value store for setting up highly available Patroni clusters
- pgpool-ll – a middleware between PostgreSQL server and client for high availability, connection pooling and load balancing.

# Failure Scenarios and How the Cluster Recovers From Them
By unplugging network and power cables, killing main processes, attempting to saturate processors. All of this while continuously writing and reading data from PostgreSQL. The idea was to see how Patroni would handle the failures and manage the cluster to continue delivering service.

