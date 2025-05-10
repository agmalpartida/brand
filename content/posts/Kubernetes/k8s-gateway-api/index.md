---
Title: "Kubernetes Gateway Api"
date: 2025-04-13
categories:
- Kubernetes
tags:
- k8s
keywords:
- k8s
summary: 
comments: false
showMeta: false
showActions: false
---

# The Kubernetes Gateway API

The Kubernetes Gateway API is a modern, extensible standard for managing ingress and routing traffic in Kubernetes environments. It builds upon the limitations of the legacy Ingress API to provide a vendor-agnostic, declarative framework for configuring L4 and L7 network traffic. The Gateway API is designed to unify and simplify traffic management while supporting advanced use cases such as multi-tenancy, path-based routing, and traffic splitting.

Vendor-Agnostic Abstraction:

The Gateway API provides a universal standard for ingress and traffic routing, eliminating the dependency on vendor-specific annotations.

It allows seamless migration across cloud providers and ingress controllers without major changes to the configuration.


Separation Of Concerns:

Enables clear boundaries between application teams and infrastructure teams by splitting responsibilities -

Infrastructure Teams: Manage the Gateway resources (e.g., ingress controllers, load balancers).

Application Teams: Define Routes (e.g., HTTPRoute, TCPRoute) without worrying about the underlying network infrastructure.



Layer 7 Load Balancing:

Offers advanced routing capabilities, including path-based routing, header-based routing, and traffic splitting for canary deployments or blue-green deployments.

Supports precise L7 policies like rate limiting, request rewrites, and cross-origin resource sharing (CORS).


Extensibility:

Designed with extensibility in mind, it allows custom implementations via GatewayClass, enabling features specific to vendors like AWS, GCP, or Istio while adhering to the Gateway API standard.

Standardized CRDs reduce reliance on annotations.


How The Gateway API Solves The “Annotation Chaos”

The legacy Ingress API relied on annotations to configure features like SSL termination, load balancing algorithms, or backend timeouts. Each ingress controller implemented annotations differently, causing inconsistencies across environments.

The Gateway API eliminates this problem by introducing Custom Resource Definitions (CRDs) for defining

Gateways: Representing the physical or logical entry point (e.g., load balancers, proxies).

Routes: Defining application-specific routing rules (e.g., HTTPRoute, TCPRoute).


---

Lack Of Flexibility:

The Ingress API was designed as a one-size-fits-all solution but fails to cater to advanced use cases. It offers limited configurability for Layer 7 (L7) routing beyond basic HTTP/HTTPS functionality.

Heavy Reliance On Annotations:

To extend Ingress capabilities, vendors introduced annotations, often in incompatible ways. For instance, annotations for AWS ALB differ significantly from those for NGINX or Traefik. This reliance creates vendor lock-in, making migrations between platforms challenging. 

Multi-Layer Traffic Routing:

Applications often require both external ingress (e.g., handling traffic from the internet) and internal service-to-service communication. Routing traffic efficiently across these layers requires features like -

Path-based and header-based routing.

Weighted traffic splitting for canary deployments or A/B testing.

Mutual TLS (mTLS):

Securing communication between microservices is critical, especially for sensitive workloads. Traditional networking setups often struggle to enforce mTLS consistently across clusters. 


Layer 4 (L4) & Layer 7 (L7) Traffic Management:

Applications frequently require both low-level TCP/UDP routing (L4) and high-level HTTP/S routing (L7). Traditional setups struggle to provide unified solutions that handle both effectively.


Verify Gateway version:
kubectl get crd gateways.gateway.networking.k8s.io -o yaml

CRDs update:
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v0.7.0/gateway.networking.k8s.io.crds.yaml



