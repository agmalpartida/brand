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

## Plugins

- Basic Structure of a kubectl Plugin

kubectl plugins are simply executables that start with the `kubectl-` prefix. When you execute a command like:

`kubectl my-plugin` 

kubectl searches for an executable called kubectl-my-plugin in the directories listed in the PATH environment variable and executes it.

