---
Title: Postgresql Transactions
date: 2024-12-20
categories:
- Postgresql
tags:
- postgresql
keywords:
- postgresql
summary: ""
comments: false
showMeta: false
showActions: false
---

# Kill transactions

To review and terminate (kill) active transactions in PostgreSQL, you can use the system views pg_stat_activity and the function pg_terminate_backend.

```sql
SELECT pid, usename, datname, application_name, client_addr, backend_start, state
FROM pg_stat_activity;

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE pid = <your_pid>;
```

If you want to kill all inactive transactions that have been open for more than 10 minutes, you can do something like this:

```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle in transaction'
  AND now() - query_start > interval '10 minutes'
  AND pid <> pg_backend_pid();
```

pg_stat_activity can show connections that are waiting for locks. If you experience frequent locking, you can investigate which queries are causing these locks using:

```sql
SELECT * 
FROM pg_locks 
WHERE granted = 'f';
```

This will provide information about locks that have not been granted.

If you find locks identify the responsible queries and consider optimizing them.

# Locking

This shows the active locks in your database and who is waiting to acquire one. Once the transaction containing the LOCK is completed (either with a COMMIT or a ROLLBACK), the lock is automatically released.

```sql
SELECT 
    pid, 
    locktype, 
    relation::regclass AS table_name, 
    mode, 
    granted
FROM 
    pg_locks
WHERE 
    NOT granted;
```

1.	Release a lock from the session holding it

If the lock is being held by your own session, you can release it by:

- Ending the transaction with COMMIT or ROLLBACK:

COMMIT; -- If you want to save the changes  
ROLLBACK; -- If you want to undo the changes  

- Closing the connection: If the transaction's connection is closed, PostgreSQL automatically releases the associated locks.


2.	Identify and release locks in other sessions

If the lock is caused by another session, you can identify it and release the responsible transaction:
Step 1: Identify the blocking process

Use the following query to identify the transaction and process holding the lock:

```sql
SELECT 
    pg_stat_activity.pid,
    pg_stat_activity.query AS query_actual,
    pg_locks.locktype,
    pg_locks.mode,
    pg_locks.relation::regclass AS tabla,
    pg_stat_activity.state,
    pg_stat_activity.application_name,
    pg_stat_activity.client_addr
FROM 
    pg_locks
JOIN 
    pg_stat_activity 
ON 
    pg_locks.pid = pg_stat_activity.pid
WHERE 
    NOT pg_locks.granted;
```

This shows the sessions that are waiting for locks.

If you need information about the processes holding the lock:

```sql
SELECT 
    pid, 
    query, 
    state, 
    application_name, 
    backend_start 
FROM 
    pg_stat_activity 
WHERE 
    state = 'active';
```

If you identify that an external process is causing the lock, you can forcibly terminate it with the following command:

```sql
SELECT pg_terminate_backend(<pid>);
```
