---
Title: PSQL Memory
date: 2024-12-27
categories:
- Postgresql
tags:
- postgresql
keywords:
- postgresql
- memory
summary: ""
comments: false
showMeta: false
showActions: false
---

# Parameters

- shared_buffers: The shared_buffers parameter defines how much RAM is reserved for PostgreSQL operations. Increasing it can improve performance, especially if you increase the number of connections.
PostgreSQL recommends setting shared_buffers to between 25% and 40% of the total RAM. With 128 GB of RAM, you can configure it to a value close to 32 GB or 40 GB, depending on system requirements and workload.

```sql
ALTER SYSTEM SET shared_buffers = '32GB';
```

- work_mem: Defines the memory allocated for temporary operations (such as sorting and joins) per session. Set it to a reasonable value based on your needs and the maximum number of connections.
Note: This value applies to each operation, so it should be adjusted if you have many concurrent sessions.

```sql
SHOW work_mem;
ALTER SYSTEM SET work_mem = '64MB';
```

- maintenance_work_mem: This is used for tasks such as index rebuilding and VACUUM. With 128 GB of RAM, an initial value could be:

```sql
ALTER SYSTEM SET maintenance_work_mem = '2GB';
```

- effective_cache_size: This is an estimate of how much of the operating system’s memory will be used for caching data. It does not allocate memory but informs the query planner. With 128 GB of RAM:

```sql
ALTER SYSTEM SET effective_cache_size = '96GB';
```
- autovacuum: Configure autovacuum to ensure that tables remain healthy. Adjust autovacuum_work_mem if the tables are large.

```
postgresql:
  parameters:
    autovacuum_work_mem: '1GB'
```

# Checking

```sql
SHOW shared_buffers;
SHOW work_mem;
SHOW maintenance_work_mem;
SHOW effective_cache_size;
SHOW max_connections;

free -h
ps aux --sort=-%mem | grep postgres
```
