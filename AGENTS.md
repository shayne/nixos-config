# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix`/`flake.lock`: flake entrypoint and pinned inputs.
- `systems/`: host configs. Common defaults live in `systems/base/`; per-host overrides live in `systems/<hostname>/` (e.g., `systems/m5mbp/`).
- `home-manager/`: user profiles (global defaults in `home-manager/<user>/default.nix`, per-host overrides in `home-manager/<user>/<hostname>/`).
- `modules/`: reusable Nix modules (shells, editors, services).
- `overlays/` + `pkgs/`: custom packages and overlay wiring.
- `nix/` and `nixpkgs.nix`: source pinning helpers.
- `iso/`: ISO build scripts.

## Darwin / Homebrew Conventions
- Darwin hosts use `systems/<hostname>/darwin-configuration.nix`; shared Darwin defaults live in `systems/base/darwin-configuration.nix`.
- Manage Homebrew declaratively through nix-darwin/nix-homebrew, not with imperative `brew install`.
- Use `homebrew.brews` for CLI formulae, `homebrew.casks` for GUI apps, `homebrew.masApps` for Mac App Store apps, and `homebrew.taps` for extra tap repos needed by tap-qualified packages.
- Prefer host-scoped edits for host-specific Darwin packages unless the user explicitly asks for a shared/base change.
- For small Darwin package changes, prefer targeted verification with `nix eval --json .#darwinConfigurations.<host>.config.homebrew.brews` or `nix eval --json .#darwinConfigurations.<host>.config.homebrew.casks` before running `mise run` on the target host.

## Build, Test, and Development Commands
- `mise run` (or `mise run default`): builds and switches the system for the current host (Darwin uses `darwin-rebuild switch`).
- `mise run lint`: runs `deadnix`, `nixpkgs-fmt`, and `statix` (same checks as the pre-commit hook).
- `mise run check`: runs `mise run lint`, then `nix flake check --all-systems`, and builds the current host system for validation.

## Coding Style & Naming Conventions
- Nix files use 2‑space indentation and compact attribute sets.
- Host names map directly to folder names (e.g., `systems/m5mbp`, `home-manager/shayne/m5mbp`).
- Prefer `pkgs.stdenv.hostPlatform.system` over deprecated `pkgs.system` or `system` alias.
- Formatting: use `nix fmt` (flake formatter is configured via nix-formatter-pack).

## Testing Guidelines
- No standalone test suite; rely on `mise run check` for evaluation/build sanity.
- Validate host changes by running `mise run` on the target host.

## Commit & Pull Request Guidelines
- Commit messages follow a short “scope: summary” style (examples: `systems/m5mbp: enable nix-index program`, `flake: update all dependencies`).
- Use `Revert "..."` when rolling back a change.
- PRs should include: a short summary, affected hosts, and the exact command(s) run (e.g., `mise run check`, `mise run`).

## Security & Configuration Tips
- Treat `*.enc.nix` files as sensitive (e.g., `home-manager/shayne/environment.enc.nix`, `systems/**/.*.enc.nix`). Avoid editing without the proper secrets workflow.
