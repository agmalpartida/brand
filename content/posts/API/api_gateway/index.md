---
Title: "API Gateway"
date: 2024-08-30
categories:
- API
tags:
- api
- microservices
keywords:
- api
summary: "API Gateway overview"
comments: false
showMeta: false
showActions: false
---

# Introduction
An API gateway is an API management tool that sits between a client and a collection of backend services. In this case, a client is the application on a user’s device and the backend services are those on an enterprise’s servers. API stands for application programming interface, which is a set of definitions and protocols for building and integrating application software.

An API gateway is a component of application delivery (the combination of services that serve an application to users) and acts as a reverse proxy to accept all application programming interface (API) calls, aggregate the various services required to fulfill them, and return the appropriate result. In simpler terms, an API gateway is a piece of software that intercepts API calls from a user and routes them to the appropriate backend service.

Why use an API gateway?
It’s usual for API gateways to handle common tasks that are used across a system of API services, such as user authentication, rate limiting, and statistics.

At its most basic, an API service accepts a remote request and returns a response. But real life is never that simple. Consider your various concerns when you host large-scale APIs.

- You want to protect your APIs from overuse and abuse, so you use an authentication service and rate limiting.
- You want to understand how people use your APIs, so you’ve added analytics and monitoring tools.
- If you have monetized APIs, you’ll want to connect to a billing system.
- You may have adopted a microservices architecture, in which case a single request could require calls to dozens of distinct applications.
- Over time you’ll add some new API services and retire others, but your clients will still want to find all your services in the same place.

Your challenge is offering your clients a simple and dependable experience in the face of all this complexity. An API gateway is a way to decouple the client interface from your backend implementation. When a client makes a request, the API gateway breaks it into multiple requests, routes them to the right places, produces a response, and keeps track of everything.

An API gateway’s role in API management

An API gateway is one part of an API management system. The API gateway intercepts all incoming requests and sends them through the API management system, which handles a variety of necessary functions.

Exactly what the API gateway does will vary from one implementation to another. Some common functions include authentication, routing, rate limiting, billing, monitoring, analytics, policies, alerts, and security. API gateways provide these benefits:

Low latency

By distributing incoming requests and offloading common tasks such as SSL termination and caching, API gateways optimize traffic routing and load balancing across backend services to ensure optimal performance and resource utilization. By doing so, API gateways minimize server load and bandwidth usage, reducing the need for additional server capacity and network bandwidth and improving user experience.

Traffic management

API gateways throttle and manage traffic through various mechanisms designed to control the rate and volume of incoming requests and ensure optimal performance and resource utilization.

- Rate limiting policies specify the maximum number of requests allowed within a certain time period (e.g., requests per second, minute, hour) for each client or API key, protecting backend services from overload.
- Request throttling policies define rules and limits for regulating request traffic, such as maximum request rates, burst allowances, and quotas.
- Concurrency control policies specify the maximum number of concurrent connections or requests that can be handled simultaneously by the backend servers.
- Circuit breaking policies monitor the health and responsiveness of backend servers and temporarily block or redirect traffic away from failing or slow services to prevent cascading failures and maintain overall system stability.
- Dynamic load balancing from API gateways continuously monitors server health and adjusts traffic routing in real-time to handle spikes in demand, minimize response times, and maximize throughput.

- Flexibility. HTTP APIs, which are more general and can use any HTTP method, offer simplicity and flexibility in development, potentially reducing development costs. REST APIs, which adhere to specific architectural principles and conventions, may require additional effort and expertise to design and implement properly, potentially increasing development costs.

- Infrastructure. Because of their flexibility, HTTP APIs may have lower infrastructure costs. REST APIs may require additional infrastructure components or services to support these features, potentially increasing infrastructure costs.

- Scalability. HTTP APIs, which can be scaled horizontally by adding more servers or instances, may offer more cost-effective scalability options, particularly in cloud environments with auto-scaling capabilities. REST APIs may have more complex scaling requirements due to statelessness, caching, and distributed architecture considerations, and may require additional infrastructure resources or services to achieve horizontal scalability, potentially increasing costs.

How API gateways work with Kubernetes

an API gateway can be a key component to manage and route traffic to services on a Kubernetes cluster. It does so by accomplishing these tasks:

- acting as an Ingress controller, intercepting incoming HTTP traffic to the cluster and routing it to the appropriate services based -on defined rules and configurations.
- leveraging Kubernetes’ DNS-based service discovery to discover and route traffic to backend services without manual configuration. This enables seamless integration with Kubernetes-native services and facilitates dynamic scaling, service discovery, and failover handling within the cluster.
- implementing advanced traffic management policies to control the flow of traffic to services deployed on Kubernetes.
- enforcing security policies such as authentication, access controls, authorization, and encryption to protect services deployed on Kubernetes from unauthorized access and cyber threats.
- providing observability and monitoring by creating visibility into traffic patterns, performance metrics, and error rates for services deployed on Kubernetes, such as request logging, metrics collection, and distributed tracing.
- integrating with service meshes, like Istio and Linkerd, to extend their capabilities and provide additional features such as external ingress, edge security, and global traffic management, ensuring seamless interoperability between Kubernetes services and external clients.

