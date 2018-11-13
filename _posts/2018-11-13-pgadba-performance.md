---
layout: post
title: Performance testing our Asynchronous PostgreSQL library
author: capitol
category: postgresql
---

# Performance testing the Asynchronous PostgreSQL library pgAdba

We have done some performance testing between the pgjdbc driver and the pgAdba driver
for PostgreSQL.

![results](/images/pgadba-vs-pgjdbc-performance.png)

The test was performed 20 times for each number of threads, with a warm-up set before.
The raw data can be found [as text]({% link /assets/performance-data-pgadba.txt %})
[or csv]({% link /assets/performance-data-pgadba.csv %})

A linear regression gives that pgAdba is 16.6% faster than pgjdbc.

## Method

The test was designed to expose the connection library, rather than the postgresql 
database itself. So if your application does a large number of very cheap sql queries
then this might be relevant.

The test is done by performing a large number of http requests against an spring boot
web server, for each request the server takes the url of the requests, sends it
to the database server as a string, which echo the request right back without any 
disk I/O, and the server returns the url as a string to the client.

The test code for the async library pgAdba is:

```java
    @RequestMapping("/{val}")
    public CompletableFuture<String> index(@PathVariable("val") String val) {
        Submission<List<RowColumn>> sub = session.<List<RowColumn>>rowOperation("select $1 as t")
            .set("$1", val, AdbaType.VARCHAR)
            .collect(Collectors.toList())
            .submit();

        return sub.getCompletionStage().thenApply(rc -> rc.get(0).at("t").get(String.class)).toCompletableFuture();
    }
```

and the code for the blocking pgjdbc driver looks like this:

```java
    @RequestMapping("/{val}")
    public String index(@PathVariable("val") String val) throws SQLException {
        PreparedStatement ps = connection.prepareStatement("select ? as t");
        ps.setString(1, val);
        ResultSet rs = ps.executeQuery();
        if(rs.next()) {
            return rs.getString("t");
        } else {
            throw new RuntimeException("error");
        }
    }
```

The machine that the test ran on had a local database server, that the web server
communicated with over localhost, for minimal latency between the web server and
the database server.

## Configuration and setup of the test

System configuration to ensure that we don't run out of open sockets while the test
runs:
`echo 1024 65000 > /proc/sys/net/ipv4/ip_local_port_range`

`sysctl -w net.ipv4.tcp_tw_reuse=1`

System Hardware:
* CPU: Intel i7-4500U 1.8 GHz
* 8 gig of ram

Software versions:
* OS: Ubuntu 18.04.1 LTS
* Spring boot: 2.0.5.RELEASE
* pgjdbc: 42.2.5
* pgAdba: 0.1.0-ALPHA
* postgresql: 10.5-0ubuntu0.18.04

jmeter command: 
`jmeter -n -t jmeter-performance-test-5.jmx -l /tmp/res-5 -e -o /tmp/out-5`

Java command to run spring boot: `java -server -XX:+UseParallelGC -XX:+AggressiveOpts -XX:+UseLargePages -Xmn1g  -Xms2g -Xmx2g -jar target/pgadba-example-application-spring-boot-0.1.0.jar`

pgAdba code [here](https://github.com/alexanderkjall/pgadba-example-application-spring-boot/tree/async-performance-test)

pgjdbc code [here](https://github.com/alexanderkjall/pgadba-example-application-spring-boot/tree/sync-performance-test)

The image was produced with R like this

```R
mydata <- read.csv(file="/home/capitol/project/hackeriet/blog/assets/performance-data-pgadba.csv", header=TRUE, sep=",")

library(ggplot2)

ggplot() + geom_smooth(data=mydata, aes(x = threads, y = async, colour = "pgAdba"))
 + geom_smooth(data=mydata, aes(x = threads, y = sync, colour = "pgjdbc"))
  + xlab("Number of threads") + ylab("Queries per second") + ggtitle("")
   + geom_point(data=mydata, aes(x = threads, y = async, colour = "pgAdba"))
    + geom_point(data=mydata, aes(x = threads, y = sync, colour = "pgjdbc"))
     + expand_limits(x = 0, y = 0) + theme_light()
```

