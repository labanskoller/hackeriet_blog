---
layout: post
title: Better password hashing in PostgreSQL with SCRAM-SHA-256
author: capitol
category: postgresql
---

![elephant-hashing](/images/elephant-hashing.jpg)

Many connections to PostgreSQL servers are not protected by TLS and for those it's
important that the password isn't sent as clear text over the network.

PostgreSQL have supported MD5 hashing with salt for a long time, and as we all know
MD5 is considered very broken by todays standards. Not only is MD5 weak, the login sequence
only contains 32 bits of new entropy per connection, so if you can listen to
multiple connection attempts then you can easily perform a replay attack on the md5
packet.

Lets look on how a MD5 based login sequence looks.

#### Client sends a startup message

| length | protocol | param name | param value |
|--------|----------|------------|-------------|
| int32  | int32    | str        | str         |
| 88     | 3        | user       | test        |

First element is just a standard length, the second the protocol version that the
client want to use, PostgreSQL has been on version 3 since version 7.4. One
interesting thing about the protocol field is that it's reused when trying to start
a TLS connection, the value 80877103 means that a TLS connection will be initiated
instead.

After that a number of parameter name/value pairs are sent, the most important
for this topic is the user one, that sets the username.

The packet looks like this as a hex dump:
```hexdump
0000   00 00 00 58 00 03 00 00 75 73 65 72 00 74 65 73
0010   74 00 64 61 74 61 62 61 73 65 00 74 65 73 74 00
0020   61 70 70 6c 69 63 61 74 69 6f 6e 5f 6e 61 6d 65
0030   00 6a 61 76 61 5f 73 71 6c 32 5f 63 6c 69 65 6e
0040   74 00 63 6c 69 65 6e 74 5f 65 6e 63 6f 64 69 6e
0050   67 00 55 54 46 38 00 00
```

#### Server responds with an Authentication request

| type marker| length | type   | type specific data      |
|------------|--------|--------|-------------------------|
|byte        | int32  | int32  | various, int32 with md5 |
|'R'         | 12     | 5      | 0xfce5c980              |

What the server responds with is controlled by the pg_hba.conf file, in this case
it has a line that looks like this that instructs it to use MD5:

```text
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             ::1/128                 md5
```

The type specific data in case of MD5 is a salt value that should be hashed together
with the password.

The packet looks like this as a hex dump:
```hexdump
0000   52 00 00 00 0c 00 00 00 05 fc e5 c9 80
```

#### Client sends a Password message

| type marker| length | value                               |
|------------|--------|-------------------------------------|
|byte        | int32  | str                                 |
|'p'         | 40     | md5374c5f834de33f6297af8f17aa050229 |

The hashing method in use here is `"md5" + md5(md5(user + password) + salt)`.

The packet looks like this as a hex dump:
```hexdump
0000   70 00 00 00 28 6d 64 35 33 37 34 63 35 66 38 33
0010   34 64 65 33 33 66 36 32 39 37 61 66 38 66 31 37
0020   61 61 30 35 30 32 32 39 00
```

## Improved security with SCRAM-SHA-256

In order to improve the situation the hashing system SCRAM-SHA-256 was introduced, 
as defined in [rfc 5802](https://tools.ietf.org/html/rfc5802) and 
[rfc 7677](https://tools.ietf.org/html/rfc7677).

It's a more complicated protocol, but it's significantly more secure.

Lets go over the packet exchange of here also.

#### Client sends a startup message

Same as above, not repeated.

#### Server responds with an Authentication request

| type marker| length | type   | type specific data      |
|------------|--------|--------|-------------------------|
|byte        | int32  | int32  | various, str with SASL  |
|'R'         | 23     | 10     | SCRAM-SHA-25            |

These authentication system uses the SASL packets, types SASL (10), SASL_CONTINUE 
(11) and SASL_FINAL (12).

The type specific data is a list of mechanism which the client can choose one of,
in this case it only has one field.

The packet looks like this as a hex dump:
```hexdump
0000   52 00 00 00 17 00 00 00 0a 53 43 52 41 4d 2d 53
0010   48 41 2d 32 35 36 00 00
```

#### client responds with the first password message

| type marker| length | mechanism     | length | parameter string                 |
|------------|--------|---------------|--------|----------------------------------|
|byte        | int32  | str           | int32  | str                              |
|'p'         | 54     | SCRAM-SHA-256 | 32     | n,,n=,r=/z+giZiTxAH7r8sNAeHr7cvp |

When sending a password packet back as part of a SASL exchange it as a few more 
fields. Most notable is the parameter string, which content if determined by
[rfc 5802](https://tools.ietf.org/html/rfc5802).

Notable is that this message also contains a username in the attribute `n`,
but the server doesn't use that so we leave that blank.

The attribute `r` is the client specified nounce, in other words the entropy that
the client supplies.

The packet looks like this as a hex dump:
```hexdump
0000   70 00 00 00 36 53 43 52 41 4d 2d 53 48 41 2d 32
0010   35 36 00 00 00 00 20 6e 2c 2c 6e 3d 2c 72 3d 2f
0020   7a 2b 67 69 5a 69 54 78 41 48 37 72 38 73 4e 41
0030   65 48 72 37 63 76 70
```

#### Server sends a SASL CONTINUE message

| type marker| length | type   | type specific data                                                                   |
|------------|--------|--------|--------------------------------------------------------------------------------------|
|byte        | int32  | int32  | various, str with SASL CONTINUE                                                      |
|'R'         | 92     | 11     | r=/z+giZiTxAH7r8sNAeHr7cvpqV3uo7G/bJBIJO3pjVM7t3ng,s=4UV68bIkC8f9/X8xH7aPhg==,i=4096 |

The server asks us to perform 4096 iterations of the hashing in attribute `i`,
the rfc specifies that the complete exchange without network lag should take at 
least 0.1 seconds. So this value will likely increase with future versions of 
PostgreSQL.

In attribute `r` the server have taken the entropy that the client supplied and
added it't own.

`s` is a server generated salt for the user.

The packet looks like this as a hex dump:
```hexdump
0000   52 00 00 00 5c 00 00 00 0b 72 3d 2f 7a 2b 67 69
0010   5a 69 54 78 41 48 37 72 38 73 4e 41 65 48 72 37
0020   63 76 70 71 56 33 75 6f 37 47 2f 62 4a 42 49 4a
0030   4f 33 70 6a 56 4d 37 74 33 6e 67 2c 73 3d 34 55
0040   56 36 38 62 49 6b 43 38 66 39 2f 58 38 78 48 37
0050   61 50 68 67 3d 3d 2c 69 3d 34 30 39 36
```

#### Client performs the hashing and returns another password message

| type marker| length | parameter string                                                                                         |
|------------|--------|----------------------------------------------------------------------------------------------------------|
|byte        | int32  | str                                                                                                      |
|'p'         | 108    | c=biws,r=/z+giZiTxAH7r8sNAeHr7cvpqV3uo7G/bJBIJO3pjVM7t3ng,p=AFpSYH/K/8bux1mRPUwxTe8lBuIPEyhi/7UFPQpSr4A= |

Here the client have done the actual work of hashing the password and sending
the proof of that in attribute `p`.

`c` is channel binding data. This isn't used by the 
[pgAdba](https://github.com/pgjdbc/pgadba) connection code yet, so
we will come back to this in the future.

The packet looks like this as a hex dump:
```hexdump
0000   70 00 00 00 6c 63 3d 62 69 77 73 2c 72 3d 2f 7a
0010   2b 67 69 5a 69 54 78 41 48 37 72 38 73 4e 41 65
0020   48 72 37 63 76 70 71 56 33 75 6f 37 47 2f 62 4a
0030   42 49 4a 4f 33 70 6a 56 4d 37 74 33 6e 67 2c 70
0040   3d 41 46 70 53 59 48 2f 4b 2f 38 62 75 78 31 6d
0050   52 50 55 77 78 54 65 38 6c 42 75 49 50 45 79 68
0060   69 2f 37 55 46 50 51 70 53 72 34 41 3d
```

#### Server end the authentication exchange with a SASL FINISH message

| type marker| length | type   | type specific data                             |
|------------|--------|--------|------------------------------------------------|
|byte        | int32  | int32  | various, str with SASL FINISH                  |
|'R'         | 54     | 12     | v=d1PXa8TKFPZrR3MBRjLy3+J6yxrfw/zzp8YT9exV7s8= |

The server sends a server signature so that the client can verify the server in
attribute `v`.

The packet looks like this as a hex dump:
```hexdump
0000   52 00 00 00 36 00 00 00 0c 76 3d 64 31 50 58 61
0010   38 54 4b 46 50 5a 72 52 33 4d 42 52 6a 4c 79 33
0020   2b 4a 36 79 78 72 66 77 2f 7a 7a 70 38 59 54 39
0030   65 78 56 37 73 38 3d
```
