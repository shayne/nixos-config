# nix-darwin Configurations

This repository houses my macOS (nix-darwin) configurations and related Nix tooling. The system loader lives in
`lib/loadSystems.nix` and `lib/mkSystem.nix`, with per-host configs under `systems/` and user config under
`home-manager/`.

## Structure

- `systems/base/`: shared Darwin defaults
- `systems/<hostname>/`: per-host overrides (current host: `m5air`)
- `home-manager/<user>/`: shared user config and per-host overlays
- `modules/`: reusable Nix modules
- `overlays/` + `pkgs/`: custom overlays/packages
- `flake.nix`/`flake.lock`: source pinning and flake outputs
- `nixpkgs.nix`: compatibility helper for importing the flake-pinned nixpkgs

## Common Commands

- `make bootstrap`: first build and switch on a host where Nix is installed but this config has not installed system tools yet
- `make`: run the default `mise` task after `mise` is installed
- `mise run lint`: run `deadnix`, `nixpkgs-fmt`, and `statix` (same as pre-commit)
- `mise run check`: run lint + `nix flake check --all-systems`, then build the current host
- `mise run` (or `mise run default`): build and switch the current host (Darwin uses `darwin-rebuild switch`)

Homebrew apps are declared in the shared and per-host Darwin configs. Remove an
app from those lists to stop managing it; the next `mise run` applies the removal
using the configured Homebrew cleanup policy. Run this on the affected host;
for `m5studio` package changes, run `mise run` on `m5studio`.

Google Chrome is declared in the shared Darwin config for all Macs.
Raycast is declared in the `m5studio` host config.
1Password (`pkgs._1password-gui`) is declared in the `m5air` host config.
After applying the config, open 1Password and sign in to the family account.
Tailscale (`tailscale-app`) is also shared by all Macs. After installation,
open Tailscale and authenticate the Mac to join the tailnet.

On `m5studio`, computer sleep, display sleep, and the idle screen saver are
disabled declaratively to match `macstudio`. Apply with `mise run` on `m5studio`;
verify with `pmset -g custom` and
`defaults -currentHost read com.apple.screensaver idleTime` (all three idle
timeouts should be `0`). The existing password requirement remains unchanged.
Screen Sharing also has `RestoreMachineState = false` on this host, so a session
unlocked remotely is not re-locked on disconnect just because it began locked.
Verify the preference with
`sudo defaults read /Library/Preferences/com.apple.RemoteManagement RestoreMachineState`
(expected `0`), then reconnect, unlock, and disconnect to check the live behavior.

The Beszel agent on `m5studio` is installed through Homebrew and runs as the
Home Manager LaunchAgent `org.nix-community.home.beszel-agent` in `gui/501`.
Home Manager renders its SOPS credentials into `~/.config/beszel/beszel-agent.env`
and restarts the agent after the secrets are ready. Do not enable Homebrew's
`start_service` for this formula: Darwin's sudo activation targets `user/501`
and can fail before Home Manager renders the credentials. Apply changes with
`mise run`; check the agent with
`launchctl print gui/501/org.nix-community.home.beszel-agent` and read logs at
`~/.cache/beszel/beszel-agent.log`.
Connect `m5studio` to the tailnet so the agent can reach
`https://beszel.shayne.ts.net`.

Home Manager imports `nix-community/nix-index-database`, so `nix-locate`, shell
`command-not-found`, and `comma`/`,` use the upstream wrappers and prebuilt
index data. There is no local `nix-index` database build step to run on Darwin
hosts in this repo.

## Pi coding agent

The shared `shayne` Home Manager profile installs `pi` from the pinned
`numtide/llm-agents.nix` flake on every Mac. Its default provider and model are
derived from `home-manager/shayne/m5air/opencode.json`, so OpenCode and Pi use
the same NInfer endpoint, model identifiers, and token limits. The local API key
comes from the existing `local_llm_api_key` SOPS secret at runtime.

Home Manager owns Pi's settings, model catalog, extension configuration, and
pinned package list. Pi still owns mutable authentication, sessions, and npm
package state under `~/.pi/agent/`. The managed extensions include
syntax-highlighted and frecency-aware tool output from `pi-pretty`, a compact
Pi-labelled footer, and read-only `pi-cc-header` configuration that preserves
the declarative settings file.

Pi discovers shared user skills from `~/.agents/skills/`. Superpowers is managed
there rather than installed again through Pi's pinned package list.

## Hermes Agent and Computer Use

The shared `shayne` Home Manager profile installs Hermes Agent from the pinned
`numtide/llm-agents.nix` flake on hosts other than `m5air`. The laptop excludes
the Hermes module, its packages, and its dedicated CUA driver. The Nix wrapper supplies Hermes'
Computer Use HTTP dependency and a writable lazy-package target, while Hermes
continues to own mutable configuration, credentials, sessions, skills, and
other state under `~/.hermes/`. Update Hermes through this flake and rebuild the
host rather than using `hermes update`.

On Darwin, Home Manager also installs the pinned, signed CUA driver package and
places `CuaDriver.app` in `/Applications`, falling back to `~/Applications` if
the system Applications directory is not writable. After the first install,
grant `CuaDriver.app` both Accessibility and Screen & System Audio Recording in
System Settings -> Privacy & Security. Re-grant them after a driver upgrade if
the upstream code signature changes.

If `make` itself is missing on a fresh host, run the bootstrap target through Nix:
`nix --extra-experimental-features "nix-command flakes" run nixpkgs#gnumake -- bootstrap`

## Secrets

This repo stores secrets with `sops` + `age`.

- Shared agent instructions are stored in the encrypted `agents_md` value in
  `secrets/shayne.yaml`. SOPS installs them at `~/.agents/AGENTS.md` with mode
  `0400`; Home Manager links `~/.codex/AGENTS.md` to that shared file so Codex
  discovers it as global guidance. Edit the value with `sops secrets/shayne.yaml`
  and apply with `mise run` on each host. Start a new Codex session to load
  updated instructions. The plaintext stays outside the repository and Nix store.
- Each host that needs to decrypt secrets must have the shared SSH private key at:
  `~/.ssh/id_ed25519`
- Shells export `SOPS_AGE_SSH_PRIVATE_KEY_FILE=~/.ssh/id_ed25519` so `sops
  secrets/shayne.yaml` works without extra flags.
- Edit shell secrets with `sops secrets/shayne.yaml`
- On Darwin, Home Manager loads the SOPS LaunchAgent before restarting it to
  render updated secrets, avoiding an immediate unload/reload race in launchd.
- Rebuild the encrypted font archive from a local plaintext font directory with:
  `tar -C /path/to/fonts -czf /tmp/custom-fonts.tar.gz . && cp /tmp/custom-fonts.tar.gz secrets/custom-fonts.tar.gz && sops encrypt -i --input-type binary secrets/custom-fonts.tar.gz`

## Pre-commit

Install hooks with:
`pre-commit install` and `pre-commit install --hook-type prepare-commit-msg`.
Note: `pre-commit install` only installs the default `pre-commit` hook; the
`prepare-commit-msg` hook must be installed explicitly.
You can run all hooks manually with `pre-commit run --all-files`.

## Current Systems

- `m5air` — Apple Silicon MacBook Air running nix-darwin
- `m5studio` — Apple Silicon Mac Studio running nix-darwin

The flake still exports cross-platform packages and formatter outputs, but the active system configs in this repo are Darwin-only.
