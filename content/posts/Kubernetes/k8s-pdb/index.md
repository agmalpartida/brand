---
Title: "Pod disruption budget (PDB)"
date: 2025-02-23
categories:
- Kubernetes 
tags:
- k8s
keywords:
- k8s
summary: ""
comments: false
showMeta: false
showActions: false
---

# Pod disruption budget

PDBs define the minimum number of replicas that must remain running during disruptions. This prevents critical workloads from being evicted but can hinder node scaling.

A PodDisruptionBudget (PDB) is a Kubernetes object that specifies the number of pods that can be unavailable in deployment, maintenance, or at any given time. This helps to ensure that your applications remain available even if some of their pods are terminated or evicted.

Let’s take an example where my application has three pods (instances); I always want to have at least two running pods all the time; I can apply a PDB object which will guarantee that I will always have at least two running pods!

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-pdb
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: my-app
```

This configuration ensures one replica are always running but can block eviction when scaling down nodes, leaving some underutilized.
