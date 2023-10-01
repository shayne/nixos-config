# NixOS System Configurations

This repository contains my NixOS system configurations.  As of 2023-09-09 it is undergoing a major overhaul.

Check back later for more information.

For now take a look at the [systems](./systems/) and [home-manager](./home-manager/) directories. A lot of the magic
happens in [lib/loadSystems.nix](./lib/loadSystems.nix) and [lib/mkSystem.nix](./lib/mkSystem.nix).

## Current systems

- `devvm` - an x86_64 headless VM for development
- `m1nix` - a 13" M1 MacBook Pro running a NixOS desktop natively ([nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon))
- `m2nix` - a 13" M2 MacBook Air running a NixOS desktop natively ([nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon))
- `m2air` - a 13" M2 MacBook Air running [nix-darwin](https://github.com/LnL7/nix-darwin)
- `wsl` - a WSL2 VM running NixOS ([nixos-wsl](https://github.com/nix-community/NixOS-WSL))
