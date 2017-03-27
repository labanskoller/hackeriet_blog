---
layout: post
title: "CTF: VolgaCTF VC task"
author: capitol
category: ctf
---
![bits](/images/volga.jpg)

##### name:
VC

##### category:
crypto

##### points:
50

#### Writeup

We were given two images, both containing black and white noise.
[A](/images/volga_vc_A.png) [B](/images/volga_vc_B.png)

Since it's a crypto challege with low points, we guessed that it's a simple XOR.

The quickest way to xor two images is with a command line one liner:

```bash
convert A.png B.png -fx "(((255*u)&(255*(1-v)))|((255*(1-u))&(255*v)))/255" C.png
```

That produced this result:
[C](/images/volga_vc_C.png)


Flag: VolgaCTF{Classic_secret_sharing_scheme}
