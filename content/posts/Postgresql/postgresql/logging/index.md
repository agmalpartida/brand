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


