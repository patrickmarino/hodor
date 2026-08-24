# hodor

Personal [Herdr](https://herdr.dev) configuration — a terminal workspace manager for AI coding
agents. Keybindings mirror my `~/.tmux.conf` so muscle memory carries over.

Lives at `~/.config/herdr/`.

## Contents

| File | Purpose |
| --- | --- |
| `config.toml` | The whole configuration — theme, keybindings, notifications |
| `setup-new-mac.sh` | Bootstraps Herdr, this config, and integrations on a new machine |
| `CLAUDE.md` | Notes for Claude Code working in this directory |

Runtime state (`session.json`, `*.sock`, `*.log`, `.plugins.lock`) is gitignored — it's
machine-specific, rewritten constantly, and hardcodes local project paths.

## Setup on a new machine

**Option A — version-controlled config** (preferred; supports `git pull` to sync later):

```bash
mkdir -p ~/.config/herdr && cd ~/.config/herdr
[ -f config.toml ] && mv config.toml config.toml.default.bak
git init -q
git remote add origin git@github.com:patrickmarino/hodor.git
git fetch -q origin
git checkout -b main --track origin/main
herdr config check && herdr server reload-config
```

Plain `git clone` won't work — the directory already holds live sockets and state. The `.gitignore`
above keeps those untouched.

**Option B — one-shot script** (no git on the target machine):

```bash
git clone git@github.com:patrickmarino/hodor.git ~/herdr-setup
bash ~/herdr-setup/setup-new-mac.sh
```

Installs Herdr if missing, copies the config (backing up any existing one), installs the Claude
integration, and adds the Herdr skill. Idempotent.

## Keybindings

Prefix is <kbd>ctrl+a</kbd> — **not** Herdr's default <kbd>ctrl+b</kbd>, so every keybinding on
herdr.dev needs translating. `ctrl+a ?` shows the live bindings and is the authority.

| Keys | Action | |
| --- | --- | --- |
| <kbd>ctrl+a</kbd> <kbd>h</kbd>/<kbd>j</kbd>/<kbd>k</kbd>/<kbd>l</kbd> | focus pane | tmux |
| <kbd>ctrl+a</kbd> <kbd>shift</kbd>+<kbd>H</kbd>/<kbd>J</kbd>/<kbd>K</kbd>/<kbd>L</kbd> | resize pane | tmux |
| <kbd>ctrl+a</kbd> <kbd>v</kbd> / <kbd>s</kbd> | split | tmux |
| <kbd>ctrl+a</kbd> <kbd>c</kbd> | new tab | tmux |
| <kbd>ctrl+a</kbd> <kbd>ctrl+h</kbd> / <kbd>ctrl+l</kbd> | previous / next tab | tmux |
| <kbd>ctrl+a</kbd> <kbd>tab</kbd> | goto picker | tmux |
| <kbd>ctrl+a</kbd> <kbd>r</kbd> | reload config | tmux |
| <kbd>ctrl+a</kbd> <kbd>,</kbd> | settings | moved off `s` |
| <kbd>ctrl+a</kbd> <kbd>shift+R</kbd> | resize mode | swapped with reload |
| <kbd>ctrl+a</kbd> <kbd>q</kbd> | detach (everything keeps running) | default |
| <kbd>ctrl+a</kbd> <kbd>?</kbd> | help | default |
| <kbd>ctrl+a</kbd> <kbd>x</kbd> / <kbd>z</kbd> | close pane / zoom | default |
| <kbd>ctrl+a</kbd> <kbd>w</kbd> | new workspace | swapped with picker |
| <kbd>ctrl+a</kbd> <kbd>shift+N</kbd> | workspace picker | swapped with new workspace |
| <kbd>ctrl+a</kbd> <kbd>b</kbd> | toggle sidebar | default |

Four deliberate departures from Herdr's defaults: `split_horizontal` is `s` rather than `minus`,
`settings` moved to `,`, and `reload_config`/`resize_mode` are swapped (all because tmux owns the
key); `new_workspace`/`workspace_picker` are swapped so `w` creates a workspace (the goto picker on
`tab` covers switching).

## Other settings

- **Theme** `terminal` — inherits the host terminal's palette rather than imposing one, so colors
  follow the local iTerm2 profile. This is the one setting that won't look identical across
  machines; set a named theme (`tokyo-night`, `gruvbox`, `catppuccin`) for that.
- **Notifications** delivered to macOS Notification Center, so agent `blocked`/`done` reaches you
  when the terminal isn't visible. Sound enabled for background workspaces.

## Daily commands

```bash
herdr config check            # validate before reloading
herdr server reload-config    # apply changes (or ctrl+a r)
herdr status                  # client/server versions, socket
herdr integration status      # per-agent hook state
herdr --default-config        # print stock defaults to diff against
```

Some settings are startup-only and reload silently skips them (`ui.sidebar_start_collapsed`,
`keys.remote_image_paste`). Restart with `herdr server stop`, then `herdr`.

## Agent integrations

Install only for agents actually run in a pane:

```bash
herdr integration install claude
```

This writes a `SessionStart` hook, so a running agent must be restarted before it reports state.
Installing an integration for an absent agent produces a hook nothing reads while
`integration status` reports `current` — misleading, so don't.
