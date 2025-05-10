---
Title: "K8S Troubleshooting"
date: 2024-07-13 
categories:
- Kubernetes
tags:
- k8s
keywords:
- k8s
summary: "Kubernetes troubleshooting"
comments: false
showMeta: false
showActions: false
---

```sh
kubectl --v=9 get pods
```

## Authorization / Authentication

Review the API server logs to get more details about the authentication error. This may provide additional clues as to why the request is failing.

Make sure you can reach the Kubernetes API server from your machine:

```sh
curl -k https://<api-server-address>:<port>/healthz
```

```sh
curl -k https://<api-server-address>:<port>/api/v1/namespaces --header "Authorization: Bearer <token>"
```

```sh
kubectl auth can-i --list
```

```sh
chmod 600 /path/to/admin.crt /path/to/admin.key /path/to/ca.crt

kubectl config view -o jsonpath='{.users}'

curl --cert /path/to/admin.crt --key /path/to/admin.key --cacert /path/to/ca.crt https://<api-server-address>:<port>/api/v1/namespaces
```
