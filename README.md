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

- `make bootstrap`: first build and switch on a host where Nix is installed but this config has not installed system tools yet
- `make`: run the default `mise` task after `mise` is installed
- `mise run lint`: run `deadnix`, `nixpkgs-fmt`, and `statix` (same as pre-commit)
- `mise run check`: run lint + `nix flake check --all-systems`, then build the current host
- `mise run` (or `mise run default`): build and switch the current host (Darwin uses `darwin-rebuild switch`)

If `make` itself is missing on a fresh host, run the bootstrap target through Nix:
`nix --extra-experimental-features "nix-command flakes" run nixpkgs#gnumake -- bootstrap`

## Secrets

This repo stores secrets with `sops` + `age`.

- Each host that needs to decrypt secrets must have the shared SSH private key at:
  `~/.ssh/id_ed25519`
- Shells export `SOPS_AGE_SSH_PRIVATE_KEY_FILE=~/.ssh/id_ed25519` so `sops
  secrets/shayne.yaml` works without extra flags.
- Edit shell secrets with `sops secrets/shayne.yaml`
- Rebuild the encrypted font archive from a local plaintext font directory with:
  `tar -C /path/to/fonts -czf /tmp/custom-fonts.tar.gz . && cp /tmp/custom-fonts.tar.gz secrets/custom-fonts.tar.gz && sops encrypt -i --input-type binary secrets/custom-fonts.tar.gz`

## Pre-commit

Install hooks with:
`pre-commit install` and `pre-commit install --hook-type prepare-commit-msg`.
Note: `pre-commit install` only installs the default `pre-commit` hook; the
`prepare-commit-msg` hook must be installed explicitly.
You can run all hooks manually with `pre-commit run --all-files`.

## Current Systems

- `m5mbp` — Apple Silicon MacBook Pro running nix-darwin
- `macstudio` — Apple Silicon Mac Studio running nix-darwin

The flake still exports cross-platform packages and formatter outputs, but the active system configs in this repo are Darwin-only.
