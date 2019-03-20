---
layout: post
title: "Solution to UTCTF 2019 - Jacobi's Chance Encryption"
author: capitol
category: ctf
---

##### Name:
Jacobi's Chance Encryption

##### Category:
crypto

##### Points:
750

#### Writeup

![red herrings](/images/red-herrings.png)

We got this challenge text and an implementation of a strange crypto system that
we needed to break:

Public Key 569581432115411077780908947843367646738369018797567841

Can you decrypt Jacobi's encryption?

def encrypt(m, pub_key):

```python
    bin_m = ''.join(format(ord(x), '08b') for x in m)
    n, y = pub_key

    def encrypt_bit(bit):
        x = randint(0, n)
        if bit == '1':
            return (y * pow(x, 2, n)) % n
        return pow(x, 2, n)

    return map(encrypt_bit, bin_m)
```

And also the [encrypted flag]({% link /assets/flag.enc %}).

Looking at the implementation it does some really strange things. It loops over every bit in the
plaintext and gets a large random number `x`. Then it checks if the bit is 1 or 0 and encodes
that information as either y * x<sup>2</sup> or x<sup>2</sup> in the congruence class of y.

There is also a public key involved that's just two primes multiplied together, but it's more
of a red herring.

This is actually a kind of neat algebra problem. We want to know if a number was
a square of itself before it got reduced by modulo `n` or not, and we know that `n` and the number
are coprime.

As with all math problems, someone has solved this in sage already. The name of the function is
`kronecker`, so all we had to do was to write a small sage program to reverse the crypto function.

```python
file = open("flag.enc", "r")
data = file.readline()

data = data.split(",")

pubkey = list(factor(569581432115411077780908947843367646738369018797567841))

i = 0
str = ""
sol = ""
for b in data:
    if b == "":
        continue

    if kronecker(int(b, 16), pubkey[1][0]) == 0:
        str += "1"
    else:
        str += "0"

    i += 1

    if i % 8 == 0:
        sol += chr(int(str, 2))
        str = ""

print(sol)
```

The flag was `utflag{did_u_pay_attention_in_number_theory}`.

