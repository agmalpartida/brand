---
Title: Postgresql operations
date: 2024-09-01
categories:
- Postgresql
tags:
- postgresql
keywords:
- postgresql
summary: Quick commands to common operations
comments: false
showMeta: false
showActions: false
---

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


