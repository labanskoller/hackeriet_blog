---
layout: post
title: "Resources for becoming a better hacker - Part 1, crypto"
author: capitol
category: crypto
---
![bits](/images/turing.jpg)

The skill set of a good hacker should cover a wide array of different topics, today we are
going to take a dive into one of those areas - Cryptographic systems.

Modern cryptography is a field that really took off 1976 when Diffie and Hellman 
introduced public-key cryptography and a method for key exchange based on the
discrete logarithm problem. Since then there has been many great developments within
the field and more algorithms have been designed based on hard mathematical problems.

Thankfully most people (that are not doing it as a living) have stopped inventing their
own encryption algorithms, so it's rare that there is a weakness in the algorithm.
But that doesn't mean that there isn't any avenues for attack for a skilled hacker.
There is no shortage of mistakes being made in the implementation of the algorithms
that we think are safe, and even if the implementation is without obvious exploits
then it might leak information through side channels (caches, timing, power usage) or
maybe the implementation of the random number generator can be attacked.

In order to be able to understand the how to build secure systems, or how to attack
them, I recommend two things, a solid theoretical understanding and lots of practice.

#### Theoretical Texts

One of the classic books on the subject is "Handbook of Applied Cryptography" and is
available for free here:

http://cacr.uwaterloo.ca/hac/

#### Useful Libraries

There is a lot of libraries that implement cryptographic primitives so that you don't
have to reinvent wheels. I have listed to two biggest ones for python and java below,
but there isn't any shortage of libraries for other languages.

Python: https://pypi.python.org/pypi/pycrypto

Java: https://www.bouncycastle.org/java.html

#### Training Exercises

Theoretical knowledge is great, but there is no more effective way to learn something
than to practice it. These are sets of challenges that lets you try to figure and 
implement solutions.

The best set of training exercises I have found is the cryptopals one.

http://cryptopals.com

https://overthewire.org/wargames/krypton/

https://www.root-me.org/en/Challenges/Cryptanalysis/


<sub><sup>(image by parameter_bond, Creative Commons 2.0)</sup></sub>
