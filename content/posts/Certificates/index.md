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

## PEM 

- Generating a TLS/SSL Certificate
```bash
openssl genrsa -out my_private_key.key 2048 
```

- Now that you have a private key, create a public key with it:
```bash
openssl rsa -in my_private_key.key -pubout > my_public_key.pub
```
- Using OpenSSL to View the Status of a Website’s Certificate
```bash
openssl s_client -connect linuxhandbook.com:443 2>/dev/null | openssl x509 -noout -dates
```
- Verifying Information within a Certificate
```bash
openssl x509 -in certificate.crt -text -noout 
```
- Checking a .csr (Certificate Signing Request) type file
```bash
openssl req -text -noout -verify -in server.csr
```
- Verifying a KEY type file
```bash
openssl rsa -in my_private_key.key -check
```
- Verifying a Public Key
```bash
openssl x509 -in certificate.pem -noout -pubkey
openssl rsa -in ssl.key -pubout
```

## PFX

>**Note**: You can try directly specifying the use of the legacy provider in the command, which may force OpenSSL to load the deprecated algorithms at runtime:

- Export private key
```bash
openssl pkcs12 -legacy -in tu_certificado.pfx -nocerts -out clave_privada.pem -nodes
```

- Export certificates
```bash
openssl pkcs12 -legacy -in tu_certificado.pfx -clcerts -nokeys -out certificados_publicos.pem
```

