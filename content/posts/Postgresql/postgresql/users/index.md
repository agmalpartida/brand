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

# Change Password

```sql
ALTER ROLE rol_name WITH PASSWORD 'nueva_contraseña';
```

If you are changing the password for the role you are connected with, you can use:

```
\password role_name
```

To verify that the password has been changed successfully, you can check the roles in the pg_roles table:

```sql
SELECT rolname, rolvaliduntil FROM pg_roles WHERE rolname = 'rol_name';
```

# Create users
Verify schema-level permissions. If the user has trouble accessing the table due to schema restrictions, you also need to grant permissions on the schema.
Allow schema access:

```sql
GRANT USAGE ON SCHEMA public TO user_name;
```

Allow object creation in the schema

```sql
GRANT CREATE ON SCHEMA public TO user_name;
```

# Delete users

If the role has dependencies (e.g., it owns any objects), you must reassign those objects before deleting the role. Use the REASSIGN OWNED command to reassign the objects to another role before removing it.

- Reassign all objects from ‘rol1’ to ‘rol2’
```sql
REASSIGN OWNED BY rol1 TO rol2;
```

- Remove all privileges granted to the role

```sql
DROP OWNED BY rol1;
DROP ROLE rol1;
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

# Revoke permissions

Before deleting a user, it is good practice to revoke their permissions on all databases and schemas.

```sql
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM user_name;
REVOKE ALL PRIVILEGES ON DATABASE db_name FROM user_name;

DROP ROLE user_name;
```

PostgreSQL does not allow deleting a user if they own tables, databases, sequences, etc. You must transfer or delete these objects first.

```sql
SELECT tablename FROM pg_tables WHERE tableowner = 'user_name';
SELECT datname FROM pg_database WHERE datdba = (SELECT oid FROM pg_roles WHERE rolname = 'user_name');
```


