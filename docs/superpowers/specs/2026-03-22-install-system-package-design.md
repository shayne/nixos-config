# Install System Package Design

**Goal:** Create an `install-system-package` skill that lets an agent satisfy missing or useful package needs declaratively on macOS hosts managed by `nix-darwin`, preferring Nix packages first and using Homebrew only when appropriate.

## Current State

- This repo is the source of truth for system package installation at `~/nixos-config`.
- Shared Darwin defaults live in `systems/base/darwin-configuration.nix`.
- Host-specific Darwin overrides live in `systems/<hostname>/darwin-configuration.nix`.
- Nix-managed system packages are declared in `environment.systemPackages`.
- Homebrew packages are declared per host in `homebrew.brews` and `homebrew.casks`.
- Rebuilds are applied with `mise run`.

## Target State

- An agent can recognize when a missing command or helpful tool should be installed instead of worked around.
- The skill presents viable install options, recommends the best one, and asks the user to confirm before changing config or running a rebuild.
- Package installation stays declarative in `~/nixos-config`; no imperative `brew install` or `nix profile install`.
- The skill asks whether the install should be host-specific or shared across hosts.
- After a successful rebuild and direct verification, the skill creates a small commit and pushes to `origin`.
- Repo-specific workflow details are isolated in a small reference file so another user can adapt the skill without rewriting the whole thing.

## Scope

- Support only macOS hosts managed by `nix-darwin`.
- Support package installation through:
  - `environment.systemPackages` for Nix packages
  - `homebrew.brews` for CLI Homebrew formulae
  - `homebrew.casks` for GUI macOS applications
- Trigger when:
  - a command needed for the current task is missing
  - a package would materially help complete the task
  - the user explicitly asks to install software

## Decision Flow

1. Detect the package need instead of silently switching to a weaker fallback.
2. Identify the current host and treat `~/nixos-config` as the declarative source of truth.
3. Find candidate install methods in this order:
   - Nix package
   - Homebrew brew
   - Homebrew cask
4. Present the user with:
   - the recommended option
   - viable alternatives, if any
   - whether the install should be host-specific or shared across hosts
5. Ask for confirmation before editing config.
6. Edit the appropriate Nix file.
7. Ask for confirmation before running `mise run`.
8. Run `mise run`.
9. Verify the package is actually available in the expected way.
10. If verification passes, create a small commit and push to `origin`.

## File Selection Rules

### Nix Packages

- Shared install: edit `systems/base/darwin-configuration.nix`.
- Host-specific install: edit `systems/<hostname>/darwin-configuration.nix`.
- Add packages to `environment.systemPackages`.

### Homebrew Packages

- Edit the target host file at `systems/<hostname>/darwin-configuration.nix`.
- Use `homebrew.brews` for CLI formulae.
- Use `homebrew.casks` for GUI apps.

### Shared Homebrew Requests

- If the user wants a Homebrew-only package on all hosts, make direct edits to each Darwin host file in v1.
- Do not introduce a new shared abstraction unless the user asks for that refactor.

### Edit Hygiene

- Preserve local formatting and keep diffs narrowly scoped.
- Preserve alphabetical ordering when the surrounding package list is already alphabetized; otherwise follow the existing local style.
- Avoid unrelated refactors.

## Verification Rules

- Treat a successful `mise run` as necessary but not sufficient.
- Verify based on install type:
  - CLI tool: `command -v <command>` and, when useful, a lightweight version or help check
  - GUI app: confirm the installed app exists at the expected macOS application path
- Account for cases where the package name differs from the executable or app name.
- Do not commit if verification fails.

## Git Rules

- After successful verification, create a small scope-style commit.
- Push to `origin`.
- Do not include unrelated working tree changes in the commit.

## Explicit Non-Goals

- Support plain NixOS hosts.
- Perform imperative package installation outside declarative config.
- Commit or push before rebuild and verification succeed.

## Skill Structure

### `SKILL.md`

- Describe when the skill should trigger and the required decision order.
- Instruct the agent to prefer Nix packages over Homebrew when both are viable.
- Require the user confirmation points:
  - before editing config
  - before running `mise run`
  - when choosing host-specific vs shared scope

### `references/workflow.md`

Keep the repo-specific knobs in one short reference file:

- config repo path: `~/nixos-config`
- shared Darwin file path
- host Darwin file pattern
- Nix package insertion target
- Homebrew brew and cask insertion targets
- rebuild command: `mise run`
- post-rebuild verification expectations
- post-verification git behavior

This keeps the skill personal to this repo while making adaptation cheap for another user.
