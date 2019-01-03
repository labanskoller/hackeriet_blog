---
layout: post
title: "Solution to 35C3 Junior CTF challenge pretty\_linear"
author: capitol
category: ctf
---

![linear-subspaces](/images/1280px-Linear_subspaces_with_shading.svg.png)

##### Name:
pretty\_linear

##### Category:
crypto

##### Points:
500 (variable)

#### Writeup

We were given a [PCAP file]({% link /assets/pretty-linear/c5c0d261333729feb801834d5168ba4c-surveillance.pcap %})
full of recorded network traffic, and the source code for
[the server]({% link /assets/pretty-linear/ad8d07e798dd88b3d4950498e3a6b4d6-server.py %}).

The server code that generated the network traffic looks like this:

```python
    print(' '.join(map(str, challenge)))
    response = int(input())
    if response != sum(x*y%p for x, y in zip(challenge, key)):
        print('ACCESS DENIED')
        exit(1)

    print('ACCESS GRANTED')
```

`challenge` and `key` are both arrays consisting of 40 integers that are 16 bytes in
length and the response is another 16 byte integer. `challenge` is sent in plain text
from the server to the client, and therefor known to us. `key` is a shared secret
between the client and the server and never sent over the network. We need to
calculate that key in order to crack the challenge. `response` is also sent over the
network, from the client to the server.

Line three has the algorithm that is used to ensure that the client and the server
both know the same `key`. We can expand that to a more readable form like this:

```python
response = c[0] * k[0] % p + c[1] * k[1] % p + ... + c[39] * k[39] % p;
```

Both variables `response` and `c` are known and `p` is hard coded to
340282366920938463463374607431768211297 in the source code.

Looking into the PCAP file we see that we have 40 of these interactions.
Combining those gives us an equation system with 40 equations, each of them
containing 40 variables. This is a problem that can be solved by a linear equation
solver, but before we can do that we need to get the data out of the PCAP file in a
structured form.

We wrote the following program to get the data out of the PCAP file, and also
generate a sage program that solves the equation system in Z over 340282366920938463463374607431768211297.

```python
from collections import defaultdict
import pyshark
import string
cap = pyshark.FileCapture('c5c0d261333729feb801834d5168ba4c-surveillance.pcap')

streams = defaultdict(list)

for p in cap:
    t = p['tcp']
    p = t.get('payload')
    if p:
        data = "".join([chr(int(c, 16))
                        for c in t.get('payload').split(":")])
        streams[t.stream].append(data)

print("R = IntegerModRing(340282366920938463463374607431768211297)")

challenges = []
responses = []
for k, v in streams.items():
    challenge, response, out = v
    print(out)
    challenges.append(list(map(int, challenge.split())))
    responses.append(int(response))
print("M = Matrix(R, [")
first = True
for c in challenges:
    if not first:
        print(",")
    first = False
    print(c, end="")
print("])")
print("b = vector(R,[")
first = True
for r in responses:
    if not first:
        print(",", end="")
    first = False
    print(r)
print("])")
print("print(M.solve_right(b))")
```

Running the generated sage program gives us the key, and lets us attack the next
part of the server code:

```python
    cipher = AES.new(
            sha256(' '.join(map(str, key)).encode('utf-8')).digest(),
            AES.MODE_CFB,
            b'\0'*16)
    print(binascii.hexlify(cipher.encrypt(flag)).decode('utf-8'))
```

Like this:

```python
import os
import math
import sys
import binascii
from hashlib import sha256
from Crypto.Cipher import AES

key = (151166356399959194245460055888166966126,
       23349654305343746371904146512921179610,
       303231127335861985008837572586617401477,
       52564325979162295713031020943288299431,
       318561098467762156502271721157519784045,
       263049694618319332492436935081367988962,
       151925705582116739255625584197651639678,
       46319333286788790879399387215584902926,
       144250191566113115015826218788418570765,
       95097625879948609497612754022619234195,
       40890527924981050968775993543458295905,
       73015657936779070795829412187806965634,
       17764129701686300306686689106838999642,
       325835500394544926294581718484613749556,
       71443020776832402486826429105359001130,
       328905290970722092344104084599942510400,
       246319993494260311894585740502008352891,
       339251916682414225894494357646852524504,
       270753355547506496805860877660621175158,
       266604583518913012106937436764867155955,
       132952188910249324219774647464400732439,
       229485064954594431373138165566214808548,
       273124499649767430591820642695664426994,
       161206428662237066098654588615704724656,
       191676246712534509807283243359699775780,
       110791878778380133926865862999743362183,
       121869512181659437298676494294916884080,
       81324902884339942138294016318959955113,
       219404824444265280645688236691554688702,
       169041597038940530794876375975659802012,
       131851490945732599957487956170326572223,
       337190018815691236060142455413012785269,
       215436829468576180414177636304832181536,
       174614268507338543165725749934608091983,
       316523955444804263394840392424504742312,
       215434679427738924369625297037020081680,
       103769840624100781721896803697739863413,
       302813910848119681638497129402557822574,
       104414047167186149419822776294661649936,
       124689157029586638342169541932443340723)

chipher = "923fa1835d8dbdcd9f9b0e6658b24fce54512fbba71d7a0012c37d2c9dd094a6278593d8d9f7a4aa9fecb66042"

cipher = AES.new(
    sha256(' '.join(map(str, key)).encode('utf-8')).digest(),
    AES.MODE_CFB,
    b'\0'*16)
print(cipher.decrypt(binascii.unhexlify(chipher)).decode('utf-8'))
```

The flag was: 35C3\_G4uss\_w0uld\_b3\_so\_pr0ud\_of\_y0u\_r1ght\_n0w
