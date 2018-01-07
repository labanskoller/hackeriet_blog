---
layout: post
title: "Running tomcat with systemd"
author: capitol
category: infrastructure
---
![tomcat](/images/tomcat.png)

The tomcat server's [documentation](https://tomcat.apache.org/tomcat-9.0-doc/setup.html#Unix_daemon) 
suggests using a custom compiled manager daemon called jsvc from the commons-daemon project.

Most modern linux systems uses [systemd](https://www.freedesktop.org/wiki/Software/systemd/)
to manage it's server processes and it has roughly the same capabilities as jsvc and much more.

To run tomcat on my machines I use a simple systemd service file that starts the service as
the tomcat user and sets some basic java settings.

```text
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-8-oracle/
Environment=CATALINA_PID=/opt/apache/apache-tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/apache/apache-tomcat
Environment=CATALINA_BASE=/opt/apache/apache-tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/apache/apache-tomcat/bin/startup.sh
ExecStop=/bin/kill -15 $MAINPID

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
```

#### Binding to port 80 or 443

It's also possible to give tomcat permission to bind to ports below 1024 without running
it as root by adding this line in the `[Service]` section

```text
AmbientCapabilities=CAP_NET_BIND_SERVICE
```

And also change the `port="8080"` or `port="8443"` setting in server.xml.

#### Limiting memory, cpu or I/O

Systemd gives you control over how much cpu, memory and I/O tomcat can use, which can be
useful if you run multiple micro-services on the same server and want to isolate them
from each other.

This setting for example limits the amount of cpu available to 20% of one processor:

```text
CPUQuota=20%
```

All options are described in the manual [here](https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html).

Systemd uses the [cgroups](https://en.wikipedia.org/wiki/Cgroups) system in the linux
kernel in order to control resource usage.

#### Security capabilities

Systemd also have a lot of other capabilities to lock down the service and reduce the
effects if your application gets hacked. You can

* Isolating services from the network
* Service-private /tmp
* Making directories appear read-only or inaccessible to services
* Taking away capabilities from services
* Disallowing forking, limiting file creation for services
* Controlling device node access of services

as explained [here](http://0pointer.de/blog/projects/security.html).
