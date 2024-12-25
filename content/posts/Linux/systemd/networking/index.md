---
Title: Systemd Networking
date: 2024-09-01
categories:
- Linux
tags:
- linux
- systemd
- networking
keywords:
- network
summary: "Daemons related to systemd"
comments: false
showMeta: false
showActions: false
---

# systemd-networkd-wait-online

systemd-networkd-wait-online[1458]: Event loop failed: Connection timed out

The systemd-networkd-wait-online service in Linux is part of systemd, and its main purpose is to ensure that the system does not proceed with booting until the configured network interfaces are fully operational or until a predefined timeout is reached. This service is useful for applications or services that rely on a stable network connection before starting.

The systemd-networkd-wait-online service is crucial to ensure that applications and services that depend on an operational network do not start prematurely. Configuring it properly can prevent many network connectivity issues during system startup.

## Main Functions:

- **Waiting for Network Connectivity** :  
systemd-networkd-wait-online waits until the configured network interfaces are in an operational state. ("online").

- **Synchronization of Dependent Services** :  
It ensures that services dependent on the network do not start until network connectivity is available, preventing errors during the startup of those services.

- **Timeout Management** :  
If the network interfaces are not ready within a specific timeout period (default is 120 seconds), the service fails and the system continues with the boot process, but an error message will be logged.

## How It Works

-  **Network Interface Configuration** :  
systemd-networkd-wait-online review the network interfaces configured by systemd-networkd to determine their status. 

`cat /lib/systemd/system/systemd-networkd-wait-online.service` 

```
[Service]
ExecStart=
ExecStart=/lib/systemd/systemd-networkd-wait-online --timeout=60
```

## Troubleshooting

```sh
systemctl disable systemd-networkd-wait-online

networkctl status

journalctl -u systemd-networkd
```

- Show service

```
systemctl cat <service>
```

- Edit service

```
systemctl edit <service>
```

