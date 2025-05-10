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

2) Check talos' API port 

```bash
nc -zv 192.168.1.71 50000
```


## Create Cluster


### Generate cluster files

1) Generate secrets:

```shell
talosctl gen secrets -o secrets.yaml
```

1) Generate control and worker config:

Caveats (according talos [documentation](https://www.talos.dev/v1.9/talos-guides/network/vip/#choose-your-shared-ip)):

Since VIP functionality relies on etcd for elections, the shared IP will not come alive until after you have bootstrapped Kubernetes.
Don’t use the VIP as the endpoint in the talosconfig, as the VIP is bound to etcd and kube-apiserver health, and you will not be able to recover from a failure of either of those components using Talos API.

```shell
talosctl gen config --with-secrets secrets.yaml "clustername" https://CONTROL_PLANE_IP:6443
talosctl gen config --with-secrets secrets.yaml "comanche" https://192.168.1.71:6443
```

3) Edit controlplane.yaml:
   
- set ```controlPlane.scheduler.disabled: false```, I want control plane nodes to schedule work.
- set `interface` with the value output from `talosctl -n node3 get links` 
- add the VIP ipadress to network stanza:

I have:

```yaml
      network:
        hostname: node3
        interfaces:
        - dhcp: true
          interface: enxd83addbb1c3a
          vip:
            ip: 192.168.1.59
        nameservers:
        - 8.8.8.8
        - 8.8.4.4
```
      
- set ```install.disk:``` to ```/dev/mmcblk0```
- optionally set ```install.wipe: true```

4) For each node (I have 3, an uneven number of control nodes is recommended in k8s):

- change hostname: ```network.hostname: nodeX``` (set X to cm4 number)
1) apply config to cm4:

```shell
talosctl apply-config --insecure -n <CM4 ipadres> --file controlplane.yaml
talosctl apply-config --insecure -n 192.168.1.71 --file controlplane-node1.yaml
talosctl apply-config --insecure -n 192.168.1.72 --file controlplane-node2.yaml
talosctl apply-config --insecure -n 192.168.1.73 --file controlplane-node3.yaml

[  118.061987] [talos] etcd is waiting to join the cluster, if this node is the first node in the cluster, please run `talosctl bootstrap` against one of the following IPs:
[  118.080674] [talos] [192.168.1.71]
   ```

### Bootstrap cluster by one of the control nodes.

```shell
   talosctl  -n <CM4 ipadres> -e <CM4 ipadres> --talosconfig ./talosconfig bootstrap
talosctl --talosconfig ~/.talos/talosconfig -n 192.168.1.71 -e 192.168.1.71 bootstrap
[  259.296059] [talos] bootstrap request received

   ```
Grab ☕

### Generate kubeconfig.

```shell
talosctl kubeconfig -f -n <VIP>

unset KUBECONFIG
talosctl kubeconfig --talosconfig talosconfig -n 192.168.1.71 -e 192.168.1.71

```

### Watch cluster

1) ```watch -n 1.5 kubectl --kubeconfig=./kubeconfig --request-timeout=1s get pods,deployment,services,nodes -A -o wide```

talosctl config nodes 192.168.1.71,192.168.1.72,192.168.1.73 --talosconfig ~/.talos/talosconfig
talosctl config endpoint 192.168.1.71,192.168.1.72,192.168.1.73 --talosconfig ~/.talos/talosconfig


```bash
❯ talosctl -n node1 health

discovered nodes: ["192.168.1.59" "192.168.1.72" "192.168.1.73"]
waiting for etcd to be healthy: ...
waiting for etcd to be healthy: OK
waiting for etcd members to be consistent across nodes: ...
waiting for etcd members to be consistent across nodes: OK
waiting for etcd members to be control plane nodes: ...
waiting for etcd members to be control plane nodes: OK
waiting for apid to be ready: ...
waiting for apid to be ready: OK
waiting for all nodes memory sizes: ...
waiting for all nodes memory sizes: OK
waiting for all nodes disk sizes: ...
waiting for all nodes disk sizes: OK
waiting for kubelet to be healthy: ...
waiting for kubelet to be healthy: OK
waiting for all nodes to finish boot sequence: ...
waiting for all nodes to finish boot sequence: OK
waiting for all k8s nodes to report: ...
waiting for all k8s nodes to report: OK
waiting for all k8s nodes to report ready: ...
waiting for all k8s nodes to report ready: OK
waiting for all control plane static pods to be running: ...
waiting for all control plane static pods to be running: OK
waiting for all control plane components to be ready: ...
waiting for all control plane components to be ready: OK
waiting for kube-proxy to report ready: ...
waiting for kube-proxy to report ready: OK
waiting for coredns to report ready: ...
waiting for coredns to report ready: OK
waiting for all k8s nodes to report schedulable: ...
waiting for all k8s nodes to report schedulable: OK
```

```bash
❯ talosctl --talosconfig ~/.talos/talosconfig config info

Current context:     comanche
Nodes:               192.168.1.71,192.168.1.72,192.168.1.73
Endpoints:           192.168.1.71,192.168.1.72,192.168.1.73
Roles:               os:admin
Certificate expires: 1 year from now (2025-12-31)
```

```bash
❯ talosctl -n node1 get admissioncontrolconfigs.kubernetes.talos.dev admission-control -o yaml

node: node1
metadata:
    namespace: controlplane
    type: AdmissionControlConfigs.kubernetes.talos.dev
    id: admission-control
    version: 1
    owner: k8s.ControlPlaneAdmissionControlController
    phase: running
    created: 2025-01-01T19:14:12Z
    updated: 1970-01-01T00:00:09Z
spec:
    config:
        - name: PodSecurity
          configuration:
            apiVersion: pod-security.admission.config.k8s.io/v1alpha1
            defaults:
                audit: restricted
                audit-version: latest
                enforce: baseline
                enforce-version: latest
                warn: restricted
                warn-version: latest
            exemptions:
                namespaces:
                    - kube-system
                runtimeClasses: []
                usernames: []
            kind: PodSecurityConfiguration
```

```bash
❯ talosctl -n node1 logs kubelet
```

```bash
❯ talosctl patch mc --talosconfig talosconfig --nodes 192.168.1.71 -e 192.168.1.71 --patch @patch.yaml
WARNING: 192.168.1.71: server version 1.7.6 is older than client version 1.9.1
patched MachineConfigs.config.talos.dev/v1alpha1 at the node 192.168.1.71
Applied configuration without a reboot
```

## Client installation

- MacOS:

```sh
curl -LO https://github.com/siderolabs/talos/releases/download/v1.7.6/talosctl-darwin-amd64
chmod +x talosctl-darwin-amd64
sudo mv talosctl-darwin-amd64 /usr/local/bin/talosctl
talosctl version
```

## Operations

- Show machine configuration:

```sh
talosctl -n node3 get machineconfig -o yaml
```
