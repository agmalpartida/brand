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

## Understanding Kustomize

### kustomization.yamlfile

The kustomization.yaml file is the main file used by the Kustomize tool.

When you execute Kustomize, it looks for the file named kustomization.yaml. This file contains a list of all of the Kubernetes resources (YAML files) that should be managed by Kustomize. It also contains all the customizations that we want to apply to generate the customized manifest.

### Base and Overlays

The Base folder represents the config that going to be identical across all the environments. We put all the Kubernetes manifests in the Base. It has a default value that we can overwrite.

On the other side, the Overlays folder allows us to customize the behavior on a per-environment basis. We can create an Overlay for each one of the environments. We specify all the properties and parameters that we want to overwrite & change.

![](assets/index_2025-02-16_19-52-30.png)

Basically, Kustomize uses patch directive to introduce environment-specific changes on existing Base standard k8s config files without disturbing them.

### Transformers

As the name indicates, transformers are something that transforms one config into another. Using Transformers, we can transform our base Kubernetes YAML configs. Kustomize has several built-in transformers. Let’s see some common transformers:

1. commonLabel – It adds a label to all Kubernetes resources
2. namePrefix – It adds a common prefix to all resource names
3. nameSuffix – It adds a common suffix to all resource names
4. Namespace – It adds a common namespace to all resources
5. commonAnnotations – It adds an annotation to all resources

Let’s see an example. In the below image, we have used commonLabels in kustomization.yaml where label env: dev gets added to the customized deployment.yaml.

![](assets/index_2025-02-16_19-56-09.png)

### Image Transformer

It allows us to modify an image that a specific deployment is going to use.

In the following example, the image transformer checks the nginx image name as mentioned deployment.yaml and changes it to the new name which is ubuntu in the kustomization.yaml file. We can change the tags as well.

![](assets/index_2025-02-16_19-57-29.png)

### Patches (Overlays)

Patches or overlays provide another method to modify Kubernetes configs. It provides more specific sections to change in the configuration. There are 3 parameters we need to provide:

1. Operation Type: add or remove or replace
2. Target: Resource name which we want to modify
3. Value: Value name that will either be added or replaced. For the remove operation type, there would not be any value.

There are two ways to define the patch:

1. JSON 6902 and
2. Stragetic Merge Patching.


