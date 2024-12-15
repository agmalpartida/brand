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

[Reference](https://www.postgresql.org/docs/current/runtime-config-client.html) 

While PostgreSQL's pg_hba.conf is the file responsible for restricting connections, when listen_addresses is set to * (wildcard), it is possible to discover the open port on 5432 using nmap and learn the database exists, thereby possibly opening the server up for an exploit. Setting it to the an IP address prevents PostgreSQL from listening on an unintended interface, preventing this potential exploit. 

# Monitoring and Continuous Optimization

Use tools like pg_stat_activity and pg_stat_database to monitor connection usage and adjust the values as needed:

```sql
SELECT * FROM pg_stat_activity;
SELECT datname, numbackends FROM pg_stat_database;
```

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

max_connections: Assess the maximum number of connections you actually need. Too many active connections can impact performance. Use a higher value, but combine this with a connection pooler like PgBouncer if you need thousands of connections.

```sql
ALTER SYSTEM SET max_connections = '500';
```

# shared_buffers

The shared_buffers parameter defines how much RAM is reserved for PostgreSQL operations. Increasing it can improve performance, especially if you increase connections.
If you are setting shared_buffers to 2GB, ensure that max_connections is adjusted accordingly. You can use this formula as a reference:
-	Total RAM * 0.25 = shared_buffers
-	Remaining RAM = work_mem, processes, etc.

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

# locks

It seems you're encountering a lock or access issue with your database, where multiple users or processes are trying to access the database "x" simultaneously. This usually occurs when the database is already being used for another query or transaction, causing delays or preventing new queries from running.

Here are a few ways to resolve or troubleshoot this:

- Check Active Queries: Use a command like pg_stat_activity in PostgreSQL to see if there are any long-running or blocking queries:

```sql
SELECT * FROM pg_stat_activity WHERE datname = '';
```

This will show you all the active sessions and queries. Look for ones that are holding locks or running for a long time.

- Terminate Blocking Queries: If you find a query that's taking too long or causing the block, you can terminate it (carefully) by identifying the pid of the process and then running:

```sql
SELECT pg_terminate_backend(<pid>);
```

- Locks Monitoring: You can also check for specific locks:

```sql
SELECT pg_terminate_backend(2010);
```

This will show you locks that are waiting to be granted, which may indicate which query or user is causing the conflict.

- Transaction Management: Ensure that you are managing transactions correctly, especially if multiple users are performing write operations at the same time. Long-running transactions should be avoided if possible.

- Timeouts and Retries: If it's a short-term contention issue, you might simply retry the query after a few moments.

- Drop connections to db:
```sql
SELECT pg_terminate_backend(pg_stat_activity.pid)
 FROM pg_stat_activity
 WHERE datname = 'db name'
  AND pid <> pg_backend_pid();
```

# Temporarily Suspending the Database

You can prevent users from working on a database by disconnecting it:

- Deny:
```sql
UPDATE pg_database SET datallowconn = false WHERE datname = 'nombre_db';
```

- Allow:
```sql
UPDATE pg_database SET datallowconn = true WHERE datname = 'nombre_db';
```

# Revoke privileges

```sql
REVOKE CONNECT ON DATABASE db_name FROM PUBLIC;
```

- Temporarily deny to user:

```sql
ALTER ROLE username NOLOGIN;
```

# Transaction timeouts
Value of 0 (zero): Disables this limit, allowing queries to run indefinitely.

- This value is in milliseconds and allows more time to complete the operations.
```sql
SET statement_timeout = 6000;
ALTER SYSTEM SET statement_timeout = '10min';
```

- It controls how long a transaction can remain open without activity before the server automatically closes it.
```sql
SHOW ALL
ALTER SYSTEM SET idle_in_transaction_session_timeout = '6000';
```

- Testing
```
postgres=# set idle_in_transaction_session_timeout = '10s';
SET
postgres=# set statement_timeout = '10s';
SET
postgres=# set transaction_timeout = '5s';
SET
postgres=# begin;
BEGIN
postgres=*# select pg_sleep(6);
```


