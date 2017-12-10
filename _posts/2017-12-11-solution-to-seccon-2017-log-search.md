---
layout: post
title: "Solution to SECCON 2017 Log Search"
author: capitol
category: ctf
---
![logs](/images/logs.png)

##### name:
Log search

##### category:
web

##### points:
100

#### Writeup

We go a [link](http://logsearch.pwn.seccon.jp/) to an empty site with the words
"Find the flag!". 

Looking at the source we found a link to another [page](http://logsearch.pwn.seccon.jp/logsearch.php).

That was a search page for accesses to the webpage. Searching for flag gave us 
 this url: http://logsearch.pwn.seccon.jp/flag-b5SFKDJicSJdf6R5Dvaf2Tx5r4jWzJTX.txt

flag was SECCON{N0SQL_1njection_for_Elasticsearch!}
