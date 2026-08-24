# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this directory is

This is **not a source repository**. It is the runtime config and state directory for
[Herdr](https://herdr.dev), a terminal workspace manager for AI coding agents. Herdr itself is an
installed binary (`~/.local/bin/herdr`, currently 0.8.2) — there is no code to build, lint, or test
here.

Work in this directory is almost always one of two things: editing `config.toml`, or inspecting
logs/state to debug Herdr behavior.

## Files

| File | Owner | Notes |
| --- | --- | --- |
| `config.toml` | **user-editable** — the only file to edit by hand | Herdr reads it at startup and on reload |
| `session.json` | Herdr server | Workspace/tab/pane layout, rewritten live. Do not hand-edit while the server runs |
| `herdr.sock`, `herdr-client.sock` | Herdr server | Live IPC sockets. Deleting them breaks the running session |
| `herdr-server.log`, `herdr-client.log` | Herdr | Structured `tracing` output; server and client are separate processes with separate logs |
| `.plugins.lock` | Herdr | Lockfile |

## Commands

```bash
herdr config check            # validate config.toml, print diagnostics (run after every edit)
herdr server reload-config    # apply config.toml to the running server
herdr status                  # client/server version, protocol, socket path, update state
herdr --default-config        # print the full annotated default config (diff source of truth)
herdr config reset-keys       # back up config.toml and strip custom keybindings
```

In-app, `prefix+shift+r` (default `prefix` is `ctrl+b`) reloads config without the CLI.

Some settings are explicitly **startup-only** and reload will not pick them up — e.g.
`ui.sidebar_start_collapsed`, `keys.remote_image_paste`. Restart the server (`herdr server stop`,
then relaunch) when a change appears to have no effect.

## Editing config.toml

The file is a copy of the annotated default, so **most lines are commented-out defaults**. To change
something, uncomment the existing line rather than appending a new key — appending risks a duplicate
key in a different table, and every TOML section header is already present.

Active settings: `theme.name = "terminal"` (inherits the host terminal palette),
`ui.toast.delivery = "system"` (macOS Notification Center), `ui.sound.enabled = true`,
`experimental.pane_history = false`, and a `[keys]` block
that mirrors `~/.tmux.conf` (prefix `ctrl+a`, `hjkl` pane focus, `v`/`s` splits, `ctrl+h`/`ctrl+l`
tab nav, `r` reload, `shift+HJKL` resize). Each remapped binding carries an inline comment naming the
tmux line it mirrors — **keep `~/.tmux.conf` and the `[keys]` block in sync when either changes.**
Non-default consequences worth knowing: `settings` moved to `prefix+comma` (tmux owns `s`),
`resize_mode`/`reload_config` are swapped relative to Herdr defaults, and
`new_workspace`/`workspace_picker` are swapped (`prefix+w` creates, `prefix+shift+n` picks).

Non-obvious points, all documented inline in the file:

- **Keybinding syntax is explicit about the prefix.** `"prefix+n"` requires the prefix key first;
  `"ctrl+alt+n"` is a direct terminal-mode chord. There is no implicit prefix. Reliable direct
  bindings are `ctrl+<letter>`, function keys, and explicit modified chords — `alt+…`, `cmd`/`super`,
  and punctuation-with-modifiers depend on the outer terminal and tmux setup.
- **Navigate-mode keys (`navigate_*`) are a separate namespace** from `focus_pane_*`. They must not
  include `prefix+`, `esc`, `enter`, `tab`, or `1..9`.
- **`[keys.indexed]` is legacy** and still parsed for compatibility. Prefer `switch_tab`,
  `switch_workspace`, and `focus_agent` for new bindings.
- **Relative paths resolve from this directory**, not the CWD — notably `ui.sound.path` and friends.
- **`[worktrees]` is commented out entirely**, so worktrees default to `~/.herdr/worktrees`, outside
  this directory.
- Custom keybindings can launch commands via `[[keys.command]]` with `type = "shell"` (detached),
  `"pane"` (temporary pane), or `"popup"` (session-modal).

## Controlling Herdr programmatically

Do **not** drive the Herdr CLI's mutating commands (`pane`, `agent`, `workspace`, `tab`, …) from
guesswork. Herdr ships its own authoritative agent instructions:

```bash
herdr --skill
```

Read that before issuing control commands. Key constraints it establishes:

- Control commands require running **inside** a Herdr-managed pane — gate on `test "${HERDR_ENV:-}" = 1`
  and stop if it fails. Do not manipulate a session from outside it.
- Never run bare `herdr` for discovery; it launches or attaches the TUI. Run a command group with no
  subcommand (`herdr agent`, `herdr pane`) to see its syntax instead.
- Never probe a mutating nested command by omitting arguments — e.g. `herdr workspace create` is
  valid with defaults and will execute.
- Public IDs (`w1`, `w1:t1`, `w1:p1`) are opaque and not reused. Read IDs out of the JSON responses
  rather than predicting them. The calling pane's context is in `$HERDR_WORKSPACE_ID`,
  `$HERDR_TAB_ID`, `$HERDR_PANE_ID`; prefer `--current` over an omitted target, which may resolve to
  the UI-focused pane belonging to the user or another client.
