# nix-darwin Configurations

This repository houses my macOS (nix-darwin) configurations and related Nix tooling. The system loader lives in
`lib/loadSystems.nix` and `lib/mkSystem.nix`, with per-host configs under `systems/` and user config under
`home-manager/`.

## Structure

- `systems/base/`: shared Darwin defaults
- `systems/<hostname>/`: per-host overrides (current host: `m5mbp`)
- `home-manager/<user>/`: shared user config and per-host overlays
- `modules/`: reusable Nix modules
- `overlays/` + `pkgs/`: custom overlays/packages
- `nix/` + `nixpkgs.nix`: source pinning helpers

## Common Commands

- `mise run lint`: run `deadnix`, `nixpkgs-fmt`, and `statix` (same as pre-commit)
- `mise run check`: run lint + `nix flake check --all-systems`, then build the current host
- `mise run` (or `mise run default`): build and switch the current host (Darwin uses `darwin-rebuild switch`)

## Pre-commit

Install hooks with:
`pre-commit install` and `pre-commit install --hook-type prepare-commit-msg`.
Note: `pre-commit install` only installs the default `pre-commit` hook; the
`prepare-commit-msg` hook must be installed explicitly.
You can run all hooks manually with `pre-commit run --all-files`.

## Current Systems

- `m5mbp` — Apple Silicon MacBook Pro running nix-darwin

The flake still exports cross-platform packages and formatter outputs, but the active system configs in this repo are Darwin-only.
