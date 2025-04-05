+++
categories = ['Kubernetes']
comments = false
keywords = ['k8s']
showActions = false
showMeta = false
tags = ['k8s']
title = 'K8S Configuration Overview'
+++

Initially, Kubernetes was build to manage Docker Containers. Docker is the technology that made containers accessible to the mainstream. Containers were not an entirely new technology. LXC containers existed before and Linux namespaces are a thing since 2002, but Docker made it so easy to use containers. By handling software packaging, distribution and all low level network and device configuration, Docker allowed every developer to start any application in an isolated environment. Promising to finally overcoming the famous: It works on my machine meme.
Even the Kubernetes core team admits that Kubernetes would've been such a success without Docker.

At some point, a lot of different people and companies tried to solve similar problems regarding containers. They agreed to build some common interfaces for their solutions so that parts of their implementations could be swapped while relying on certain standards. This led to the creation of the Open Container Initiative (OCI), Container Network Interface (CNI), Container Storage Interface (CSI) and Container Runtime Interface (CRI).

## Labels

A consistent labeling strategy helps you filter resources quickly and maintain a clear mental map of your cluster.

- Labels: Key-value pairs used for grouping and selecting Kubernetes objects. For instance, app=my-app, env=staging, team=payments.
- Annotations: Key-value pairs for attaching non-identifying metadata (e.g., version info, contact email, or last-deployed timestamp).

### Safe-to-Evict Annotations

Pods marked with safe-to-evict: false cannot be removed or rescheduled during node scaling or bin-packing operations.

Annotation Example:

```yaml
metadata:
  annotations:
    cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
```

- Naked Pods

Pods created directly without a controller (e.g., Deployments, ReplicaSets) lack the automation needed for rescheduling or scaling.

Naked Pod Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: standalone-pod
spec:
  containers:
  - name: app-container
    image: app-image:v1
```

These pods prevent nodes from being scaled down, leading to idle resources.

- Removing Safe-to-Evict Annotations

Safe-to-evict annotations prevent pods from being evicted by the autoscaler. To find pods with this annotation:

```sh
kubectl get pods --all-namespaces -o json | jq '.items[] | select(.metadata.annotations."cluster-autoscaler.kubernetes.io/safe-to-evict" == "false") | .metadata.name'
```

Once identified, edit the pod configuration to remove the annotation.


## Namespaces 

Why Use Namespaces?

Namespaces help:

- Isolate Resources: Separate applications and environments (e.g., development, staging, production) within the same cluster.
- Manage Access: Apply role-based access control (RBAC) for specific namespaces.
- Organize Resources: Group related resources logically for clarity.

Namespace Like Your Life Depends on It

- Team-based namespaces: Dev, QA, Prod, or per microservice if that makes sense.
- Access Control: Combine namespaces with RBAC (Role-Based Access Control) policies to ensure that only the right people (and services) can mess with your stuff.
-  Resource Quotas: You can set quotas (e.g., CPU, memory) per namespace, preventing one rogue microservice from hogging all resources.

Take a step back and design your namespace strategy; future you will say thanks.



## CRI

With version 1.24, Kubernetes has overcome its dependence on Docker and now only relies on any CRI compliant runtime to start containers.
The containerd project was originally developed by Docker Inc and still is the core of Docker, but its ownership was since donated to the CNCF.
When a new Pod is scheduled to a node, the kubelet communicates with containerd over the container runtime interface to actually pull the image and start the container with the configuration specified in the pod definition. Containerd is now in charge to set up the Linux namespace, mount volumes or devices and apply seccomp profiles and much more for every new container. That's a lot of tasks, and not quite according to the UNIX philosophy to do one thing and do it well.

By default, containerd calls runc. The runc binary actually spawns the container process with all its applied properties. It does not pull images, manages the containers file system, sets up networking or monitors the container process. Overly simplified it is just a spawn syscall with a bunch of extra properties for some isolation, but it still runs on the same kernel since containers are NOT VMs.

![](images/k8s-overall.jpg)

## Master Components

![](images/k8s-master-components.jpg)

## Configuration

![](images/k8s-config.jpg)

## Networking

![](images/k8s-net.jpg)

## Resources 

- **Resource Requests**: This is basically your container’s baseline. If your container requests 200m CPU and 512Mi of memory, the Kubernetes scheduler will place your Pod on a node with at least that much capacity available.
- **Resource Limits:**:  This is the upper bound. If your container tries to exceed the limit, it might get throttled (CPU) or even evicted (memory).

![](images/k8s-optimization-resources.jpg)

## Security

![](images/k8s-security.jpg)

### Secrets

Kubernetes expects the values in stringData to be strings (string)

```yaml
kind: Secret
metadata:
  name: my-secret
type: Opaque
stringData:
  password: "12345"  # ✅ It is now a string
```

If you use data, you must ensure that the values are in Base64:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  password: MTIzNDU=  # "12345" in Base64
```

`echo -n "12345" | base64` 
