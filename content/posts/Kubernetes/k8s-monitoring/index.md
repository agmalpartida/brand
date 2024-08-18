---
Title: "K8S Monitoring"
date: 2024-08-18
categories:
- Kubernetes
tags:
- monitoring
- k8s
summary: "Kubernetes monitoring"
comments: false
showMeta: false
showActions: false
---

## Readiness & Liveness

• Readiness Probe: This probe determines if a pod is ready to start receiving traffic. Use it to ensure that the pod is fully initialized and ready to handle requests.

• Liveness Probe: This probe checks the health of the pod on an ongoing basis. It ensures that the pod is still functioning correctly and can continue to receive traffic. If the liveness probe fails, the pod will be restarted.

If your api is "tits" up wouldn't your /health endpoint be "tits" up too? Unless you have some concurrency paradigm at place I'll assume that this is the case.

Use readiness to check on things before routing traffic to it for instance.
Use liveness to check constantly if you should continue to receive traffic else reschedule.


