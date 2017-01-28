---
layout: post
title: "CTF: Don't try RSA at home"
author: capitol
category: ctf
---
![channel](/images/rsa.png)

##### name:
Sudan - RSA is for everyone

##### category:
crypto

##### points:
100

#### Writeup
Our friends over at xil.se have written some challenges for a ctf named smash the stack at https://ctf.anti-network.org/

The challenge "RSA is for everyone" required you to send and retrieve messages with RSA. Fortunately it is really easy to implement RSA yourself in java (don't try this at home kids).

The class for getting the RSA primitives looks like this (some code shamelessly stolen from Stack Overflow, like all real programmers do):

```java
public class RSA {
    private final BigInteger p;
    private final BigInteger q;
    private final BigInteger n;
    private final BigInteger d;
    private final BigInteger e;

    public RSA() {
        int SIZE = 512;

        /* Step 1: Select two large prime numbers. Say p and q. */
        p = new BigInteger(SIZE, 15, new Random());
        q = new BigInteger(SIZE, 15, new Random());

        /* Step 2: Calculate n = p.q */
        n = p.multiply(q);

        /* Step 3: Calculate ø(n) = (p - 1).(q - 1) */
        BigInteger phiN = p.subtract(BigInteger.valueOf(1));
        phiN = phiN.multiply(q.subtract(BigInteger.valueOf(1)));

        BigInteger eTmp;
        /* Step 4: Find e such that gcd(e, ø(n)) = 1 ; 1 < e < ø(n) */
        do {
            eTmp = new BigInteger(2 * SIZE, new Random());
        } while ((eTmp.compareTo(phiN) != 1) || (eTmp.gcd(phiN).compareTo(BigInteger.valueOf(1)) != 0));
        e = eTmp;

        /* Step 5: Calculate d such that e.d = 1 (mod ø(n)) */
        d = e.modInverse(phiN);
    }

    public BigInteger getP() {
        return p;
    }

    public BigInteger getQ() {
        return q;
    }

    public BigInteger getN() {
        return n;
    }

    public BigInteger getD() {
        return d;
    }

    public BigInteger getE() {
        return e;
    }
}
		
```

With that in hand it was easy to respond to the questions in the challenge. 

#### Solution
```java
public class App {

    public static void main(String[] args) throws IOException {
        Socket attackTarget = new Socket("ctf1.xil.se", 4300);
        PrintWriter out = new PrintWriter(attackTarget.getOutputStream(), true);
        BufferedReader in = new BufferedReader(new InputStreamReader(attackTarget.getInputStream()));

        BigInteger n;
        BigInteger e;
        RSA rsa = new RSA();

        String in1;
        in.readLine();
        in.readLine();
        in.readLine();
        in.readLine();
        in.readLine();
        out.println("1");
        in.readLine();
        in.readLine();
        in1 = in.readLine();
        n = new BigInteger(in1.substring(2));
        in1 = in.readLine();
        e = new BigInteger(in1.substring(2));
        in.readLine();
        in.readLine();
        in.readLine();
        in.readLine();
        in.readLine();
        in.readLine();
        out.println("2");
        in.readLine();
        out.println(new BigInteger("RSA is for everyone".getBytes(StandardCharsets.ISO_8859_1)).modPow(e, n).toString(16));
        in.readLine();
        in.readLine();
        in.readLine();
        in.readLine();
        out.println(rsa.getN().toString(10));
        in.readLine();
        out.println(rsa.getE().toString(10));
        in.readLine();
        in1 = in.readLine();

        System.out.println("flag: " + new String(new BigInteger(in1, 16).modPow(rsa.getD(), rsa.getN()).toByteArray()));
    }
}
```
