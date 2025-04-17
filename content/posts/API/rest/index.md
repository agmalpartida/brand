---
Title: "API Rest"
date: 2025-04-17
categories:
- API
tags:
- api
- microservices
keywords:
- api
- rest
summary: ""
comments: false
showMeta: false
showActions: false
---

# A REST API (Representational State Transfer) 

Is a type of interface that allows different systems to communicate with each other through HTTP requests, similar to how web pages work. However, instead of returning HTML, it returns data, usually in JSON or XML format.

- What is REST?

REST is an architectural style for designing APIs that uses the principles of the web. It is based on resources, and each resource has a unique URL. REST uses standard HTTP methods to operate on those resources.

- Common HTTP Methods in REST

| Method | Action              | Example           |
|--------|---------------------|-------------------|
| GET    | Retrieve a resource | `GET /users`      |
| POST   | Create a resource   | `POST /users`     |
| PUT    | Update a resource   | `PUT /users/1`    |
| DELETE | Delete a resource   | `DELETE /users/1` |

- What is a resource?

A resource is any object that the API manages: users, products, orders, etc. Each one has a unique URL.

/products     →  all products  
/products/42  →  the product with ID 42  

Characteristics of a REST API

- Stateless: each request contains all the necessary information; the server does not remember the client’s state.
- Uses standard HTTP and URLs.
- Lightweight data exchange (usually JSON).
- Facilitates scalability and separation between frontend and backend.
