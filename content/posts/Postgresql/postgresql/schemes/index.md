---
Title: Postgresql Scheme
date: 2024-12-21
categories:
- Postgresql
tags:
- postgresql
keywords:
- postgresql
summary: ""
comments: false
showMeta: false
showActions: false
---

# Databases and Schemas in PostgreSQL

In PostgreSQL, databases and schemas are different but related concepts used to organize data:

## 1. Database

- The highest level of data organization in PostgreSQL.
- A database contains all the information, including schemas, tables, indexes, functions, views, and other data objects.
- Each database in PostgreSQL is independent; data in one database cannot be accessed from another database (unless using specific extensions like `dblink` or `postgres_fdw`).
- It serves as the main container for all related data objects.

**Example:**  
For an accounting application, you could have a database named `accounting` that contains all the data related to your company’s accounting.

---

## 2. Schema

- A level of organization within a database.
- A schema acts like a folder inside a database and can contain tables, views, functions, indexes, and other objects.
- Schemas help group objects within a database to keep them organized or separate them by functionality or department.
- A database can have multiple schemas, and users initially access the default schema named `public` unless another is specified.
- Object names (e.g., tables) can be repeated across different schemas since each schema has its own namespace.

**Example:**  
In your `accounting` database, you could have:

- A `sales` schema with tables related to sales (e.g., invoices, customers).
- A `purchases` schema with tables related to purchases (e.g., suppliers, orders).

---

## Key Differences Between Databases and Schemas

| **Feature**         | **Database**                  | **Schema**                                           |
|----------------------|-------------------------------|-----------------------------------------------------|
| **Hierarchy Level**  | Main container               | Subset within the database                          |
| **Independence**     | Independent of other databases | Depends on a database                               |
| **Namespace**        | Global across the database   | Separate for each schema                           |
| **Cross-Access**     | Not directly possible without extensions | Yes, you can access tables in other schemas within the same database (using full name: `schema.table`) |
| **Usage Example**    | Separate applications         | Modules or departments within the same application |

---

## Summary

- **Database**: Large-scale organization, contains everything.
- **Schema**: Subdivision within a database for better structuring of data.

# Tuple

In PostgreSQL, a **tuple** refers to a row of data within a table. It is a term primarily used in the context of relational databases and derives from the relational model, where a tuple represents an instance of a dataset that adheres to the structure defined by the table schema.

For example, if you have a table called `users` with the following columns: `id`, `name`, `email`, a tuple would be a set of values filling these fields, like:

| id | name      | email             |
|----|-----------|-------------------|
| 1  | John Doe  | john@example.com  |

In this case, the tuple would be `(1, 'John Doe', 'john@example.com')`.

From a technical perspective in PostgreSQL:
1. **Tuple in memory**: When PostgreSQL processes data, it uses in-memory structures called tuples to represent rows.
2. **Tuple on disk**: Tuples are also physically stored in the data pages of the system's files, which make up the tables on disk.

## Key aspects of tuples in PostgreSQL

1. **MVCC (Multi-Version Concurrency Control)**: PostgreSQL manages tuples under the MVCC model, allowing multiple versions of a tuple to exist in the database. This is essential for consistent reads and managing locks during concurrent transactions.
   
2. **TID (Tuple Identifier)**: Each tuple has a unique identifier called `TID`, which points to its specific location within a page. This is useful for fast lookups.

3. **Tuple states**: A tuple can have different states (visible, invisible, updated, or deleted) depending on the transaction context.

In summary, a tuple in PostgreSQL is simply a row in a table, but its internal management is optimized to handle data efficiently in a transactional environment.


