---
layout: post
title: "Solution to SECCON 2017 Vigenere3d"
author: capitol
category: ctf
---
![fractal](/images/fractal.jpg)

##### name:
Vigenere3d

##### category:
crypto

##### points:
100

#### Writeup

We got a python program:

```python
import sys
def _l(idx, s):
    return s[idx:] + s[:idx]
def main(p, k1, k2):
    s = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz_{}"
    t = [[_l((i+j) % len(s), s) for j in range(len(s))] for i in range(len(s))]
    i1 = 0
    i2 = 0
    c = ""
    for a in p:
        c += t[s.find(a)][s.find(k1[i1])][s.find(k2[i2])]
        i1 = (i1 + 1) % len(k1)
        i2 = (i2 + 1) % len(k2)
    return c
print main(sys.argv[1], sys.argv[2], sys.argv[2][::-1])
```

and some example output:

```bash
$ python Vigenere3d.py SECCON{**************************} **************
POR4dnyTLHBfwbxAAZhe}}ocZR3Cxcftw9
```

Lets call the first argument "flag" and the second "seed".

Line 2 in the main function creates a three dimensional lookup table, and as seen in the
 first line in the for loop, the lookups are based on flag string, the seed string and
 the seed string inversed.

Since we know 7 characters of the flag, we can calculate the key string like this:
```python
    plain = "SECCON{"
    encry = "POR4dnyTLHBfwbxAAZhe}}ocZR3Cxcftw9"
    #print seed
    for a in range(0, 7):
        for d in range(0, len(t[s.find(plain[a])])):
            for e in range(0, len(t[s.find(plain[a])][s.find(plain[a])])):
                if t[s.find(plain[a])][d][e] == encry[a] and s[d] == 'A':
                    print "%i %c %c" % (a, s[d], s[e])
```

which gives us the output:

```bash
0 A _
1 A K
2 A P
3 A 2
4 A Z
5 A a
6 A _
```

Once we know that the seed is AAAAAAA_aZ2PK_ we can calculate the flag with:
```python
    #print flag
    for a in range(0, len(p)):
        for d in range(0, len(s)):
            if t[d][s.find(k1[i1])][s.find(k2[i2])] == encry[a]:
                print "%i %c" % (a, s[d])

        i1 = (i1 + 1) % len(k1)
        i2 = (i2 + 1) % len(k2)
```

Flag was: SECCON{Welc0me_to_SECCON_CTF_2017}
