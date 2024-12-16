---
Title: Keepalived for Haproxy
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

- **INTERFACES** : Ensure that ethX is the correct interface on your server.

- **HAProxy** : Ensure HAProxy is correctly installed and configured, as Keepalived tracks this service.

# Configuration

- `global_defs { }` 

This block is used to define global parameters for Keepalived. You could define global options here, such as the router identification or email notifications.

- `vrrp_script chk_haproxy { ... }` 

This block defines a monitoring script to check the status of HAProxy. Keepalived uses this script to perform periodic checks.

- script "pkill -0 haproxy":

This command checks if the HAProxy process is running. pkill -0 does not kill the process; it simply verifies its existence.
If the script fails (i.e., if HAProxy isn’t running), Keepalived adjusts the state and can trigger a VRRP state change.
  - interval 2:
    This parameter sets the interval (in seconds) between script executions. In this case, Keepalived will check if HAProxy is active every 2 seconds.
  - weight 2:
    Defines the weight to be added or subtracted from the node’s priority. If the check passes (HAProxy is running), 2 points are added to the priority. If it fails, Keepalived may subtract those points and adjust the node’s priority.

- `vrrp_instance VI_1 { ... }` 

This block defines a VRRP instance. Each instance represents a set of rules that Keepalived follows to switch between nodes. Here, the details for the Virtual Router Redundancy Protocol (VRRP) are configured.
  - interface eth1:
Specifies the network interface for this VRRP instance. It must be a valid interface on your system (e.g., eth0, eth1). Use ip a to verify your interfaces.
  - state MASTER:
Sets the initial state of this instance on this server.
  - MASTER: This server is currently the primary.
  -	BACKUP: This node is in a backup state.
Keepalived will automatically switch the state from MASTER to BACKUP when necessary based on the status of the other node.
  - priority 101:
Sets the priority of this node. The node with the highest priority becomes the MASTER. If you have two nodes, the one with the lower priority will be the BACKUP. Typically, the MASTER has a slightly higher value (e.g., 101 for MASTER and 100 for BACKUP).
  - virtual_router_id 51:
This is the Virtual Router ID (VRID). It’s a unique number between 0 and 255 that identifies this VRRP instance within the network. Ensure both nodes in the same network have the same virtual_router_id.
  - unicast_src_ip 192.168.50.10:
Specifies the unicast source IP for VRRP communication on this node. This will be the initial MASTER’s main IP on the network.
  - unicast_peer { 192.168.50.20 }:
Defines the IP of the secondary or backup node to which Keepalived will send VRRP packets in unicast mode. In this case, 192.168.50.20 is the BACKUP server.
  - authentication { auth_type PASS, auth_pass 1234 }:
Configures authentication between nodes:
  - auth_type PASS: The authentication type is a simple password. Alternatively, you can use AH for more secure authentication.
  - auth_pass 1234: The password for authentication. It must be the same on both nodes (MASTER and BACKUP) for proper communication.
  - virtual_ipaddress { 192.168.50.108 }:
Defines the virtual IP address (VIP) used by the VRRP group. This VIP will float between the MASTER and BACKUP. Clients will connect to this IP, ensuring it’s always available as long as one node is active.
  - track_script { chk_haproxy }:
Specifies that the previously defined script (chk_haproxy) will be monitored. If the script fails (e.g., HAProxy stops working), it affects this node’s state and priority.

Summary:
  - VRRP Script: Keepalived will execute the chk_haproxy script to monitor HAProxy every 2 seconds. If the script passes (HAProxy is running), the node maintains MASTER status or gains 2 priority points.
  - VRRP Failover: If the MASTER node fails (e.g., HAProxy stops running), Keepalived reduces this node’s priority, and the BACKUP node takes over, announcing the virtual IP (192.168.50.108) as its own.
  -	High Availability: This ensures that if the MASTER server fails, the BACKUP server automatically takes over, providing high availability through the virtual IP address.
