+++
categories = ['Proxmox']
comments = false
keywords = ['virtualization']
showActions = false
showMeta = false
tags = ['proxmox']
title = 'Proxmox Remove Node from Cluster Including Ceph'
+++

# Proxmox

![](assets/ha-diagram-animated.gif) 

The pvecm command is the tool you use to manage cluster nodes. It provides capabilities for checking the status of nodes, adding new nodes, and, crucially, removing nodes from the cluster.

```sh
pvecm nodes
```

This command lists all nodes in the cluster and statuses. This definitely helps to understand the current topology before making changes or removing a node from a cluster, including the node ID that we will need later.

You can also see which nodes are listed in the directory:

```sh
/etc/pve/nodes/nodename
```

## Preparing to Remove a Node

Before removing a node from the cluster, assess the impact on virtual machines and services running on the node. It may be necessary to migrate virtual machines to other nodes or plan for downtime.

Example Command for Listing Virtual Machines on a Node using the following command

```sh
qm list
```

This command will show all virtual machines and containers running on the current node. So, you will want to remote into the node you are planning on removing from the cluster.

## Make sure you have backups

Make sure you have a backup using Proxmox Backup Server, or you have a replication job that has created another copy of the data.

### Removing a node step-by-step

This involves the following workflow:

1. Migrate virtual machines
2. Cleanup Ceph HCI and CephFS (if applicable)
3. Remove the node from a cluster using the pvecm command
4. Shut down the node
5. Verify and check the cluster after removal

1. Migrate virtual machines

If any virtual machines or services were still running on the node, you can move those to another cluster node using the following command for VM migration:

```sh
qm migrate <VMID> <TargetNode>
```

Replace <VMID> with the virtual machine ID and <TargetNode> with the node to which you want to migrate the VM. You may need to use the `--online`  flag if it is online.

Make sure the virtual machines have successfully migrated to a different host before you assume everything is good. Ping the VM, or remote into the VM to perform sanity checks on the health of the virtual machine.


2. Cleanup Ceph HCI and CephFS (if applicable)

There is additional complexity when you have a node that is contributing to Ceph HCI storage.

Get rid of the Monitor and Manager components on the node. After removing ceph monitor and manager.
Next, down and out the OSDs (Down and outing ceph osds).
Make sure to allow time for the degraded state of the Ceph components to get healthy before destroying the OSDs. 

Components start rebuilding, Objects begin repairing. Components are rebuilt successfully.

Now, we can destroy the OSDs on the host without issue. This will remove the local data on the OSDs that was used for Ceph.

Destroying osd disks from the host:

If you are running CephFS, make sure to stop and destroy the Metadata Servers.
Destroying the metadata server for cephfs

Remove the OSD from the Ceph crush map.

```sh
ceph osd crush remove pmox01
```

Removing the host from the crush map in ceph

3. Removing the Node Using pvecm delnode

Use the pvecm delnode command to remove the node from the cluster. This command will update the cluster’s configuration and safely remove references to the node and the cluster conf file.

Example Command:

```sh
pvecm delnode nodename
```

Replace nodename with the actual name or ID of the node you want to remove.


4. Shut down the node

Now that everything has been removed, you can shut down the node if you don’t plan on utilizing it any longer after the delete process. Use the command below on the physical servers removed from the cluster.

Example Command for Safely Shutting Down a Proxmox Node:

```sh
shutdown -h now
```

5. Verify and check the cluster after removing a node

Verify the cluster is running correctly on the remaining nodes. Check the following:

- Check log entries, including cluster logs
- Check the load distribution
- Make sure virtual machines are healthy running on the new hosts

