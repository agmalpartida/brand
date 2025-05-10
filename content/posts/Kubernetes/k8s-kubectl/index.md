---
Title: "Kubectl: Kubernetes Swiss Knife"
date: 2025-03-29
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

# Kubectl

## kubectl taint

Taints are used to prevent pods from being scheduled on certain nodes unless those pods have the appropriate tolerations.

```sh
kubectl taint nodes node1 node2 node3 node-role.kubernetes.io/control-plane:NoSchedule-
```

- `node-role.kubernetes.io/control-plane:NoSchedule` is a taint typically applied to control plane nodes to prevent regular pods from being scheduled on them.

- The `-` at the end removes the taint from the nodes.

If you want to add the taint instead of removing it, just remove the - at the end:

```sh
kubectl taint nodes node1 node2 node3 node-role.kubernetes.io/control-plane:NoSchedule
```

## kubectl wait

```sh
kubectl wait -n istio-ingress --for=condition=programmed gateways.gateway.networking.k8s.io gateway
```

This kubectl command waits for a specific condition (in this case, for the Gateway resource to be programmed) within a namespace called istio-ingress. Here's a breakdown of each part:

- kubectl wait: This command pauses execution until a resource or set of resources meets a specified condition.

- -n istio-ingress: Specifies the namespace where the resource is located. In this case, the istio-ingress namespace.

- --for=condition=programmed: Defines the condition that must be met. Here, it means the Gateway resource must reach the programmed state—indicating it has been properly configured and is ready for use.

- gateways.gateway.networking.k8s.io: Specifies the type of resource being monitored. In this case, a Gateway resource from the gateway.networking.k8s.io API group.

- gateway: The name of the specific Gateway resource you're monitoring.

What does this mean in practice?

The command waits until the Gateway resource in the istio-ingress namespace is fully configured (i.e., programmed) and ready to handle network traffic. This is especially useful when you need to ensure that a network configuration or proxy (like an Istio Gateway) is ready before proceeding with a deployment or any other dependent operations.

If the Gateway does not reach the specified condition within the default timeout period (30 seconds by default, which can be adjusted using --timeout), the command will fail.

## Plugins

- Basic Structure of a kubectl Plugin

kubectl plugins are simply executables that start with the `kubectl-` prefix. When you execute a command like:

`kubectl my-plugin` 

kubectl searches for an executable called kubectl-my-plugin in the directories listed in the PATH environment variable and executes it.

