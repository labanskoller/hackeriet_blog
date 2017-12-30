---
layout: post
title: "Attacking Elgamal Encryption"
author: capitol
category: ctf
---
![elgamal](/images/taher_elgamal.jpg)

##### name:
Megalal

##### category:
crypto

##### points:
500 / variable

#### Writeup

We got this task from the game masters at the 34c3 junior ctf:
```text
You can reach a strange authentication system here: nc 35.197.255.108 1337

I'm sure you know what you have to do.
```

And we got the [python source]({% link /assets/megalal.py %}) of the program running on the
server.

When connecting to the service we got two options, either to provide a name and a role and get
an authentication token. Or to provide an token that contained the role `overlord` and get the
flag. It was illegal to generate a token with the role `overlord`.

The token was the name concatenated with `#` and the role, and then encrypted with 
[elgamal](https://en.wikipedia.org/wiki/ElGamal_encryption). The elgamal encryption scheme
produces two numbers when you encrypt something, and those two numbers where converted to hex
and concatinated with a `_`.

Reading the wikipedia article about elgamal we discovered we discovered that you can manipulate
the cipher in order to produce another plain text. As described by wikipedia:

```text
ElGamal encryption is unconditionally malleable, and therefore is not secure under chosen ciphertext 
attack. For example, given an encryption (c1 , c2) of some (possibly unknown) message m, one can
easily construct a valid encryption ( c1 , 2 * c2 ) of the message 2 * m.
```

This means that if we manages to produce a message that when doubled decrypts to something that 
ends in the charactes `#overlord` we will get the flag.

The string `#overlord` is 0x236f7665726c6f7264 when converted to hex so if we send in the byte
values that are half that as role we will get something that we can double and send back and get
the flag.

We wrote a small python tool to do this for us:

```python
import socket
import binascii

name = "a"
a = int(binascii.hexlify("#overlord"), 16)
role2 = binascii.unhexlify("%x"%((a/2)))

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(("35.197.255.108", 1337))

s.send("2\n")
s.send(name + "\n")
s.send(role2 + "\n")
data = s.recv(4096)
c1_c2 = s.recv(4096)
data = s.recv(4096)

(c1, c2) = c1_c2.split("_")
c1 = c1.split("\n")[4]

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(("35.197.255.108", 1337))

data = s.recv(4096)
s.send("1\n")
data = s.recv(4096)
s.send("%s_%x\n" % (c1, int(c2, 16) * 2 ))
data = s.recv(4096)
data = s.recv(4096)
print(data)
```

What's happening here is that we first connect and log in, get the token from our specially
crafted role then we split the token in `c1` and `c2`. Double `c2` and sends the token back and get
the flag.

Flag was `34C3_such_m4lleable_much_w0w`