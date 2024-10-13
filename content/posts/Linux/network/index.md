---
Title: Networking on Linux 
date: 2024-10-13
categories:
- Linux
tags:
- network
- linux
keywords:
- network
summary: 
comments: false
showMeta: false
showActions: false
---


# Network Troubleshooting Commands

## Layer 1: The Physical Layer
- **Show interface status:**
    ```bash
    ip link show
    ip link set eth0 up
    ip -br link show
    ```

- **Show interface statistics:**
    ```bash
    ip -s -h l show dev enp1s0
    ```

- **Check interface speed with ethtool:**
    ```bash
    ethtool eth0
    ```

## Layer 2: The Data Link Layer
- **Address Resolution Protocol (ARP):**
    ```bash
    ip neighbor show
    ```

- **Delete ARP entry:**
    ```bash
    ip neighbor delete 192.168.122.170 dev eth0
    ```

## Layer 3: The Network/Internet Layer
- **Show IP addresses:**
    ```bash
    ip -br address show
    ```

- **Ping utility for testing connectivity:**
    ```bash
    ping 192.168.122.1
    ```

- **Trace the route to a host:**
    ```bash
    tracepath -n sat65server
    ```

- **Show routing table:**
    ```bash
    ip route show
    ip route show 10.0.0.0/8
    ```

## Layer 4: The Transport Layer
- **Check listening ports and associated processes:**
    ```bash
    ss -tunlp4
    sudo ss -tnlp
    ```

- **Check TCP connections:**
    ```bash
    ss dst 192.168.122.1
    ```

- **Test UDP port with netcat:**
    ```bash
    nc 192.168.122.1 -u 80
    ```

### Notes:
- The `tracepath` command is used to display the network connectivity path between the local host and a remote host, identifying all routers in the path.
- ARP helps resolve IP addresses to MAC addresses, and the ARP table can be manipulated using the `ip neighbor` command.
- Tools like `ping` and `traceroute` are crucial for testing network connectivity and identifying routes between hosts.


