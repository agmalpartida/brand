---
Title: Postgresql Logging
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

# Enable additional context information in logs

1. Adjust the following parameters in postgresql.conf or with ALTER SYSTEM:

```sql
ALTER SYSTEM SET log_line_prefix = '%t [%p]: user=%u,db=%d,app=%a,client=%h ';
```

Explanation of the formats:
- %t → Timestamp.
- %p → Process ID.
- %u → Database user.
- %d → Database the user connected to.
- %a → Application name.
- %h → Client address.

2. Reload configuration

Reload PostgreSQL configuration to apply the changes:

```sql
SELECT pg_reload_conf();
```

# Disable connection and disconnection logging

```sql
ALTER SYSTEM SET log_connections = 'off';
ALTER SYSTEM SET log_disconnections = 'off';

SELECT pg_reload_conf();

SHOW log_connections;
SHOW log_disconnections;
```

- If you prefer to do it manually in the postgresql.conf configuration file, look for the following lines and adjust them:

```
log_connections = off
log_disconnections = off
```

# By user

PostgreSQL allows you to apply configurations for specific users/roles. If a user connects to the desired database, you can enable logging only for that user.

```sql
ALTER ROLE my_user SET log_min_messages = DEBUG1;
ALTER ROLE my_user SET log_statement = 'all';
```

Use DEBUG1 to DEBUG5 temporarily in development or testing environments, or while troubleshooting critical issues in production.

# By sessión

```sql
SET log_statement = 'all';
```

# Connection Time Configuration

```sql
SET log_min_messages = DEBUG1;
SET log_statement = 'all';
```

# Configure log files rotation by size

These are only used if logging_collector is on:

logging_collector
  - on: Enables the log collector, redirecting log messages to files instead of standard output.
        Requires: log_directory and log_filename to define storage location and log file names.
  -off: Disables the log collector; logs are sent to standard output (stdout).
        Impact: Enabling the log collector is essential for capturing and storing logs in files.

```
log_directory = 'pg_log'           # directory where log files are written,
                                   # can be absolute or relative to PGDATA
log_filename = 'postgresql-%a.log' # log file name pattern,
                                   # can include strftime() escapes
log_file_mode = 0600               # creation mode for log files,
                                   # begin with 0 to use octal notation
log_truncate_on_rotation = on      # If on, an existing log file with the
                                   # same name as the new log file will be
                                   # truncated rather than appended to.
                                   # But such truncation only occurs on
                                   # time-driven rotation, not on restarts
                                   # or size-driven rotation.  Default is
                                   # off, meaning append to existing files
                                   # in all cases.
log_rotation_age = 1440            # Automatic rotation of logfiles will
                                   # happen after that time.  0 disables.
log_rotation_size = 0              # Automatic rotation of logfiles will
                                   # happen after that much log output.
                                   # 0 disables
```

Recommended usage of the options for the backup period:

- For backup period of only 24 hours, just use %H: log_filename = 'postgresql-%H.log', set log_rotation_age = 60.
One day could be too short for future investigation and troubleshooting, because the log files will be overwritten after one day.

- For backup period of one week, use %a-%w: log_filename = 'postgresql-%a.log', and set log_rotation_age = 1440.
The log files will be overwritten after one week. %a is the day of the week and %w is the week of the month.

- For backup period of one month, use %d: log_filename = 'postgresql-%d.log', and set log_rotation_age = 1440.
The log file will be overwritten after a month. %d is the day of the month.

## Force log rotation

```sql
SELECT pg_rotate_logfile();
```

- Verify if pg_rotate_logfile is applicable:

The command SELECT pg_rotate_logfile(); only works if:

- logging_collector is enabled (on).
- A log filename pattern that supports rotation is being used, such as postgresql-%a.log.

If any of these conditions are not met, the command will have no effect.

# log_min_messages 
Controls the level of detail for messages recorded in the server logs.

The log_min_messages parameter controls the level of detail for messages recorded in the server logs.
Log Levels for log_min_messages:

- PANIC
Logs only critical events that cause the PostgreSQL server to stop working.
Typically, this level is not needed unless investigating complete server crashes.

- FATAL
Logs events that cause a session to terminate.
Example: authentication errors or critical issues processing a transaction.

- ERROR
Logs errors that affect query execution but do not close the connection.
This is the default level.

- WARNING
Logs warnings that do not stop execution but might indicate potential problems.
Example: corrupted indexes or incorrect configurations.

- NOTICE
Logs informational messages about significant or unusual operations.
Example: information about query rewrites.

- INFO
Provides additional information about server status or queries.
Useful for monitoring activity without high detail levels.

- DEBUG1 to DEBUG5
Logs progressively more detailed debugging information.
  - DEBUG1 provides low detail.
  - DEBUG5 is extremely detailed. Useful for developers and administrators investigating complex issues.
Note: These levels can generate a significant amount of log data, especially in high-activity environments.

# log_statement

The log_statement parameter determines what types of SQL queries will be logged in the server logs. It is used to monitor and debug the activity of queries reaching the server.
Options for log_statement

- none (default)
Does not log any SQL queries.
This is the most restrictive level and generates the least log load.

- ddl
Logs only Data Definition Language (DDL) statements.

```sql
CREATE TABLE;
ALTER TABLE;
DROP INDEX;
```
Useful for tracking structural changes in the database.

- mod
Logs all DDL statements and those that modify data (DML).

```sql
INSERT INTO;
UPDATE;
DELETE;
```
Does not log read-only queries like SELECT.

- all
Logs all SQL queries, including:
  - DDL: CREATE, ALTER, DROP
  - DML: INSERT, UPDATE, DELETE
  - Read-only queries: SELECT
This is the most detailed level and can generate significant log data.
All queries executed by users or applications are logged, including successful and failed queries.

# Additional Logging Parameters

1. client_min_messages: ERROR
   Sets the minimum level of messages sent to the client (application or tool running queries).

2. log_error_verbosity: TERSE
   Controls the level of detail in error messages recorded in logs.

3. log_min_duration_statement: '-1'
   Specifies the minimum time (in milliseconds) a query must take to be logged.

4. log_min_messages: ERROR
   Sets the minimum level of messages written to the server logs.
