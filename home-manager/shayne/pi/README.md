# Pi coding agent

This shared Home Manager module installs Pi from the pinned
[`numtide/llm-agents.nix`](https://github.com/numtide/llm-agents.nix) flake and
translates the local provider from `../m5air/opencode.json` into Pi's native
model schema. OpenCode remains the source of truth for the NInfer endpoint,
default model, display name, and token limits.

Pi runs in Node mode (`useBun = false` with `dontNpmPrune = true`) so the SDK
dependency tree retained in the store package remains available to
`@tintinweb/pi-subagents` native background sessions.

Home Manager owns Pi's declarative settings, model catalog, keybindings, MCP
adapter defaults, pinned package list, extension configuration, theme, and
local extensions under `~/.pi/agent/`. Pi continues to own `auth.json`,
sessions, package state, and other mutable runtime data.

## Pinned packages

The pinned set is adapted from
[`wimpysworld/nix-config`](https://github.com/wimpysworld/nix-config/tree/main/home-manager/_mixins/agentic/pi)
(Blue Oak Model License 1.0.0):

- `git:github.com/nicobailon/pi-mcp-adapter@80fcdef8` — the v5.2.0 release
  commit, which supports Pi 1.0 and carries the GHSA-6qxp-vccf-f47h fix. Pi
  clones it under `~/.pi/agent/git/` and installs its runtime dependencies.
- `npm:@tintinweb/pi-subagents@0.20.0` — requires Pi 1.1.0 or later. Settings
  are written to `~/.pi/agent/subagents.json`. Do not install the former
  `pi-subagents` package alongside it.
- `npm:pi-lens@4.4.1` plus a direct `npm:typescript@7.0.2` runtime dependency
  (pi-lens imports the compiler API but omits TypeScript from its runtime
  dependencies).
- `npm:pi-footer@0.5.1`
- `npm:@marckrenn/pi-sub-core@1.5.0`
- `npm:pi-cc-header@1.1.1`
- `npm:@heyhuynhgiabuu/pi-pretty@0.6.31`
- `npm:@juicesharp/rpiv-ask-user-question@2.12.0` — structured questionnaires
  with typed options.
- `npm:@juicesharp/rpiv-btw@2.12.0` — explicit side model calls using the
  current conversation context.
- `npm:@tintinweb/pi-tasks@0.9.1` — Claude Code-style task tracking
  (`TaskCreate`, `TaskList`, `TaskGet`, `TaskUpdate`, `TaskOutput`,
  `TaskStop`, `TaskExecute`), a persistent widget above the editor, reminder
  injection, and dependency tracking. The `/tasks` command saves display
  overrides to project-local `.pi/tasks-config.json`, which stays user-owned.

Pi automatically discovers shared user skills from `~/.agents/skills/`,
including Superpowers. The package list does not install a second Superpowers
collection or its bootstrap extension, avoiding duplicate skill registrations
and conflicting versions.

`pi-mcp-adapter` is configured through `~/.pi/agent/mcp-adapter.json` (not
the native `mcp.json`). Native MCP is disabled via
`extensions = [ "-builtin:mcp" ]` in the Home Manager-owned `settings.json`,
so the adapter never needs to rewrite that file. Shell-level `pi mcp`
commands still use native MCP; use `/mcp-adapter` inside Pi.

The wimpysworld-specific integrations (Herd, Fence, provider routing,
communication policy, service-tier/fast mode, assistant mapping) are
intentionally omitted.

## Behaviours

- `pi-pretty` supplies collapsed, syntax-highlighted output for Pi's built-in
  tools, themed to match the Catppuccin Mocha Pi theme. It enables the opt-in
  `ls` renderer with Nerd Font icons and owns the `find` and `grep` tools
  through its bundled FFF frecency index. Do not install `pi-fff` alongside
  it because both extensions claim the same tool names. Its mutable index
  remains under `~/.pi/agent/pi-pretty/fff/`; Home Manager owns only
  `~/.pi/agent/pi-pretty.json`.
- The Catppuccin theme pair is deployed as
  `~/.pi/agent/themes/catppuccin-latte.json` and
  `~/.pi/agent/themes/catppuccin-mocha.json`, and the default theme is
  `catppuccin-latte/catppuccin-mocha`: Pi picks the theme matching the
  terminal's reported background (then the terminal light/dark notification,
  then `COLORFGBG`, then dark) and switches live on appearance changes.
- `showHardwareCursor = true` lets the terminal emulator draw the cursor.
  The `hardware-cursor` extension strips Pi's inverse-block editor cursor so
  only the emulator's cursor is visible; set the setting to `false` to make
  the extension inert.
- `pi-cc-header` runs with its native read-only configuration mode
  (`ccHeader.readOnlyConfig`), so header commands can affect the current
  session without trying to modify the Home Manager-owned `settings.json`.
- The footer starts with a Pi glyph and shows the model, thinking level,
  working directory basename, quota (published by the local `quota-status`
  extension through `pi-sub-core`), and context-window usage. Static MCP, MCP
  authentication, and Pi Lens statuses that have dedicated widgets or no
  actionable state are hidden from the extra status row.
- Home Manager also hides Pi Lens's always-present diagnostics widget through
  `~/.pi-lens/config.json`; the `/lens-widget-toggle` command can reveal it
  for the current session.

## Local extensions

- `extensions/prompt-template-display/` — displays the original slash
  invocation while expanding file-backed prompt templates.
- `extensions/quota-status/` — publishes compact provider quota windows from
  `pi-sub-core` through `ctx.ui.setStatus("pi-quota:usage", ...)`, consumed
  by the footer. Model-scoped bonus windows (for example
  "GPT-5.3-Codex-Spark 5h") are filtered out of the segment.
- `extensions/hardware-cursor/` — strips the software cursor while
  `showHardwareCursor` is enabled.

## Migration notes

- When upgrading from the former `pi-subagents` package, run
  `pi remove pi-subagents` (and `pi remove @juicesharp/rpiv-todo`, if
  installed) once after activation, then start a fresh Pi session. Do not run
  both subagent extensions in one session.
- Existing sessions remain mutable and unmanaged under `~/.pi/agent`;
  historical logs and sessions are untouched by the package migration.
