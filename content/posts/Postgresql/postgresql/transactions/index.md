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

## Deactivate or minimize the impact of locking

a. Change the transaction isolation level:

If the transaction doesn’t require a high level of isolation, you might consider changing the isolation level to a less restrictive one, such as READ COMMITTED (default level) or READ UNCOMMITTED.

```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

b. Use a concurrency model based on MVCC:

PostgreSQL already uses MVCC (Multiversion Concurrency Control). Check if the locking occurs due to other long transactions holding unnecessary locks.

If a transaction is trying to acquire an exclusive lock (ACCESS EXCLUSIVE MODE) on the table, which blocks any other operation on that table until the transaction is completed. 

c. Redefine the access policies for the table:

You can change the permissions of users or processes attempting to apply locks on the table to restrict who can use LOCK.

## Use partitioning or temporary tables

If your process needs to process data in a table, consider using partitions or temporary tables.
This can reduce the need to lock the entire table.

Example: Temporarily move data to a table before performing the operation.

```sql
CREATE TEMP TABLE temp_logjob AS SELECT * FROM <scheme>.<table> WHERE <conditions>;
```

## 	Review indexes and schemas
Make sure the table is optimized and has the correct indexes to avoid prolonged locks due to operations that take too long.
If the table is small and the issue persists, reviewing its design (such as avoiding UNIQUE or FOREIGN KEYS in certain cases) might be helpful.

- Modify server behavior: Global configuration

In the PostgreSQL configuration file (postgresql.conf), you can adjust parameters related to locking.

Example:
- deadlock_timeout: Reduces the time PostgreSQL takes to detect lock conflicts.
- lock_timeout: Sets a timeout for acquiring locks.

```sql
SET lock_timeout = '5s';
```

# Locking parameters

- View all lock-related parameters

```sql
SELECT 
    name, 
    setting, 
    unit, 
    category, 
    short_desc 
FROM 
    pg_settings 
WHERE 
    name LIKE '%lock%' OR name LIKE '%deadlock%' OR name LIKE '%timeout%' OR name LIKE '%concurrent%';
```

| Parameter                            | Description                                                                 |
|--------------------------------------|-----------------------------------------------------------------------------|
| `max_locks_per_transaction`          | Maximum number of locks that a single transaction can acquire.              |
| `deadlock_timeout`                   | Time PostgreSQL waits before checking for a deadlock.                        |
| `lock_timeout`                       | Maximum time a transaction will wait to acquire a lock before failing.      |
| `idle_in_transaction_session_timeout`| Timeout for an idle session in an open transaction.                         |
| `statement_timeout`                  | Maximum time a SQL statement can run before being canceled.                 |
| `max_connections`                    | Maximum number of concurrent connections the server accepts, which can influence locks. |
| `vacuum_defer_cleanup_age`           | Number of deferred transactions to avoid cleaning old versions that block queries. |

# Transactions parameters

[Reference](https://www.postgresql.org/docs/17/runtime-config-client.html) 

- transaction_timeout (integer)
  Terminate any session that spans longer than the specified amount of time in a transaction. The limit applies both to explicit transactions (started with BEGIN) and to an implicitly started transaction corresponding to a single statement. If this value is specified without units, it is taken as milliseconds. A value of zero (the default) disables the timeout.
  If transaction_timeout is shorter or equal to idle_in_transaction_session_timeout or statement_timeout then the longer timeout is ignored.
  Setting transaction_timeout in postgresql.conf is not recommended because it would affect all sessions.

# Restart point starting

A "restart point" is similar to a "checkpoint" in a functioning database, but it occurs when the database is in recovery mode (e.g., during a recovery process after a failure).

- Restart point complete:
  This line details the statistics of what PostgreSQL did during the restart point:

- lsn=1D/96012DE0, redo lsn=1D/96012D88:
    LSN (Log Sequence Number): A number indicating a position in the WAL file. It marks where this restart point was completed.
    Redo LSN: Indicates the oldest position in the WAL from where records need to be replayed.

- Recovery restart point at 1D/96012D88
  This confirms that the restart point was set at LSN 1D/96012D88.
  The database will be able to recover quickly from this point without needing to process earlier records in the WAL.

The restart point helps reduce recovery time by creating a "safe point" from which the database can quickly restart in the event of subsequent failures.
