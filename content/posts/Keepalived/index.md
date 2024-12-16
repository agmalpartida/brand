---
Title: Keepalived
date: 2024-12-16
categories:
- Keepalived
tags:
- postgresql
- ha
- keepalived
keywords:
- keepalived
summary: ""
comments: false
showMeta: false
showActions: false
---

# Overview

Keepalived, which is mainly used to provide high availability by implementing the VRRP (Virtual Router Redundancy Protocol). Your configuration is commonly used to monitor services like HAProxy and automatically switch between servers in case of failures.

```bash
apt update && sudo apt upgrade -y
apt install keepalived -y

vi /etc/keepalived/keepalived.conf

systemctl restart keepalived
systemctl enable keepalived
```
