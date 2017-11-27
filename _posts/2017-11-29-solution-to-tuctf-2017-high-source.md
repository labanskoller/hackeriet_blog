---
layout: post
title: "Solution to TUCTF 2017 High Source"
author: capitol
category: ctf
---
![high_noon](/images/high_noon.jpg)

##### name:
High Source

##### category:
web

##### points:
25

#### Writeup

This was easier than trivial, only 2 steps:

* Look at source, get password; I4m4M4st3rC0d3rH4x0rsB3w43
* enter password be redirected to this:

curl 'http://highsource.tuctf.com/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flagdir/flag' 

flag was TUCTF{H1gh_S0urc3_3qu4ls_L0ng_F4ll}
