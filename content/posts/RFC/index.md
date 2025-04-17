---
Title: "RFC"
date: 2025-04-17
categories:
- RFC
tags:
- rfc
keywords:
- rfc
summary: ""
comments: false
showMeta: false
showActions: false
---

# RFCs (Request for Comments)

RFCs (Request for Comments) are technical documents published by the IETF (Internet Engineering Task Force) and other related organizations. They define standards, protocols, procedures, and concepts related to the Internet and computer networks.

## What exactly are they?

- "Request for Comments" doesn't mean they are open drafts for discussion (although some are in their early stages). It's a historical name that stuck.
- Many RFCs become official Internet standards, such as HTTP, TCP/IP, SMTP, DNS, etc.
- They are numbered sequentially and do not change once published. If a standard evolves, a new RFC is published to update or replace the old one.

---

## Example: RFC 6749

- This RFC defines the **OAuth 2.0 Authorization Framework**.
- It specifies how an application can obtain limited access to a user's resources without handling their credentials directly.
- Widely used in modern authentication (e.g., when you **"Sign in with Google"**).

---

## Who creates RFCs?

Mainly the **IETF**, although organizations like the **IRTF** or the **IAB** can also produce them.

Anyone can propose an RFC, but the formal process usually involves **IETF working groups**.

---

## RFC Creation Process

1. **Idea or Need**  
   Someone (usually in an IETF working group) identifies a technical issue or need that requires a formal specification.

2. **Internet-Draft (I-D)**  
   A temporary draft document is written (`draft-...`), proposing a solution.  
   This draft is valid for 6 months and can be renewed or replaced.

3. **Discussion and Review**  
   The draft is discussed via mailing lists, working group meetings, or IETF plenaries.  
   Technical reviews, comments, and improvements are made.

4. **Last Call and Formal Technical Review**  
   When the draft matures, a "Last Call" is issued for final comments.

5. **Approval**  
   The draft is reviewed by the **IESG** (Internet Engineering Steering Group). If approved, it becomes an RFC.

6. **Publication**  
   It is officially published with a permanent number.  
   For example, the OAuth 2.0 draft became **RFC 6749**.

---

## Types of RFCs

Not all RFCs are standards. They can be classified as:

- **Standards Track** – Technologies forming the core of the Internet (e.g., HTTP/2, TCP, DNS).
- **Informational** – Describe ideas, technologies, or analyses; not intended as standards.
- **Experimental** – Proposals being tested.
- **Historic** – Outdated or obsolete technologies.

---

## Maturity Levels of Standards

For **Standards Track** RFCs, there are three levels:

- **Proposed Standard** – First stable version, still subject to change.
- **Draft Standard** – Quite stable and tested in real-world implementations.
- **Internet Standard** – Fully mature and widely adopted across the industry.

---

## Real Example: OAuth 2.0 (RFC 6749)

- **Idea**: A simpler and more secure replacement for OAuth 1.0 was needed.
- **Drafts**: The *OAuth WG* of the IETF began publishing drafts like `draft-ietf-oauth-v2`.
- **Public Discussion**: Between 2009–2012, use cases, improvements, and risks were discussed.
- **Last Call & Review**: The community reviewed the draft to reach consensus.
- **Approval**: The **IESG** approved the draft in October 2012.
- **Publication**: It was published as **RFC 6749**.

### Follow-up RFCs and Extensions

- **RFC 6750** – Bearer Tokens  
- **RFC 6819** – Security Considerations  
- **RFC 8252** – OAuth for Native Apps  
- **RFC 9126** – OAuth 2.1 *(still evolving)*

---

## Useful Resources

- [IETF Datatracker](https://datatracker.ietf.org/) — Track drafts and RFCs  
- [RFC Editor](https://www.rfc-editor.org/) — Official RFC library  
- [IETF Tools](https://tools.ietf.org/) — Tools and active working groups
