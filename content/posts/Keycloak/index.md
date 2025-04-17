---
Title: "Keycloak"
date: 2024-11-17
categories:
- Keycloa
tags:
- keycloak
keywords:
- keycloak
summary: ""
comments: false
showMeta: false
showActions: false
---

# Intro

Keycloak is an open-source tool that helps manage user authentication and authorization. Think of it as a centralized system where you can:

- Allow users to log in to your application.
- Manage their roles and permissions.
- Connect your app to external identity providers like Google, Facebook, or your company’s directory.

It saves developers time by handling the complex parts of authentication, like secure logins, tokens, and integrating with standards like OAuth or SAML.

Example Use Case: Imagine you’re building an e-commerce website. Instead of creating your login system, you integrate Keycloak. It manages user accounts, supports “Login with Google,” and ensures secure access.

How Keycloak Works (In Simple Steps):

- User Opens Your App:
A user visits your app and clicks “Log in.”

- Redirect to Keycloak:
Instead of asking for their username and password, your app sends them to Keycloak.

- User Logs in with Keycloak:
Keycloak shows a login form. The user enters their credentials or chooses to log in with Google or another provider.

- Keycloak Verifies the User:
Keycloak checks if the username and password are correct or asks the chosen provider (e.g., Google) to confirm the user’s identity.

- Keycloak Sends a Token:
Once verified, Keycloak sends your app a token, which is proof that the user is authenticated.

- Your App Lets the User In:
Your app reads the token and knows who the user is and what they’re allowed to do.

## Account Console

Keycloak users can manage their accounts through the Account Console. They can configure their profiles, add two-factor authentication, include identity provider accounts, and oversee device activity.

- Accessing the Account Console
1. Make note of the realm name and IP address for the Keycloak server where your account exists.
2. In a web browser, enter a URL in this format: `server-root/realms/{realm-name}/account`.
3. Enter your login name and password.

You can also ask for additional scopes when calling the account console URL by setting the scope parameter in this format: `server-root/realms/{realm-name}/account?scope=phone`.

---
## Features

- Single-Sign On

Users authenticate with Keycloak rather than individual applications. This means that your applications don't have to deal with login forms, authenticating users, and storing users. Once logged-in to Keycloak, users don't have to login again to access a different application.

This also applies to logout. Keycloak provides single-sign out, which means users only have to logout once to be logged-out of all applications that use Keycloak.

- Identity Brokering and Social Login

Enabling login with social networks is easy to add through the admin console. It's just a matter of selecting the social network you want to add. No code or changes to your application is required. 
Keycloak can also authenticate users with existing OpenID Connect or SAML 2.0 Identity Providers. Again, this is just a matter of configuring the Identity Provider through the admin console. 
Identity Brokering OpenID Connect or SAML 2.0 IdPs

- User Federation

Keycloak has built-in support to connect to existing LDAP or Active Directory servers. You can also implement your own provider if you have users in other stores, such as a relational database.

- Admin Console

Through the admin console administrators can centrally manage all aspects of the Keycloak server. 


- Standard Protocols

Keycloak is based on standard protocols and provides support for OpenID Connect, OAuth 2.0, and SAML.

- Authorization Services

If role based authorization doesn't cover your needs, Keycloak provides fine-grained authorization services as well. This allows you to manage permissions for all your services from the Keycloak admin console and gives you the power to define exactly the policies you need.



## OAuth

[OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc6749) 

The OAuth 2.0 authorization framework enables a third-party application to obtain limited access to an HTTP service

OAuth is a protocol that lets users give one app access to their data in another app, without sharing their passwords.

Example: When you log in to a service using “Sign in with Google,” you’re using OAuth.

    You click “Sign in with Google.”
    Google asks for your permission to share your email with the app.
    Once you agree, Google sends a token to the app, which acts as proof that you’re authenticated.

How OAuth Works (Simple Steps):

    You Request Access:
    You open an app (e.g., a calendar app) and click “Connect with Google.”
    The App Redirects You to Google:
    Instead of asking for your password, the app sends you to Google, where you log in securely.
    You Grant Permission:
    Google shows you a screen asking, “This app wants to access your calendar. Allow?” You click “Allow.”
    Google Sends a Token to the App:
    Once you allow, Google gives the app a token. This token is like a temporary key that allows the app to access your calendar without knowing your password.
    The App Uses the Token:
    The app uses the token to get your calendar data (but can’t do anything else, like sending emails).

## SAML

SAML (Security Assertion Markup Language) is another protocol for authentication, primarily used in enterprise settings.

While OAuth focuses on giving apps access to data, SAML is about securely transferring login credentials between a user’s identity provider (IdP) and the app they’re trying to access.

    You try to access an internal company app.
    The app redirects you to your company’s IdP (e.g., Microsoft Active Directory).
    You log in once, and the IdP tells the app, “This user is authenticated.”

SAML uses XML for its communication, which makes it different from OAuth.

How SAML Works (Simple Steps):

    You Try to Access an App (Service Provider):
    You open an app like Slack and click “Login.”
    The App Redirects You to Your Company’s Login Page (Identity Provider):
    Slack says, “I don’t know who you are. Please log in through your company’s system.”
    You Log in with Your Company Credentials:
    You enter your username and password on your company’s login page.
    Your Company Confirms Your Identity:
    Once you’re authenticated, your company sends a secure message (called an assertion) back to Slack saying, “This user is verified.”
    You Get Access to the App:
    Slack trusts the assertion and lets you in without asking for a password again.

## SSO

SSO means logging in once to access multiple apps without logging in again.

Example: When you log in to Gmail, you’re also logged into Google Drive, YouTube, and other Google services. That’s SSO in action.

How SSO Works:

    It uses either OAuth, SAML, or other protocols to share authentication across apps.
    It’s especially helpful in workplaces, where employees use one login for multiple tools like Slack, Jira, and Salesforce.

Here’s how all these pieces fit together in a practical scenario:

    A user opens a web application.
    The app redirects the user to Keycloak for authentication.
    Keycloak verifies the user’s credentials.
    a) If the app uses OAuth, Keycloak issues an access token.
    b) If the app uses SAML, Keycloak sends a SAML assertion.
    The user gains access to the application.
    The user navigates to another app. This app redirects to Keycloak.
    Keycloak recognizes the user’s session and grants access without requiring a new login.

## OpenID Connect

OpenID Connect (OIDC), an identity layer built on top of OAuth2. OIDC is supported by most identity providers
OpenID Connect (OIDC) is an authentication protocol that is an extension of OAuth 2.0.

OAuth 2.0 is a framework for building authorization protocols and is incomplete. OIDC, however, is a full authentication and authorization protocol that uses the Json Web Token (JWT) standards. The JWT standards define an identity token JSON format and methods to digitally sign and encrypt data in a compact and web-friendly way.

In general, OIDC implements two use cases. The first case is an application requesting that a Keycloak server authenticates a user. Upon successful login, the application receives an identity token and an access token. The identity token contains user information including user name, email, and profile information. The realm digitally signs the access token which contains access information (such as user role mappings) that applications use to determine the resources users can access in the application.



The second use case is a client accessing remote services.

    The client requests an access token from Keycloak to invoke on remote services on behalf of the user.

    Keycloak authenticates the user and asks the user for consent to grant access to the requesting client.

    The client receives the access token which is digitally signed by the realm.

    The client makes REST requests on remote services using the access token.

    The remote REST service extracts the access token.

    The remote REST service verifies the tokens signature.

    The remote REST service decides, based on access information within the token, to process or reject the request.


    Your apps are integrated with OIDC with Keycloak (No ROPC grant)
    SSO means having an active IdP session cookie

    The system 1 (client 1) performs a standard OIDC federation, the user completes the authn mechanism and then, the system 1 gets the tokens, and you have an IdP session :cookie:
    The system 2 (client 2) performs a standard OIDC federation but you achieve SSO because you have an active IdP session :cookie:, and the system 2 obtains NEW tokens



## Core concepts and terms

Consider these core concepts and terms before attempting to use Keycloak to secure your web applications and REST services.

composite roles

    A composite role is a role that can be associated with other roles. For example a superuser composite role could be associated with the sales-admin and order-entry-admin roles. If a user is mapped to the superuser role they also inherit the sales-admin and order-entry-admin roles.


realms

    A realm manages a set of users, credentials, roles, and groups. A user belongs to and logs into a realm. Realms are isolated from one another and can only manage and authenticate the users that they control.
Master realm - This realm was created for you when you first started Keycloak. It contains the administrator account you created at the first login. Use the master realm only to create and manage the realms in your system.

if you want to disable the master realm and define administrator accounts within any new realm you create. Each realm has its own dedicated Admin Console that you can log into with local accounts.

https://www.keycloak.org/docs/latest/server_admin/index.html#_per_realm_admin_permissions


Configuring email for a realm
Keycloak sends emails to users to verify their email addresses, when they forget their passwords, or when an administrator needs to receive notifications about a server event. To enable Keycloak to send emails, you provide Keycloak with your SMTP server settings.
Procedure

    Click Realm settings in the menu.

    Click the Email tab.


clients

    Clients are entities that can request Keycloak to authenticate a user. Most often, clients are applications and services that want to use Keycloak to secure themselves and provide a single sign-on solution. Clients can also be entities that just want to request identity information or an access token so that they can securely invoke other services on the network that are secured by Keycloak.


client adapters

    Client adapters are plugins that you install into your application environment to be able to communicate and be secured by Keycloak. Keycloak has a number of adapters for different platforms that you can download. There are also third-party adapters you can get for environments that we don’t cover.


consent

    Consent is when you as an admin want a user to give permission to a client before that client can participate in the authentication process. After a user provides their credentials, Keycloak will pop up a screen identifying the client requesting a login and what identity information is requested of the user. User can decide whether or not to grant the request.



client scopes

    When a client is registered, you must define protocol mappers and role scope mappings for that client. It is often useful to store a client scope, to make creating new clients easier by sharing some common settings. This is also useful for requesting some claims or roles to be conditionally based on the value of scope parameter. Keycloak provides the concept of a client scope for this.

client role

    Clients can define roles that are specific to them. This is basically a role namespace dedicated to the client.


identity token

    A token that provides identity information about the user. Part of the OpenID Connect specification.

access token

    A token that can be provided as part of an HTTP request that grants access to the service being invoked on. This is part of the OpenID Connect and OAuth 2.0 specification.

assertion

    Information about a user. This usually pertains to an XML blob that is included in a SAML authentication response that provided identity metadata about an authenticated user.


service account

    Each client has a built-in service account which allows it to obtain an access token.


direct grant

    A way for a client to obtain an access token on behalf of a user via a REST invocation.

protocol mappers

    For each client you can tailor what claims and assertions are stored in the OIDC token or SAML assertion. You do this per client by creating and configuring protocol mappers.


session

    When a user logs in, a session is created to manage the login session. A session contains information like when the user logged in and what applications have participated within single sign-on during that session. Both admins and users can view session information.


user federation provider

    Keycloak can store and manage users. Often, companies already have LDAP or Active Directory services that store user and credential information. You can point Keycloak to validate credentials from those external stores and pull in identity information.


identity provider

    An identity provider (IDP) is a service that can authenticate a user. Keycloak is an IDP.


identity provider federation

    Keycloak can be configured to delegate authentication to one or more IDPs. Social login via Facebook or Google is an example of identity provider federation. You can also hook Keycloak to delegate authentication to any other OpenID Connect or SAML 2.0 IDP.


identity provider mappers

    When doing IDP federation you can map incoming tokens and assertions to user and session attributes. This helps you propagate identity information from the external IDP to your client requesting authentication.



required actions

    Required actions are actions a user must perform during the authentication process. A user will not be able to complete the authentication process until these actions are complete. For example, an admin may schedule users to reset their passwords every month. An update password required action would be set for all these users.


authentication flows

    Authentication flows are work flows a user must perform when interacting with certain aspects of the system. A login flow can define what credential types are required. A registration flow defines what profile information a user must enter and whether something like reCAPTCHA must be used to filter out bots. Credential reset flow defines what actions a user must do before they can reset their password.

---
Set Up a Realm

    In the Keycloak admin console, log in with the default administrator credentials (admin/admin).
    Create a new realm for your application by clicking on “Add Realm” and provide a unique name for your realm.
    Configure the realm settings, such as token lifespan, SSO settings, etc., according to your application’s requirements.

Create a Client for Your Application

    Inside your realm, navigate to the “Clients” section and click on “Create” to add a new client.
    Provide a unique client ID and choose “confidential” as the client’s access type.
    Configure the allowed redirect URLs, web origins, and base URL for your application.

Define User Roles

    In the Keycloak admin console, go to the “Roles” section and create roles that correspond to different levels of access within your application.
    For each role, specify the permissions it grants to users.

Integrate Keycloak with Your Application

    Add the Keycloak JavaScript adapter to your frontend application by including the Keycloak JavaScript library in your HTML files.
    Configure the adapter with your client ID and Keycloak server URL.
    Initialize the Keycloak adapter in your application to handle authentication and session management.

Implement Login and Logout Functionality

    Create a login button in your application that redirects users to the Keycloak login page.
    Handle the authentication callback from Keycloak and set up the user session in your application after successful login.
    Implement a logout mechanism that redirects users to the Keycloak logout page to terminate their session.

Secure Resources Based on User Roles

    Use the Keycloak adapter to enforce role-based access control for your application’s resources.
    Protect specific endpoints or components by checking the user’s assigned roles before granting access.

Enable Single Sign-On (SSO)

    In the Keycloak admin console, go to the “Realm Settings” and enable Single Sign-On (SSO) for your realm.
    Configure your applications to participate in the SSO realm to enable users to log in once and access multiple applications seamlessly.

Customize the Login and Registration Flow (Optional)

    Customize the Keycloak login and registration themes to match your application’s branding and user experience.
    Add your own logo, colors, and styles to create a cohesive user interface.


Connect 3rd party with Keycloak

we’ll see how we use Keycloak for Authentication and Authorization. Below are the steps we keep in mind when we deal with keycloak.

Flow Diagram Steps:

    User Request: A user initiates a request to access data or perform an action in the frontend application, which sends a request to the Hasura GraphQL API.
    Hasura GraphQL API: Hasura receives the GraphQL request from the frontend and processes it.
    Auth Webhook Check:

Before processing the request, Hasura checks for the presence of an Authorization header containing a valid JWT token. If the token is not present or invalid, Hasura redirects the user to Keycloak for authentication.

    Keycloak Authentication:

The user is redirected to the Keycloak login page to enter their credentials. After successful authentication, Keycloak generates a JWT access token.

    JWT Token Exchange:

Keycloak sends the JWT access token back to the frontend application.

    Frontend Request with JWT:

The frontend includes the JWT access token in the Authorization header and re-sends the original request to the Hasura GraphQL API.

    Hasura Auth Webhook:

Hasura forwards the request to the Auth Webhook, passing the JWT token in the request header.

    Auth Webhook Validation:

The Auth Webhook receives the request and validates the JWT token by sending it to Keycloak’s token validation endpoint.

    Token Validation with Keycloak:

The Auth Webhook sends the JWT token to Keycloak for validation. Keycloak responds with the token status (active or inactive).

    Extract Roles:

If the token is active, the Auth Webhook extracts the user’s roles from the JWT token.

    Authorize Request:

The Auth Webhook responds to Hasura with the user’s roles, which include the necessary permissions for the requested action.

    Hasura Authorization:

Hasura receives the roles from the Auth Webhook and validates the user’s permissions against the requested action.

    Request Fulfillment:

If the user is authorized, Hasura processes the original request and retrieves data or performs the action requested.

    Response to Frontend:

Hasura sends the response back to the frontend application with the requested data or action result.

    User Interaction:

The frontend application displays the data or action result to the user.

This flow diagram outlines the process of how user requests are fulfilled with an authorization layer connecting Hasura and Keycloak.


## Users and Roles


Managing user attributes

In Keycloak a user is associated with a set of attributes. These attributes are used to better describe and identify users within Keycloak as well as to pass over additional information about them to applications.

A user profile defines a well-defined schema for representing user attributes and how they are managed within a realm. By providing a consistent view over user information, it allows administrators to control the different aspects on how attributes are managed as well as to make it much easier to extend Keycloak to support additional attributes.

Although the user profile is mainly targeted for attributes that end-users can manage (e.g.: first and last names, phone, etc) it also serves for managing any other metadata you want to associate with your users.


The user profile schema or configuration uses a JSON format to represent attributes and their metadata. From the administration console, you are able to manage the configuration by clicking on the Realm Settings on the left side menu and then clicking on the User Profile tab on that page.

Understanding Managed and Unmanaged Attributes

By default, Keycloak will only recognize the attributes defined in your user profile configuration. The server ignores any other attribute not explicitly defined there.



By being strict about which user attributes can be set to your users, as well as how their values are validated, Keycloak can add another defense barrier to your realm and help you to prevent unexpected attributes and values associated to your users.

That said, user attributes can be categorized as follows:

    Managed. These are attributes controlled by your user profile, to which you want to allow end-users and administrators to manage from any user profile context. For these attributes, you want complete control on how and when they are managed.

    Unmanaged. These are attributes you do not explicitly define in your user profile so that they are completely ignored by Keycloak, by default.


Assigning permissions using roles and groups

Roles and groups have a similar purpose, which is to give users access and permissions to use applications. Groups are a collection of users to which you apply roles and attributes. Roles define specific applications permissions and access control.

There is a global namespace for roles and each client also has its own dedicated namespace where roles can be defined.

Client roles

Client roles are namespaces dedicated to clients. Each client gets its own namespace. Client roles are managed under the Roles tab for each client. You interact with this UI the same way you do for realm-level roles.

Converting a role to a composite role

Any realm or client level role can become a composite role. A composite role is a role that has one or more additional roles associated with it. When a composite role is mapped to a user, the user gains the roles associated with the composite role. This inheritance is recursive so users also inherit any composite of composites. However, we recommend that composite roles are not overused.

Using default roles

Use default roles to automatically assign user role mappings when a user is created or imported through Identity Brokering.

https://www.keycloak.org/docs/latest/server_admin/index.html#_identity_broker

Procedure

    Click Realm settings in the menu.

    Click the User registration tab.

Role scope mappings

On creation of an OIDC access token or SAML assertion, the user role mappings become claims within the token or assertion. Applications use these claims to make access decisions on the resources controlled by the application. Keycloak digitally signs access tokens and applications reuse them to invoke remotely secured REST services. However, these tokens have an associated risk. An attacker can obtain these tokens and use their permissions to compromise your networks. To prevent this situation, use Role Scope Mappings.

Role Scope Mappings limit the roles declared inside an access token. When a client requests user authentication, the access token it receives contains only the role mappings that are explicitly specified for the client’s scope. The result is that the permissions of each individual access token are limited instead of giving the client access to all the user’s permissions.

Groups compared to roles

Groups and roles have some similarities and differences. In Keycloak, groups are a collection of users to which you apply roles and attributes. Roles define types of users, and applications assign permissions and access control to roles.

Composite Roles are similar to Groups as they provide the same functionality. The difference between them is conceptual. Composite roles apply the permission model to a set of services and applications. Use composite roles to manage applications and services.

Groups focus on collections of users and their roles in an organization. Use groups to manage users.


## Integrating identity providers

An Identity Broker is an intermediary service connecting service providers with identity providers. The identity broker creates a relationship with an external identity provider to use the provider’s identities to access the internal services the service provider exposes.

From a user perspective, identity brokers provide a user-centric, centralized way to manage identities for security domains and realms. You can link an account with one or more identities from identity providers or create an account based on the identity information from them.

Keycloak bases identity providers on the following protocols:

    SAML v2.0

    OpenID Connect v1.0

    OAuth v2.0

## Realms

Managing access to realm resources

Each realm created on the Keycloak has a dedicated Admin Console from which that realm can be managed. The master realm is a special realm that allows admins to manage more than one realm on the system. You can also define fine-grained access to users in different realms to manage the server.

Master realm access control

The master realm in Keycloak is a special realm and treated differently than other realms. Users in the Keycloak master realm can be granted permission to manage zero or more realms that are deployed on the Keycloak server. When a realm is created, Keycloak automatically creates various roles that grant permissions to access that new realm. Access to The Admin Console and Admin REST endpoints can be controlled by mapping these roles to users in the master realm. It’s possible to create multiple superusers, as well as users that can only manage specific realms.

Global roles

There are two realm-level roles in the master realm. These are:

    admin

    create-realm

Users with the admin role are superusers and have full access to manage any realm on the server. Users with the create-realm role are allowed to create new realms. They will be granted full access to any new realm they create.

Realm specific roles

Admin users within the master realm can be granted management privileges to one or more other realms in the system. Each realm in Keycloak is represented by a client in the master realm. The name of the client is <realm name>-realm. These clients each have client-level roles defined which define varying level of access to manage an individual realm.

Dedicated realm admin consoles

Each realm has a dedicated Admin Console that can be accessed by going to the url /admin/{realm-name}/console. Users within that realm can be granted realm management permissions by assigning specific user role mappings.

Each realm has a built-in client called realm-management. You can view this client by going to the Clients left menu item of your realm. This client defines client-level roles that specify permissions that can be granted to manage the realm.

Managing Policies

The Policies tab allows administrators to define conditions using different access control methods to determine whether a permission should be granted to an administrator attempting to perform operations on a realm resource. When managing permissions, you must associate at least a single policy to grant or deny access to a realm resource.

Policies are basically conditions that will evaluate to either a GRANT or a DENY. Their outcome will decide whether a permission should be granted or denied.
A permission is only granted if all its associated policies evaluate to a GRANT. Otherwise, the permission is denied and a realm administrator will not be able to access the protected resource.



