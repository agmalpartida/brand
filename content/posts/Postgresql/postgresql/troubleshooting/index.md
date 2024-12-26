---
Title: Postgresql Troubleshooting
date: 2024-12-22
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

# init postgresql db from scratch

```bash
systemctl stop postgresql
rm -rf /var/lib/postgresql/15/main/*

export PATH=$PATH:/usr/lib/postgresql/15/bin
pg_ctl -D /var/lib/postgresql/15/main/ initdb
```

# init db manually

```bash
sudo -u postgres /usr/lib/postgresql/17/bin/postgres -D /var/lib/postgresql/17/main
```


