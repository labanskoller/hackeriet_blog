---
layout: post
title: "Release of Ripasso version 0.4.0"
author: capitol
category: infrastructure
---
![ripasso-cursive](/images/ripasso-cursive-0.4.0.png)

After two months of development effort, we are proud to present
ripasso version 0.4.0.

## New Features

#### Support for localization

Ripasso's ncurses based application now have support for localization and have been translated into:

 * French
 * Italian
 * Norwegian bokmål
 * Norwegian nynorsk
 * Swedish


#### Display a padlock icon if the git commit a password comes from have been signed by a valid key

If the git commit that a password came from have been signed by a gpg key that's in your keyring,
then ripasso will display a padlock icon ( 🔒 ) to symbolize this.

If there is a minor problem with the key, then an open padlock icon ( 🔓 ) will be displayed.

And if there was a major problem, then a stop icon ( ⛔ ) will be displayed.

#### Package for fedora created

Ripasso have now been packaged for fedora by [Artem Polishchuk](https://github.com/tim77)

#### Major startup time improvement

In the previous versions, ripasso did the equivalence of a git blame on every password file
in the repository, this was fine for small repositories, but for large ones it didn't work
at all. The startup cost was on the order of O(n<sup>2</sup>) where n was the number of passwords.

This have been replaced by walking through the history once and populating the metadata
for each file as we see them in the history.

#### Support for environmental variable `PASSWORD_STORE_SIGNING_KEY`

If you specify one or more 40 character gpg key ids in this variable, this ripasso will
verify that the `.gpg-id` file in the password directory has been signed by one of those keys.

The signature is a detached gpg signature located in the `.gpg-id.sig` file.

## Bugs Fixed

#### Don't print passwords onscreen as they are generated

The generate button now prints stars instead of the actual password when pressed.

#### Prevent directory traversal

Before it was possible to create files outside the password store directory, by
writing `..` in the password path.

## Credits

 * Joakim Lundborg - Developer
 * Alexander Kjäll - Developer
 * Artem Polishchuk - Fedora packager
 * Silje Enge Kristensen - Norwegian bokmål translation
 * Eivind Syvertsen - Norwegian nynorsk translation
 * Enrico Razzetti - Italian translation
 * Camille Victor Prunier - French translation

Also a big thanks to everyone who contributed with bug reports and patches.
