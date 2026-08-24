#!/usr/bin/env bash
# Bootstrap this Herdr setup on another Mac.
#
#   scp -r ~/.config/herdr other-mac:~/herdr-setup   # or use your dotfiles
#   ssh other-mac 'bash ~/herdr-setup/setup-new-mac.sh'
#
# Idempotent: safe to re-run. Only config.toml is portable; session.json,
# *.sock, and *.log are machine-local and are never copied.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME/.config/herdr"

say() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
ok()  { printf '    \033[32m✓\033[0m %s\n' "$1"; }
warn(){ printf '    \033[33m!\033[0m %s\n' "$1"; }

# 1. Herdr itself ------------------------------------------------------------
say "Herdr binary"
if command -v herdr >/dev/null 2>&1; then
  ok "already installed ($(herdr --version))"
else
  curl -fsSL https://herdr.dev/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  ok "installed ($(herdr --version))"
  warn "add ~/.local/bin to PATH in your shell rc if it isn't already"
fi

# 2. config.toml -------------------------------------------------------------
say "config.toml"
mkdir -p "$DEST_DIR"
if [ "$SRC_DIR" = "$DEST_DIR" ]; then
  ok "running from $DEST_DIR; leaving config in place"
elif [ ! -f "$SRC_DIR/config.toml" ]; then
  warn "no config.toml next to this script — copy it yourself"
else
  if [ -f "$DEST_DIR/config.toml" ]; then
    backup="$DEST_DIR/config.toml.bak.$(date +%Y%m%d%H%M%S)"
    cp "$DEST_DIR/config.toml" "$backup"
    warn "existing config backed up to $(basename "$backup")"
  fi
  cp "$SRC_DIR/config.toml" "$DEST_DIR/config.toml"
  ok "copied to $DEST_DIR/config.toml"
fi

herdr config check

# 3. Agent integrations ------------------------------------------------------
# Only install for agents actually present. Installing for an absent agent
# yields a hook nothing reads, and a misleading "current" in `integration status`.
say "Agent integrations"
if [ -d "$HOME/.claude" ]; then
  herdr integration install claude
  ok "claude integration installed"
else
  warn "no ~/.claude — skipping (run 'herdr integration install claude' later)"
fi
warn "for other agents: herdr integration status, then install only what you run"

# 4. Herdr skill -------------------------------------------------------------
say "Herdr skill (lets agents drive Herdr)"
if [ -d "$HOME/.agents/skills/herdr" ]; then
  ok "already installed"
else
  npx --yes skills add herdrdev/herdr --skill herdr -g || \
    warn "skill install failed — rerun manually if you want programmatic control"
fi

# 5. Done --------------------------------------------------------------------
say "Done"
cat <<'EOF'
    Next:
      1. cd to a project and run:  herdr
      2. press ctrl+a ? to see your bindings (prefix is ctrl+a, not ctrl+b)
      3. restart your agent once so its SessionStart hook engages

    Note: theme.name = "terminal" inherits this machine's terminal palette,
    so colors will match the local terminal profile, not the other Mac's.
    Set a named theme (tokyo-night, gruvbox, catppuccin...) for identical looks.
EOF
