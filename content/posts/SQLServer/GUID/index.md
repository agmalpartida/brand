---
Title: "SQL Server GUID"
date: 2025-04-05
categories:
- sqlserver
tags:
- sqlserver
keywords:
- sql
summary: ""
comments: false
showMeta: false
showActions: false
---

# GUID

In SQL Server, a GUID (Globally Unique Identifier) is a 16-byte (128-bit) unique identifier commonly used as a primary key or unique identifier in a table. In SQL Server, GUIDs are handled using the uniqueidentifier data type.

Characteristics of GUIDs in SQL Server:

- Globally Unique: Designed to be unique across different systems and servers, with virtually no chance of collision.

- Random: Unlike IDENTITY values, GUIDs are not sequential and do not follow a predictable pattern.

- Larger than an integer: GUIDs take up 16 bytes of storage, which can impact performance and storage usage.

- Can be generated using NEWID() or NEWSEQUENTIALID():

- NEWID() generates a completely random GUID.

- NEWSEQUENTIALID() generates a sequential GUID, which can improve indexing performance.

Example Usage:

```sql
CREATE TABLE Customers (
    Id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL
);

INSERT INTO Customers (Name) VALUES ('Juan Pérez');
```

In this example, the Id field will be automatically generated using NEWID(), ensuring that each record has a unique value.

Considerations:

- Indexes: Using GUIDs as primary keys can affect performance due to their size and randomness. Using NEWSEQUENTIALID() can help mitigate this by improving index efficiency.

- Storage: GUIDs occupy more space than INT or BIGINT, potentially increasing the overall size of the database.

- Compatibility: GUIDs are often used in distributed environments and systems that require data synchronization across multiple databases or services.
