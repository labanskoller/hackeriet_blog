---
layout: post
title: "CTF: Solving nullcon crypto question 2"
author: capitol
category: ctf
---
![diffie-hellman](/images/diffie-hellman.jpeg)

##### name:
Crypto Question 2

##### category:
crypto

##### points:
350

#### Writeup
The nullcon ctf competition ran this weekend, and the organizers managed to completely give away one of the crypto challenges by giving out a hint that made it trivial.

The problem was given as this image: [problem](/images/cryptopuzzle2.png)

And the hint that gave the problem away was:  Hint 2 : 'a' and 'b' both are less than 1000 

By doing a simple iteration from 0 to 1000 we got two possible answers for both a and b.

```java
        BigInteger q = new BigInteger("541");
        BigInteger g = new BigInteger("10");
        for(int i = 0; i < 1000; i++) {
            BigInteger a = g.modPow(BigInteger.valueOf(i), q);

            if(a.equals(BigInteger.valueOf(298)))
                System.out.println("a = " + i);

            if(a.equals(BigInteger.valueOf(330)))
                System.out.println("b = " + i);
        }
```

gave us the output:
```
a = 170
b = 268
a = 710
b = 808
```

And that gave us four possible values for the flag, which was: flag{170,808}
