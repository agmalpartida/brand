---
Title: Postgresql Processes
date: 2024-12-21
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

# Parameters

- max_worker_processes: parallel processes. Usually, default value is low.

# Load stress with pgbench

[Reference](https://www.postgresql.org/docs/current/pgbench.html) 

pgbench is provided with postgres-client package.

```bash
pgbench -h <host> -U <user> -T 60 -c 10 -j 2 <dbname>
```

First step: Initialise db

The pgbench_branches table in the target database. This table is automatically created during initialisation with pgbench. To solve this problem, you need to initialise the database with the following command:
- `-i` initialise pgbench tables (pgbench_branches, pgbench_accounts, pgbench_tellers, etc.).

```bash
❯ pgbench -h 172.20.20.210 -p 5000 -U postgres -i <db_name>
dropping old tables...
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.20 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 1.22 s (drop tables 0.03 s, create tables 0.13 s, client-side generate 0.80 s, vacuum 0.14 s, primary keys 0.11 s).
```

## Parameters

- `-T 300`: Run the test for 300 seconds (5 minutes).
- `-c 200`: Use 200 concurrent clients. You can increase or decrease it according to the desired stress level.
- `-j 50`: Use 50 threads. Increasing the threads helps to take advantage of the available CPU cores.
- `-S`: Executes SELECT queries (reads) only. If you want to perform reads and writes, omit this parameter.
- `-C`: Each transaction uses a new connection. This can stress both the network and the connection handler.
- `-M prepared`: Uses prepared statements, which can improve performance by reducing the cost of query parsing.

