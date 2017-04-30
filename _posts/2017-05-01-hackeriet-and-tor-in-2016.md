---
layout: post
title: "TOR at hackeriet in 2016"
author: capitol
category: report
---
![onions](/images/red_onions.jpg)

We at hackeriet started our tor node one year ago, with help from the
[NUUG foundation](http://www.nuugfoundation.no/no/).

The node is still happily churning out encrypted data to different parts of the 
internet, as can be seen on out [network graphs](https://munin.hackeriet.no/munin/hackeriet.no/tor-node001.hackeriet.no/if_eth0.html).

####Our setup
#####Hardware
We started the project with a dedicated 1U rack machine, a HP ProLiant DL160 G5 Server,
it had four cores and 20 gig of ram.

This turned out to be way more iron than what we needed in order to power to node, so
in september the machine was converted to a virtual machine in our proxmox cluster.

#####Software
The machine was installed with Debian 8 and setup to automatically install security
updates. The tor software was installed with the help of debian packages.

The machine have both ipv4 and ipv6 addresses, and we accept connections to tor from
both.

The munin monitoring software ran on a separate machine.

####What happened

We had a hardware failure on the machine that hosted the munin graphs, and as those
were complimentary we didn't have backups of them.

We also had a series of 5 power outages in the end of summer, most likely due
to faulty hardware in one machine. As the problem was hard to reproduce and intermittent
we never managed to conclude that the hardware we suspected was the culprit, but the
problems stopped occurring when it was removed.

We opted into becoming a [fallback directory mirror](https://trac.torproject.org/projects/tor/wiki/doc/FallbackDirectoryMirrors)
as our node is quite stable.

Right now the latest stable version of tor have just been [released](https://blog.torproject.org/blog/tor-0306-released-new-series-stable)
and we are in the process of upgrading to it.

####What we learned

There has been a lot of drama in the tor project during 2016, one of the
main activists resigned due to committing acts of [sexual harassment](https://blog.torproject.org/blog/statement).

There has also been multiple different attempts as FUD, mainly due to the fact
that a lot of the funding for the development of the project comes from the american military.

There were also an attack on the tor network performed by FBI And Carnegie Mellon University
in 2014, more information on the [circumstances](http://qntra.net/2016/02/silk-road-2-0-case-confirms-fbi-and-cmu-tor-attack-collaboration/)
was published and combed over by the community.

####What will happen now

We will continue to host our entry node, as tor is still one of the best projects
for ensuring freedom from some of those that want to monitor your network traffic.
