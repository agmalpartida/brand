---
Title: Haproxy
date: 2024-12-16
categories:
- HAProxy
tags:
- haproxy
- ha
keywords:
- haproxy
summary: ""
comments: false
showMeta: false
showActions: false
---

# HAProxy for Patroni

HAProxy checks the nodes' status using the httpchk option, but the replicas of your Patroni cluster do not respond to the HTTP check on port 8008 in the same way as the primary node. In a Patroni cluster, only the leader should respond as active on this HTTP port, while the replicas might not, causing HAProxy to mark them as "down."

Adjust the HAProxy configuration to properly check the nodes' status based on their roles within the cluster (leader or replica). This can be achieved by using the Patroni endpoint that returns the status of each node, checking if the node is a replica or the leader.

Patroni provides an HTTP endpoint that shows the node's state (/master or /replica).

```
listen postgres
    bind *:5432
    option httpchk GET /master
    http-check expect string {"state":"running"}
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server node1 10.201.217.181:5432 maxconn 100 check port 8008
    server node2 10.201.217.182:5432 maxconn 100 check port 8008
    server node3 10.201.217.183:5432 maxconn 100 check port 8008
```

Option httpchk GET /master: Performs a GET request to the /master endpoint. This checks if the node is the leader. If the node responds with the correct status ({"state":"running"}), HAProxy will consider it "up."
The http-check expect string {"state":"running"}: Verifies that the response contains "state":"running", indicating that the node is in good health (leader or replica).


