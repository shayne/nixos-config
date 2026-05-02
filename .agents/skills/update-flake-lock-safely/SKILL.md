---
name: update-flake-lock-safely
description: Safely update flake.lock in this nixos-config repo with build-first validation, mise run activation, and selective rollback of broken inputs. Use when the user asks to update or refresh flake.lock, upgrade flake inputs, update Nix or Homebrew pins, diagnose breakage after a lockfile refresh, or avoid a yolo nix flake update that leaves the host unbuildable.
---

# Update Flake Lock Safely

## Overview

Update `flake.lock` as a controlled maintenance operation. Keep as many compatible input advances as possible, but do not call the update done until the target host builds and the normal activation path succeeds.

## Workflow

1. Inspect the starting state.
   - Run `git status --short`, `hostname -s`, and inspect the current branch.
   - If `flake.lock` or related config is already dirty, understand those changes before updating. Do not overwrite unrelated user work.
   - Read the repo `AGENTS.md` rules and respect requested scope: all inputs, Homebrew-only, one named input, or target-host apply.

2. Establish a baseline when failure attribution matters.
   - For Darwin, use `host="$(hostname -s)"` and build `nix build ".#darwinConfigurations.${host}.system" --no-link`.
   - For Linux hosts, build `nix build ".#nixosConfigurations.${host}.config.system.build.toplevel" --no-link`.
   - If the baseline already fails, diagnose that first; do not blame the upcoming update.

3. Update only the intended scope.
   - For an all-input refresh, `nix flake update` is acceptable, but it is only the first step.
   - For Homebrew package/cask upgrades, follow repo policy and update the pinned Homebrew tap inputs, typically `nix flake update homebrew-core homebrew-cask`, plus any explicitly relevant pinned tap input.
   - For one input, use `nix flake update INPUT`.
   - After updating, inspect `git diff --stat -- flake.lock` and the changed input names before building.

4. Build before activation.
   - Run `nix build ".#darwinConfigurations.${host}.system" --no-link` on Darwin before `mise run`.
   - If the build fails, run `nix log DRV` for the failing derivation and identify the real failing leaf. Do not remove the first visible app/package unless the log proves it is the root cause.
   - Roll back the smallest broken input, then rebuild. Preserve unrelated forward progress.

5. Activate only after the build passes.
   - Run `mise run`; in this repo that goes through `scripts/switch_host.sh`, builds the host, then runs `darwin-rebuild switch` on Darwin.
   - Let Homebrew and Home Manager activation finish. Do not interrupt during `brew bundle` unless the command is clearly stuck or destructive.
   - If sudo/password prompts block non-interactive completion, say activation was not verified and stop short of claiming success.

6. Finish with evidence.
   - Report what changed, what was rolled back, and why.
   - Include the exact validation commands and outcomes.
   - Leave commits to the user unless they explicitly ask to commit.

## Rollback Patterns

Use the previous committed lockfile as the rollback source:

```sh
previous_input_rev() {
  input="$1"
  git show HEAD:flake.lock | jq -r --arg input "$input" '
    .nodes.root.inputs[$input] as $node | .nodes[$node].locked.rev
  '
}
```

Roll back one input by name:

```sh
rev="$(previous_input_rev nixpkgs)"
nix flake update nixpkgs --override-input nixpkgs "github:NixOS/nixpkgs/${rev}"
```

For non-flake Homebrew taps:

```sh
rev="$(previous_input_rev homebrew-cask)"
nix flake update homebrew-cask --override-input homebrew-cask "github:homebrew/homebrew-cask/${rev}"
```

Rebuild after each rollback. If several inputs look suspicious, roll them back one at a time so the final diff keeps every compatible advance.

## Known Failure Signatures

- `direnv` build fails during `test-fish`, ending in `Killed: 9`: suspect a bad signed `fish` binary from the updated root `nixpkgs` closure. Confirm with `codesign --verify --verbose=4 /nix/store/...-fish-.../bin/fish`; if it reports an invalid signature, roll back only the root `nixpkgs` input.
- Homebrew activation fails with `Cask NAME is unreadable: wrong number of arguments (given 1, expected 0)`: suspect Homebrew parser/cask syntax skew, not the first named cask. Check another cask or the generated Brewfile before changing package declarations. Prefer rolling back only `homebrew-cask` if the active pinned brew cannot parse the new cask tree.
- A Nix build fails before activation: stay in Nix logs and derivation inputs. Homebrew changes are not active yet.
- A failure appears only during `mise run` after the system build passes: inspect activation output, especially Homebrew setup, `brew bundle`, Home Manager activation, and SOPS steps.

## Useful Checks

```sh
git status --short
git diff --stat -- flake.lock
nix build ".#darwinConfigurations.$(hostname -s).system" --no-link --print-out-paths
HOMEBREW_NO_AUTO_UPDATE=1 /opt/homebrew/bin/brew bundle check --file=/nix/store/...-Brewfile
mise run
```

Find the generated Brewfile path from the built Darwin system when needed:

```sh
system="$(nix build ".#darwinConfigurations.$(hostname -s).system" --no-link --print-out-paths)"
rg -n "brew bundle --file='[^']+-Brewfile'" "$system/activate"
```

## Guardrails

- Do not present `nix flake update` alone as the result.
- Do not revert the whole lockfile when one input can be dialed back.
- Do not run bare `brew update` or `brew upgrade`; Homebrew upgrades should flow through the flake-pinned taps and nix-darwin activation.
- Do not edit package declarations to dodge parser/build failures unless the declaration itself is proven wrong.
- Do not hide partial success: if build passes but activation fails, say exactly where it stopped.
