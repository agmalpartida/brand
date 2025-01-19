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
summary: "Log Management with Journalctl"
comments: false
showMeta: false
showActions: false
---

# Useful commands

```sh
journalctl -xe -f
sudo journalctl --rotate
sudo journalctl --vacuum-time=1s

--since "2019-01-30 14:00:00"
--since today
```

# Configuration

## Size
You can set this in /etc/systemd/journald.conf like so:

`SystemMaxUse=100M` 

This will be enforced on the next reboot or restart of the journald service:

```sh
$ systemctl restart systemd-journald
```


