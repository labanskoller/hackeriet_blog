---
layout: post
title: "Release of Ripasso version 0.2.0"
author: capitol
category: infrastructure
---
![ripasso-cursive](/images/ripasso-cursive.png)

I have just released the first version of ripasso, a password manager that lets you
control the level of risk that you expose your passwords too.

Ripasso aims to be filesystem compatible with [pass](https://www.passwordstore.org/), and
this enables you to use the same password store across all your devices.

Passwords in ripasso are encrypted with one or more public pgp keys and optionally added
to a git repository.

This gives you a lot of flexibility on how securely you want to manage the passwords. 
Here are some examples use cases:
 * You can encrypt the passwords with all the people on your team's gpg keys and have a common passwords in a
  shared git repository. 
 * You can store your passwords locally without using git, that way there's no history
  of your old passwords to leak.
 * You can use your password store on your phone (if you use git as a backend), but have a separate gpg
  key for your computer and your phone. That way if you lose your phone, your gpg identity 
  isn't lost.
  
Ripasso is written in rust and so far packaged in nix and arch.

### Install instructions

#### Arch linux

`yay install ripasso-git`

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
 * David Plassman - Arch packager

Also a big thanks to everyone who contributed with bug reports and patches.
