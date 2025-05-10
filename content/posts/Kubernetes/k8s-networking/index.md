---
Title: "K8S Networking"
date: 2024-07-14
categories:
- Kubernetes
tags:
- network
- k8s
summary: "Kubernetes networking"
comments: false
showMeta: false
showActions: false
---


## CNI plugins

CNI (**Container Network Interface**) is a standard API which allows different network implementations to plug into Kubernetes. Kubernetes calls the API any time a pod is being created or destroyed. There are two types of CNI plugins:

- CNI network plugins: responsible for adding or deleting pods to/from the Kubernetes pod network. This includes creating/deleting each pod’s network interface and connecting/disconnecting it to the rest of the network implementation.
- CNI IPAM plugins: responsible for allocating and releasing IP addresses for pods as they are created or deleted. Depending on the plugin, this may include allocating one or more ranges of IP addresses (CIDRs) to each node, or obtaining IP addresses from an underlying public cloud’s network to allocate to pods.

### Cloud provider integrations
Kubernetes cloud provider integrations are cloud-specific controllers that can configure the underlying cloud network to help provide Kubernetes networking. Depending on the cloud provider, this could include automatically programming routes into the underlying cloud network so it knows natively how to route pod traffic.

### Kubenet
Kubenet is an extremely basic network plugin built into Kubernetes. It does not implement cross-node networking or network policy. It is typically used together with a cloud provider integration that sets up routes in the cloud provider network for communication between nodes, or in single node environments. Kubenet is not compatible with Calico.
