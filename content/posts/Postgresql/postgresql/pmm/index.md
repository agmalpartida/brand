---
Title: PSQL Percona Monitoring and Management
date: date
categories:
- Postgresql
tags:
- postgresql
- percona
keywords:
- postgresql
- pmm
- percona
summary: ""
comments: false
showMeta: false
showActions: false
---

# Backup db
pg_dump -h <origin ip> -p <origin port> -U postgres -d db_name -F c -b -v -f file.sql

- -d db_name
- -F c: more efficient
- -b: binary data incluyed (blobs or binary objects)
- -v: more detailed
- -f: file_name

# Backup roles

```bash
pg_dumpall -h <origin ip> -p <origin port> -U postgres --roles-only -f roles.sql
```

# Restore

1. drop db before recovery

```sql
postgres=# DROP DATABASE db_name;
DROP DATABASE
```

2. create db

```bash
createdb -h <destination ip> -p <destination port> -U postgres db_name
```

3. restore
pg_restore -h <destination ip> -p <destination port> -U postgres -d db_name -v file.sql

# Restore roles

```bash
psql -h <destination ip> -p <destination port> -U postgres -f roles.sql
```


