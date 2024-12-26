---
Title: Postgresql Scheme
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

# Databases and Schemas in PostgreSQL

In PostgreSQL, a "cluster" does not refer to a group of networked servers (as it might in other databases or distributed systems). Instead, a cluster in PostgreSQL refers to a set of databases that share the same data directory, a common configuration, and are managed by a single PostgreSQL server instance.

1. Dedicated Data Directory

The cluster is defined by a data directory initialized with initdb. This directory contains:

- Configuration files:
  - postgresql.conf: Main server configuration (port, memory, etc.).
  - pg_hba.conf: User authentication configuration.
- Control files:
  - pg_control: Tracks the cluster's state.
- Database data:
  - Subdirectories for each database created within the cluster.

2. PostgreSQL Server Instance

A cluster is associated with a PostgreSQL instance.
This instance manages all the databases within the cluster's directory. Each cluster has its own PostgreSQL server process.

3. Multiple Databases

A PostgreSQL cluster can contain multiple databases that share:

- A single system of users/roles.
- The server's configuration and resources.

Example:

```sql
CREATE DATABASE mydb;
CREATE DATABASE anotherdb;
```

4. Isolated Configuration

Each cluster has:

- Its own port (default is 5432, but this can be changed in postgresql.conf).
- Its own memory, connection, and other settings defined in postgresql.conf.

This means you can run multiple PostgreSQL clusters on the same physical server, as long as they use different ports.

5. Independent Processes

Each cluster has its own set of PostgreSQL server processes:

- One main process (postmaster).
- Additional subprocesses to handle connections, queries, and background tasks.

This ensures that clusters are completely independent of each other.

6. Scalability

Although a PostgreSQL cluster is not inherently distributed, you can configure:

- Replication: Hot standby or streaming replication to create replicas.
- Sharding: Using external tools like pgpool-II or Citus.


## Key Differences Between Databases and Schemas

| **Feature**         | **Database**                  | **Schema**                                           |
|----------------------|-------------------------------|-----------------------------------------------------|
| **Hierarchy Level**  | Main container               | Subset within the database                          |
| **Independence**     | Independent of other databases | Depends on a database                               |
| **Namespace**        | Global across the database   | Separate for each schema                           |
| **Cross-Access**     | Not directly possible without extensions | Yes, you can access tables in other schemas within the same database (using full name: `schema.table`) |
| **Usage Example**    | Separate applications         | Modules or departments within the same application |

---

## Summary

- **Database**: Large-scale organization, contains everything.
- **Schema**: Subdivision within a database for better structuring of data.

A PostgreSQL "schema" is roughly the same as a MySQL "database". Having many databases on a PostgreSQL installation can get problematic; having many schemas will work with no trouble. So you definitely want to go with one database and multiple schemas within that database.

[Reference](https://www.postgresql.org/docs/current/manage-ag-templatedbs.html) 

# Tuple

In PostgreSQL, a **tuple** refers to a row of data within a table. It is a term primarily used in the context of relational databases and derives from the relational model, where a tuple represents an instance of a dataset that adheres to the structure defined by the table schema.

For example, if you have a table called `users` with the following columns: `id`, `name`, `email`, a tuple would be a set of values filling these fields, like:

| id | name      | email             |
|----|-----------|-------------------|
| 1  | John Doe  | john@example.com  |

In this case, the tuple would be `(1, 'John Doe', 'john@example.com')`.

From a technical perspective in PostgreSQL:
1. **Tuple in memory**: When PostgreSQL processes data, it uses in-memory structures called tuples to represent rows.
2. **Tuple on disk**: Tuples are also physically stored in the data pages of the system's files, which make up the tables on disk.

## Key aspects of tuples in PostgreSQL

1. **MVCC (Multi-Version Concurrency Control)**: PostgreSQL manages tuples under the MVCC model, allowing multiple versions of a tuple to exist in the database. This is essential for consistent reads and managing locks during concurrent transactions.
   
2. **TID (Tuple Identifier)**: Each tuple has a unique identifier called `TID`, which points to its specific location within a page. This is useful for fast lookups.

3. **Tuple states**: A tuple can have different states (visible, invisible, updated, or deleted) depending on the transaction context.

In summary, a tuple in PostgreSQL is simply a row in a table, but its internal management is optimized to handle data efficiently in a transactional environment.


