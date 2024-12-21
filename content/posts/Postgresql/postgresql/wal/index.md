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

# Wal Configuration

[Reference](https://www.postgresql.org/docs/current/wal-configuration.html) 

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
