---
layout: post
title: Simple and Extended queries in PostgreSQL
author: capitol
category: postgresql
---

![elephant-family](/images/elephant-family.jpg)

# Simple and Extended queries in PostgreSQL

The postgresql wire format have two mechanism to send queries to the database,
the simple and the extended protocol. Lets go over how they work and the difference 
between them.

## Simple protocol

Queries are sent as plain text to the server, without any parameters. It's also allowed
to send multiple queries in the same frame by separating them with `;`.

This makes the simple protocol a bit more vulnerable to sql injection attacks.

The query looks like this on the wire:

| type marker| length | query    |
|------------|--------|----------|
|byte        | int32  | str      |
|'Q'         | 8      | select 1 |


The server can respond with one or more of 

* CommandComplete
* CopyInResponse
* CopyOutResponse
* RowDescription
* DataRow
* EmptyQueryResponse
* ErrorResponse
* ReadyForQuery
* NoticeResponse

We will not go into detail about the server responses in this blog post

## Extended protocol

The extended protocol is a bit more complex, but in return you get better type safety
and less exposure to sql injections.

The sending of queries is split into five steps

* Parse
* Describe
* Bind
* Execute
* Sync

### Parse

The parse message contains the query, with placeholders on the format `$<number>`, for 
example `$1`.

The parse message looks like this on the wire:

| type marker| length | name | query      | num params | param oid |
|------------|--------|-------|-----------|------------| ----------|
|byte        | int32  | str   | str       | int16      | int32     |
|'P'         | 23     | q1    | select $1 | 1          | 5         |

In hex: `500000001771310073656c65637420243100000100000017`

An `oid` is an id of a type in postgresql. A complete list of all the standard types
can be retrieved by doing `select * from pg_type`.

The name is optional, if it's specified the query is saved in the connection context
and the parsed query can be reused, otherwise it's saved in the unnamed statement slot
and will be overwritten by the next unnamed parse message or simple query.

### Describe

The describe message is used to get a description of the statement or portal in
order to know the types of the returned columns.

| type marker| length | type       | name      |
|------------|--------|------------|-----------|
|byte        | int32  | 'S' or 'P' | str       |
|'D'         | 8      | P          | p1        |

In hex: `440000000853713100`

### Bind

Once the query is parsed it's possible to bind parameters to it with a bind message.

This creates an `output portal`.

| type marker| length | portal | query | num formats | format | num parameters | parameter length | value        |
|------------|--------|--------|-------|------------| --------|----------------|------------------|--------------|
|byte        | int32  | str    | str   | int16      | int16   | int16          | int16            | str or bytes |
|'B'         | 26     | p1     | q1    | 1          | 1       | 1              | 1                | 1            |

In hex: `420000001a70310071310000010001000100000004000000010000`

The format of a parameter can either be `1` or `0` indicating if the parameter is 
formatted as text or binary.

### Execute

Once everything has been setup by the other frames it's time to execute the query and
let the server do the actual work.

| type marker| length | portal | row limit |
|------------|--------|--------|-----------|
|byte        | int32  | str    | int32     |
|'E'         | 11     | p1     | 0         |

In hex: `450000000b70310000000000`

### Sync

The sync message signals that the frontend is finished and that the backend can close
the current transaction unless the query is in a `begin transaction` block.

| type marker| length |
|------------|--------|
|byte        | int32  |
|'S'         | 4      |

In hex: `5300000004`

And after this the query is finished and it's possible to start over with the next
query.