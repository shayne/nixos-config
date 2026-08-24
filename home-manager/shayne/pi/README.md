# Pi coding agent

This shared Home Manager module installs Pi from the pinned
[`numtide/llm-agents.nix`](https://github.com/numtide/llm-agents.nix) flake and
translates the local provider from `../m5mbp/opencode.json` into Pi's native
model schema. OpenCode remains the source of truth for the NInfer endpoint,
default model, display name, and token limits.

Home Manager owns Pi's declarative settings, model catalog, keybindings, MCP
defaults, and extension configuration under `~/.pi/agent/`. Pi continues to own
`auth.json`, sessions, package state, and other mutable runtime data.

The plugin selection and local extensions are adapted from
[`wimpysworld/nix-config`](https://github.com/wimpysworld/nix-config/tree/main/home-manager/_mixins/agentic/pi).
That source is licensed under the
[`Blue Oak Model License 1.0.0`](https://blueoakcouncil.org/license/1.0.0).
Herd, Fence, Noughty-specific assistants, provider routing, and communication
policy integrations are intentionally omitted.
