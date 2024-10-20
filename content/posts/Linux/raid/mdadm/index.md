---
Title: Managing RAID with mdadm on Linux 
date: 2024-10-13
categories:
- Linux
tags:
- raid
- linux
keywords:
- raid
summary: "Software RAID"
comments: false
showMeta: false
showActions: false
---

# Managing RAID with mdadm on Linux

`mdadm` is a tool for managing RAID arrays on Linux systems. Here are some basic tasks you can perform with `mdadm`:

## 1. Create a RAID array

To create a RAID array, use the `mdadm --create` command. For example, to create a RAID 5 array with three disks (/dev/sd[b-d]):

```bash
sudo mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd
```

## 2. Add a disk to an existing RAID array

To add a disk to an existing RAID array, use the `mdadm --add` command. For example, to add `/dev/sde` to `/dev/md0`:

```bash
sudo mdadm --add /dev/md0 /dev/sde
```

## 3. Remove a disk from a RAID array

To remove a disk from a RAID array, first mark the disk as faulty, then remove it. For example, to remove `/dev/sdc` from `/dev/md0`:

```bash
sudo mdadm --fail /dev/md0 /dev/sdc
sudo mdadm --remove /dev/md0 /dev/sdc
```

## 4. Monitor the RAID array status

To check the status of your RAID array, use the `mdadm --detail` command. For example, to see the details of `/dev/md0`:

```bash
sudo mdadm --detail /dev/md0
```

## 5. Repair a RAID array

To repair a RAID array, you need to add a new disk and reassign the array. For example, after adding `/dev/sdf`:

```bash
sudo mdadm --add /dev/md0 /dev/sdf
```

The rebuild process will begin automatically.

## 6. Save RAID configuration

To ensure that the RAID configuration is loaded at boot, save the current configuration to the `mdadm` config file. This can be done with the `mdadm --detail --scan` command and redirecting the output to the configuration file:

```bash
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
```

Here’s an example output of the configuration:

```bash
ARRAY /dev/md/md2 metadata=1.2 name=md2 UUID=a1079a27:f9562ae5:a195fe0d:fbe4a305
ARRAY /dev/md/md3 metadata=1.2 name=md3 UUID=30a7e838:c1e7d6ea:03255854:5b607a73
ARRAY /dev/md/srvdatastoreplt01:6 metadata=1.2 name=srvdatastoreplt01:6 UUID=602da39c:111b2659:8fdccdaf:9f4998b4
```

Then, update `initramfs`:

```bash
sudo update-initramfs -u
```

## 7. Stop a RAID array

To stop a RAID array, use the `mdadm --stop` command. For example, to stop `/dev/md0`:

```bash
sudo mdadm --stop /dev/md0
```

## 8. Delete a RAID array

To delete a RAID array, first stop the array and then remove the device. For example:

```bash
sudo mdadm --stop /dev/md0
sudo mdadm --remove /dev/md0
```

## 9. Check current RAID configuration

To check the current RAID configuration, you can use:

```bash
sudo mdadm --examine /dev/sd[b-d]
```

Here’s an example output from examining a RAID device:

```bash
sudo mdadm --examine /dev/nvme1n1p2
```

```bash
/dev/nvme1n1p2:
          Magic : a92b4efc
        Version : 1.2
    Feature Map : 0x0
     Array UUID : a1079a27:f9562ae5:a195fe0d:fbe4a305
           Name : md2
  Creation Time : Mon Apr 29 09:34:15 2024
     Raid Level : raid1
   Raid Devices : 2
...
   Device Role : Active device 1
   Array State : AA ('A' == active, '.' == missing, 'R' == replacing)
```

## Integrity Check

`mdadm` also allows checking the integrity of a RAID device by running a consistency check.

### 1. Check the current status of the RAID

Before performing a consistency check, review the current status of the RAID array:

```bash
cat /proc/mdstat
```

### 2. Start the RAID check

To start a consistency check on a RAID array, you can use the following command, replacing `/dev/mdX` with the name of the RAID device (e.g., `/dev/md0`):

```bash
echo check > /sys/block/mdX/md/sync_action
```

### 3. Monitor the progress

You can monitor the progress of the check using:

```bash
cat /proc/mdstat
```

### 4. Review the results

After the check completes, review any errors or issues with:

```bash
mdadm --detail /dev/mdX
```

### Optional: Repair detected errors

If errors were found during the check, you can force a repair by running:

```bash
echo repair > /sys/block/mdX/md/sync_action
```

## Summary of Commands

- View RAID status:

```bash
cat /proc/mdstat
```

- Start consistency check:

```bash
echo check > /sys/block/mdX/md/sync_action
```

- Monitor progress:

```bash
cat /proc/mdstat
```

- View RAID details:

```bash
mdadm --detail /dev/mdX
```

For more detailed options and advanced usage, consult the `mdadm` manual:

```bash
man mdadm
```
