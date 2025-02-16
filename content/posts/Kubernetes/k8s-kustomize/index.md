---
Title: "Kustomize: Kubernetes deployment"
date: 2025-02-16
categories:
- Kubernetes
tags:
- k8s
keywords:
- k8s
- kustomize 
summary: "kustomize lets you customize raw, template-free YAML files for multiple purposes, leaving the original YAML untouched and usable as is."
comments: false
showMeta: false
showActions: false
---

# Kustomize

Kustomize is an open-source configuration management tool for Kubernetes.

It allows you to define and manage Kubernetes objects such as deployments, Daemonsets, services, configMaps, etc for multiple environments in a declarative manner without modifying the original YAML files. To put it simply, you have a single source of truth for YAMLs, and you patch required configurations on top of the base YAMLs as per the environment requirements.

Kustomize has two key concepts, Base and Overlays. With Kustomize we can reuse the base files (common YAMLs) across all environments and overlay (patches) specifications for each of those environments.

Overlaying is the process of creating a customized version of the manifest file (base manifest + overlay manifest = customized manifest file).

![](assets/index_2025-02-16_19-39-07.png)

## Kustomize Features

The following are the key features of Kustomize:

1. Acts as a configuration tool with declarative configuration same as Kubernetes YAMLs.
2. It can modify resources without altering the original files.
3. It can add common labels and annotations to all the resources.
4. It can Modify container images based on the environment it is being deployed in.
5. Kustomize also ships with secretGenerator and configMapGenerator that use environment files or key-value pairs to create secrets and configMaps.

