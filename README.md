# NixOS System Configurations

This repository contains my NixOS system configurations. It started as a fork of [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config/) and much of the structure remains.

There exist several separate machine configs:

- devvm - x86_64-linux kvm/qemu vm
- m1nix - aarch64-linux [running natively](https://github.com/tpwrules/nixos-m1/) on a M1 MacBook Pro 
- m2vm - aarch64-linux vm running under VMWare Fusion Tech Preview (_No longer in use_)
- m2air - aarch64-darwin running natively on a Macbook Air M2
- lima - aarch64-linux vm running under [Lima](https://github.com/lima-vm/lima)
- wsl - x86_64-linux Windows WSL vm
- pinix - aarch64-linux RPi 4

