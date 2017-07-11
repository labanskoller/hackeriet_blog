---
layout: post
title: "Finding side channel attacks in jasypt 1.8"
author: capitol
category: security
---
![stopwatch](/images/Time-Lapse-Stopwatch.jpg)

While doing an audit of some code for a project, I read through the code that
verifies the password hashes.

It looked something like this:

```java
    BasicPasswordEncryptor bpe = new BasicPasswordEncryptor();
    return bpe.checkPassword(clearText, storedPasswordHash);
```

Where the BasicPasswordEncryptor comes from the org.jasypt package.

After digging through some abstraction layers I found this in the class
StandardByteDigester in jasypt.

```java
    byte[] encryptedMessage = this.digest(message, salt);
    return Arrays.equals(encryptedMessage, digest);
```

This was a red flag, the Arrays.equals implementation is optimized for speed. This
means that it's implemented so that it returns at the first difference in the two 
arrays, in other words that the loop will take longer the more of the arrays that is equal.
 
It's a tiny amount of time, but it's possible to measure, specially if you are
on the same machine or in the same data center, something that's not so unrealistic
when everything is hosted in one of the big cloud providers.

This specific leak compares two hashes with each other, and not two plain text
passwords, this means that it leaks bytes from the hash and not from the password.
This isn't as bad, but it's still not good.

If you want to do a dictionary attack on a user, in order guess what passwords that
user is using, then if you manage to leak the first byte of the hash and there isn't
a salt in the algorithm then you can precompile the hash on the attacker side, see
if the hashes compare and only send those that match to the server.

We can do a simple example on how to implement this locally:

```java
    public static void main(String[] args) {
        String correctPassword = "correct";
        String wrongPassword = "wrong";

        BasicPasswordEncryptor bpe = new BasicPasswordEncryptor();
        String correctHash = bpe.encryptPassword(correctPassword);
        String wrongHash = bpe.encryptPassword(wrongPassword);

        int iterations = 10000;

        // warm up
        long[] warmUp1 = getLongs(correctPassword, bpe, correctHash, iterations);
        long[] warmUp2 = getLongs(correctPassword, bpe, wrongHash, iterations);

        long[] correctTimes = getLongs(correctPassword, bpe, correctHash, iterations);

        long[] wrongTimes = getLongs(correctPassword, bpe, wrongHash, iterations);

        Arrays.sort(correctTimes);
        Arrays.sort(wrongTimes);

        System.out.println("correct = " + median(correctTimes));
        System.out.println("wrong   = " + median(wrongTimes));
    }

    private static long[] getLongs(String correctPassword, BasicPasswordEncryptor bpe, String correctHash, int iterations) {
        long[] times = new long[iterations];
        for(int i = 0; i < iterations; i++) {
            long start = System.nanoTime();
            bpe.checkPassword(correctPassword, correctHash);
            long end = System.nanoTime();
            times[i] = end - start;
        }
        return times;
    }

    private static double median(long[] m) {
        int middle = m.length/2;
        if (m.length%2 == 1) {
            return m[middle];
        } else {
            return (m[middle-1] + m[middle]) / 2.0;
        }
    }
```

Running this on my laptop, with frequency scaling turned of, I get an average
time difference of 17 nano seconds between checking a correct password and an
incorrect.

In 2009 some scientists managed to measure timing attacks down to 100 ns over a
gigabit network and speculated that 50 ns was possible with more sampling, in
[this paper](http://www.cs.rice.edu/~dwallach/pub/crosby-timing2009.pdf).

With 10 gigabit being common in modern server hardware it's not unreasonable
to think that it would be possible to execute such an attack against an unguarded
target.

After some more digging, it turns out that this vulnerability have been fixed in
version 1.9.2 of jasypt, it has been replaced with this code:

```java
    private static boolean digestsAreEqual(byte[] a, byte[] b) {
        if(a != null && b != null) {
            int aLen = a.length;
            if(b.length != aLen) {
                return false;
            } else {
                int match = 0;

                for(int i = 0; i < aLen; ++i) {
                    match |= a[i] ^ b[i];
                }

                return match == 0;
            }
        } else {
            return false;
        }
    }
```

What happens here is that the bitvise xor operator is used instead, so if there
is any difference in the two byte arrays, then the match value will end up with 1's
in some of it bit positions, and the == 0 check will fail.

There is no early escape from the loop, as it compares hashes the size is guaranteed
to be equal between the two parameters.

I strongly advise everyone who uses jasypt to upgrade to version 1.9.2.

The maintainers of jasypt was contacted in advance of the publication but were
unresponsive. The debian security team was also contacted, as jasypt is packaged by
debian. Mitre assigned it [CVE-2014-9970](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-9970).

##### Update

The author of the code contacted us on twitter and pointed out that this bug was
described in the [changelog of version 1.9.2](http://jasypt.org/changelogs/jasypt/ChangeLog.txt).
