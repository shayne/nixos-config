# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix`/`flake.lock`: flake entrypoint and pinned inputs.
- `systems/`: host configs. Common defaults live in `systems/base/`; per-host overrides live in `systems/<hostname>/` (e.g., `systems/m4mbp/`).
- `home-manager/`: user profiles (global defaults in `home-manager/<user>/default.nix`, per-host overrides in `home-manager/<user>/<hostname>/`).
- `modules/`: reusable Nix modules (shells, editors, services).
- `overlays/` + `pkgs/`: custom packages and overlay wiring.
- `nix/` and `nixpkgs.nix`: source pinning helpers.
- `iso/`: ISO build scripts.

## Build, Test, and Development Commands
- `make` or `make switch`: builds and switches the system for the current host (Darwin uses `darwin-rebuild switch`). Only run `make` when explicitly asked.
- `make lint`: runs `deadnix`, `nixpkgs-fmt`, and `statix` (same checks as the pre-commit hook).
- `make check`: runs `make lint`, then `nix flake check --all-systems`, and builds the current host system for validation.
- `make test`: runs `nixos-rebuild test --flake .` (Linux only).
- `make iso/nixos.iso`: builds the ISO image (see `iso/build.sh`).

## Coding Style & Naming Conventions
- Nix files use 2‑space indentation and compact attribute sets.
- Host names map directly to folder names (e.g., `systems/m4mbp`, `home-manager/shayne/m4mbp`).
- Prefer `pkgs.stdenv.hostPlatform.system` over deprecated `pkgs.system` or `system` alias.
- Formatting: use `nix fmt` (flake formatter is configured via nix-formatter-pack).

## Testing Guidelines
- No standalone test suite; rely on `make check` for evaluation/build sanity.
- Validate host changes by running `make` on the target host.

## Commit & Pull Request Guidelines
- Commit messages follow a short “scope: summary” style (examples: `systems/m4mbp: enable nix-index program`, `flake: update all dependencies`).
- Use `Revert "..."` when rolling back a change.
- PRs should include: a short summary, affected hosts, and the exact command(s) run (e.g., `make check`, `make`).

## Security & Configuration Tips
- Treat `*.enc.nix` files as sensitive (e.g., `home-manager/shayne/environment.enc.nix`, `systems/**/.*.enc.nix`). Avoid editing without the proper secrets workflow.
