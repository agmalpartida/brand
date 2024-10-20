---
Title: "Certificates"
date: 2024-10-19
categories:
- Certificates
tags:
- SSL
- certificates
keywords:
- openssl
summary: ""
comments: false
showMeta: false
showActions: false
---

- Generating a TLS/SSL Certificate
`openssl genrsa -out my_private_key.key 2048` 

- Now that you have a private key, create a public key with it:
`openssl rsa -in my_private_key.key -pubout > my_public_key.pub` 

- Using OpenSSL to View the Status of a Website’s Certificate
`openssl s_client -connect linuxhandbook.com:443 2>/dev/null | openssl x509 -noout -dates` 

- Verifying Information within a Certificate
`openssl x509 -in certificate.crt -text -noout` 

- Checking a .csr (Certificate Signing Request) type file
`openssl req -text -noout -verify -in server.csr` 

- Verifying a KEY type file
`openssl rsa -in my_private_key.key -check` 

- Verifying a Public Key
```bash
openssl x509 -in certificate.pem -noout -pubkey
openssl rsa -in ssl.key -pubout
```
