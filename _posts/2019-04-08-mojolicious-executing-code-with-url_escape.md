---
layout: post
title: "Mojolicious: Executing code with url_escape()"
author: sgo
category: security
---
![failraptor](/images/failraptor.png)

Let's look at the 
[url_escape](https://mojolicious.org/perldoc/Mojo/Util#url_escape) function in
the [Mojolicious](https://mojolicious.org/) web framework for Perl 5, and how it
can be used to evaluate code trough the second argument of the function.

## TLDR;
```perl
use Mojo::Util qw(url_escape);
url_escape('some-stuff', '\w](?{die()})|[a'); # Dies!
```

## The [`url_escape`](https://mojolicious.org/perldoc/Mojo/Util#url_escape) function

This function is a part of the very useful [Mojo::Util](https://mojolicious.org/perldoc/Mojo/Util) library.

It accepts a list of two arguments:
1. A string to escape `$str`
2. An optional pattern that determines what characters to escape `$pattern`

Some usage examples:

```perl
url_escape('foo/bar.baz'); # Returns "foo%2Fbar.baz"
url_escape('foo/bar.baz', '/.'); # Returns "foo%2Fbar%2Ebaz"
```


This is the implementation in [Mojolicious v8.13](https://github.com/mojolicious/mojo/blob/v8.13/lib/Mojo/Util.pm#L339..L354):

```perl
sub url_escape {
  my ($str, $pattern) = @_;

  if ($pattern) {
    unless (exists $PATTERN{$pattern}) {
      (my $quoted = $pattern) =~ s!([/\$\[])!\\$1!g;
      $PATTERN{$pattern}
        = eval "sub { \$_[0] =~ s/([$quoted])/sprintf '%%%02X', ord \$1/ge }"
        or croak $@;
    }
    $PATTERN{$pattern}->($str);
  }
  else { $str =~ s/([^A-Za-z0-9\-._~])/sprintf '%%%02X', ord $1/ge }

  return $str;
}
```


When `url_escape` is called with a `$pattern` it hasn't seen before, it will
generate, [string eval](https://perldoc.perl.org/functions/eval.html#String-eval) and cache a function to handle this specific pattern.
Subsequent calls with the same `$pattern` will [re-use](https://github.com/mojolicious/mojo/commit/a7cdf6fb2c60c28ac4ab9ffad0e528bb23b0f7b8) the generated code.

So, an input parameter to the function is interpolated into a string which is
eval'ed... Interesting! Let's try to inject some code :D

## Quoting

```perl
(my $quoted = $pattern) =~ s!([/\$\[])!\\$1!g;
```

The `$pattern` input value is quoted with the expression `s!([/\$\[])!\\$1!g;`
and stored in `$quoted` before it's interpolated into the string of code to be
evaled, preventing us from ending the pattern part of the string substitution.
Damn... So close!


## Code Subpattern

It doesn't appear that we can (easily) break out of the substitution expression,
so let's try something inside the expression instead, like [(?{
code })](https://perldoc.perl.org/perlre.html#%28%3f%7b-code-%7d%29)


> [code subpattern](https://perldoc.perl.org/perlglossary.html#code-subpattern):
> A regular expression subpattern whose real purpose is to execute some Perl
> code—for example, the (?{...}) and (??{...}) subpatterns.

Very nice, but this can be a bit dangerous, as the
[perlre](https://perldoc.perl.org/perlre.html#%28%3f%7b-code-%7d%29) doc points
out:

> [..] for reasons of security, use re 'eval' must be in scope. This is to stop
> user-supplied patterns containing code snippets from being executable. In
> situations where you need to enable this with use re 'eval' , you should also
> have taint checking enabled. Better yet, use the carefully constrained
> evaluation within a Safe compartment. [..]

Normally, adding `(?{ code })` to a pattern trough string interpolation will
result in a fatal error, unless `use re 'eval'` is set. But since the
code we want to tamper with is string evaled, these restrictions do not
apply. 

## Crafting the `$pattern` argument

This is what we want to execute:
```perl
die()
```

Let's wrap `die()` in a code subpattern and add some stuff to both sides of it to make it compile, and match.

```perl
'\w](?{die()})|[a'
```

Passing this `$pattern` to `url_escape` makes it generate code that looks like this:

```perl
sub { $_[0] =~ s/([\w](?{die()})|[a])/sprintf '%%%02X', ord $1/ge }
```

So we're left with:

```perl
url_escape('some-stuff', '\w](?{die()})|[a'); # Dies!
```

## Is this a vulnerability? 

The Mojolicious team reviewed a
[PoC](/assets/bcb314da8be677049c40d8a4601fb5c1c133ad3637ad9a4bb5caf83b39603a70-mojo-url-escape.pl)
before this post, and concluded that it was not a security vulnerability.

Imho, this could allow for some vulnerability chaining. But the behaviour is not
exploitable unless function is used incorrectly.

How to create vulnerable code:

1. The most obvious way to create a vulnerability is to expose the second
   `$pattern` argument of `url_escape` directly to user input. Game
   Over.
   
2. A more subtle way, is by having a another function return a list with
   elements that an attacker can control as arguments to `url_escape`.
   
   ```perl
   use Mojo::Util qw(url_escape);
   
   sub good { return 'some-stuff' }; # returns 1 string
   sub evil { return ('some-stuff', '\w](?{die()})|[a') }; # returns 2 strings
   
   url_escape( good() ); 
   url_escape( evil() ); # Dies!
   ```
   
   Variations of this belong to a [class of
   vulnerabilities](https://blog.gerv.net/2014/10/new-class-of-vulnerability-in-perl-web-applications/)
   in Perl web applications that are generally well known.


## Takeaways

Regular expressions in Perl are very powerful, functions that return lists can
be scary, and library functions can have hidden features.



