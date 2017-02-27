---
layout: post
title: "CTF: Eating a nice RSA buffet"
author: capitol
category: ctf
---
![buffet](/images/smorgastarta.png)

##### name:
RSA Buffet

##### category:
crypto

##### points:
150

#### Writeup
During the 2017 Boston Key Party we were presented with a very nice buffet of RSA key to crack.

There where 10 different keys and five of them decrypted five other cipher texts. Any three of
those five could be combined with the help of [secret sharing](https://github.com/blockstack/secret-sharing) to get the flag.

We used four different attacks on RSA in order to retrieve five of the keys.

##### Brute force to find key 2

One of the primes for key number two was really small, only 2758599203, we
could have just used brute force to calculate it, but instead we found it in factordb: http://factordb.com/index.php?id=1100000000906574033

##### Greatest common divisor to find both key 0 and 6

Finding if to numbers have a common divisor is extremely efficient, it's done with one of
the oldest known algorithms, the Euclidean algorithm.

Comparing all the keys with each other takes no time at all:

```java
    private static void findKey0and6(BigInteger[] keys) {
        for(int i = 0; i < keys.length; i++) {
            for(int j = 0; j < keys.length; j++) {
                if(i == j)
                    continue;

                BigInteger gcd = keys[i].gcd(keys[j]);
                if(gcd.compareTo(BigInteger.ONE) > 0)
                    System.out.println("gcd " + i + ":" + j +" = " + gcd);
            }
        }
    }
```

That gave us that there was an reused prime between key 0 and 6.


##### Fermat's Factorization Method to find key 1

If the two primes p and q are clustered close to \sqrt{N}, then we can use the fermat
 factorization method to find them.
 
This is the implementation that we used:

```java
public class Fermat {

    public static BigInteger factor(BigInteger n) {
        // Fermat's Factorization Method
        BigInteger A = BigMath.sqrt(n);
        BigInteger Bsq = A.multiply(A).subtract(n);
        BigInteger B = BigMath.sqrt(Bsq);
        BigInteger AminusB = A.subtract(B);

        // c is a chosen bound which controls when Fermat stops
        BigInteger c = new BigInteger("30");
        BigInteger AminusB_prev = A.subtract(B).add(c);
        BigInteger result = null;

        while (!BigMath.sqrt(Bsq).pow(2).equals(Bsq) && AminusB_prev.subtract(AminusB).compareTo(c) > -1) {
            A = A.add(BigInteger.ONE);
            Bsq = A.multiply(A).subtract(n);

            B = BigMath.sqrt(Bsq);
            AminusB_prev = AminusB;
            AminusB = A.subtract(B);
        }

        if (BigMath.sqrt(Bsq).pow(2).equals(Bsq)) {
            result = AminusB;
        }

        // Trial Division
        else {
            boolean solved = false;
            BigInteger p = AminusB.add(BigMath.TWO);

            if (p.remainder(BigMath.TWO).intValue() == 0) {
                p = p.add(BigInteger.ONE);
            }
            while (!solved) {
                p = p.subtract(BigMath.TWO);
                if (n.remainder(p).equals(BigInteger.ZERO)) {
                    solved = true;
                }
            }

            result = p;
        }

        return result;
    }
}
```

##### Wiener attack to solve key 3

Key 3 had a really big e, that was a good hint that we could use the wiener attack.

RSA isn't an algorithm that's very well suited to run on very constrained systems.
This has lead people to try to speed it up, and one thing that they tried was to have
a small d and a large e. Michael J. Wiener was the man who developed this attack.

The implementation that we used was this one:

```java
public class WienerAttack {

    //Four ArrayList for finding proper n/d which later on for guessing k/dg
    private List<BigInteger> q = new ArrayList<>();
    private List<Fraction> r = new ArrayList<>();
    private List<BigInteger> n = new ArrayList<>();
    private List<BigInteger> d = new ArrayList<>();

    private BigInteger e;
    private BigInteger N;

    private Fraction kDdg = new Fraction(BigInteger.ZERO, BigInteger.ONE); // k/dg, D means "divide"

    //Constructor for the case using files as inputs for generating e and N
    public WienerAttack(BigInteger e, BigInteger N) throws IOException {
        this.e = e;
        this.N = N;
    }

    public BigInteger attack() {
        int i = 0;
        BigInteger temp1;

        //This loop keeps going unless the privateKey is calculated or no privateKey is generated
        //When no privateKey is generated, temp1 == -1
        while ((temp1 = step(i)) == null) {
            i++;
        }

        return temp1;
    }

    //Steps follow the paper called "Cryptanalysis of Short RSA Secret Exponents by Michael J. Wiener"
    private BigInteger step(int iteration) {
        if (iteration == 0) {
            //initialization for iteration 0
            Fraction ini = new Fraction(e, N);
            q.add(ini.floor());
            r.add(ini.remainder());
            n.add(q.get(0));
            d.add(BigInteger.ONE);
        } else if (iteration == 1) {
            //iteration 1
            Fraction temp2 = new Fraction(r.get(0).denominator, r.get(0).numerator);
            q.add(temp2.floor());
            r.add(temp2.remainder());
            n.add((q.get(0).multiply(q.get(1))).add(BigInteger.ONE));
            d.add(q.get(1));
        } else {
            if (r.get(iteration - 1).numerator.equals(BigInteger.ZERO)) {
                return BigInteger.ONE.negate(); //Finite continued fraction. and no proper privateKey could be generated. Return -1
            }

            //go on calculating n and d for iteration i by using formulas stating on the paper
            Fraction temp3 = new Fraction(r.get(iteration - 1).denominator, r.get(iteration - 1).numerator);
            q.add(temp3.floor());
            r.add(temp3.remainder());
            n.add((q.get(iteration).multiply(n.get(iteration - 1)).add(n.get(iteration - 2))));
            d.add((q.get(iteration).multiply(d.get(iteration - 1)).add(d.get(iteration - 2))));
        }

        //if iteration is even, assign <q0, q1, q2,...,qi+1> to kDdg
        if (iteration % 2 == 0) {
            if (iteration == 0) {
                kDdg = new Fraction(q.get(0).add(BigInteger.ONE), BigInteger.ONE);
            } else {
                kDdg = new Fraction((q.get(iteration).add(BigInteger.ONE)).multiply(n.get(iteration - 1)).add(n.get(iteration - 2)), (q.get(iteration).add(BigInteger.ONE)).multiply(d.get(iteration - 1)).add(d.get(iteration - 2)));
            }
        }

        //if iteration is odd, assign <q0, q1, q2,...,qi> to kDdg
        else {
            kDdg = new Fraction(n.get(iteration), d.get(iteration));
        }

        BigInteger edg = this.e.multiply(kDdg.denominator); //get edg from e * dg

        //dividing edg by k yields a quotient of (p-1)(q-1) and a remainder of g
        BigInteger fy = (new Fraction(this.e, kDdg)).floor();
        BigInteger g = edg.mod(kDdg.numerator);

        //get (p+q)/2 and check whether (p+q)/2 is integer or not
        BigDecimal pAqD2 = (new BigDecimal(this.N.subtract(fy))).add(BigDecimal.ONE).divide(new BigDecimal("2"));
        if (!pAqD2.remainder(BigDecimal.ONE).equals(BigDecimal.ZERO))
            return null;

        //get [(p-q)/2]^2 and check [(p-q)/2]^2 is a perfect square or not
        BigInteger pMqD2s = pAqD2.toBigInteger().pow(2).subtract(N);
        BigInteger pMqD2 = BigMath.sqrt(pMqD2s);
        if (!pMqD2.pow(2).equals(pMqD2s))
            return null;

        //get private key d from edg/eg
        return edg.divide(e.multiply(g));

    }
}

public class Fraction {
    public BigInteger numerator;
    public BigInteger denominator;

    //Constructor of the Fraction class which initializes the numerator and denominator
    public Fraction(BigInteger paramBigInteger1, BigInteger paramBigInteger2) {
        //find out the gcd of paramBigInteger1 and paramBigInteger2 which is used for ensuring the numerator and denominator are relatively prime
        BigInteger localBigInteger = paramBigInteger1.gcd(paramBigInteger2);

        this.numerator = paramBigInteger1.divide(localBigInteger);
        this.denominator = paramBigInteger2.divide(localBigInteger);
    }

    //Constructor for the case when calculating (paramBigInteger1 /(paramFraction.numerator / paramFraction.denominator))
    public Fraction(BigInteger paramBigInteger, Fraction paramFraction) {
        this.numerator = paramBigInteger.multiply(paramFraction.denominator);
        this.denominator = paramFraction.numerator;
        BigInteger localBigInteger = this.numerator.gcd(this.denominator);
        this.numerator = this.numerator.divide(localBigInteger);
        this.denominator = this.denominator.divide(localBigInteger);
    }

    //Calculate the quotient of this Fraction
    public BigInteger floor() {
        BigDecimal localBigDecimal1 = new BigDecimal(this.numerator);
        BigDecimal localBigDecimal2 = new BigDecimal(this.denominator);
        return localBigDecimal1.divide(localBigDecimal2, 3).toBigInteger();
    }

    //Calculate the remainder of this Fraction and assign the result to form a new Fraction
    public Fraction remainder() {
        BigInteger floor = this.floor();
        BigInteger numeratorNew = this.numerator.subtract(floor.multiply(this.denominator));
        BigInteger denominatorNew = this.denominator;
        return new Fraction(numeratorNew, denominatorNew);
    }
}
```

These attacks combined gave us enough plaintext so that we could recover that flag, which was FLAG{ndQzjRpnSP60NgWET6jX}

[Image credit](http://www.mynewsdesk.com/se/haga-taartcompani-och-bageri-ab/images/smoergaastaarta-haga-taartcompani-bageri-290078)