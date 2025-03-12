---
Title: "k9scli: Kubernetes cli to manage your clusters"
date: 2025-03-12
categories:
- Kubernetes
tags:
- k8s
keywords:
- cli
summary: 
comments: false
showMeta: false
showActions: false
---

# K9scli

## [CPU/MEM Metrics](https://github.com/derailed/k9s/blob/master/change_logs/release_v0.13.4.md#cpumem-metrics) 

A small change here based on [Benjamin](https://github.com/binarycoded) excellent PR! We've added 2 new columns for pod/container views to indicate percentages of resources request/limits if set on the containers. The columns have been renamed to represent the resources requests/limits as follows:

| Name   | Description                    | Sort Keys |
|--------|--------------------------------|-----------|
| %CPU/R | Percentage of requested cpu    | shift-x   |
| %MEM/R | Percentage of requested memory | shift-z   |
| %CPU/L | Percentage of limited cpu      | ctrl-x    |
| %MEM/L | Percentage of limited memory   | ctrl-z    |

```sh
View: Pods(<namespace>)[number of pods listed]

NAME      pod name
READY     number of pods in ready state / number of pods to be in ready state
RESTARTS  number of times the pod has been restarted so far
STATUS    state of the pod life cycle, such as Running | ... | Completed
CPU       current CPU usage, unit is milli-vCPU
MEM       current main memory usage, unit is MiB
%CPU/R    current CPU usage as a percentage of what has been requested by the pod
%MEM/R    current main memory usage as a percentage of what has been requested by the pod
%CPU/L    current CPU usage as a percentage of the pod's limit (it cannot go beyond its limit)
%MEM/L    current main memory usage as a percentage of the pod's limit (it cannot go beyond its limit)
IP        IP address of the pod
NODE      name of the node the pod is running on
AGE       age of the pod, units are indicated (s = seconds, m = minutes, h = hours, d = days)
```

What about CPU/A and MEM/A when you see the nodes?

- CPU/A is about the CPU allocatable (unit is milli-vCPU)
- MEM/A is the memory allocatable (unit is MiB)

if you're asking yourself like me, what a milli-vCPU is 1/1000 of
(Threads x Cores) x Physical CPU = Number vCPU

