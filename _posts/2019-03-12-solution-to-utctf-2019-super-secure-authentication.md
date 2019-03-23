---
layout: post
title: "Solution to UTCTF 2019 - Super Secure Authentication"
author: fR30n
category: ctf
---

##### name:
Super Secure Authentication

##### category:
reverse

##### points:
750

##### credits:
Big thanks to capitol and karltk for the help around the Java tools!


#### Writeup
The challenge consisted of the following set of Java (compiled) classes:
```text
Authenticator.class
jBaseZ85.class
Verifier0.class
Verifier1.class
Verifier2.class
Verifier3.class
Verifier4.class
Verifier5.class
Verifier6.class
Verifier7.class
```

The text description tells us to run: `java Authenticator [password]`, so that's our starting
point. After decompiling `Authenticator.class` in Ghidra we get the main and checkFlag methods:

```java
void main_java.lang.String[]_void(String[] param1)
{
  boolean bVar2;
  StringBuilder objectRef;
  String pSVar1;
  PrintStream[] objectRef_00;
  
  if (param1.length != (dword)0x1) {
    objectRef_00 = System.out;
    objectRef_00.println("usage: java Authenticator [password]");
    return;
  }
  pSVar1 = param1[0];
  bVar2 = Authenticator.checkFlag(pSVar1);
  if (bVar2 == false) {
    objectRef_00 = System.out;
    objectRef_00.println("Oops, try again!");
  }
  else {
    objectRef_00 = System.out;
    objectRef = new StringBuilder();
    objectRef = objectRef.append("You got it! The flag is: ");
    objectRef = objectRef.append(pSVar1);
    pSVar1 = objectRef.toString();
    objectRef_00.println(pSVar1);
  }
  return;
}
```


```java
boolean checkFlag_java.lang.String_boolean(String param1)
{
  String objectRef;
  boolean bVar3;
  int iVar1;
  char cVar2;
  StringTokenizer objectRef_00;
  int iVar4;
  StringTokenizer objectRef_01;
  
  objectRef = param1.substring(0,7);
  bVar3 = objectRef.equals("utflag{");
  if (bVar3 == false) {
    return false;
  }
  objectRef = param1;
  iVar1 = param1.length();
  cVar2 = objectRef.charAt(iVar1 + -1);
  if (cVar2 != '}') {
    return false;
  }
  objectRef_01 = new(StringTokenizer);
  iVar4 = 7;
  objectRef_00 = objectRef_01;
  iVar1 = param1.length();
  objectRef = param1.substring(iVar4,iVar1 + -1);
  objectRef_01.<init>(objectRef,"_");
  objectRef = objectRef_00.nextToken();
  bVar3 = Verifier0.verifyFlag(objectRef);
  if (bVar3 == false) {
    return false;
  }
  objectRef = objectRef_00.nextToken();
  bVar3 = Verifier1.verifyFlag(objectRef);
  if (bVar3 == false) {
    return false;
  }
  objectRef = objectRef_00.nextToken();
  bVar3 = Verifier2.verifyFlag(objectRef);
  if (bVar3 == false) {
    return false;
  }
  objectRef = objectRef_00.nextToken();
  bVar3 = Verifier3.verifyFlag(objectRef);
  if (bVar3 == false) {
    return false;
  }
  objectRef = objectRef_00.nextToken();
  bVar3 = Verifier4.verifyFlag(objectRef);
  if (bVar3 == false) {
    return false;
  }
  objectRef = objectRef_00.nextToken();
  bVar3 = Verifier5.verifyFlag(objectRef);
  if (bVar3 == false) {
    return false;
  }
  objectRef = objectRef_00.nextToken();
  bVar3 = Verifier6.verifyFlag(objectRef);
  if (bVar3 == false) {
    return false;
  }
  objectRef = objectRef_00.nextToken();
  bVar3 = Verifier7.verifyFlag(objectRef);
  if (bVar3 == false) {
    return false;
  }
  return true;
}
```

From the code above we understand that the flag is composed by 8 tokens and has the form `utflag{token0_token1_token2_token3_token4_token5_token6_token7}`, where each tokenX is validated by each VerifierX.class.
So we continue to decompile the first one (Verifier0) of these classes. The decompiled class looks gigantic, but from the code we could spot two important things.

(a) There is a static initializer, which allocates a big string and calls `jBaseZ85.decode` with it and this is stored in a static member of the class.
The code looks something like the following:

```java
void <clinit>_void(void)
{
  StringBuilder objectRef;
  String objectRef_00;
  byte[] pbVar1;
  
  objectRef = new StringBuilder();
  objectRef_00 = new String(<big_string_here>);
  ..
  more allocations of big strings
  ..
  objectRef = objectRef.append(objectRef_00);
  objectRef_00 = objectRef.toString();
  pbVar1 = jBaseZ85.decode(objectRef_00);
  Verifier0.arr = pbVar1;
  return;
```

(b) The `verifyFlag` method uses the bytes from above to define a new 
`Verifier0` class and then calls the `verifyFlag` method defined for that class. It looks like a basic way to obfuscate the real method.
```java
boolean verifyFlag_java.lang.String_boolean(String param1)
{
  Class[] ppCVar1;
  Object[] ppOVar2;
  Class objectRef;
  Method objectRef_00;
  Object objectRef_01;
  boolean bVar3;
  Verifier0 objectRef_02;
  
  objectRef_02 = new Verifier0();
  objectRef = objectRef_02.defineClass("Verifier0",Verifier0.arr,0,Verifier0.arr.length);
  ppCVar1 = new Class[1];
  ppCVar1[0] = String.class;
  objectRef_00 = objectRef.getMethod("verifyFlag",ppCVar1);
  ppOVar2 = new Object[1];
  ppOVar2[0] = param1;
  objectRef_01 = objectRef_00.invoke(null,ppOVar2);
  throwExceptionOp(objectRef_01);
  bVar3 = objectRef_01.booleanValue();
  return bVar3;
}
```

So from (a) and (b) we have an idea of what we need to do: in order to get to the last state of the `Verifier0` class we need to decode those strings with Z85, dump the class, and reverse the `verifyFlag` method.
To automate part of that job we wrote a simple Python 3 script that uses `javap` to dump the stored strings and `pyzmq` to decode the new verifier class. After playing a bit with the script we also realized that this obfuscation is done several times.

```python
#!python3
import os
import io
import sys

# install pyzmq with pip!
import zmq.utils.z85

def get_class_bytes_from_verifier(java_bytecode):
    bytes = ""
    lines = java_bytecode.split('\n')
    if len(lines) is 0:
        return ""

    for line in lines:
        str_index = line.find("String")
        if str_index > 0:
            java_str = line[str_index + len("String") :]
            java_str_len = len(java_str)

            if java_str_len > 200 or len(bytes) > 0:

                # complete with padding to match the size as it is expected in z85
                if java_str_len != 10001:
                    java_str += '0' * (10001 - java_str_len)

                print("adding line : {} {}".format(java_str[:10],java_str[-10:]))
                bytes += java_str.strip()

    return bytes.strip()

def dump_byte_code(classname, path):
    javap_ret = os.popen('cd {} && javap -cp . -c {} | grep ldc'.format(path, classname)).read()
    byte_code = get_class_bytes_from_verifier(javap_ret)

    if len(byte_code) is 0:
        print("Finished!")
        return False

    assert(len(byte_code) % 5 == 0)
    print ("Found byte code! dumping...\n")
    with io.open('work/dump.class'.format(classname), 'wb') as f:
        decoded_byte_code = zmq.utils.z85.decode(byte_code)
        f.write(decoded_byte_code)
    return True

def extract_class(classname):
    # cleanup previous job
    os.system("mkdir -p work")
    os.system("rm -fr work")
    os.system("mkdir -p work")

    # dump from the initial directory
    dump_byte_code(classname, ".")

    while dump_byte_code("*", "./work/"):
        pass

if len(sys.argv) > 1:
    extract_class(sys.argv[1])

```

After running the script with the name of the class we want to dump we get the deobfuscated version of the Verifier0 class!
```bash
$ python3 dump.py Verifier0

-- some output we added to see progress --

$ file work/dump.class 
work/dump.class: compiled Java class data, version 52.0 (Java 1.8)
```

Now is only a matter of dumping and reversing each class.
We wrote another Python 3 script with the logic of each token verifier:

```python
#!python3
import string
import hashlib

# calculates the hashCode() of a string like Java does:
def java_hashcode(strval):
    h = 0
    if len(strval):
        for i in strval:
            h = 31 * h + ord(i)
    return h

print("flag: utflag{", end="")
verifier0 = [50, 48, 45, 50, 42, 39, 54, 49]
for i in verifier0:
    print(chr(i ^ 66), end="")
print("_", end="")

verifier1 = [ 0x73, 0x75, 0x6f, 0x69, 0x78, 0x6e, 0x61 ]
# iterate in reverse!
for i in verifier1[::-1]:
    print(chr(i), end="")
print("_", end="")

verifier2 = [ 0x2f01e2, 0x2f7641, 0x331939, 0x3401f7, 0x32a4da, 0x3147bd, 0x3647d2, 0x3147bd, 0x3401f7, 0x338d98 ]
for hashcode in verifier2:
    for i in string.ascii_lowercase:
        if java_hashcode(i + 'foo') == hashcode:
            print(i, end="")
print("_", end="")


verifier3 = "obwaohfcbwq"
for i in verifier3:
    x = ((ord(i) - 0x55) % 0x1a) + 0x61
    c = chr(x)
    print(c, end="")

print("_", end="")


verifier4 = [
        0xd30,
        0xcdf,
        0xe3e,
        0xc73,
        0xd9c,
        0xcc4 ]

for i in verifier4:
    x = int((i - 0x238) / 0x1b)
    print(chr(x), end ="")
print("_", end="")


verifier5 = "8FA14CDD754F91CC6554C9E71929CCE7865C0C0B4AB0E063E5CAA3387C1A8741FBADE9E36A3F36D3D676C1B808451DD7FBADE9E36A3F36D3D676C1B808451DD7"
verifier5 = verifier5.lower()

def verify_flag_verifier5(flag):
    flaghash = ""
    for i in flag:
        m = hashlib.md5()
        m.update(i.encode()) #   md.update((byte)flagbytes[i]);
        tmp = ""  #   ss = new StringBuilder();
        tmp += flaghash #   ss.append(flag_hash);
        # print(len(flaghash))
        dg_bytes = m.digest() #   digest_bytes = md.digest();
        dg_str = dg_bytes.hex() #   digest_str = DatatypeConverter.printHexBinary(digest_bytes);
        tmp += dg_str  #   ss.apend(digest_str)

        flaghash = tmp #   flag_hash = ss.toString();
    return flaghash == verifier5

for i in string.ascii_lowercase:
    for j in string.ascii_lowercase:
        for k in string.ascii_lowercase:
            for l in string.ascii_lowercase:
                    if verify_flag_verifier5(i + j + k +l):
                        print((i + j + k + l), end="")

print("_", end="")


verifier6 = "1B480158E1F30E0B6CEE7813E9ECF094BD6B3745"
verifier6 = bytes.fromhex(verifier6)

def verify_flag_verifier6(flag):
    m = hashlib.sha1()
    m.update(flag.encode())
    dg = m.digest()
    return  dg == verifier6

for i in string.ascii_lowercase:
    for j in string.ascii_lowercase:
        for k in string.ascii_lowercase:
            for l in string.ascii_lowercase:
                if verify_flag_verifier6(i + j + k + l):
                    print(i + j + k + l, end="")
print("_", end="")

verifier7 = "goodbye"
print(verifier7, end="")

print("}")
```

flag was:
`utflag{prophets_anxious_demolition_animatronic_herald_fizz_stop_goodbye}`

