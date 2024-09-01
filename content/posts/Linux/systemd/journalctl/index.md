---
Title: Systemd Logging
date: 2024-09-01
categories:
- Linux
tags:
- systemd
- linux
- logging
- journalctl
keywords:
- journalctl
summary: Common systemd logging tasks
comments: false
showMeta: false
showActions: false
---

# Configuration

## Size
You can set this in /etc/systemd/journald.conf like so:

`SystemMaxUse=100M` 

This will be enforced on the next reboot or restart of the journald service:

```sh
$ systemctl restart systemd-journald
```


