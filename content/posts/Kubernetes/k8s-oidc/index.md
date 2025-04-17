---
Title: "Keycloak as an OIDC provider for Kubernetes"
date: 2025-04-17
categories:
- Kubernetes 
tags:
- k8s
keywords:
- k8s
summary: ""
comments: false
showMeta: false
showActions: false
---

# Keycloak as an OIDC provider for Kubernetes

The workflow

1. The client requests an ID Token with claims for it’s identity (name) and the groups he/she belongs to
2. The client then requests access to Kubernetes providing the ID token from the IDP obtained previously
3. This token (which contains the claims for name, group ) is used in each request to the API Server
4. The API Server in turn checks the ID Token validity with the ID provider
5. If the token is valid, then the API Server will check if the request is authorized based on the token’s claims and the configured RBAC (by matching it with the corresponding resources)
6. Finally, the actions will be performed or denied
7.  A response is sent back to the client

From the user perspective, once everything is setup, we will perform this actions to obtain access to the cluster:

1. Get an ID Token (and Refresh token) from the ID provider (we will request the tokens from Keycloak).
2. Set a user’s credentials for kubectl .
3. Set a new kubectl config with this user and a configured cluster (for example, minikube )
4. Done: Use the config, issue commands

From the Keycloak admin’s perspective, we will:

1. Create a client (in our example, a public client, i.e.: no client secret)
2. Create some basic claims for identification and management of users and groups, specifically:
   - name
   - groups
3. Place the target users within the corresponding group

From the Kubernetes admin’s perspective, we will:

1. Configure the required RBAC resources: for example, a ClusterRole with the permitted operations and a ClusterRoleBinding that matches the desired group.
2. Configure the API Server to use Keycloak as an OIDC provider

## Configure a Keycloak client for Kubernetes SSO

```json
{
  "clientId": "k8s",
  "name": "k8s",
  "description": "Kubernetes SSO",
  "rootUrl": "",
  "adminUrl": "",
  "baseUrl": "",
  "surrogateAuthRequired": false,
  "enabled": true,
  "alwaysDisplayInConsole": false,
  "clientAuthenticatorType": "client-secret",
  "redirectUris": [
    "/*"
  ],
  "webOrigins": [
    "/*"
  ],
  "notBefore": 0,
  "bearerOnly": false,
  "consentRequired": false,
  "standardFlowEnabled": true,
  "implicitFlowEnabled": false,
  "directAccessGrantsEnabled": true,
  "serviceAccountsEnabled": false,
  "publicClient": true,
  "frontchannelLogout": true,
  "protocol": "openid-connect",
  "attributes": {
    "oidc.ciba.grant.enabled": "false",
    "oauth2.device.authorization.grant.enabled": "false",
    "backchannel.logout.session.required": "true",
    "backchannel.logout.revoke.offline.tokens": "false"
  },
  "authenticationFlowBindingOverrides": {},
  "fullScopeAllowed": true,
  "nodeReRegistrationTimeout": -1,
  "defaultClientScopes": [
    "web-origins",
    "acr",
    "profile",
    "roles",
    "name",
    "groups",
    "email"
  ],
  "optionalClientScopes": [
    "address",
    "phone",
    "offline_access",
    "microprofile-jwt"
  ],
  "access": {
    "view": true,
    "configure": true,
    "manage": true
  }
}
```

- I am allowing all redirects and all web origins, though this is less than desirable in production.
- Please change this values to your redirect URLs to enhance the security.
