---
layout: post
title: "Release of Ripasso version 0.3.0"
author: capitol
category: infrastructure
---
![ripasso-cursive](/images/ripasso-cursive.png)

We have just released version 0.3.0 of Ripasso, a password manager that lets you
control the level of risk that you expose your passwords to.

## New Features

#### Support for signing Git commits, if it's configured in Git's config

If you set the Git configuration values `commit.gpgsign` and `user.signingkey`, then Ripasso
will respect them when creating Git commits and signing those.

#### Display who touched a password last

If the password store is backed by a Git repository, then Ripasso will read and display who changed
a password last.

#### Support for initializing a Git repo in the quick start wizard

If you start Ripasso without a password store directory you will get a guide that helps you get
set up. That guide now also gives you the opportunity to initialize a Git repository.

#### Added a status bar, and a menu

We reworked to information at the bottom of the screen, moved the shortcuts into a menu and added
a status bar that displays what's happening in the application.

## Bugs fixed

#### Ctrl-W doesn't delete last word in search bar

Made Ctrl-W behave as in the shell, so that you can delete last typed word with it.

#### Fixed performance problem if the Git repo was large

Ripasso initialized the Git repository once for every operation that it did, which was very slow.
Ownership of the Git repository object have now been moved so that it will only be initialized once.

#### Fixed problem with passwords that contained a . character

Newly created passwords that contained a . character weren't accessible without a restart.

### Install instructions

#### Arch Linux

Arch now has two packages, `ripasso-git` that tracks the development branch and `ripasso-cursive`
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
