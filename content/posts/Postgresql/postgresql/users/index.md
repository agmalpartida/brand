---
Title: Postgresql Users
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

# Active connections

```sql
SELECT pid, usename, datname, application_name FROM pg_stat_activity WHERE usename = 'user_name';
```

# Force user logout

```sql
REVOKE CONNECT ON DATABASE db_name FROM PUBLIC;

SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'db_name'
  AND pid <> pg_backend_pid();
```

# Change the ownership of their objects

```sql
ALTER TABLE table_name OWNER TO user ;
```

If you can’t transfer ownership, delete the objects first:

```sql
DROP TABLE table_name;
DROP DATABASE db_name;
```

# Revoke permissions:

```sql
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM user_name;
```
