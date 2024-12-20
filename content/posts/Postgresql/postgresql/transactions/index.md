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
