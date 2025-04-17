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

## Shortcuts

```
Ctrl-d: delete.
Ctrl-k: kill (no confirmation).
Ctrl-w: toggle wide columns. (Equivalent to kubectl … -o wide)
Ctrl-z: toggle error state
Ctrl-e: hide header.
Ctrl-s: save output (e.g. the YAML) to disk.
Ctrl-l: rollback.
```

## Sort by Column

If you want to sort any view (Pod/Services) based on some exact column - you can just press `Shift + Column Initial`  

e.g. If you want to sort items by column Age - Just press `Shift + A` 

- Shift-c: sorts by CPU.
- Shift-m: sorts by MEMORY.
- Shift-s: sorts by STATUS.
- Shift-n: sorts by name;
- Shift-o: sorts by node;
- Shift-i: sorts by IP address;
- Shift-a: sorts by container age;
- Shift-t: sorts by number of restarts;
- Shift-r: sorts by pod readiness;

## List all available resources: 

`:aliases` or `Ctrl-a`: list all available aliases and resources. `:crd:`  list all CRDs.

## Filter

- `/<filter>` : regex filter. 
- `/!<filter>` : inverse regex filter. 
- `/-l <label>` : filter by labels. 
- `/-f <filter>` : fuzzy match.

## Choose context

`:ctx`: list ctx, then select from the list. 
`:ctx <context>`:  switch to the specified context.

## Show Decrypted Secrets

Type `:secrets` to list the secrets, then

- x to decrypt the secret.
- Esc to leave the decrypted display.

`x`: decode a Secret.
`f`:  full screen. Tip: enter full screen mode before copying, to avoid in copied text.

## Helm

- `:helm` : show helm releases.
- `:helm NAMESPACE` : show releases in a specific namespace.

## XRay View

- `:xray RESOURCE` , e.g. `:xray deploy`.

## Pulse View

- `:pulse` : displays general information about the Kubernetes cluster.

## Show Disk Files

- `:dir /path`  

E.g. `:dir /tmp` will show your `/tmp` folder on local disk. One common use case: `Ctrl-s` to save a yaml, then find it in `:dir /tmp/k9s-screens-root`, find the file, press e to edit and a to apply.

## Benchmark

k9s includes a basic HTTP load generator.

To enable it, you have to configure port forwarding in the pod. Select the pod and press `SHIFT + f`, go to the port-forward menu (using the pf alias).

After selecting the port and hitting `CTRL + b`, the benchmark would start. Its results are saved in `/tmp` for subsequent analysis.

To change the configuration of the benchmark, create the `$HOME/.k9s/bench-<my_context>.yml` file (unique for each cluster).


## Check Resources with the Same Name in Different API Groups

e.g. Cluster may be found in different api groups, like `cluster.x-k8s.io` or `clusterregistry.k8s.io` or `baremetal.cluster.gke.io`.

```yaml
apiVersion: cluster.x-k8s.io/v1alpha3
kind: Cluster

apiVersion: clusterregistry.k8s.io/v1alpha1
kind: Cluster

apiVersion: baremetal.cluster.gke.io/v1
kind: Cluster
```

Use `apiVersion/kind` (i.e. `Group/Version/kind`) instead of just kind to check the API of a specific group.

```
:cluster.x-k8s.io/v1alpha3/clusters
:clusterregistry.k8s.io/v1alpha1/clusters
:baremetal.cluster.gke.io/v1/clusters
```

## Change log setting

Change `~/.config/k9s/config.yml`:

```
logger:
  tail: 500
  buffer: 5000
  sinceSeconds: -1
```

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

## Views

- Example:

```yaml
views:
  v1/endpoints:
    columns:
      - AGE|RW
      - NAME
      - ENPOINTS|H
      - BLA:.subsets[*].ports[*].port
      - BOZO:.metadata.labels.app|W
      - BLEE:.metadata.creationTimestamp|T
      - ZORG:.status.containersStatuses[*].restart
```

- keywords:

  - W -> show only in wide mode.
  - H -> hide.





