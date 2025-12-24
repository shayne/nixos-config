# NixOS & nix-darwin Configurations

This repository houses my NixOS and macOS (nix-darwin) configurations. The system loader lives in
`lib/loadSystems.nix` and `lib/mkSystem.nix`, with per-host configs under `systems/` and user config under
`home-manager/`.

## Structure

- `systems/base/`: shared defaults for Linux and Darwin
- `systems/<hostname>/`: per-host overrides (current host: `m4mbp`)
- `home-manager/<user>/`: shared user config and per-host overlays
- `modules/`: reusable Nix modules
- `overlays/` + `pkgs/`: custom overlays/packages

## Common Commands

- `make lint`: run `deadnix`, `nixpkgs-fmt`, and `statix` (same as pre-commit)
- `make check`: run lint + `nix flake check --all-systems`, then build the current host
- `make` or `make switch`: build and switch the current host (Darwin uses `darwin-rebuild switch`)
- `make test`: NixOS test build (Linux only)

## Current Systems

- `m4mbp` — Apple Silicon MacBook Pro running nix-darwin

The repo remains multi-system capable (aarch64/x86_64, Linux/Darwin) for future hosts.
