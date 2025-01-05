---
Title: "Installing talos on a Turing Piv2 board with cm4 modules"
date: 2025-01-05
categories:
- Kubernetes
tags:
- k8s
keywords:
- k8s
- talos
summary: "Installing talos on a Turing Piv2 board with cm4 modules."
comments: false
showMeta: false
showActions: false
---

# Installing talos on a Turing Piv2 board with cm4 modules.

## Flash image to all nodes

1) download metal-arm64.raw.xz from https://github.com/siderolabs/talos/releases

2) after putting cm4 in usb mode (use rpi cm4 emmc usb programming stick or use tpiv2, see: https://help.turingpi.com/hc/en-us/articles/8687165986205-Install-OS)
3) flash talos, this works for sd card and emmc storage. Check the correct device name.

   ```
   time xz -d < metal-arm64.raw.xz | sudo dd of=/dev/sda bs=1M status=progress conv=fsync
   893665280 bytes (894 MB, 852 MiB) copied, 3 s, 298 MB/s1306525696 bytes (1,3 GB, 1,2 GiB) copied, 3,82763 s, 341 MB/s

   0+152937 records in
   0+152937 records out
   1306525696 bytes (1,3 GB, 1,2 GiB) copied, 99,591 s, 13,1 MB/s

   real	1m39,600s
   user	0m3,607s
   sys	0m0,226s
   ```

4) make sure tpiv4 node is no longer in device mode, it should be host mode for normal operation.
5) optionally log in to bmc and connect to serial console of the node with minicom.

## Minicom example for node2

```shell
microcom -s 115200 /dev/ttyS1
```

## Hardwired bmc serial port connections to nodes

|Node  | bmc device |
|------|----------|
|Node 1|/dev/ttyS2|
|Node 2|/dev/ttyS1|
|Node 3|/dev/ttyS4|
|Node 4|/dev/ttyS5|

## Boot nodes

1) boot all the nodes by powering down and up using the bmc


## Create Cluster

nc -zv 192.168.1.71 50000
talosctl -n node1 get links


