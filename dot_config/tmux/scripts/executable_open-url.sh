#!/usr/bin/env bash
# Pick a URL out of a pane's visible content + recent scrollback and open it.
# Usage: open-url.sh <pane_id>   (pane_id passed in by the keybinding, since
# this runs inside a popup - its own pane, not the one we want to scan)
set -euo pipefail

pane="$1"

url=$(tmux capture-pane -J -p -S -2000 -t "$pane" \
  | grep -oE 'https?://[^[:space:]"'"'"'<>()]+' \
  | tac \
  | awk '!seen[$0]++' \
  | fzf --prompt="open> ")

[ -z "${url:-}" ] && exit 0

if command -v open >/dev/null 2>&1; then
  open "$url"
else
  printf '%s\n' "$url"
fi
