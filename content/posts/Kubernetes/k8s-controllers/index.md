---
Title: "Kubernetes Controllers"
date: 2025-04-17
categories:
- Kubernetes
tags:
- k8s
keywords:
- controller
summary: 
comments: false
showMeta: false
showActions: false
---

# What is a Replication Controller?

A Replication Controller (RC) ensures that a specified number of pod replicas are running at all times. It continuously monitors the cluster and if a pod fails, it will replace it to maintain the desired state.

Features

    Ensures availability of pods by replacing failed ones.
    Basic scaling of pods by changing the replica count.
    Legacy Component: Being replaced by ReplicaSets in modern Kubernetes due to limited functionality.

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: my-rc
spec:
  replicas: 3
  selector:
    app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

```sh
kubectl get rc
```

## What is a ReplicaSet?

A ReplicaSet (RS) is the newer, more advanced version of Replication Controllers. It provides additional functionality and is often managed by Deployments.
Features

    Supports set-based label selectors, allowing complex filtering of pods.
    Works seamlessly with Deployments for rolling updates and rollbacks.
    Dynamic scaling support by modifying the number of replicas.

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: my-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

```sh
kubectl get rs
```

## What is a Deployment?

A Deployment is the most common way to manage ReplicaSets. It provides features like rolling updates, rollbacks, and scaling.
Features

    Manages ReplicaSets to maintain desired state of applications.
    Supports Rolling Updates & Rollbacks to ensure zero downtime during updates.
    Automatically scales pods based on defined replicas.
    Provides self-healing capabilities to replace unhealthy pods.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

Check Deployment Status:

kubectl rollout status deployment/my-deployment

View Deployment History:

kubectl rollout history deployment/my-deployment

Rollback to Previous Version:

kubectl rollout undo deployment/my-deployment

Scale the Deployment:

kubectl scale deployment my-deployment --replicas=5


Summary

    Replication Controller: Ensures availability of a specified number of pods.
    ReplicaSet: Improved version of RC with better label selection and scaling support.
    Deployment: Manages ReplicaSets, supports rolling updates, rollbacks, and scaling.
