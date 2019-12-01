---
layout: post
title: "Release of Ripasso version 0.3.0"
author: capitol
category: infrastructure
---
![ripasso-cursive](/images/ripasso-cursive.png)

We have just released version 0.3.0 of ripasso, a password manager that lets you
control the level of risk that you expose your passwords too.

## New Features

#### Support for signing git commit's, if it's configured in gits config

If you set the git configuration values `commit.gpgsign` and `user.signingkey`, then ripasso
will respect them when creating git commit's and sign those.

#### Display who touched a password last

If the password store is backed by a git repository, then ripasso will read and display who changed
a password last.

#### Support for initializing a git repo in the quick start wizard

If you start ripasso without a password store directory you will get a guide that helps you get
set up, that guide now also gives you the opportunity to initialize a git repository.

#### Added a status bar, and a menu

We reworked to information at the bottom of the screen, moved the shortcuts into a menu and added
a status bar that displays what's happening in the application.

## Bugs fixed

#### ctrl-w doesn't delete last word in search bar

Made ctrl-w behave as in the shell, so that you can delete last typed word with it.

#### fixed performance problem if the git repo was large

Ripasso initialized the git repository once for every operation that it did, which was very slow.
Ownership of the git repository object have now been moved so that it will only be initialized once.

#### fixed problem with passwords that contained a . character

Newly created passwords that contained a . character wasn't accessible without a restart.

### Install instructions

#### Arch linux

Arch now have two packages, `ripasso-git` that tracks the development branch and `ripasso-cursive`
that contains the stable version.

`yay install ripasso-git`

or

`yay install ripasso-cursive`

#### Nix

`nix-env -iA nixpkgs.ripasso-cursive`

#### General

```bash
git clone git@github.com:cortex/ripasso.git
cd ripasso
cargo build -p ripasso-cursive
```

### Credits

 * Joakim Lundborg - developer
 * Alexander Kjäll - developer
 * Stig Palmquist - NixOS packager
 * Tae Sandoval - NixOS macos packager
 * David Plassman - Arch packager

Also a big thanks to everyone who contributed with bug reports and patches.
