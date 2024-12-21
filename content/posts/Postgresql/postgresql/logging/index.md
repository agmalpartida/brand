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

