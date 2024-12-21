---
Title: Postgresql pgBouncer
date: 2024-12-21
categories:
- Postgresql
tags:
- postgresql
- pgbouncer
keywords:
- postgresql
- pgbouncer
summary: ""
comments: false
showMeta: false
showActions: false
---

# pgBouncer

| **Column**               | **Description**                                                                                                       |
|--------------------------|-----------------------------------------------------------------------------------------------------------------------|
| **database**             | The name of the database managed by PgBouncer.                                                                        |
| **total_xact_count**     | Total number of completed transactions processed since PgBouncer started.                                            |
| **total_query_count**    | Total number of completed queries processed since PgBouncer started.                                                 |
| **total_received**       | Total bytes received from clients (incoming).                                                                         |
| **total_sent**           | Total bytes sent to clients (outgoing).                                                                               |
| **total_xact_time**      | Total time, in microseconds, that client connections spent processing transactions in the backend.                    |
| **total_query_time**     | Total time, in microseconds, that client connections spent processing queries in the backend.                         |
| **total_wait_time**      | Total time, in microseconds, that client connections spent waiting to acquire a connection from the pool.             |
| **avg_xact_count**       | Average number of transactions completed per second.                                                                  |
| **avg_query_count**      | Average number of queries completed per second.                                                                      |
| **avg_recv**             | Average number of bytes received per second from clients.                                                             |
| **avg_sent**             | Average number of bytes sent per second to clients.                                                                   |
| **avg_xact_time**        | Average transaction duration in microseconds.                                                                         |
| **avg_query_time**       | Average query duration in microseconds.                                                                               |
| **avg_wait_time**        | Average wait time to acquire a connection from the pool, in microseconds.                                            |
