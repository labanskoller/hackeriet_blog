---
layout: post
title: "Packaging an executable Python script nicely in Nix for NixOS"
author: sshow
category: nixos
---

> This is a [cross-post from blog.stigok.com](https://blog.stigok.com/2019/11/05/packing-python-script-binary-nicely-in-nixos.html)

I was making [a Python script][ruterstop] as a backend to an
[Arduino project I did][ruterstop-arduino]. As usual I got the idea of upping
the ante in my hobby project, this time by packaging and running that backend on NixOS.

This was a great way for me to learn more about NixOS, but also a way
to discover the difficulties of getting into it from scratch. I want to share
the *.nix* files I ended up with, and how I incorporated it into my NixOS config,
in the hope that I can speed things up for someone else getting to know Nix.

I will not go deep into how the language Nix works, but rather comment a tiny
bit on what I've done that I feel is noteworthy for the new citizens of NixOS.

## Building a custom Python package in NixOS

### Python project

[My Python project][ruterstop] consists of just a few files, of which the below
are the only ones that matter for the sake of this post.

```
├── tests
│   ├── test_data.json
│   └── test_ruterstop.py
├── requirements.txt
├── ruterstop.py
└── setup.py
```

The *setup.py* file is a small file that leans on the Python 3 built-in library
`distuils`, which is used to define an installable Python package.
Most importantly, it defines what scripts that should be added to the PATH, i.e.
executable scripts.

```python
# setup.py
from distutils.core import setup

setup(
    name='ruterstop',
    version='0.0.1',
    scripts=['ruterstop.py',],
)
```

This file will let you "install" the package/script by running `python setup.py install`, which
is also how the Nix function `python37Packages.buildPythonPackage` builds Python packages by default.

Since the script will be installed as an executable, I have
to define a suitable hashbang at the top of *ruterstop.py*:

```
#!/usr/bin/env python3
```

I will not be locking down my python library dependencies to specific versions
right now, but rather just pull in the (latest) versions from the Nix package
repository. The contents of my *requirements.txt* are:

```
bottle
requests
```

You will see these being defined explicitly in the Nix function `buildPythonPackage`
later on. They will not be installed using `pip`.

Before continuing, you should verify that running `python setup.py install` works
as intended. Maybe you have to run `pip install -r requirements.txt` on your development
system first.

### package.nix

You can start out in a new directory wherever you'd like.

Let's start out with the *default.nix* file. This file will describe the package itself,
where and how to get its sources, what dependencies to inject and how to actually build it.

```nix
# Below, we can supply defaults for the function arguments to make the script
# runnable with `nix-build` without having to supply arguments manually.
# Also, this lets me build with Python 3.7 by default, but makes it easy
# to change the python version for customised builds (e.g. testing).
{ nixpkgs ? import <nixpkgs> {}, pythonPkgs ? nixpkgs.pkgs.python37Packages }:

let
  # This takes all Nix packages into this scope
  inherit (nixpkgs) pkgs;
  # This takes all Python packages from the selected version into this scope.
  inherit pythonPkgs;

  # Inject dependencies into the build function
  f = { buildPythonPackage, bottle, requests }:
    buildPythonPackage rec {
      pname = "ruterstop";
      version = "0.0.1";

      # If you have your sources locally, you can specify a path
      #src = /home/stigok/src/ruterstop

      # Pull source from a Git server. Optionally select a specific `ref` (e.g. branch),
      # or `rev` revision hash.
      src = builtins.fetchGit {
        url = "git://github.com/stigok/ruterstop.git";
        ref = "master";
        #rev = "a9a4cd60e609ed3471b4b8fac8958d009053260d";
      };

      # Specify runtime dependencies for the package
      propagatedBuildInputs = [ bottle requests ];

      # If no `checkPhase` is specified, `python setup.py test` is executed
      # by default as long as `doCheck` is true (the default).
      # I want to run my tests in a different way:
      checkPhase = ''
        python -m unittest tests/*.py
      '';

      # Meta information for the package
      meta = {
        description = ''
          Realtime stop info for public transport in Oslo, using the EnTur JourneyPlanner API
        '';
      };
    };

  drv = pythonPkgs.callPackage f {};
in
  if pkgs.lib.inNixShell then drv.env else drv
```

- You can see if your package file compiles with `nix-instantiate --eval default.nix`
- You can build it and look at the resulting package with `nix-build default.nix`.
  A symlink `results` will be created in your working directory.

I want to run my service on boot with systemd. Next section takes on defining that service file.

### service.nix

Create this file right next to *default.nix*

```nix
{ config, lib, pkgs, ... }:

let
        # The package itself. It resolves to the package installation directory.
        ruterstop = pkgs.callPackage ./default.nix {};

        # An object containing user configuration (in /etc/nixos/configuration.nix)
        cfg = config.services.ruterstop;

        # Build a command line argument if user chose direction option
        directionArg = if cfg.direction == ""
                          then ""
                          else "--direction=${cfg.direction} ";
in {
    # Create the main option to toggle the service state
    options.services.ruterstop.enable = lib.mkEnableOption "ruterstop";

    # The following are the options we enable the user to configure for this
    # package.
    # These options can be defined or overriden from the system configuration
    # file at /etc/nixos/configuration.nix
    # The active configuration parameters are available to us through the `cfg`
    # expression.

    options.services.ruterstop.host = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        example = "127.0.0.1";
    };
    options.services.ruterstop.port = lib.mkOption {
        type = lib.types.int;
        default = 4000;
    };
    options.services.ruterstop.stop-id = lib.mkOption {
        type = lib.types.str;
        example = "6013";
    };
    options.services.ruterstop.direction = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "inbound";
    };
    options.services.ruterstop.direction = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "inbound";
    };
    options.services.ruterstop.extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [""];
        example = ["--debug"];
    };

    # Everything that should be done when/if the service is enabled
    config = lib.mkIf cfg.enable {
        # Open selected port in the firewall.
        # We can reference the port that the user configured.
        networking.firewall.allowedTCPPorts = [ cfg.port ];

        # Describe the systemd service file
        systemd.services.ruterstop = {
            description = "Et program som viser sanntidsinformasjon for stoppesteder i Oslo og Akershus.";
            environment = {
                PYTHONUNBUFFERED = "1";
            };

            # Wait not only for network configuration, but for it to be online.
            # The functionality of this target is dependent on the system's
            # network manager.
            # Replace the below targets with network.target if you're unsure.
            after = [ "network-online.target" ];
            wantedBy = [ "network-online.target" ];

            # Many of the security options defined here are described
            # in the systemd.exec(5) manual page
            # The main point is to give it as few privileges as possible.
            # This service should only need to talk HTTP on a high numbered port
            # -- not much more.
            serviceConfig = {
                DynamicUser = "true";
                PrivateDevices = "true";
                ProtectKernelTunables = "true";
                ProtectKernelModules = "true";
                ProtectControlGroups = "true";
                RestrictAddressFamilies = "AF_INET AF_INET6";
                LockPersonality = "true";
                RestrictRealtime = "true";
                SystemCallFilter = "@system-service @network-io @signal";
                SystemCallErrorNumber = "EPERM";
                # See how we can reference the installation path of the package,
                # along with all configured options.
                # The package expression `ruterstop` expands to the root
                # installation path.
                ExecStart = "${ruterstop}/bin/ruterstop.py --server --host ${cfg.host} --port ${toString cfg.port} --stop-id ${cfg.stop-id} ${directionArg}${lib.concatStringsSep " " cfg.extraArgs}";
                Restart = "always";
                RestartSec = "5";
            };
        };
    };
}
```

### Adding the package to the system

Now the service can be registered in the system configuration.
Since the package itself is defined by the service file, it's not necessary
to import *default.nix*.

Open */etc/nixos/configuration.nix* and import the *service.nix* file. Somewhere up at the top is the `imports` section. Add the path to the service file there.

```nix
imports =
  [
    ./hardware-configuration.nix
    /path/to/your/ruterstop/service.nix # <--
  ];
```

Then, further down the file, where appropriate for your taste, enable the service and service options.

```nix
services.ruterstop.enable = true;
services.ruterstop.stop-id = "6013";
services.ruterstop.direction = "outbound";
services.ruterstop.extraArgs = ["--debug"];
```

Now, try to rebuild the system and switch to the new configuration immediately by using the `switch` argument.

```
# nixos-rebuild switch
```

If everything went right, that should have started the service and enabled it to start on boot.
Check the service log to see if it runs alright.

```terminal
# journalctl -u ruterstop.service
```

That should be it! Comments are very welcome!

## References
- <https://nixos.org/nixpkgs/manual/#python>

[ruterstop]: https://github.com/stigok/ruterstop
[ruterstop-arduino]: https://github.com/stigok/ruterstop/tree/master/examples/arduino-esp8266-feather-oled
