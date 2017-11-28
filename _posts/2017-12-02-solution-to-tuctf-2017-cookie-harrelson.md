---
layout: post
title: "Solution to TUCTF 2017 Cookie Harrelson"
author: capitol
category: ctf
---
![tallahassee](/images/tallahassee_night_city.jpg)

##### name:
Cookie Harrelson

##### category:
web

##### points:
200

#### Writeup

On accessing the webpage we got this cookie: tallahassee=Y2F0IGluZGV4LnR4dA%3D%3D

Decoding that with base64 revealed that it contained the string: cat index.txt

Playing around with the cookie showed that if we changed it the string "cat index.txt#" was prepended to the supplied value and sent back.

Based on that we guessed that the server generated the webpage by executing the content of the cookie. We just needed to break out of the comment pund character and we would be able to get the flag. First we did a ls to see that the filename of the flag was flag, and then we got the flag itself.

```bash
curl 'http://cookieharrelson.tuctf.com/' -H "Cookie: tallahassee=`echo -e '\ncat flag'|base64`"
curl 'http://cookieharrelson.tuctf.com/' -H "Cookie: tallahassee=`echo -e '\ncat flag'|base64`"
```

Flag was TUCTF{D0nt_3x3cut3_Fr0m_C00k13s}