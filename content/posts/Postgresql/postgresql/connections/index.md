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

# active connections

```sql
SELECT * FROM pg_stat_activity;
```

Check:
- state: Should be active for working connections. If you see many connections in idle, Pentaho might not be closing them properly.
- waiting: If true, there may be locks or concurrency issues.

# max_connections
Check the configured maximum limit:

```sql
SHOW max_connections;
```

If you are setting shared_buffers to 2GB, ensure that max_connections is adjusted accordingly. You can use this formula as a reference:
-	Total RAM * 0.25 = shared_buffers
-	Remaining RAM = work_mem, processes, etc.

max_connections: Assess the maximum number of connections you actually need. Too many active connections can impact performance. Use a higher value, but combine this with a connection pooler like PgBouncer if you need thousands of connections.

```sql
ALTER SYSTEM SET max_connections = '500';
```

# Handle many clients

If you expect to handle many clients, it is preferable to use PgBouncer with a high max_client_conn and adjust max_connections in Patroni according to the available resources.

PgBouncer can handle more clients (max_client_conn), but it can only open connections to PostgreSQL up to the limit defined by max_connections.

For example:
- If max_connections = 200 in Patroni and default_pool_size = 20 in PgBouncer, PgBouncer can only open 200 connections to PostgreSQL in total (if connecting to multiple databases, the pool is split among them).
- If max_client_conn = 500 in PgBouncer, it can accept up to 500 client connections, but only 200 connections will be established to PostgreSQL at the same time.

1. Increase max_connections in Patroni

```yaml
postgresql:
  parameters:
    max_connections: 500
```

2. Configure default_pool_size in PgBouncer based on needs:

Set a reasonable pool size based on the expected load.
For example, if you expect 500 concurrent clients and have 200 connections available in PostgreSQL, a default_pool_size = 10 might be sufficient to distribute the load.

3. Monitor connection usage:

Use views like pg_stat_activity and PgBouncer statistics to ensure you are not reaching the limits.

```sql
SELECT * FROM pg_stat_activity;
```

Connect to PgBouncer:

```bash
psql -h <pgBouncer_host> -p 6432 -U <user> pgbouncer
SHOW POOLS;
```
