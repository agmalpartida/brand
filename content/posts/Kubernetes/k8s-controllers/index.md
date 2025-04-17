---
Title: "Kubernetes: CRD, Custom Resource Definition"
date: 2025-04-05
categories:
- Kubernetes
tags:
- k8s
keywords:
- crd
summary: 
comments: false
showMeta: false
showActions: false
---

# Create your own CRD

## CRD (Custom Resource Definition)

This defines how we want our custom Kubernetes objects to look and behave.

The name of the CRD must follow this format: <plural-name>.<api-group>

Example: `albertocrds.crds.albertogalvez.com` 
    
To list existing CRDs:

```sh
kubectl get crds
```

In the custom resource manifest, you must specify:

```yaml
apiVersion: crds.albertogalvez.com/v1
kind: Albertocrds
...
```

## Controller

Now we create our controller, which is simply an application running continuously in Kubernetes, listening for changes to our custom resources.

There are libraries available to build controllers in various programming languages.

In Python, for example, you can use the [kopf](https://github.com/nolar/kopf) library.

Example execution:

```sh
kopf run /path/to/controller.py
```
