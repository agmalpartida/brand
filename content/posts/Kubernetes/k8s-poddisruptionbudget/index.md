+++
title = 'Pods Disruption Budget'
date = '2024-11-24'
categories = ['K8s']
tags = ['k8s']
keywords = ['k8s','pod']
summary = ''
comments = false
showActions = false
showMeta = false
+++

# Pod disruption budget

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

We will deploy a PDB and ensure at least 10% of your application will be available. Coupled with the application autoscaler, you’re safe about your application availability.

