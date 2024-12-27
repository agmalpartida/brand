---
Title: PSQL Extensions
date: 2024-12-27
categories:
- Postgresql
tags:
- postgresql
keywords:
- postgresql
- extension
summary: ""
comments: false
showMeta: false
showActions: false
---

# Overview
Percona Distribution for PostgreSQL includes a set of extensions that have been tested to work together. These extensions enable you to efficiently solve essential practical tasks to operate and manage PostgreSQL.

[Reference](https://docs.percona.com/postgresql/17/extensions.html) 

The pg_stat_statements and pg_stat_monitor extensions are used to collect and monitor query statistics in PostgreSQL, but they have key differences in functionality, focus, and efficiency.

- pg_stat_statements:
This is an official extension included with PostgreSQL.
Its main purpose is to track the performance of queries executed in the database. It maintains a history of executed queries, the number of times they were executed, and basic performance metrics such as execution time and resource consumption.
It is widely used due to its simplicity and integration within the official PostgreSQL ecosystem.

-	pg_stat_monitor:
This is an extension developed by Percona, designed as an enhanced alternative to pg_stat_statements.
It aims to address some of the limitations of pg_stat_statements by providing more detailed metrics and a more advanced approach to analyzing query performance. Percona developed this extension to make monitoring more efficient and to offer statistics that better meet modern requirements.

## Granularity and Metrics:

- pg_stat_statements:
Groups queries by their parameterized version (e.g., SELECT * FROM users WHERE id = $1), providing aggregated statistics.
Offers basic metrics such as total execution time, number of calls, CPU time, number of blocks read/written, among others.
Does not include advanced metrics like wait times, memory usage, or other more detailed resources.
It is less granular, meaning it may be insufficient for scenarios requiring detailed query pattern analysis.
-	pg_stat_monitor:
Provides a higher level of granularity than pg_stat_statements, breaking down metrics into time intervals so you can analyze query performance over different periods.
Includes additional metrics such as wait times, memory usage, query details by time intervals, and individual statement statistics, allowing for much more detailed and precise query analysis.
Also supports capturing original queries, which is useful for auditing or debugging purposes.

## Performance and Overhead:

- pg_stat_statements:
Introduces minimal overhead to PostgreSQL’s performance since it focuses on maintaining simple aggregated statistics. This is one of the reasons it is the default choice for basic query monitoring in PostgreSQL.
By not collecting too much detailed information, it is less resource-intensive.
- pg_stat_monitor:
While offering more advanced and granular functionality, it may generate higher overhead compared to pg_stat_statements, as it collects more data and processes it in a more sophisticated way.
The overhead depends on how much data is collected and how it is used, but it is designed to be efficient and scalable in more complex environments.

## Special Features:

- pg_stat_statements:
Does not offer time interval segmentation or fine-grained details about resources consumed by queries.
It is more basic and does not support capturing all details of each individual query.
- pg_stat_monitor:
Introduces advanced features such as time interval segmentation, allowing you to see how statistics vary over time instead of just aggregated data.
Can capture more contextual information, such as the client’s IP address or additional details about the users executing the queries.
Provides more detailed reports and better analysis for high-concurrency situations or large databases with advanced monitoring needs.

## Compatibility and Ease of Use:

- pg_stat_statements:
As part of PostgreSQL’s native tools, it guarantees full compatibility and is widely supported by most monitoring tools.
Requires less configuration and tuning compared to pg_stat_monitor, making it a straightforward option for most users.
- pg_stat_monitor:
May not be compatible with all PostgreSQL versions or third-party monitoring tools since it is a Percona extension.
Requires a bit more configuration and tuning to unlock its full potential but offers greater flexibility and monitoring power.

# Install

To use an extension, install it. Run the CREATE EXTENSION command on the PostgreSQL node where you want the extension to be available. 
The user should be a superuser or have the CREATE privilege on the current database to be able to run the CREATE EXTENSION command. Some extensions may require additional privileges depending on their functionality. To learn more, check the documentation for the desired extension.

## pg_stat_monitor (Query Performance Monitoring tool for PostgreSQL)

[Reference](https://docs.percona.com/pg-stat-monitor/user_guide.html) 

It collects various statistics data such as query statistics, query plan, SQL comments and other performance insights. The collected data is aggregated and presented in a single view. This allows you to view queries from performance, application and analysis perspectives.

pg_stat_monitor groups statistics data and writes it in a storage unit called bucket. The data is added and stored in a bucket for the defined period – the bucket lifetime. This allows you to identify performance issues and patterns based on time.

You can specify the following:

- The number of buckets. Together they form a bucket chain.
- Bucket size. This is the amount of shared memory allocated for buckets. Memory is divided equally among buckets.
- Bucket lifetime.

When a bucket lifetime expires, pg_stat_monitor resets all statistics and writes the data in the next bucket in the chain. When the last bucket’s lifetime expires, pg_stat_monitor returns to the first bucket.

**Important**: The contents of the bucket will be overwritten. In order not to lose the data, make sure to read the bucket before pg_stat_monitor starts writing new data to it.

### Install from sources

[Github](https://github.com/percona/pg_stat_monitor) 

```bash
apt update
apt install percona-postgresql-server-dev-all gcc make
```

The pg_stat_monitor package is not available in PostgreSQL’s default repositories, so you will need to install it from its source code. 
Use PGXS (PostgreSQL Extension Building Infrastructure) to compile the module. Some projects, like pg_stat_monitor, support this approach.

```bash
git clone https://github.com/percona/pg_stat_monitor.git
cd pg_stat_monitor

make clean USE_PGXS=1
make USE_PGXS=1
make install USE_PGXS=1
```

If you need to use the pg_stat_statements extension instead.
Set or change the value for shared_preload_library in your postgresql.conf file:

```
shared_preload_libraries = 'pg_stat_monitor'
```

Set up configuration values in your postgresql.conf file:

```
pg_stat_monitor.pgsm_query_max_len = 2048
```

In a psql session, run the following command to create the view where you can access the collected statistics. We recommend that you create the extension for the postgres database so that you can receive access to statistics from each database.

```bash
sudo -u postgres psql 
\c <db_name>
```

```sql
CREATE EXTENSION pg_stat_monitor;
```

Verify:

```sql
SELECT * FROM pg_stat_monitor_version();
SELECT * FROM pg_stat_monitor();
SHOW shared_preload_libraries;
```

Functions:

- pg_stat_monitor_internal(): Although pg_stat_monitor_internal() is an internal function, the main function for retrieving statistics, which replaces the old pg_stat_monitor_settings() or other functions, is pg_stat_monitor().

- pg_stat_monitor_reset(): Resets the statistics collected by pg_stat_monitor. If you want to clear the statistics, you can use this function:

```sql
SELECT * FROM pg_stat_monitor_reset();
```

To list all installed extensions in PostgreSQL, you can use the following query:

```sql
SELECT * FROM pg_extension;
SELECT * FROM pg_available_extensions WHERE name = 'pg_stat_monitor';
```

To list all functions related to pg_stat_monitor in PostgreSQL, you can use the following query:

```sql
SELECT proname 
FROM pg_proc 
WHERE proname LIKE '%pg_stat_monitor%';
```

Check the version of pg_stat_monitor.

```sql
SELECT default_version FROM pg_available_extensions WHERE name = 'pg_stat_monitor';
```

Example of a query with pg_stat_monitor.

```sql
SELECT bucket, query, calls, total_exec_time, rows
FROM pg_stat_monitor
WHERE query IS NOT NULL
ORDER BY total_exec_time DESC;
```

## Remove Extension pg_stat_monitor

Verify if the extension is installed:

```sql
SELECT * FROM pg_extension WHERE extname = 'pg_stat_monitor';
```

Uninstall the extension from the database:

```sql
DROP EXTENSION pg_stat_monitor;
```

If the extension depends on other configurations or tables, use CASCADE to force the removal:

```sql
DROP EXTENSION pg_stat_monitor CASCADE;
```

This will remove the extension and all associated objects.

-Remove the extension files from the server

Even after removing the extension from the database, the extension files may remain on the file system.

Locate the pg_stat_monitor files. They are usually in the PostgreSQL extensions directory:

```bash
ls /usr/share/postgresql/<version>/extension/ | grep pg_stat_monitor
```

If you find the related files, delete them:

```bash
sudo rm /usr/share/postgresql/<version>/extension/pg_stat_monitor*
```

## Example pg_stat_monitor

https://www.percona.com/blog/pg_stat_monitor-a-new-way-of-looking-at-postgresql-metrics/
https://www.percona.com/blog/improve-postgresql-query-performance-insights-with-pg_stat_monitor/

For example, to view the IP address of the client application that made the query, run the following command:

```sql
SELECT DISTINCT userid::regrole, pg_stat_monitor.datname, substr(query,0, 50) AS query, calls, bucket, bucket_start_time, queryid, client_ip
FROM pg_stat_monitor, pg_database
WHERE pg_database.oid = oid;
```

- Changing the configuration

Run the following query to list available configuration parameters.

```sql
SELECT name, short_desc FROM pg_settings WHERE name LIKE '%pg_stat_monitor%';
```

You can change a parameter by setting a new value in the configuration file. Some parameters require server restart to apply a new value. For others, configuration reload is enough.

https://docs.percona.com/pg-stat-monitor/configuration.html

As an example, let’s set the bucket lifetime from default 60 seconds to 40 seconds. Use the ALTER SYSTEM command:

```sql
ALTER SYSTEM set pg_stat_monitor.pgsm_bucket_time = 40;
```

Restart the server to apply the change.

Verify the updated parameter:

```sql
SELECT name, setting 
FROM pg_settings 
WHERE name = 'pg_stat_monitor.pgsm_bucket_time';

                 name               | setting
  ----------------------------------+---------
   pg_stat_monitor.pgsm_bucket_time |   40
```

