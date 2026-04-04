# Workflow Reference

## Repo Map

- Shared Darwin defaults: `systems/base/darwin-configuration.nix`
- Host-specific Darwin configs: `systems/<hostname>/darwin-configuration.nix`
- Flake tap inputs: `flake.nix`
- Apply the current host config with `mise run`
- Run commands from the repository root

## Scope Rules

- Prefer host-specific edits unless the user explicitly asks for a shared/base install.
- Use `systems/base/darwin-configuration.nix` for packages that should apply to every Darwin host.
- If a request names a host such as `m5mbp` or `macstudio`, edit that host file directly.
- If scope is omitted and the current machine hostname matches `systems/<hostname>/`, prefer that host for a local install and mention the assumption.

## Package Edit Targets

- CLI formulae: `homebrew.brews`
- GUI app bundles: `homebrew.casks`
- Mac App Store apps: `homebrew.masApps`
- Extra Homebrew taps: `homebrew.taps`
- Pinned tap sources for nix-homebrew: `nix-homebrew.taps`

## Tap Patterns

- Existing core taps are pinned in `systems/base/darwin-configuration.nix` through:
  - `nix-homebrew.taps."homebrew/homebrew-core" = inputs.homebrew-core`
  - `nix-homebrew.taps."homebrew/homebrew-cask" = inputs.homebrew-cask`
- Host-local tap strings live in each host file's `homebrew.taps` list.
- For a new third-party tap that should be pinned, follow the `Arthur-Ficial` pattern:
  1. Add a flake input in `flake.nix` with `flake = false;`, for example `homebrew-owner-name-tap = { url = "github:owner/homebrew-name"; flake = false; };`
  2. Add the input to `nix-homebrew.taps` in the target host/base config, mapping the full tap repo name to the flake input.
  3. Add the Homebrew tap string to `homebrew.taps`, for example `"owner/name"`.
  4. Add the formula or cask token to `homebrew.brews` or `homebrew.casks`, using a tap-qualified token when needed.
- If the tap already exists in this repo, reuse the existing flake input and tap wiring instead of introducing a duplicate input name.

## Verification Commands

Use targeted `nix eval` before broader rebuilds for small package edits:

```bash
nix eval --json .#darwinConfigurations.<host>.config.homebrew.brews | jq -r '.[].name'
nix eval --json .#darwinConfigurations.<host>.config.homebrew.casks | jq -r '.[].name'
nix eval --json .#darwinConfigurations.<host>.config.homebrew.taps | jq -r '.[].name'
nix eval --json .#darwinConfigurations.<host>.config.nix-homebrew.taps | jq -r 'keys[]'
```

Notes:

- `homebrew.brews`, `homebrew.casks`, and `homebrew.taps` evaluate to lists of objects, so check `.[].name`.
- `nix-homebrew.taps` evaluates to an attrset, so check `keys[]`.
- When adding a new file that must be visible to flake evaluation, stage it before trusting `nix eval`.
- Use `mise run` on the target host when the user asks to apply the config, then verify the installed command or app bundle directly.

## Diff Hygiene

- Preserve the surrounding list order and 2-space Nix indentation.
- Keep package-only requests to the relevant host/base file and `flake.nix`/`flake.lock` only when tap inputs change.
- Never use imperative `brew install`.
- Do not revert unrelated user edits in a dirty worktree.
