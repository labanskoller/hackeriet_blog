---
layout: post
title: "Solution to SECCON 2017 putchar Music"
author: capitol
category: ctf
---
![rebels](/images/rebels.png)

##### name:
putchar music

##### category:
programming

##### points:
100

#### Writeup

We got a one liner c program and where asked to find the movie title, after adding 
include lines it looked like this

```c
#include <stdio.h>
#include <math.h>

main(t,i,j){unsigned char p[]="###<f_YM\204g_YM\204g_Y_H #<f_YM\204g_YM\204g_Y_H #+-?[WKAMYJ/7 #+-?[WKgH #+-?[WKAMYJ/7hk\206\203tk\\YJAfkkk";
for(i=0;t=1;i=(i+1)%(sizeof(p)-1)){double x=pow(1.05946309435931,p[i]/6+13);for(j=1+p[i]%6;t++%(8192/j);)
putchar(t>>5|(int)(t*x));}}
```

We compiled it with:

```bash
gcc putchar.c -lm
```

And when we can the program it produced a lot of random output in intervals, so we piped
 it to the sound card with:
 
```bash
./a.out | padsp tee /dev/audio > /dev/null
```

That produced beautiful music and we are thinking about converting all our mp3s to C now.

flag was SECCON{STAR_WARS}
