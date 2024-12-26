---
Title: PostgreSQL pgBackRest
date: 2024-09-01
categories:
- Postgresql
tags:
- postgresql
- pgbackrest
- backup
keywords:
- backup
summary: "pgBackRest is a reliable backup and restore solution for PostgreSQL that seamlessly scales up to the largest databases and workloads."
comments: false
showMeta: false
showActions: false
---

# PostgreSQL disaster recovery options

**A Disaster Recovery (DR)** solution ensures that a system can be quickly restored to a normal operational state if something unexpected happens. When operating a database, you would back up the data as frequently as possible and have a mechanism to restore that data when needed. Disaster Recovery is often mistaken for high availability (HA), but they are two different concepts altogether:

- High availability ensures guaranteed service levels at all times. This solution involves configuring one or more standby systems to an active database, and the ability to switch seamlessly to that standby when the primary database becomes unavailable, for example, during a power outage or a server crash.

- Disaster Recovery protects the database instance against accidental or malicious data loss or data corruption. Disaster recovery can be achieved by using either the options provided by PostgreSQL, or external extensions.

PostgreSQL offers multiple options for setting up database disaster recovery.

1. pg_dump or the pg_dumpall utilities

This is the basic backup approach. These tools can generate the backup of one or more PostgreSQL databases (either just the structure, or both the structure and data), then restore them through the pg_restore command.

Disadvantages:
  1. Backup of only one database at a time.
  2. No incremental backups.
  3. No point-in-time recovery since the backup is a snapshot in time.
  4. Performance degradation when the database size is large.

2. File-based backup and restore

  1. Requires stopping PostgreSQL in order to copy the files. This is not practical for most production setups.
  2. No backup of individual databases or tables.

3. PostgreSQL pg_basebackup

This backup tool is provided by PostgreSQL. It is used to back up data when the database instance is running. pgasebackup makes a binary copy of the database cluster files, while making sure the system is put in and out of backup mode automatically. 

  1. No incremental backups.
  2. No backup of individual databases or tables.

To achieve a production grade PostgreSQL disaster recovery solution, you need something that can take full or incremental database backups from a running instance, and restore from those backups at any point in time. Percona Distribution for PostgreSQL is supplied with pgBackRest: a reliable, open-source backup and recovery solution for PostgreSQL.

# pgBackRest

[Reference](https://pgbackrest.org/user-guide.html) 

pgBackRest is an easy-to-use, open-source solution that can reliably back up even the largest of PostgreSQL databases.

**A backup** is a consistent copy of a database cluster that can be restored to recover from a hardware failure, to perform Point-In-Time Recovery, or to bring up a new standby.

- **Full Backup** : pgBackRest copies the entire contents of the database cluster to the backup. The first backup of the database cluster is always a Full Backup. pgBackRest is always able to restore a full backup directly. The full backup does not depend on any files outside of the full backup for consistency.

- **Differential Backup** : pgBackRest copies only those database cluster files that have changed since the last full backup. pgBackRest restores a differential backup by copying all of the files in the chosen differential backup and the appropriate unchanged files from the previous full backup. The advantage of a differential backup is that it requires less disk space than a full backup, however, the differential backup and the full backup must both be valid to restore the differential backup. 

- **Incremental Backup** : pgBackRest copies only those database cluster files that have changed since the last backup (which can be another incremental backup, a differential backup, or a full backup). As an incremental backup only includes those files changed since the prior backup, they are generally much smaller than full or differential backups. As with the differential backup, the incremental backup depends on other backups to be valid to restore the incremental backup. Since the incremental backup includes only those files since the last backup, all prior incremental backups back to the prior differential, the prior differential backup, and the prior full backup must all be valid to perform a restore of the incremental backup. If no differential backup exists then all prior incremental backups back to the prior full backup, which must exist, and the full backup itself must be valid to restore the incremental backup.

- **A restore** is the act of copying a backup to a system where it will be started as a live database cluster. A restore requires the backup files and one or more WAL segments in order to work correctly. When it comes to restoring, pgBackRest can do a full or a delta restore.
A full restore needs an empty PostgreSQL target directory. A delta restore is intelligent enough to recognize already-existing files in the PostgreSQL data directory, and update only the ones the backup contains. 

- **WAL** is the mechanism that PostgreSQL uses to ensure that no committed changes are lost. Transactions are written sequentially to the WAL and a transaction is considered to be committed when those writes are flushed to disk. Afterwards, a background process writes the changes into the main database cluster files (also known as the heap). In the event of a crash, the WAL is replayed to make the database consistent.

WAL is conceptually infinite but in practice is broken up into individual 16MB files called segments. WAL segments follow the naming convention 0000000100000A1E000000FE where the first 8 hexadecimal digits represent the timeline and the next 16 digits are the logical sequence number (LSN).

- **Encryption** is the process of converting data into a format that is unrecognizable unless the appropriate password (also referred to as passphrase) is provided.

pgBackRest will encrypt the repository based on a user-provided password, thereby preventing unauthorized access to data stored within the repository.

## Commands

- annotate        add or modify backup annotation
- archive-get     get a WAL segment from the archive
- archive-push    push a WAL segment to the archive
- backup          backup a database cluster
- check           check the configuration
- expire          expire backups that exceed retention
- help            get help
- info            retrieve information about backups
- repo-get        get a file from a repository
- repo-ls         list files in a repository
- restore         restore a database cluster
- server          pgBackRest server
- server-ping     ping pgBackRest server
- stanza-create   create the required stanza data
- stanza-delete   delete a stanza
- stanza-upgrade  upgrade a stanza
- start           allow pgBackRest processes to run
- stop            stop pgBackRest processes from running
- verify          verify contents of the repository
- version         get version

## Configure Cluster Stanza 

- **A stanza** is the configuration for a PostgreSQL database cluster that defines where it is located, how it will be backed up, archiving options, etc.
Most db servers will only have one PostgreSQL database cluster and therefore one stanza, whereas backup servers will have a stanza for every database cluster that needs to be backed up.

It is tempting **to name the stanza** after the primary cluster but a better name describes the databases contained in the cluster. Because the stanza name will be used for the primary and all replicas it is more appropriate to choose a name that describes the actual function of the cluster, such as app or dw, rather than the local cluster name, such as main or prod. 

pgBackRest needs to know *where the base data directory* for the PostgreSQL cluster is located. 
The path can be requested from PostgreSQL directly but in a recovery scenario the PostgreSQL process will not be available.
During backups the value supplied to pgBackRest will be compared against the path that PostgreSQL is running on and they must be equal or the backup will return an error. Make sure that pg-path is exactly equal to data_directory as reported by PostgreSQL. 
By default Debian/Ubuntu stores clusters in `/var/lib/postgresql/[version]/[cluster]` so it is easy to determine the correct path for the data directory.
When creating the `/etc/pgbackrest/pgbackrest.conf` file, the database owner (usually postgres) must be granted read privileges.

```bash
mkdir -p /var/lib/pgbackrest
chmod 0750 /var/lib/pgbackrest
chown -R postgres:postgres /var/lib/pgbackrest
```

- Example:

```ini
[global]
repo1-cipher-pass=RvcooAMdZgwE5T4EzsjHvWE5+sIAKDEGU95APTPalQPfdgjQ8sLakAy3PqIBkogc
repo1-cipher-type=aes-256-cbc
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
log-level-console=info
log-level-file=debug

[demo]
pg1-path=/var/lib/pgsql/15/data
```

*Quoting is not supported and whitespace is trimmed from keys and values*. Sections will be merged if they appear more than once.

The [global] section defines the location of backups, logging settings, and encryption settings.
The [demo] section defines a stanza for the demo backup repository, which we will configure.

Finally, initialize the pgBackRest stanza, which contains the definitions for the location, archiving options, backup settings, and other similar configurations for the PostgreSQL database cluster.
There is generally one stanza defined for each database cluster that needs to have backups.
The stanza-create command must be run on the primary host after pgbackrest.conf has been configured.

```bash
sudo -u postgres pgbackrest --stanza=main stanza-create
```



## Create the Repository 

It may be difficult to estimate in advance how much space you'll need. The best thing to do is take some backups then record the size of different types of backups (full/incr/diff) and measure the amount of WAL generated per day. This will give you a general idea of how much space you'll need, though of course requirements will likely change over time as your database evolves.

[Multiple](https://pgbackrest.org/user-guide.html#multi-repo) repositories may also be configured.

## Configure Archiving 

Backing up a running PostgreSQL cluster requires WAL archiving to be enabled. Note that at least one WAL segment will be created during the backup process even if no explicit writes are made to the cluster.

When archiving a WAL segment is expected to take more than 60 seconds (the default) to reach the pgBackRest repository, then the pgBackRest archive-timeout option should be increased. Note that this option is not the same as the PostgreSQL archive_timeout option which is used to force a WAL segment switch; useful for databases where there are long periods of inactivity. [Reference](https://www.postgresql.org/docs/current/static/runtime-config-wal.html) 

The archive-push command can be configured with its own options. For example, a lower compression level may be set to speed archiving without affecting the compression used for backups.

```ini
[demo]
pg1-path=/var/lib/postgresql/15/demo

[global]
repo1-path=/var/lib/pgbackrest

[global:archive-push]
compress-level=3 
```

This configuration technique can be used for any command and can even target a specific stanza, e.g. demo:archive-push.

## Configure Retention [Reference](https://pgbackrest.org/user-guide.html#retention) 

pgBackRest expires backups based on retention options.

```ini
[demo]
pg1-path=/var/lib/postgresql/15/demo

[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2

[global:archive-push]
compress-level=3 
```

## Configure Repository Encryption 

Encryption is always performed client-side even if the repository type (e.g. S3 or other object store) supports encryption.
It is important to use a long, random passphrase for the cipher key. A good way to generate one is to run: openssl rand -base64 48.
Once the repository has been configured and the stanza created and checked, the repository encryption settings cannot be changed. 

```bash
$  openssl rand -base64 48
RvcooAMdZgwE5T4EzsjHvWE5+sIAKDEGU95APTPalQPfdgjQ8sLakAy3PqIBkogc
```

```ini
[demo]
pg1-path=/var/lib/postgresql/15/demo

[global]
repo1-cipher-pass=zWaf6XtpjIVZC5444yXB+cgFDFl7MxGlgkZSaoPvTGirhPygu4jOKOXf9LO4vjfO
repo1-cipher-type=aes-256-cbc
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2

[global:archive-push]
compress-level=3
``` 

Once we have pgBackRest configured and running, it is very important to make a copy of the pgbackrest.conf file. This file contains our encryption key, Azure credentials (key, account, and bucket).

💡Pro-Tip: IF WE LOSE THIS FILE, WE WILL NOT BE ABLE TO RECOVER OUR BACKUPS.

Additionally, keep in mind that pgBackRest splits backups into small files, which makes it easier to upload them to our Azure account instead of uploading a single large file.

## Create the Stanza 

The stanza-create command must be run to initialize the stanza. It is recommended that the check command be run after stanza-create to ensure archiving and backups are properly configured.

```
$ sudo -u postgres pgbackrest --stanza=prod_backup stanza-create
2021-11-07 11:08:18.157 P00   INFO: stanza-create command begin 2.36: --exec-id=155883-2277a3e7 --log-level-console=info --log-level-file=off --pg1-host=pg-primary --pg1-host-user=postgres --pg1-path=/var/lib/postgresql/14/main --pg1-port=5432 --repo1-path=/home/pgbackrest/pg_backup --stanza=prod_backup
2021-11-07 11:08:19.453 P00   INFO: stanza-create for stanza 'prod_backup' on repo1
2021-11-07 11:08:19.566 P00   INFO: stanza-create command end: completed successfully (1412ms)
```

## Check the Configuration 

The check command validates that pgBackRest and the archive_command setting are configured correctly for archiving and backups for the specified stanza.

It will attempt to check all repositories and databases that are configured for the host on which the command is run. It detects misconfigurations, particularly in archiving, that result in incomplete backups because required WAL segments did not reach the archive.

The command can be run on the PostgreSQL or repository host. The command may also be run on the standby host, however, since pg_switch_xlog()/pg_switch_wal() cannot be performed on the standby, the command will only test the repository configuration.

Note that pg_create_restore_point('pgBackRest Archive Check') and pg_switch_xlog()/pg_switch_wal() are called to force PostgreSQL to archive a WAL segment.

## Performance Tuning 

pgBackRest has a number of performance options that are not enabled by default to maintain backward compatibility in the repository. However, when creating a new repository the following options are recommended. They can also be used on an existing repository with the caveat that older versions of pgBackRest will not be able to read the repository. This incompatibility depends on when the feature was introduced, which will be noted in the list below.

- compress-type - determines the compression algorithm used by the backup and archive-push commands. The default is gz (Gzip) but zst (Zstandard) is recommended because it is much faster and provides compression similar to gz. zst has been supported by the compress-type option since v2.27. See Compress Type for more details.
- repo-bundle - combines small files during backup to save space and improve the speed of both the backup and restore commands, especially on object stores. The repo-bundle option was introduced in v2.39. See File Bundling for more details.
- repo-block - stores only the portions of of files that have changed rather than the entire file during diff/incr backup. This saves space and increases the speed of the backup. The repo-block option was introduced in v2.46 but at least v2.52.1 is recommended. See Block Incremental for more details. 

There are other performance options that are not enabled by default because they require additional configuration or because the default is safe (but not optimal). These options are available in all v2 versions of pgBackRest.

- process-max - determines how many processes will be used for commands. The default is 1, which is almost never the appropriate value. Each command uses process-max differently so refer to each command's documentation for details on usage.
- archive-async - archives WAL files to the repository in batch which greatly increases archiving speed. It is not enabled by default because it requires a spool path to be created. See Asynchronous Archiving for more details.
- backup-standby - performs the backup on a standby rather than the primary to reduce load on the primary. It is not enabled by default because it requires additional configuration and the presence of one or more standby hosts. See Backup from a Standby for more details. 

## Perform a Backup 

By default pgBackRest will wait for the next regularly scheduled checkpoint before starting a backup.
Depending on the checkpoint_timeout and checkpoint_segments settings in PostgreSQL it may be quite some time before a checkpoint completes and the backup can begin. Generally, it is best to set start-fast=y so that the backup starts immediately. This forces a checkpoint, but since backups are usually run once a day an additional checkpoint should not have a noticeable impact on performance. However, on very busy clusters it may be best to pass --start-fast on the command-line as needed. 

```ini
[demo]
pg1-path=/var/lib/postgresql/15/demo

[global]
repo1-cipher-pass=zWaf6XtpjIVZC5444yXB+cgFDFl7MxGlgkZSaoPvTGirhPygu4jOKOXf9LO4vjfO
repo1-cipher-type=aes-256-cbc
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
start-fast=y

[global:archive-push]
compress-level=3 
```


By default pgBackRest will attempt to perform an incremental backup. However, an incremental backup must be based on a full backup and since no full backup existed pgBackRest ran a full backup instead.
The type option can be used to specify a full or differential backup.
While incremental backups can be based on a full or differential backup, differential backups must be based on a full backup. A full backup can be performed by running the backup command with --type=full. 

```bash
$  sudo -u postgres pgpassword='postgres' pgbackrest --stanza=psqlcluster01-backup --type=full backup
2024-11-19 16:24:43.603 P00   INFO: backup command begin 2.53.1: --exec-id=720635-9235d0d6 --log-level-console=info --log-level-file=debug --pg1-path=/var/lib/postgresql/17/main --repo1-cipher-pass=<redacted> --repo1-cipher-type=aes-256-cbc --repo1-path=/mnt/backup/pgbackrest --repo1-retention-full=2 --stanza=psqlcluster01-backup --type=full
2024-11-19 16:24:44.342 P00   INFO: execute non-exclusive backup start: backup begins after the next regular checkpoint completes
2024-11-19 16:24:44.743 P00   INFO: backup start archive = 0000000F0000000000000010, lsn = 0/10000028
2024-11-19 16:24:44.743 P00   INFO: check archive for prior segment 0000000F000000000000000F
2024-11-19 16:25:34.819 P00   INFO: execute non-exclusive backup stop and wait for all WAL segments to archive
2024-11-19 16:25:35.019 P00   INFO: backup stop archive = 0000000F0000000000000010, lsn = 0/10000158
2024-11-19 16:25:35.075 P00   INFO: check archive for segment(s) 0000000F0000000000000010:0000000F0000000000000010
2024-11-19 16:25:35.202 P00   INFO: new backup label = 20241119-162444F
2024-11-19 16:25:35.921 P00   INFO: full backup size = 22.3MB, file total = 974
2024-11-19 16:25:35.921 P00   INFO: backup command end: completed successfully (52319ms)
2024-11-19 16:25:35.921 P00   INFO: expire command begin 2.53.1: --exec-id=720635-9235d0d6 --log-level-console=info --log-level-file=debug --repo1-cipher-pass=<redacted> --repo1-cipher-type=aes-256-cbc --repo1-path=/mnt/backup/pgbackrest --repo1-retention-full=2 --stanza=psqlcluster01-backup
2024-11-19 16:25:36.072 P00   INFO: expire command end: completed successfully (151ms)
```

To start an incremental backup for db-primary, use this command:

```bash
$  sudo -u postgres PGPASSWORD='postgres' pgbackrest --stanza=psqlcluster01-backup --type=incr backup
2024-11-19 16:32:08.555 P00   INFO: backup command begin 2.53.1: --exec-id=722479-7021efbf --log-level-console=info --log-level-file=debug --pg1-path=/var/lib/postgresql/17/main --repo1-cipher-pass=<redacted> --repo1-cipher-type=aes-256-cbc --repo1-path=/mnt/backup/pgbackrest --repo1-retention-full=2 --stanza=psqlcluster01-backup --type=incr
2024-11-19 16:32:09.295 P00   INFO: last backup label = 20241119-162444F, version = 2.53.1
2024-11-19 16:32:09.295 P00   INFO: execute non-exclusive backup start: backup begins after the next regular checkpoint completes
2024-11-19 16:32:09.696 P00   INFO: backup start archive = 0000000F0000000000000012, lsn = 0/12000028
2024-11-19 16:32:09.696 P00   INFO: check archive for prior segment 0000000F0000000000000011
2024-11-19 16:32:10.760 P00   INFO: execute non-exclusive backup stop and wait for all WAL segments to archive
2024-11-19 16:32:10.961 P00   INFO: backup stop archive = 0000000F0000000000000012, lsn = 0/12000120
2024-11-19 16:32:11.027 P00   INFO: check archive for segment(s) 0000000F0000000000000012:0000000F0000000000000012
2024-11-19 16:32:11.122 P00   INFO: new backup label = 20241119-162444F_20241119-163209I
2024-11-19 16:32:11.827 P00   INFO: incr backup size = 8.3KB, file total = 974
2024-11-19 16:32:11.827 P00   INFO: backup command end: completed successfully (3273ms)
2024-11-19 16:32:11.827 P00   INFO: expire command begin 2.53.1: --exec-id=722479-7021efbf --log-level-console=info --log-level-file=debug --repo1-cipher-pass=<redacted> --repo1-cipher-type=aes-256-cbc --repo1-path=/mnt/backup/pgbackrest --repo1-retention-full=2 --stanza=psqlcluster01-backup
2024-11-19 16:32:11.943 P00   INFO: expire command end: completed successfully (116ms)
```

To view a list of all backups available of db-primary, use this command:

```bash
sudo -u postgres pgbackrest --stanza=psqlcluster01-backup info
```

## Deleting old backups manually

To keep only the last full backup:

```bash
sudo -u postgres pgbackrest --stanza=db-primary --repo1-retention-full=1 expire
```

To keep only the last differential backup:

```bash
sudo -u postgres pgbackrest --stanza=db-primary --repo1-retention-diff=1 expire
```

## Verify Backup 

And finally, confirm the backup is working:

```bash
$  sudo -u postgres pgbackrest --stanza=psqlcluster01-backup info
stanza: psqlcluster01-backup
    status: ok
    cipher: aes-256-cbc

    db (current)
        wal archive min/max (17): 0000000E0000000000000006/0000001D00000001000000B7

        full backup: 20241007-150357F
            timestamp start/stop: 2024-10-07 15:03:57+00 / 2024-10-07 15:04:02+00
            wal start/stop: 0000000E0000000000000006 / 0000000E0000000000000006
            database size: 86.9MB, database backup size: 86.9MB
            repo1: backup set size: 4.1MB, backup size: 4.1MB

        full backup: 20241009-154952F
            timestamp start/stop: 2024-10-09 15:49:52+00 / 2024-10-09 15:52:48+00
            wal start/stop: 0000001D00000001000000B0 / 0000001D00000001000000B0
            database size: 3.7GB, database backup size: 3.7GB
            repo1: backup set size: 1GB, backup size: 1GB

        diff backup: 20241009-154952F_20241009-161331D
            timestamp start/stop: 2024-10-09 16:13:31+00 / 2024-10-09 16:13:33+00
            wal start/stop: 0000001D00000001000000B2 / 0000001D00000001000000B3
            database size: 3.7GB, database backup size: 8.3KB
            repo1: backup set size: 1GB, backup size: 464B
            backup reference list: 20241009-154952F

        diff backup: 20241009-154952F_20241009-230002D
            timestamp start/stop: 2024-10-09 23:00:02+00 / 2024-10-09 23:00:03+00
            wal start/stop: 0000001D00000001000000B5 / 0000001D00000001000000B6
            database size: 3.7GB, database backup size: 8.3KB
            repo1: backup set size: 1GB, backup size: 464B
            backup reference list: 20241009-154952F
```

```bash
sudo -u postgres pgbackrest --stanza=psqlcluster01-backup verify
2024-10-12 11:29:02.254 P00   INFO: verify command begin 2.50: --exec-id=66076-56e5d74b --log-level-console=info --log-level-file=debug --repo1-cipher-pass=<redacted> --repo1-cipher-type=aes-256-cbc --repo1-path=/var/lib/pgbackrest --stanza=main
2024-10-12 11:29:03.649 P00   INFO: verify command end: completed successfully (1404ms)

```

## Schedule a Backup

Once backups are scheduled it's important to configure retention so backups are expired on a regular schedule, see [Retention](https://pgbackrest.org/user-guide.html#retention). 

## Backup Information

Use the info command to get information about backups.
The info command operates on a single stanza or all stanzas. Text output is the default and gives a human-readable summary of backups for the stanza(s) requested. 
For machine-readable output use --output=json. The JSON output contains far more information than the text output and is kept stable unless a bug is found.

Each stanza has a separate section and it is possible to limit output to a single stanza with the --stanza option. The stanza 'status' gives a brief indication of the stanza's health. If this is 'ok' then pgBackRest is functioning normally.

The 'wal archive min/max' shows the minimum and maximum WAL currently stored in the archive and, in the case of multiple repositories.

The backups are displayed oldest to newest. The oldest backup will always be a full backup (indicated by an F at the end of the label) but the newest backup can be full, differential (ends with D), or incremental (ends with I).

The 'timestamp start/stop' defines the time period when the backup ran. The 'timestamp stop' can be used to determine the backup to use when performing [Point-In-Time](https://pgbackrest.org/user-guide.html#pitr) Recovery.

The 'wal start/stop' defines the WAL range that is required to make the database consistent when restoring. The backup command will ensure that this WAL range is in the archive before completing.

- The 'database size' is the full uncompressed size of the database while 'database backup size' is the amount of data in the database to actually back up (these will be the same for full backups).

The 'repo' indicates in which repository this backup resides. The 'backup set size' includes all the files from this backup and any referenced backups in the repository that are required to restore the database from this backup while 'backup size' includes only the files in this backup (these will also be the same for full backups). Repository sizes reflect compressed file sizes if compression is enabled in pgBackRest.

The 'backup reference total' summarizes the list of additional backups that are required to restore this backup. Use the --set option to display the complete reference list. 

## [Restore](https://pgbackrest.org/user-guide.html#restore) a Backup

Backups can protect you from a number of disaster scenarios, the most common of which are hardware failure and data corruption. The easiest way to simulate data corruption is to remove an important PostgreSQL cluster file. 

pg-primary ⇒ Stop the demo cluster and delete the pg_control file

sudo pg_ctlcluster 15 demo stop

sudo -u postgres rm /var/lib/postgresql/15/demo/global/pg_control

Starting the cluster without this important file will result in an error. 

pg-primary ⇒ Attempt to start the corrupted demo cluster

sudo pg_ctlcluster 15 demo start

To restore a backup of the PostgreSQL cluster run pgBackRest with the restore command. The cluster needs to be stopped (in this case it is already stopped) and all files must be removed from the PostgreSQL data directory. 

 pg-primary ⇒ Remove old files from demo cluster

sudo -u postgres find /var/lib/postgresql/15/demo -mindepth 1 -delete

pg-primary ⇒ Restore the demo cluster and start PostgreSQL

sudo -u postgres pgbackrest --stanza=demo restore

sudo pg_ctlcluster 15 demo start

This time the cluster started successfully since the restore replaced the missing pg_control file. 

- Example:

Now that a full backup is performed on a fresh database, it might be useful to test restoring from the full backup.

To do this, stop the PostgreSQL instance, and delete its data files, simulating a system administration disaster.

```bash
sudo systemctl stop postgresql
sudo find /var/lib/postgresql/15/demo -mindepth 1 -delete
```

At this point, trying to start the database will result in a failure:

```bash
$ sudo systemctl start postgresql
## THIS WILL FAIL
```

Perform a restore on the database:

```bash
sudo -iu postgres pgbackrest --stanza=demo --delta restore
```

Once the restore has completed, the database will start as expected:

```bash
sudo systemctl start postgresql
```

You can verify that pgBackRest is still working:

```bash
$ sudo -u postgres pgbackrest --stanza=demo check
```

After any sort of disaster instance, it is always best practice to follow up any restore with a fresh backup:

```bash
sudo -u postgres pgbackrest --stanza=demo --type=full backup
```

To restore from backup to the same location on the DB server and at a specified time, you can start the restore process with the following command:

```bash
sudo -u postgres pgbackrest --stanza=db-primary --type=time --target="2022-06-02 17:05:23" restore
```

To restore from backup to a desired location on the DB server, you can start the restore process with the following command:

```bash
sudo -u postgres pgbackrest --stanza=db-primary --reset-pg1-host --pg1-path=/var/lib/pgsql/14/restored restore
```

If only missing files need to be added, you can use the --delta parameter. This parameter restores only missing files.


##  Monitoring

Monitoring is an important part of any production system. There are many tools available and pgBackRest can be monitored on any of them with a little work.
pgBackRest can output information about the repository in JSON format which includes a list of all backups for each stanza and WAL archive info. 

##  In PostgreSQL
The PostgreSQL COPY command allows pgBackRest info to be loaded into a table. The following example wraps that logic in a function that can be used to perform real-time queries. 

 pg-primary ⇒ Load pgBackRest info function for PostgreSQL

```
sudo -u postgres cat \
       /var/lib/postgresql/pgbackrest/doc/example/pgsql-pgbackrest-info.sql

-- An example of monitoring pgBackRest from within PostgreSQL
--
-- Use copy to export data from the pgBackRest info command into the jsonb
-- type so it can be queried directly by PostgreSQL.

-- Create monitor schema
create schema monitor;

-- Get pgBackRest info in JSON format
create function monitor.pgbackrest_info()
    returns jsonb AS $$
declare
    data jsonb;
begin
    -- Create a temp table to hold the JSON data
    create temp table temp_pgbackrest_data (data text);

    -- Copy data into the table directly from the pgBackRest info command
    copy temp_pgbackrest_data (data)
        from program
            'pgbackrest --output=json info' (format text);

    select replace(temp_pgbackrest_data.data, E'\n', '\n')::jsonb
      into data
      from temp_pgbackrest_data;

    drop table temp_pgbackrest_data;

    return data;
end $$ language plpgsql;

sudo -u postgres psql -f \
       /var/lib/postgresql/pgbackrest/doc/example/pgsql-pgbackrest-info.sql
```

Now the monitor.pgbackrest_info() function can be used to determine the last successful backup time and archived WAL for a stanza.
pg-primary ⇒ Query last successful backup time and archived WAL 

```
sudo -u postgres cat \
       /var/lib/postgresql/pgbackrest/doc/example/pgsql-pgbackrest-query.sql

-- Get last successful backup for each stanza
--
-- Requires the monitor.pgbackrest_info function.
with stanza as
(
    select data->'name' as name,
           data->'backup'->(
               jsonb_array_length(data->'backup') - 1) as last_backup,
           data->'archive'->(
               jsonb_array_length(data->'archive') - 1) as current_archive
      from jsonb_array_elements(monitor.pgbackrest_info()) as data
)
select name,
       to_timestamp(
           (last_backup->'timestamp'->>'stop')::numeric) as last_successful_backup,
       current_archive->>'max' as last_archived_wal
  from stanza;

sudo -u postgres psql -f \
       /var/lib/postgresql/pgbackrest/doc/example/pgsql-pgbackrest-query.sql

  name  | last_successful_backup |    last_archived_wal     
--------+------------------------+--------------------------
 "demo" | 2024-12-16 15:09:30+00 | 000000010000000000000005
(1 row)
```

## Using jq

jq can be used to query the last successful backup time for a stanza.

```bash
sudo -u postgres pgbackrest --output=json --stanza=demo info | \
       jq '.[0] | .backup[-1] | .timestamp.stop'
```

Or the last archived WAL. 

```bash
sudo -u postgres pgbackrest --output=json --stanza=demo info | \
       jq '.[0] | .archive[-1] | .max'
```

## File Bundling 

Bundling files together in the repository saves time during the backup and some space in the repository. This is especially pronounced when the repository is stored on an object store such as S3. Per-file creation time on object stores is higher and very small files might cost as much to store as larger files.
The file bundling feature is enabled with the repo-bundle option. 

```ini
[demo]
pg1-path=/var/lib/postgresql/15/demo

[global]
repo1-bundle=y
repo1-cipher-pass=zWaf6XtpjIVZC5444yXB+cgFDFl7MxGlgkZSaoPvTGirhPygu4jOKOXf9LO4vjfO
repo1-cipher-type=aes-256-cbc
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
start-fast=y

[global:archive-push]
compress-level=3 
```

A full backup without file bundling will have 1000+ files in the backup path, but with bundling the total number of files is greatly reduced. An additional benefit is that zero-length files are not stored (except in the manifest), whereas in a normal backup each zero-length file is stored individually.

 pg-primary ⇒ Perform a full backup

sudo -u postgres pgbackrest --stanza=demo --type=full backup

pg-primary ⇒ Check file total

sudo -u postgres find /var/lib/pgbackrest/backup/demo/latest/ -type f | wc -l

While file bundling is generally more efficient, the downside is that it is more difficult to manually retrieve files from the repository. It may not be ideal for deduplicated storage since each full backup will arrange files in the bundles differently. Lastly, file bundles cannot be resumed, so be careful not to set repo-bundle-size too high. 

## Backup Annotations 

Users can attach informative key/value pairs to the backup. This option may be used multiple times to attach multiple annotations.
pg-primary ⇒ Perform a full backup with annotations

sudo -u postgres pgbackrest --stanza=demo --annotation=source="demo backup" \
       --annotation=key=value --type=full backup

 Annotations included with the backup command can be added, modified, or removed afterwards using the annotate command.
pg-primary ⇒ Change backup annotations

sudo -u postgres pgbackrest --stanza=demo --set=20241216-150945F \
       --annotation=key= --annotation=new_key=new_value annotate

sudo -u postgres pgbackrest --stanza=demo --set=20241216-150945F info

## Retention

Generally it is best to retain as many backups as possible to provide a greater window for [Point-In-Time](https://pgbackrest.org/user-guide.html#pitr) Recovery, but practical concerns such as disk space must also be considered. Retention options remove older backups once they are no longer needed.

Archived WAL is retained by default for backups that have not expired, however, although not recommended, this schedule can be modified per repository with the retention-archive options.

The expire command is run automatically after each successful backup and can also be run by the user. When run by the user, expiration will occur as defined by the retention settings for each configured repository. If the --repo option is provided, expiration will occur only on the specified repository.

## Full Backup Retention 
only WAL segments generated after a backup can be used to recover that backup. 

The repo1-retention-full-type determines how the option repo1-retention-full is interpreted; either as the count of full backups to be retained or how many days to retain full backups. New backups must be completed before expiration will occur — that means if repo1-retention-full-type=count and repo1-retention-full=2 then there will be three full backups stored before the oldest one is expired, or if repo1-retention-full-type=time and repo1-retention-full=20 then there must be one full backup that is at least 20 days old before expiration can occur.

## Differential Backup Retention 

Set repo1-retention-diff to the number of differential backups required. Differentials only rely on the prior full backup so it is possible to create a "rolling" set of differentials for the last day or more. This allows quick restores to recent points-in-time but reduces overall space consumption.

```ini
[demo]
pg1-path=/var/lib/postgresql/15/demo

[global]
repo1-block=y
repo1-bundle=y
repo1-cipher-pass=zWaf6XtpjIVZC5444yXB+cgFDFl7MxGlgkZSaoPvTGirhPygu4jOKOXf9LO4vjfO
repo1-cipher-type=aes-256-cbc
repo1-path=/var/lib/pgbackrest
repo1-retention-diff=1
repo1-retention-full=2
start-fast=y

[global:archive-push]
compress-level=3 
```

Backup repo1-retention-diff=1 so two differentials will need to be performed before one is expired. An incremental backup is added to demonstrate incremental expiration. Incremental backups cannot be expired independently — they are always expired with their related full or differential backup.

Now performing a differential backup will expire the previous differential and incremental backups leaving only one differential backup.

## Archive Retention 

Although pgBackRest automatically removes archived WAL segments when expiring backups (the default expires WAL for full backups based on the repo1-retention-full option), it may be useful to expire archive more aggressively to save disk space. Note that full backups are treated as differential backups for the purpose of differential archive retention. 

Expiring archive will never remove WAL segments that are required to make a backup consistent. However, since Point-in-Time-Recovery (PITR) only works on a continuous WAL stream, care should be taken when aggressively expiring archive outside of the normal backup expiration process. To determine what will be expired without actually expiring anything, the dry-run option can be provided on the command line with the expire command. 

## Restore

The restore command automatically defaults to selecting the latest backup from the first repository where backups exist (see [Quick Start - Restore a Backup](https://pgbackrest.org/user-guide.html#quickstart/perform-restore)). The order in which the repositories are checked is dictated by the pgbackrest.conf (e.g. repo1 will be checked before repo2). To select from a specific repository, the --repo option can be passed (e.g. --repo=1). The --set option can be passed if a backup other than the latest is desired.

When PITR of --type=time or --type=lsn is specified, then the target time or target lsn must be specified with the --target option. If a backup is not specified via the --set option, then the configured repositories will be checked, in order, for a backup that contains the requested time or lsn. If no matching backup is found, the latest backup from the first repository containing backups will be used for --type=time while no backup will be selected for --type=lsn. For other types of PITR, e.g. xid, the --set option must be provided if the target is prior to the latest backup. 

Replication slots are not included per recommendation of [PostgreSQL](https://www.postgresql.org/docs/current/continuous-archiving.html#BACKUP-LOWLEVEL-BASE-BACKUP-DATA). 

## Delta Option 

The delta option allows pgBackRest to automatically determine which files in the database cluster directory can be preserved and which ones need to be restored from the backup — it also removes files not present in the backup manifest so it will dispose of divergent changes. This is accomplished by calculating a SHA-1 cryptographic hash for each file in the database cluster directory. If the SHA-1 hash does not match the hash stored in the backup then that file will be restored. This operation is very efficient when combined with the process-max option. Since the PostgreSQL server is shut down during the restore, a larger number of processes can be used than might be desirable during a backup when the PostgreSQL server is running. 

```bash
sudo pg_ctlcluster 15 demo stop

sudo -u postgres pgbackrest --stanza=demo --delta \
       --log-level-console=detail restore

       [filtered 2 lines of output]
P00 DETAIL: check '/var/lib/postgresql/15/demo' exists
P00 DETAIL: remove 'global/pg_control' so cluster will not start if restore does not complete

P00   INFO: remove invalid files/links/paths from '/var/lib/postgresql/15/demo'

P00 DETAIL: remove invalid file '/var/lib/postgresql/15/demo/backup_label.old'
P00 DETAIL: remove invalid file '/var/lib/postgresql/15/demo/base/1/pg_internal.init'
       [filtered 15 lines of output]
P01 DETAIL: restore file /var/lib/postgresql/15/demo/backup_label (260B, 0.00%) checksum 9f9ae79bb90477b96b90a8229341e9ee89f921b2
P01 DETAIL: restore file /var/lib/postgresql/15/demo/pg_multixact/members/0000 - exists and matches backup (bundle 20241216-150952F/1/0, 8KB, 0.04%) checksum 0631457264ff7f8d5fb1edc2c0211992a67c73e6

P01 DETAIL: restore file /var/lib/postgresql/15/demo/PG_VERSION - exists and matches backup (bundle 20241216-150952F/1/40, 3B, 0.04%) checksum 587b596f04f7db9c2cad3d6b87dd2b3a05de4f35

P01 DETAIL: restore file /var/lib/postgresql/15/demo/global/pg_filenode.map - exists and matches backup (bundle 20241216-150952F/1/64, 512B, 0.04%) checksum 8426f71eec225fb3087aa80427d8e6b4e6a8a65b
P01 DETAIL: restore file /var/lib/postgresql/15/demo/global/6247 - exists and matches backup (bundle 20241216-150952F/1/232, 8KB, 0.07%) checksum ea40c8171261ed36b40f1597297f0a111790313c
       [filtered 985 lines of output]

sudo pg_ctlcluster 15 demo start
```

## Restore Selected Databases 

 To demonstrate this feature two databases are created: test1 and test2.

```bash
sudo -u postgres psql -c "create database test1;"
sudo -u postgres psql -c "create database test2;"
```

Each test database will be seeded with tables and data to demonstrate that recovery works with selective restore.

```bash
sudo -u postgres psql -c "create table test1_table (id int); \
       insert into test1_table (id) values (1);" test1

sudo -u postgres psql -c "create table test2_table (id int); \
       insert into test2_table (id) values (2);" test2
```

A fresh backup is run so pgBackRest is aware of the new databases.

```bash
sudo -u postgres pgbackrest --stanza=demo --type=incr backup
```

One of the main reasons to use selective restore is to save space. The size of the test1 database is shown here so it can be compared with the disk utilization after a selective restore.

```bash
sudo -u postgres du -sh /var/lib/postgresql/15/demo/base/32768
7.3M	/var/lib/postgresql/15/demo/base/32768
```

If the database to restore is not known, use the info command set option to discover databases that are part of the backup set.

```bash
sudo -u postgres pgbackrest --stanza=demo \
       --set=20241216-150952F_20241216-151010I info

       [filtered 12 lines of output]
            repo1: backup size: 2.0MB
            backup reference list: 20241216-150952F, 20241216-150952F_20241216-151000D

            database list: postgres (5), test1 (32768), test2 (32769)
```

Stop the cluster and restore only the test2 database. Built-in databases (template0, template1, and postgres) are always restored. 

 WARNING:
Recovery may error unless --type=immediate is specified. This is because after consistency is reached PostgreSQL will flag zeroed pages as errors even for a full-page write. For PostgreSQL ≥ 13 the ignore_invalid_pages setting may be used to ignore invalid pages. In this case it is important to check the logs after recovery to ensure that no invalid pages were reported in the selected databases.

```bash
sudo pg_ctlcluster 15 demo stop

sudo -u postgres pgbackrest --stanza=demo --delta \
       --db-include=test2 --type=immediate --target-action=promote restore

sudo pg_ctlcluster 15 demo start
```

Once recovery is complete the test2 database will contain all previously created tables and data.

```bash
sudo -u postgres psql -c "select * from test2_table;" test2
```

The test1 database, despite successful recovery, is not accessible. This is because the entire database was restored as sparse, zeroed files. PostgreSQL can successfully apply WAL on the zeroed files but the database as a whole will not be valid because key files contain no data. This is purposeful to prevent the database from being accidentally used when it might contain partial data that was applied during WAL replay.

```bash
sudo -u postgres psql -c "select * from test1_table;" test1
```

Since the test1 database is restored with sparse, zeroed files it will only require as much space as the amount of WAL that is written during recovery. While the amount of WAL generated during a backup and applied during recovery can be significant it will generally be a small fraction of the total database size, especially for large databases where this feature is most likely to be useful.
It is clear that the test1 database uses far less disk space during the selective restore than it would have if the entire database had been restored. 

At this point the only action that can be taken on the invalid test1 database is drop database. pgBackRest does not automatically drop the database since this cannot be done until recovery is complete and the cluster is accessible.

```bash
sudo -u postgres psql -c "drop database test1;"
```

Now that the invalid test1 database has been dropped only the test2 and built-in databases remain.

```bash
sudo -u postgres psql -c "select oid, datname from pg_database order by oid;"
```

## Point-in-Time Recovery 

In the case of a hardware failure this is usually the best choice but for data corruption scenarios (whether machine or human in origin) Point-in-Time Recovery (PITR) is often more appropriate.
Point-in-Time Recovery (PITR) allows the WAL to be played from a backup to a specified lsn, time, transaction id, or recovery point. For common recovery scenarios time-based recovery is arguably the most useful. A typical recovery scenario is to restore a table that was accidentally dropped or data that was accidentally deleted. Recovering a dropped table is more dramatic so that's the example given here but deleted data would be recovered in exactly the same way.

```bash
sudo -u postgres psql -c "begin; \
       create table important_table (message text); \
       insert into important_table values ('Important Data'); \
       commit; \
       select * from important_table;"
```

It is important to represent the time as reckoned by PostgreSQL and to include timezone offsets. This reduces the possibility of unintended timezone conversions and an unexpected recovery result.

```bash
sudo -u postgres psql -Atc "select current_timestamp"
```

Now that the time has been recorded the table is dropped. In practice finding the exact time that the table was dropped is a lot harder than in this example. It may not be possible to find the exact time, but some forensic work should be able to get you close.

```bash
sudo -u postgres psql -c "begin; \
       drop table important_table; \
       commit; \
       select * from important_table;"
```

If the wrong backup is selected for restore then recovery to the required time target will fail. To demonstrate this a new incremental backup is performed where important_table does not exist.

```bash
sudo -u postgres pgbackrest --stanza=demo --type=incr backup
sudo -u postgres pgbackrest info
```

It will not be possible to recover the lost table from this backup since PostgreSQL can only play forward, not backward. 

```bash
sudo pg_ctlcluster 15 demo stop

sudo -u postgres pgbackrest --stanza=demo --delta \
       --set=20241216-150952F_20241216-151022I --target-timeline=current \
       --type=time "--target=2024-12-16 15:10:20.768816+00" --target-action=promote restore

sudo pg_ctlcluster 15 demo start
       [filtered 13 lines of output]
LOG:  database system is ready to accept read-only connections
LOG:  redo done at 0/1B000100 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.04 s

FATAL:  recovery ended before configured recovery target was reached

LOG:  startup process (PID 1985) exited with exit code 1
LOG:  terminating any other active server processes
       [filtered 3 lines of output]
```

A reliable method is to allow pgBackRest to automatically select a backup capable of recovery to the time target, i.e. a backup that ended before the specified time.
NOTE:
pgBackRest cannot automatically select a backup when the restore type is xid or name. 

```bash
sudo -u postgres pgbackrest --stanza=demo --delta \
       --type=time "--target=2024-12-16 15:10:20.768816+00" \
       --target-action=promote restore

sudo -u postgres cat /var/lib/postgresql/15/demo/postgresql.auto.conf
       [filtered 9 lines of output]
# Recovery settings generated by pgBackRest restore on 2024-12-16 15:10:26
restore_command = 'pgbackrest --stanza=demo archive-get %f "%p"'
recovery_target_time = '2024-12-16 15:10:20.768816+00'
recovery_target_action = 'promote'
```

pgBackRest has generated the recovery settings in postgresql.auto.conf so PostgreSQL can be started immediately. %f is how PostgreSQL specifies the WAL segment it needs and %p is the location where it should be copied. Once PostgreSQL has finished recovery the table will exist again and can be queried.

```bash
sudo pg_ctlcluster 15 demo start
sudo -u postgres psql -c "select * from important_table"
```

The PostgreSQL log also contains valuable information. It will indicate the time and transaction where the recovery stopped and also give the time of the last transaction to be applied. 

## Replication 

### Hot Standby 
A hot standby performs replication using the WAL archive and allows read-only queries.
pgBackRest configuration is very similar to pg-primary except that the standby recovery type will be used to keep the cluster in recovery mode when the end of the WAL stream has been reached. 

```bash
sudo -u postgres pgbackrest --stanza=demo --delta --type=standby restore

sudo -u postgres cat /var/lib/postgresql/15/demo/postgresql.auto.conf

# Do not edit this file manually!
# It will be overwritten by the ALTER SYSTEM command.

# Recovery settings generated by pgBackRest restore on 2024-12-16 15:09:32
restore_command = 'pgbackrest --stanza=demo archive-get %f "%p"'

# Recovery settings generated by pgBackRest restore on 2024-12-16 15:10:03
restore_command = 'pgbackrest --stanza=demo archive-get %f "%p"'

# Recovery settings generated by pgBackRest restore on 2024-12-16 15:10:26
restore_command = 'pgbackrest --stanza=demo archive-get %f "%p"'
# Removed by pgBackRest restore on 2024-12-16 15:11:05 # recovery_target_time = '2024-12-16 15:10:20.768816+00'
# Removed by pgBackRest restore on 2024-12-16 15:11:05 # recovery_target_action = 'promote'

# Recovery settings generated by pgBackRest restore on 2024-12-16 15:11:05
restore_command = 'pgbackrest --repo=3 --repo-target-time="2024-12-16 15:10:52+00" --stanza=demo archive-get %f "%p"'

# Recovery settings generated by pgBackRest restore on 2024-12-16 15:11:29
restore_command = 'pgbackrest --stanza=demo archive-get %f "%p"'

# Recovery settings generated by pgBackRest restore on 2024-12-16 15:12:04
restore_command = 'pgbackrest --stanza=demo archive-get %f "%p"'
```

The hot_standby setting must be enabled before starting PostgreSQL to allow read-only connections on pg-standby. Otherwise, connection attempts will be refused. The rest of the configuration is in case the standby is promoted to a primary.

```
archive_command = 'pgbackrest --stanza=demo archive-push %p'
archive_mode = on
hot_standby = on
max_wal_senders = 3
wal_level = replica 
```

The PostgreSQL log gives valuable information about the recovery. Note especially that the cluster has entered standby mode and is ready to accept read-only connections. 

An easy way to test that replication is properly configured is to create a table on pg-primary. 

```bash
sudo -u postgres psql -c " \
       begin; \
       create table replicated_table (message text); \
       insert into replicated_table values ('Important Data'); \
       commit; \
       select * from replicated_table";
```

And then query the same table on pg-standby.

```bash
sudo -u postgres psql -c "select * from replicated_table;"
```

So, what went wrong? Since PostgreSQL is pulling WAL segments from the archive to perform replication, changes won't be seen on the standby until the WAL segment that contains those changes is pushed from pg-primary.

This can be done manually by calling pg_switch_wal() which pushes the current WAL segment to the archive (a new WAL segment is created to contain further changes).

```bash
sudo -u postgres psql -c "select *, current_timestamp from pg_switch_wal()";
```

Check the standby configuration for access to the repository.

```bash
sudo -u postgres pgbackrest --stanza=demo --log-level-console=info check

P00   INFO: check command begin 2.54.1: --exec-id=1261-2714b3d2 --log-level-console=info --log-level-file=detail --no-log-timestamp --pg1-path=/var/lib/postgresql/15/demo --repo1-host=repository --stanza=demo
P00   INFO: check repo1 (standby)
P00   INFO: switch wal not performed because this is a standby
P00   INFO: check command end: completed successfully
```

###  Streaming Replication 

Instead of relying solely on the WAL archive, streaming replication makes a direct connection to the primary and applies changes as soon as they are made on the primary. This results in much less lag between the primary and standby.
Streaming replication requires a user with the replication privilege.

```bash
sudo -u postgres psql -c " \
       create user replicator password 'jw8s0F4' replication";
```

The pg_hba.conf file must be updated to allow the standby to connect as the replication user. Be sure to replace the IP address below with the actual IP address of your pg-standby. A reload will be required after modifying the pg_hba.conf file.

```bash
sudo -u postgres sh -c 'echo \
       "host    replication     replicator      172.17.0.8/32           md5" \
       >> /etc/postgresql/15/demo/pg_hba.conf'

sudo pg_ctlcluster 15 demo reload
```

The standby needs to know how to contact the primary so the primary_conninfo setting will be configured in pgBackRest. 

```ini
[demo]
pg1-path=/var/lib/postgresql/15/demo
recovery-option=primary_conninfo=host=172.17.0.6 port=5432 user=replicator

[global]
log-level-file=detail
repo1-host=repository 
```

It is possible to configure a password in the primary_conninfo setting but using a .pgpass file is more flexible and secure. 

```bash
sudo -u postgres sh -c 'echo \
       "172.17.0.6:*:replication:replicator:jw8s0F4" \
       >> /var/lib/postgresql/.pgpass'

sudo -u postgres chmod 600 /var/lib/postgresql/.pgpass
```

Now the standby can be created with the restore command. 

```bash
sudo pg_ctlcluster 15 demo stop

sudo -u postgres pgbackrest --stanza=demo --delta --type=standby restore

sudo -u postgres cat /var/lib/postgresql/15/demo/postgresql.auto.conf
# Do not edit this file manually!
# It will be overwritten by the ALTER SYSTEM command.

# Recovery settings generated by pgBackRest restore on 2024-12-16 15:09:32
restore_command = 'pgbackrest --stanza=demo archive-get %f "%p"'

# Recovery settings generated by pgBackRest restore on 2024-12-16 15:10:03
restore_command = 'pgbackrest --stanza=demo archive-get %f "%p"'

# Recovery settings generated by pgBackRest restore on 2024-12-16 15:10:26
restore_command = 'pgbackrest --stanza=demo archive-get %f "%p"'
# Removed by pgBackRest restore on 2024-12-16 15:11:05 # recovery_target_time = '2024-12-16 15:10:20.768816+00'
# Removed by pgBackRest restore on 2024-12-16 15:11:05 # recovery_target_action = 'promote'

# Recovery settings generated by pgBackRest restore on 2024-12-16 15:11:05
restore_command = 'pgbackrest --repo=3 --repo-target-time="2024-12-16 15:10:52+00" --stanza=demo archive-get %f "%p"'

# Recovery settings generated by pgBackRest restore on 2024-12-16 15:11:29
restore_command = 'pgbackrest --stanza=demo archive-get %f "%p"'

# Recovery settings generated by pgBackRest restore on 2024-12-16 15:12:20
primary_conninfo = 'host=172.17.0.6 port=5432 user=replicator'
restore_command = 'pgbackrest --stanza=demo archive-get %f "%p"'
```

 NOTE:
The primary_conninfo setting has been written into the postgresql.auto.conf file because it was configured as a recovery-option in pgbackrest.conf. The --type=preserve option can be used with the restore to leave the existing postgresql.auto.conf file in place if that behavior is preferred.
pg-standby ⇒ Start PostgreSQL

sudo pg_ctlcluster 15 demo start

The PostgreSQL log will confirm that streaming replication has started.
pg-standby ⇒ Examine the PostgreSQL log output for log messages indicating success

sudo -u postgres cat /var/log/postgresql/postgresql-15-demo.log

       [filtered 13 lines of output]
LOG:  consistent recovery state reached at 0/26000088
LOG:  database system is ready to accept read-only connections

LOG:  started streaming WAL from primary at 0/28000000 on timeline 7

Now when a table is created on pg-primary it will appear on pg-standby quickly and without the need to call pg_switch_wal().
pg-primary ⇒ Create a new table on the primary

sudo -u postgres psql -c " \
       begin; \
       create table stream_table (message text); \
       insert into stream_table values ('Important Data'); \
       commit; \
       select *, current_timestamp from stream_table";

       [filtered 4 lines of output]
    message     |       current_timestamp       
----------------+-------------------------------

 Important Data | 2024-12-16 15:12:27.258093+00

(1 row)

pg-standby ⇒ Query table on the standby

sudo -u postgres psql -c " \
       select *, current_timestamp from stream_table"

    message     |       current_timestamp       
----------------+-------------------------------

 Important Data | 2024-12-16 15:12:27.644922+00

(1 row)

# Configure pgBackRest to Use the Password
If you've set a password for the postgres user, you need to ensure that pgBackRest is provided with the correct password. This can be done by setting the password in the PGPASSWORD environment variable or by configuring pgBackRest to read from a file.

To set the PGPASSWORD environment variable for the command, you can use:

```bash
sudo -u postgres PGPASSWORD='your_password' pgbackrest --stanza=psqlcluster01-backup stanza-create
```
```bash
$  sudo -u postgres PGPASSWORD='postgres' pgbackrest --stanza=psqlcluster01-backup stanza-create
2024-11-19 15:58:47.739 P00   INFO: stanza-create command begin 2.53.1: --exec-id=1088955-6138710b --log-level-console=info --log-level-file=debug --pg1-path=/var/lib/postgresql/17/main --repo1-cipher-pass=<redacted> --repo1-cipher-type=aes-256-cbc --repo1-path=/mnt/backup/pgbackrest --stanza=psqlcluster01-backup
2024-11-19 15:58:48.345 P00   INFO: stanza-create for stanza 'psqlcluster01-backup' on repo1
2024-11-19 15:58:48.822 P00   INFO: stanza-create command end: completed successfully (1084ms)
```

Alternatively, you can configure pgBackRest to use a .pgpass file, which contains credentials for PostgreSQL. The .pgpass file should be placed in the home directory of the user running pgBackRest (in this case, the postgres user). The format is:

`hostname:port:database:username:password` 

For example, for local connections, it might look like this:

`*:5432:postgres:postgres:your_password` 


