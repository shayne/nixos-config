# Repository Guidelines

## Agent Skill Usage
- Do not use `using-superpowers` or other Superpowers skills for work in this repository unless the user explicitly asks for that specific skill or workflow.

## Project Structure & Module Organization
- `flake.nix`/`flake.lock`: flake entrypoint and pinned inputs.
- `systems/`: host configs. Common defaults live in `systems/base/`; per-host overrides live in `systems/<hostname>/` (e.g., `systems/m5mbp/`).
- `home-manager/`: user profiles (global defaults in `home-manager/<user>/default.nix`, per-host overrides in `home-manager/<user>/<hostname>/`).
- Do not remove seemingly empty `home-manager/<user>/<hostname>/default.nix` files without checking `lib/mkSystem.nix`; those tracked host directories determine which users attach to which hosts.
- `modules/`: reusable Nix modules (shells, editors, services).
- `overlays/` + `pkgs/`: custom packages and overlay wiring.
- `flake.nix`/`flake.lock`: source pinning and flake outputs.
- `nixpkgs.nix`: compatibility helper for importing the flake-pinned nixpkgs.
- `iso/`: ISO build scripts.

## Darwin / Homebrew Conventions
- Darwin hosts use `systems/<hostname>/darwin-configuration.nix`; shared Darwin defaults live in `systems/base/darwin-configuration.nix`.
- Manage Homebrew declaratively through nix-darwin/nix-homebrew, not with imperative `brew install`.
- Use `homebrew.brews` for CLI formulae, `homebrew.casks` for GUI apps, `homebrew.masApps` for Mac App Store apps, and `homebrew.taps` for extra tap repos needed by tap-qualified packages.
- Prefer host-scoped edits for host-specific Darwin packages unless the user explicitly asks for a shared/base change.
- When the user asks to upgrade Homebrew packages, formulae, or casks, update only the pinned Homebrew tap inputs in `flake.lock` with `nix flake update homebrew-core homebrew-cask`, then apply the Darwin config with `mise run` on the target host. Do not run bare `nix flake update` for this request, and do not run imperative `brew update` or `brew upgrade`; `homebrew.onActivation.upgrade = true` makes nix-darwin's generated `brew bundle` upgrade declared formulae/casks from the flake-pinned taps during activation.
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
- When deciding whether a Home Manager module is actually used, verify all three layers: the import site, the host/user attachment in `lib/mkSystem.nix`, and the built closure or generated config output. A successful system build alone can miss accidentally detaching a user from a host.
- Stage newly added host marker files before trusting flake evaluation results. Untracked files may not be visible to the Git-based flake source that `nix` evaluates.

## Commit & Pull Request Guidelines
- Commit messages follow a short “scope: summary” style (examples: `systems/m5mbp: enable nix-index program`, `flake: update all dependencies`).
- Use `Revert "..."` when rolling back a change.
- PRs should include: a short summary, affected hosts, and the exact command(s) run (e.g., `mise run check`, `mise run`).
- When a change affects active hosts, secret bootstrap/decryption, or common operator commands, update `README.md` in the same change so the repo docs stay current.

## Security & Configuration Tips
- Treat [secrets/shayne.yaml](/Users/shayne/nixos-config/secrets/shayne.yaml) and [secrets/custom-fonts.tar.gz](/Users/shayne/nixos-config/secrets/custom-fonts.tar.gz) as sensitive. Edit them with `sops`; do not reintroduce legacy `git-crypt` or `*.enc.nix` workflows.
- The repo decrypts secrets with `~/.ssh/id_ed25519` via `SOPS_AGE_SSH_PRIVATE_KEY_FILE`. Do not switch back to `keys.txt` or implicit key discovery unless the user explicitly asks for it.
