---
layout: post
title: "Release of pgAdba, an asynchronous connection library for PostgreSQL"
author: capitol
category: member-project
---
![coffee-elephant](/images/coffee-elephant.jpg)

# Release of pgAdba, an asynchronous connection library for PostgreSQL

The jdbc group have been working on building an api for doing asynchronous
sql queries against a database, called [ADBA](ttp://cr.openjdk.java.net/%7Elancea/8188051/apidoc/jdk/incubator/sql2/package-summary.html).

The purpose of this api is to reduce overhead when doing database intensive tasks. Take
a standard http request as an example, we can break down it's lifecycle into four phases

1) request arrives to the application server over http
2) application code collects data to be able to render the output
3) output is rendered into a string
4) said string is sent over the network to the client

Point 1 and 4 is already handled asynchronous on modern application servers and 3 is only
limited by cpu speed. Left is the collection of data to fulfill the rendering and in many
cases this involve sending queries to a database in a blocking manner. That means that
we have an application thread that starts processing, send a query to the database
and then sits and waits until the database responds.

If we instead could hand the query/queries of to the connection library and receive
a future that the connection library completes when the database answers we can let
the thread work on something else in the meantime. That way reducing the number
of threads needed, thus minimizing memory overhead and context switching.

The [pgAdba](https://github.com/pgjdbc/pgadba) library implements a useful subset of
this proposed API for postgresql, the plan is to implement the whole api, but it's
better to release early and often than waiting for perfection.

# Architectural changes from JDBC

## Asynchronous

A useful mental model for how the programming against the api work are two parallel 
threads, the one the user controls build up one or more queries, called 
[Operations](https://github.com/pgjdbc/pgadba/blob/master/src/main/java/jdk/incubator/sql2/Operation.java),
fills them with parameter data and everything else that's needed and hands them over
to the other thread. It gets a future in return, in the form of a [Submission](https://github.com/pgjdbc/pgadba/blob/master/src/main/java/jdk/incubator/sql2/Submission.java).

The other thread is responsible for the network communication, and sends the query to the
database. On return it completes the future, either normally or in case of an error 
exceptionally.

## Queries are not parsed by the connection library

That both the connection library and the database should parse the query is a waste of
effort, therefor the pgAdba library never parses the sql query string and instead sends
it as-is to the database server.

This removes the need for complicated parsing and escaping logic in the driver, and
makes debugging problems with the query simpler, as you can know that what you as a 
developer see and what the server see are the same.

## Minimal amount of state inside the library

The library manages the state of the connections to the database, but everything
related to updatable ResultSets have been removed.

# Technical improvements 

## Query pipelining

By using the extended query protocol in the postgresql wire format we can ensure that
we get one answer for every query we send. This enables us to start sending query number
two before we have received the answer to the first query.

This really helps with throughput, especially in situations where there is increased
latency between the database server and the application server.

## Use of `java.time` date classes

The new time classes that arrived in java 8 are a huge improvement over `java.util.Date`
and they are first class citizens in this library.

# What remains

A lot! Suggestions, bug reports and pull requests are very welcome.

The version number includes the -ALPHA denomination, this has two meanings. The first is that the
API published under the  `jdk.incubator.sql2` namespace isn't stable and will change in future 
releases. The other is that the driver itself isn't tested under production workloads and there
will be bugs.

But regardless of that it's possible to experiment and get a feeling for how the proposed API works.

# How to test it out

[Here](https://github.com/alexanderkjall/pgadba-example-application-spring-boot/) is a complete example of an small REST based webserver application built with
[Spring Boot](https://spring.io/projects/spring-boot).

Or just include the maven dependency in your project:

### Maven

```xml
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>pgadba</artifactId>
  <version>0.1.0-ALPHA</version>
</dependency>
```

### Gradle

```groovy
compile 'org.postgresql:pgadba:0.1.0-ALPHA'
```
