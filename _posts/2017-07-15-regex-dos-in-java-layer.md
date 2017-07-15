---
layout: post
title: "Performance problems in the java layer, Catastrophic Backtracking"
author: capitol
category: performance
---
![regex](/images/RegexNFA.png)

We discovered that we had a couple of requests that took extreme amounts of time and
cpu power on our servers.

After dumping the thread stacks, we found out that the culprit was this regex:
```regexp
"((\\S*[\\s\\.]+)+)([0-9]+)[\\s\\.]*([A-z]([\\s\\.]|$))?(.*)"
```

When encountering strings that contains a large number of spaces, for example:
```java
"SUNDEVEIEN                               A"
```
it uses very large amounts of cpu time to try to match. 

After some testing, we determined that the execution time scaled in the order of O(2^n).
As seen in this table.

|spaces|milliseconds|
|:-|-----:|
|27| 13915|
|28| 26509|
|29| 50512|
|30|106652|
|31|207174|
|32|409100|
|33|824363|

The problem class is called catastrophic backtracking, and many regex engines are
of the backtracking kind, also the standard one in java.

The problematic regex can be simplified to this in order to better highlight the 
problem:

```regexp
"(\\S*[\\s\\.]+)+[0-9]+"
```

What happens here is that the regex engine have multiple paths for matching the spaces
it encounters, it can either add it to a the last space in the previous group or it
can start a new group with it. When it encounters the ending A in the string it's 
obvious for the human eye that the regex will never match, but the engine doesn't know
that without trying all combinations of groups of spaces, so it will backtrack in
the string and try another way, which doesn't work either, until all combinations
are exhausted.

There is a number of ways to fix this problem, the most radical might be to replace
the regex engine with one that guarantees linear execution, for example [RE2J](https://github.com/google/re2j).

Or you could avoid nesting quantifiers (the pluses and stars), but this requires
that you can restructure the problem.

Another way would be to rewrite the regex so that there isn't a choice between
different ways to match the string, for example by changing the first * into a +.
