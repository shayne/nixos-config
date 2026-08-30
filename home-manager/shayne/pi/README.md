# Pi coding agent

This shared Home Manager module installs Pi from the pinned
[`numtide/llm-agents.nix`](https://github.com/numtide/llm-agents.nix) flake and
translates the local provider from `../m5mbp/opencode.json` into Pi's native
model schema. OpenCode remains the source of truth for the NInfer endpoint,
default model, display name, and token limits.

Home Manager owns Pi's declarative settings, model catalog, keybindings, MCP
defaults, pinned extension list, and extension configuration under
`~/.pi/agent/`. Pi continues to own `auth.json`, sessions, package state, and
other mutable runtime data.

The pinned extension set includes `pi-mcp-adapter`, `pi-subagents`, `pi-lens`,
`pi-footer`, `pi-sub-core`, `pi-cc-header`, `pi-pretty`, `rpiv-btw`, and
`rpiv-todo`. `pi-cc-header` runs with its native read-only configuration mode,
so header commands can affect the current session without trying to modify the
Home Manager-owned `settings.json`.

`pi-pretty` supplies collapsed, syntax-highlighted output for Pi's built-in
tools. It enables the opt-in `ls` renderer with Nerd Font icons and owns the
`find` and `grep` tools through its bundled FFF frecency index. Do not install
`pi-fff` alongside it because both extensions claim the same tool names. Its
mutable index remains under `~/.pi/agent/pi-pretty/fff/`; Home Manager owns only
`~/.pi/agent/pi-pretty.json`.

The footer starts with a Pi glyph and shows only the working directory's
basename. Static MCP, MCP authentication, quota, and Pi Lens statuses that have
dedicated widgets or no actionable state are hidden from the extra status row;
transient subagent status remains visible. Home Manager also hides Pi Lens's
always-present diagnostics widget through `~/.pi-lens/config.json`; the
`/lens-widget-toggle` command can reveal it for the current session.

The plugin selection and local extensions are adapted from
[`wimpysworld/nix-config`](https://github.com/wimpysworld/nix-config/tree/main/home-manager/_mixins/agentic/pi).
That source is licensed under the
[`Blue Oak Model License 1.0.0`](https://blueoakcouncil.org/license/1.0.0).
Herd, Fence, Noughty-specific assistants, provider routing, and communication
policy integrations are intentionally omitted.
