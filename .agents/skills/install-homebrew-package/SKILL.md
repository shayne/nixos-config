---
name: install-homebrew-package
description: Add or update Homebrew brews, casks, and taps declaratively in this nixos-config repo's nix-darwin host configs. Use when the user asks to install a Homebrew formula or cask, add a tap, make a package host-specific or shared/base, or asks where Homebrew packages are declared in `systems/HOSTNAME/darwin-configuration.nix` and `systems/base/darwin-configuration.nix`. Do not use for Nix package or Home Manager module installs unless the requested change is explicitly a Homebrew declaration.
---

# Install Homebrew Package

## Overview

Add Homebrew declarations to this repo quickly without breaking the host/base layout, tap pinning pattern, or verification loop. Keep the edit narrow, infer scope from the request when possible, and verify the evaluated config before reporting success.

## Workflow

Read `references/workflow.md` first for the repo map, package/tap edit patterns, and exact verification commands.

1. Determine the package kind and target scope from the user request.
   - Use `homebrew.brews` for CLI formulae.
   - Use `homebrew.casks` for GUI app bundles.
   - Use `homebrew.taps` plus `nix-homebrew.taps` and possibly `flake.nix` when adding a tap or tap-qualified package.
   - If the user names a host or asks for a shared/base change, use that scope directly. If scope is omitted, prefer the current host for host-local installs and ask only when the target scope is genuinely ambiguous.

2. Inspect the existing config before editing.
   - Read the target host/base file and `flake.nix` when tap pinning may be needed.
   - Preserve the local list ordering and attribute style.
   - Do not revert unrelated worktree changes.

3. Verify package or tap identifiers before inserting them.
   - Reuse existing tap-qualified package names already present in this repo when they match.
   - If the token is uncertain, confirm the Homebrew formula/cask/tap name from an authoritative source before editing instead of guessing.

4. Edit only the required declaration files.
   - Add packages/taps to the right host/base config and add a flake input only when introducing a new pinned tap source.
   - Keep the diff minimal and avoid unrelated refactors.

5. Run targeted config evaluation before broader rebuilds.
   - For small host package changes, evaluate the affected `darwinConfigurations.<host>` Homebrew attr and confirm the package/tap appears in the output.
   - If new files are involved in a flake source path, stage them before trusting `nix eval`.

6. Report exactly what changed, which files were edited, and what verification ran.
   - Mention if `mise run` was not run.
   - Do not claim installation is complete from config edits alone.

## Edit Rules

- Prefer host-scoped edits in `systems/<hostname>/darwin-configuration.nix` unless the user explicitly asks for a shared/base change.
- Use `systems/base/darwin-configuration.nix` for packages intended to apply to all Darwin hosts.
- When adding a tap-qualified package from a new third-party tap, wire both the Homebrew tap string and the pinned tap source if this repo does not already have that tap input.
- Keep tap names and package tokens exactly as Homebrew expects, including owner-qualified names such as `owner/tap/formula`.
- Use `apply_patch` for manual edits and keep generated files out of the diff unless they are part of the requested skill/package change.

## Common Requests

- "Add cinebench cask to m5mbp" -> edit `systems/m5mbp/darwin-configuration.nix` `homebrew.casks`, then evaluate the `m5mbp` cask list.
- "Install tmux via brew on all Macs" -> edit `systems/base/darwin-configuration.nix` `homebrew.brews`, then evaluate both Darwin hosts.
- "Add Arthur-Ficial/tap/apfel on m5mbp" -> add the tap input in `flake.nix` if missing, wire `nix-homebrew.taps` and `homebrew.taps` in `systems/m5mbp/darwin-configuration.nix`, add the brew token, then evaluate `brews`, `taps`, and `nix-homebrew.taps`.
