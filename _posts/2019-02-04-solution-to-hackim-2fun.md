---
layout: post
title: "Solution to Hackim CTF challenge 2fun"
author: capitol
category: ctf
---

![jordan](/images/jordan.jpg)

##### Name:
2fun

##### Category:
crypto

##### Points:
500 (variable)

#### Writeup

We got this challenge text:

```text
24 bit key space is brute forceable so how about 48 bit key space? 
flag is hackim19{decrypted flag}

16 bit plaintext: b'0467a52afa8f15cfb8f0ea40365a6692' 
flag: b'04b34e5af4a1f5260f6043b8b9abb4f8'
```

And a block crypto implementation:

```python
from hashlib import md5
from binascii import hexlify, unhexlify
from secret import key, flag
BLOCK_LENGTH = 16
KEY_LENGTH = 3
ROUND_COUNT = 16

sbox = [210, 213, 115, 178, 122, 4, 94, 164, 199, 230, 237, 248, 54,
        217, 156, 202, 212, 177, 132, 36, 245, 31, 163, 49, 68, 107,
        91, 251, 134, 242, 59, 46, 37, 124, 185, 25, 41, 184, 221,
        63, 10, 42, 28, 104, 56, 155, 43, 250, 161, 22, 92, 81,
        201, 229, 183, 214, 208, 66, 128, 162, 172, 147, 1, 74, 15,
        151, 227, 247, 114, 47, 53, 203, 170, 228, 226, 239, 44, 119,
        123, 67, 11, 175, 240, 13, 52, 255, 143, 88, 219, 188, 99,
        82, 158, 14, 241, 78, 33, 108, 198, 85, 72, 192, 236, 129,
        131, 220, 96, 71, 98, 75, 127, 3, 120, 243, 109, 23, 48,
        97, 234, 187, 244, 12, 139, 18, 101, 126, 38, 216, 90, 125,
        106, 24, 235, 207, 186, 190, 84, 171, 113, 232, 2, 105, 200,
        70, 137, 152, 165, 19, 166, 154, 112, 142, 180, 167, 57, 153,
        174, 8, 146, 194, 26, 150, 206, 141, 39, 60, 102, 9, 65,
        176, 79, 61, 62, 110, 111, 30, 218, 197, 140, 168, 196, 83,
        223, 144, 55, 58, 157, 173, 133, 191, 145, 27, 103, 40, 246,
        169, 73, 179, 160, 253, 225, 51, 32, 224, 29, 34, 77, 117,
        100, 233, 181, 76, 21, 5, 149, 204, 182, 138, 211, 16, 231,
        0, 238, 254, 252, 6, 195, 89, 69, 136, 87, 209, 118, 222,
        20, 249, 64, 130, 35, 86, 116, 193, 7, 121, 135, 189, 215,
        50, 148, 159, 93, 80, 45, 17, 205, 95]
p = [3, 9, 0, 1, 8, 7, 15, 2, 5, 6, 13, 10, 4, 12, 11, 14]


def xor(a, b):
    return bytearray(map(lambda s: s[0] ^ s[1], zip(a, b)))


def fun(key, pt):
    assert len(pt) == BLOCK_LENGTH
    assert len(key) == KEY_LENGTH
    key = bytearray(unhexlify(md5(key).hexdigest()))
    ct = bytearray(pt)
    for _ in range(ROUND_COUNT):
        ct = xor(ct, key)
        for i in range(BLOCK_LENGTH):
            ct[i] = sbox[ct[i]]
        nct = bytearray(BLOCK_LENGTH)
        for i in range(BLOCK_LENGTH):
            nct[i] = ct[p[i]]
        ct = nct
    return hexlify(ct)


def toofun(key, pt):
    assert len(key) == 2 * KEY_LENGTH
    key1 = key[:KEY_LENGTH]
    key2 = key[KEY_LENGTH:]

    ct1 = unhexlify(fun(key1, pt))
    ct2 = fun(key2, ct1)

    return ct2

print("16 bit plaintext: %s" % toofun(key, b"16 bit plaintext"))
print("flag: %s" % toofun(key, flag))
```

Lets examine the crypto more in detail, starting with the `funtoo` function. It takes a key,
verifies that it is 6 characters long, splits in in two and runs the fun function twice, 
with the output of the first round as input to the second. These two rounds turned out to be
the weakness of the system, and we could mount a `meet in the middle` attack with the known
plaintext and ciphertext that we go in the challenge text.

The `fun` function is where all the real crypto work is carried out, it operates on blocks of
size 16, with an key that is expanded to 16 bytes with the help of MD5. It does three steps
in 16 rounds:

1. xor the key into the encryption work memory.
2. apply a sbox, this is just a lookup table that replaces values with other values.
3. shuffle the bytes around.

At first we thought we maybe could recover the key that was used in the attack by reversing
the fun function, or doing some gauss elimination if we represent the crypto as an equation
system but that wasn't possible. Since the key is xored into the work memory at each round we
can't reverse the function to return the key from the plaintext and ciphertext. And doing
gauss elimination isn't possible, because the sbox makes the functions non-linear.

But we did manage to write a version of the fun function that takes the key and the ciphertext
and returns the plaintext, and this we used to perform the meet in the middle attack.

The total number of combinations of the key is 256<sup>3</sup> * 256<sup>3</sup> = 
256<sup>6</sup> = 281474976710656, which is a too large number to be able to brute 
force. But we can divide this into 2 parts thanks to the intermediate step. We can
create a dictionary consisting of all the possible values for the first part of the key
together with what encrypted value it computes to. And then compute the reverse of the
second part together with the ciphertext for all keys and compare the result with the values
in the hash, when we have a match we will know both the first part and the second part
of the key.

This reduces the complexity from 256<sup>6</sup> to 2 * 256<sup>3</sup>.
 
Below is roughly how the solution code looked, we wrote an inverse version of the fun method
and called it with the ciphertext and all combinations of the key and saved the output to a
file.

And we did the equivalent thing with the normal fun method and the plaintext and saved that
to another file.
```python
sbox_inv = [221,  62, 140, 111,   5, 213, 225, 242, 157, 167,  40,  80, 121,  83,  93,  64, 
            219, 253, 123, 147, 234, 212,  49, 115, 131,  35, 160, 191,  42, 204, 175,  21,
            202,  96, 205, 238,  19,  32, 126, 164, 193,  36,  41,  46,  76, 252,  31,  69, 
            116,  23, 247, 201,  84,  70,  12, 184,  44, 154, 185,  30, 165, 171, 172,  39, 
            236, 168,  57,  79,  24, 228, 143, 107, 100, 196,  63, 109, 211, 206,  95, 170, 
            251,  51,  91, 181, 136,  99, 239, 230,  87, 227, 128,  26,  50, 250,   6, 255, 
            106, 117, 108,  90, 208, 124, 166, 192,  43, 141, 130,  25,  97, 114, 173, 174, 
            150, 138,  68,   2, 240, 207, 232,  77, 112, 243,   4,  78,  33, 129, 125, 110, 
             58, 103, 237, 104,  18, 188,  28, 244, 229, 144, 217, 122, 178, 163, 151,  86, 
            183, 190, 158,  61, 248, 214, 161,  65, 145, 155, 149,  45,  14, 186,  92, 249, 
            198,  48,  59,  22,   7, 146, 148, 153, 179, 195,  72, 137,  60, 187, 156,  81, 
            169,  17,   3, 197, 152, 210, 216,  54,  37,  34, 134, 119,  89, 245, 135, 189, 
            101, 241, 159, 226, 180, 177,  98,   8, 142,  52,  15,  71, 215, 254, 162, 133, 
             56, 231,   0, 218,  16,   1,  55, 246, 127,  13, 176,  88, 105,  38, 233, 182,
            203, 200,  74,  66,  73,  53,   9, 220, 139, 209, 118, 132, 102,  10, 222,  75,
             82,  94,  29, 113, 120,  20, 194,  67,  11, 235,  47,  27, 224, 199, 223,  85]

p_inv = [2, 3, 7, 0, 12, 8, 9, 5, 4, 1, 11, 14, 13, 10, 15, 6]

def fun_rev(key, hash):
    hash = unhexlify(hash)
    ct = bytearray(hash)
    key = bytearray(unhexlify(md5(key).hexdigest()))
    for _ in range(ROUND_COUNT):
      nct = bytearray(BLOCK_LENGTH)
      for i in range(BLOCK_LENGTH):
        nct[i] = ct[p_inv[i]]
      ct = nct

      for i in range(BLOCK_LENGTH):
        ct[i] = sbox_inv[ct[i]]

      ct = xor(ct, key)
    return hexlify(ct)

for k1 in range(256):
  for k2 in range(256):
    for k3 in range(256):
      key = bytearray(3)
      key[0] = k1
      key[1] = k2
      key[2] = k3
      print(hexlify(key) + " = " + fun(key, b"16 bit plaintext"))
      print(hexlify(key) + " = " + fun_rev(key, b'0467a52afa8f15cfb8f0ea40365a6692'))

```

When we had the two files with all the hashes, we could use some shell magic and the excellent
tool `comm` to find the matching hash.

That gave us the key, which was `a277b5c1bc8b` in hex and we could write a reverse function
of the funtoo method and get the flag:

```python
def toofun_rev(key, hash):
  assert len(key) == 2 * KEY_LENGTH
  key1 = key[:KEY_LENGTH]
  key2 = key[KEY_LENGTH:]

  ct1 = fun_rev(key2, hash)
  ct2 = fun_rev(key1, ct1)

  return ct2

key = unhexlify("a277b5c1bc8b")
print("flag: %s" % unhexlify(toofun_rev(key, b'04b34e5af4a1f5260f6043b8b9abb4f8')))
```

flag was: hackim19{1337_1n_m1ddl38f}
