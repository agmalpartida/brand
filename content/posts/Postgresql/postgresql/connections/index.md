---
Title: PSQL Connections
date: 2024-12-15
categories:
- Postgresql
tags:
- postgresql
- connections
keywords:
- postgresql
summary: ""
comments: false
showMeta: false
showActions: false
---

# Overview

While PostgreSQL's pg_hba.conf is the file responsible for restricting connections, when listen_addresses is set to * (wildcard), it is possible to discover the open port on 5432 using nmap and learn the database exists, thereby possibly opening the server up for an exploit. Setting it to the an IP address prevents PostgreSQL from listening on an unintended interface, preventing this potential exploit. 

# View active connections

```sql
SELECT * FROM pg_stat_activity;
```

Check:
- state: Should be active for working connections. If you see many connections in idle, Pentaho might not be closing them properly.
- waiting: If true, there may be locks or concurrency issues.

Check the configured maximum limit:

```sql
SHOW max_connections;
```
