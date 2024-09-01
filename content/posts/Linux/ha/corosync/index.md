---
Title: Corosync and Pacemaker cluster
date: 2024-09-01
categories:
- Linux
tags:
- corosync
- pacemaker
- ha
keywords:
- ha
summary: Setting a cluster up and running
comments: false
showMeta: false
showActions: false
---

**Corosync** is an open source program that provides cluster membership and messaging capabilities, often referred to as the messaging layer, to client servers. Corosync uses UDP transport between ports 5404 and 5406.

**Pacemaker** is an open source cluster resource manager (CRM), a system that coordinates resources and services that are managed and made highly available by a cluster. 
In essence, **Corosync enables servers to communicate as a cluster** , while **Pacemaker provides the ability to control how the cluster behaves** .

```sh
iptables -A INPUT  -i eth1 -p udp -m multiport --dports 5404,5405,5406 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT  -o eth1 -p udp -m multiport --sports 5404,5405,5406 -m conntrack --ctstate ESTABLISHED -j ACCEPT
```

`apt-get install pacemaker` 
Note that Corosync is installed as a dependency of the Pacemaker package.

# Configure Corosync

Corosync must be configured so that our servers can communicate as a cluster.

1. Create Cluster Authorization Key

In order to allow nodes to join a cluster, Corosync requires that each node possesses an identical cluster authorization key.

On the primary server, install the haveged package:

`apt-get install haveged` 

This software package allows us to easily increase the amount of entropy on our server, which is required by the corosync-keygen script.

`On the primary server`, run the corosync-keygen script:

`corosync-keygen` 

This will generate a 128-byte cluster authorization key, and write it to `/etc/corosync/authkey`.

Now that we no longer need the haveged package, let’s remove it from the primary server:

```sh
apt-get remove --purge haveged
apt-get clean
```
On the primary server, copy the authkey to the secondary server:

`scp /etc/corosync/authkey username@secondary_ip:/tmp` 

On the secondary server, move the authkey file to the proper location, and restrict its permissions to root:

```sh
mv /tmp/authkey /etc/corosync
chown root: /etc/corosync/authkey
chmod 400 /etc/corosync/authkey
```

Now both servers should have an identical authorization key in the /etc/corosync/authkey file.

2. Configure Corosync Cluster

In order to get our desired cluster up and running, we must set up these:

On both servers, open the corosync.conf file for editing.

`vi /etc/corosync/corosync.conf` 

Here is a Corosync configuration file that will allow your servers to communicate as a cluster. 
- `bindnetaddr` should be set to the private IP address of the server you are currently working on. With the exception of the bindnetaddr, the file should be identical on both servers.

```sh
    totem {

      version: 2
      cluster_name: lbcluster
      transport: udpu
      interface {
        ringnumber: 0
        bindnetaddr: server_private_IP_address
        broadcast: yes
        mcastport: 5405
      }
    }

    quorum {

      provider: corosync_votequorum

      two_node: 1
    }

    nodelist {
      node {
        ring0_addr: primary_private_IP_address
        name: primary
        nodeid: 1
      }
      node {
        ring0_addr: secondary_private_IP_address
        name: secondary
        nodeid: 2
      }
    }

    logging {
      to_logfile: yes
      logfile: /var/log/corosync/corosync.log
      to_syslog: yes
      timestamp: on
    }
```

The **totem section**, which refers to the Totem protocol that Corosync uses for cluster membership, specifies how the cluster members should communicate with each other. In our setup, the important settings include transport: udpu (specifies unicast mode) and bindnetaddr (specifies which network address Corosync should bind to).

The **quorum section** specifies that this is a two-node cluster, so only a single node is required for quorum (two_node: 1). This is a workaround of the fact that achieving a quorum requires at least three nodes in a cluster. This setting will allow our two-node cluster to elect a coordinator (DC), which is the node that controls the cluster at any given time.

The **nodelist section** specifies each node in the cluster, and how each node can be reached. Here, we configure both our primary and secondary nodes, and specify that they can be reached via their respective private IP addresses.

The **logging section** specifies that the Corosync logs should be written to /var/log/corosync/corosync.log.

3. We need to configure Corosync to allow the Pacemaker service.

On both servers, create the pcmk file in the Corosync service directory with an editor.

`vi /etc/corosync/service.d/pcmk` 

Then add the Pacemaker service:

```sh
service {
  name: pacemaker
  ver: 1
}
```

This will be included in the Corosync configuration, and allows Pacemaker to use Corosync to communicate with our servers.

By default, the Corosync service is disabled. On both servers, change that by editing /etc/default/corosync:

`vi /etc/default/corosync` 

Change the value of START to yes:

`START=yes` 

Now we can start the Corosync service.

On both servers, start Corosync:

`service corosync start` 

Once Corosync is running on both servers, they should be clustered together:

`corosync-cmapctl | grep members` 

# Start and Configure Pacemaker

Pacemaker, which depends on the messaging capabilities of Corosync, is now ready to be started and to have its basic properties configured.
Enable and Start Pacemaker

The Pacemaker service requires Corosync to be running, so it is disabled by default.

On both servers, enable Pacemaker to start on system boot. It is important to specify a start priority that is higher than Corosync’s, so that Pacemaker starts after Corosync.

Now let’s start Pacemaker:

`service pacemaker start` 

To interact with Pacemaker, we will use the crm utility.

Check Pacemaker with crm:

`crm status` 

- First, Current DC (Designated Coordinator) should be set to either primary or secondary. 
- Second, there should be 2 Nodes configured and 0 Resources configured. 
- Third, both nodes should be marked as online. If they are marked as offline, try waiting 30 seconds and check the status again to see if it corrects itself.

From this point on, you may want to run the interactive CRM monitor in another SSH window (connected to either cluster node). This will give you real-time updates of the status of each node, and where each resource is running:

`crm_mon` 

The output of this command looks identical to the output of crm status except it runs continuously. If you want to quit, press Ctrl-C.

## Configure Cluster Properties

Now we’re ready to configure the basic properties of Pacemaker. Note that all Pacemaker (crm) commands can be run from either node server, as it automatically synchronizes all cluster-related changes across all member nodes.

We want to disable STONITH—a mode that many clusters use to remove faulty nodes—because we are setting up a two-node cluster. To do so, run this command on either server:

`crm configure property stonith-enabled=false` 

We also want to disable quorum-related messages in the logs:

`crm configure property no-quorum-policy=ignore` 

Again, this setting only applies to 2-node clusters.

If you want to verify your Pacemaker configuration, run this command:

`crm configure show` 

This will display all of your active Pacemaker settings. Currently, this will only include two nodes, and the STONITH and quorum properties you just set.

## Create Reserved IP Reassignment Resource Agent

Now that Pacemaker is running and configured, we need to add resources for it to manage.

**resources** are services that the cluster is responsible for making highly available. In Pacemaker, adding a resource requires the use of a resource agent, which act as the interface to the service that will be managed. Pacemaker ships with several resource agents for common services, and allows custom resource agents to be added.

In our setup, we want to make sure that the service provided by our web servers, primary and secondary, is highly available in an active/passive setup, which means that we need a way to ensure that our Reserved IP is always pointing to a server that is available. To enable this, we need to set up a resource agent that each node can run to determine if it owns the Reserved IP and, if necessary, run a script to point the Reserved IP to itself. Reserved IPs are sometimes known as floating IPs. In the following examples, we’ll refer to the resource agent as "**FloatIP OCF**", and the Reserved IP reassignment script as assign-ip. Once we have the FloatIP OCF resource agent installed, we can define the resource itself, which we’ll refer to as FloatIP.

We need a script to assign an floating ip to our cluster:

`chmod +x /usr/local/bin/assign-ip` 

- Let’s install the Float IP Resource Agent next.

1. Download FloatIP OCF Resource Agent

Pacemaker allows the addition of OCF resource agents by placing them in a specific directory.

On both servers, create the resource agent provider directory with this command:

`mkdir /usr/lib/ocf/resource.d/<agent>` 

On both servers, download the FloatIP OCF Resource Agent:

`curl -o /usr/lib/ocf/resource.d/<agent>/floatip https://gist.githubusercontent.com/thisismitch/b4c91438e56bfe6b7bfb/raw/2dffe2ae52ba2df575baae46338c155adbaef678/floatip-ocf` 

On both servers, make it executable:

`chmod +x /usr/lib/ocf/resource.d/<agent>/floatip` 

Now we can use the FloatIP OCF resource agent to define our FloatIP resource.

## Add FloatIP Resource

With our FloatIP OCF resource agent installed, we can now configure our FloatIP resource.

On either server, create the FloatIP resource:

```sh
crm configure primitive FloatIP ocf:<agent>:floatip \
  params ...
```

This creates a **primitive resource**, which is a generic type of cluster resource, called "FloatIP", using the FloatIP OCF Resource Agent we created earlier (ocf:<agent>:floatip).

If you check the status of your cluster, you should see that the FloatIP resource is defined and started on one of your nodes:

Currently, the failover (Reserved IP reassignment) is only triggered if the active host goes offline or is unable to communicate with the cluster. A better version of this setup would specify additional resources that should be managed by Pacemaker. This would allow the cluster to detect failures of specific services, such as load balancer or web server software.


# Test High Availability

1. use curl to access the Reserved IP on a 1 second loop.

`while true; do curl reserved_IP_address; sleep 1; done` 

If we cause the primary server to fail, by powering it off or by changing the primary node’s cluster status to standby, we will see if the Reserved IP gets reassigned to the secondary server.

Let’s reboot the primary server now. After a few moments, the primary server should become unavailable. 

That is, the Reserved IP address should be reassigned to point to the IP address of the secondary server. That means that your HA setup is working, as a successful automatic failover has occurred.

If you check the status of Pacemaker, you should see that the FloatIP resource is started on the secondary server. Also, the primary server should temporarily be marked as OFFLINE but will join the Online list as soon as it completes its reboot and rejoins the cluster.

# Troubleshooting the Failover

```sh
crm_mon
crm configure show
```

If the crm commands aren’t working at all, you should look at the Corosync logs for clues:

`tail -f /var/log/corosync/corosync.log` 

# Miscellaneous CRM Commands

These commands can be useful when configuring your cluster.

You can set a node to standby mode, which can be used to simulate a node becoming unavailable, with this command:

`crm node standby NodeName` 

You can change a node’s status from standby to online with this command:

`crm node online NodeName` 

You can edit a resource, which allows you to reconfigure it, with this command:

`crm configure edit ResourceName` 

You can delete a resource, which must be stopped before it is deleted, with these command:

```sh
crm resource stop ResourceName
crm configure delete ResourceName
```

Lastly, the crm command can be run by itself to access an interactive crm prompt:

`crm` 
