---
Title: Postgresql operations
date: 2024-09-01
categories:
- Postgresql
tags:
- postgresql
keywords:
- postgresql
summary: "Quick commands to common operations"
comments: false
showMeta: false
showActions: false
---

# Configuration

It is possible to check if the configuration values have been correctly applied to the database by running the following command:

```sql
SELECT name,setting,context,source FROM pg_settings WHERE NAME IN ('listen_addresses','archive_mode','password_encryption');
```

```sql
SHOW log_directory;
SHOW log_filename;
```

# tables

## list tables

```sh
\dt: list all tables in the current database using your search_path
\dt *.: list all tables in the current database regardless your search_path
```
- This lists tables in the current database

```sql
SELECT table_schema,table_name
FROM information_schema.tables
ORDER BY table_schema,table_name;
```

# databases

## create db

```sql
CREATE DATABASE db_name
WITH OWNER admin
ENCODING 'UTF8'
LC_COLLATE 'C.UTF-8'
LC_CTYPE 'C.UTF-8'
TEMPLATE template0;
```

## list databases
- psql tool

`\l: list all databases` 

- sql query

```sql
SELECT datname FROM pg_database
WHERE datistemplate = false;
```

## To switch databases:

```sh
\connect database_name or \c database_name
```

# users

## Listing users

`\du+` 

- The following statement returns all users in the current database server by querying data from the pg_catalog.pg_user catalog:

```sql
SELECT usename AS role_name,
  CASE 
     WHEN usesuper AND usecreatedb THEN 
	   CAST('superuser, create database' AS pg_catalog.text)
     WHEN usesuper THEN 
	    CAST('superuser' AS pg_catalog.text)
     WHEN usecreatedb THEN 
	    CAST('create database' AS pg_catalog.text)
     ELSE 
	    CAST('' AS pg_catalog.text)
  END role_attributes
FROM pg_catalog.pg_user
ORDER BY role_name desc;
```

## Change password

```sql
ALTER USER postgres PASSWORD 'demoPassword';
```

# psql
- users list
```
\du
```
- db owner 

```
\dt+ <scheme>.*
\dt+ *.*
```

```sql
SELECT datname AS base_de_datos, pg_catalog.pg_get_userbyid(datdba) AS owner
FROM pg_database;

SELECT pg_catalog.pg_get_userbyid(datdba) AS owner 
FROM pg_database
WHERE datname = 'db_name';
```

- export result

```
\o file.txt
```

- exec script

```
psql -d mydb -f tasks.sql

\i tasks.sql
```
