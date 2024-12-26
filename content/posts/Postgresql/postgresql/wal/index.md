---
Title: Postgresql Wal Configuration
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

# Write-Ahead Log (WAL) in PostgreSQL

[Reference](https://www.postgresql.org/docs/current/wal-configuration.html) 

WAL (Write-Ahead Log) files are an essential part of the transaction logging system. They are used to ensure the integrity and consistency of the database, especially in cases of failures or unexpected interruptions.

WAL stands for Write-Ahead Logging. It is a mechanism that ensures any changes to the database data are first recorded in a log file (WAL) before being physically applied to the tables or indexes on disk.

## Benefits of WAL

### 1. Failure Recovery

If a failure occurs (such as a power outage), PostgreSQL can use WAL records to restore the database to its last consistent state.

### 2. Data Safety

It ensures that transactions are processed atomically and durably, even in cases of interruptions.

## How WAL Files Work

### 1. Write-Ahead

Before writing data to tables, PostgreSQL first writes a detailed log of the operation in the WAL file. This log includes information about the changes (such as inserts, updates, or deletions) being made.

### 2. Deferred Application

The actual changes to table data are applied later. If a failure occurs before this happens, PostgreSQL can use WAL files to "replay" the operations and restore the consistent state.

### 3. Lifecycle

WAL records are stored in a folder named `pg_wal` within the PostgreSQL data directory. They are generated in fixed-size segments, typically 16 MB (though this can be configured). Older records are deleted or archived, depending on the configuration.

## Configuring WAL

WAL settings can be adjusted in the `postgresql.conf` file. Key settings include:

- **wal_level:**  
  Defines the level of detail in WAL records. Common values:  
  - `minimal`: Basic logging.  
  - `replica`: Suitable for read replication.  
  - `logical`: For logical replication.

- **archive_mode:**  
  If enabled, old WAL files are archived instead of being deleted.

- **archive_command:**  
  The command used to store archived WAL files in an external location.

- **max_wal_size** and **min_wal_size:**  
  Control the amount of disk space WAL files can occupy before PostgreSQL removes older ones.

## Practical Uses of WAL

### Failure Recovery

During recovery, PostgreSQL uses WAL to restore pending or incomplete transactions.

### Replication

In a replication environment, WAL files are transmitted to secondary servers (replicas) to apply changes.

### Point-In-Time Recovery (PITR)

By combining WAL with base backups, you can restore the database to an exact point in time.

## Useful Commands Related to WAL

- **pg_wal:** The folder where WAL files are stored.  
- **pg_archivecleanup:**  
  Used to clean up old WAL files that are no longer needed for recovery or replication.

### Example: Enabling WAL Archiving

```text
archive_mode = on
archive_command = 'cp %p /path/to/archive/%f'
```

Proper management of WAL is crucial for the performance and reliability of a PostgreSQL system.

## Verifying the Integrity of WAL Files

If WAL files are corrupted or missing, PostgreSQL may get stuck during recovery. Use the following command to check the status of WAL files:

```bash
pg_waldump -p /var/lib/pgsql/<version>/data/pg_wal/
```

If corruption is detected, you will need to restore the files from a backup or use a primary node if replication is configured.

## Key Settings for Replication and Archiving

- **wal_level: replica**  
  Suitable for a replication cluster, as it allows WAL transmission.

- **wal_keep_size: 1024** (or **wal_keep_segments: 100**)  
  Ensure this is sufficient to prevent replicas from losing WAL files during idle periods or slow replication.

- **max_wal_senders: 5** and **max_replication_slots: 5**  
  These settings allow up to five simultaneous replicas. Check for saturation on the primary server using:

```sql
SELECT * FROM pg_stat_replication;
```

- **archive_mode: on** and **archive_command**  
  If the required WAL file is unavailable on the primary server, verify that the archive command (e.g., `pgBackRest`) is functioning properly:

```bash
pgbackrest --stanza=psqlcluster01-backup check
```

If issues arise, the WAL files may not be available for replicas.

# Archiving:

Maintain a continuous record of write-ahead log (WAL) transactions to enable point-in-time recovery (PITR) or replication.

In PostgreSQL, WAL archiving is enabled by setting the archive_mode parameter to on and defining the archive_command.
Whenever a WAL file is completed, PostgreSQL transfers it to a specified location (e.g., a disk, NAS, or external storage system).

- Primary Use Cases:
  - Support for Point-in-Time Recovery (PITR).
  - Data replication for high availability.

- Features:
  - It is a continuous and automatic process (as long as the server is running and correctly configured).
  - Requires additional storage for WAL files.
  - More granular than a full backup, as it records all transactions.

# Example

```
2024-12-18 20:49:59.524 P00   INFO: archive-push command begin 2.53.1: [pg_wal/00000038000000720000007E] --exec-id=1079752-ccdfbdb0 --log-level-console=info --log-level-file=debug --pg1-path=/var/lib/postgresql/17/main --repo1-cipher-pass=<redacted> --repo1-cipher-type=aes-256-cbc --repo1-path=/mnt/backup/pgbackrest --stanza=psqlcluster01-backup
2024-12-18 20:49:59 UTC [87768]: LOG:  checkpoints are occurring too frequently (23 seconds apart)
2024-12-18 20:49:59 UTC [87768]: HINT:  Consider increasing the configuration parameter "max_wal_size".
2024-12-18 20:49:59 UTC [87768]: LOG:  checkpoint starting: wal
2024-12-18 20:50:00.234 P00   INFO: pushed WAL file '00000038000000720000007E' to the archive
2024-12-18 20:50:00.235 P00   INFO: archive-push command end: completed successfully (712ms)
```

1.	Increase max_wal_size

Try increasing max_wal_size to a higher value, for example:

```
max_wal_size = 4GB

postgresql:
  parameters:
    max_wal_size: 4GB
```

2. Adjust checkpoint_timeout

Increasing checkpoint_timeout allows checkpoints to occur less frequently over time. For example:

```
checkpoint_timeout = 15min
```

3.	Adjust checkpoint_completion_target

Set checkpoint_completion_target to distribute the I/O load during the checkpoint. For example:

```
checkpoint_completion_target = 0.9
```

4.	Monitor the Size of Generated WALs

You can monitor the size of the generated WALs with:

```
du -sh /var/lib/postgresql/17/main/pg_wal/
```

If the pg_wal directory grows rapidly, confirm that the write load is high.

5.	Review System Load

- Disk I/O: Check if the storage can handle the write load. Tools like iostat can help:

```
iostat -x 1
```

6. Adjust wal_buffers

If you have a high write load, increasing wal_buffers can help. For example:

```
postgresql:
  parameters:
    wal_buffers: 16MB
```
