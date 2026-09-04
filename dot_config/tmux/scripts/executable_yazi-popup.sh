#!/usr/bin/env bash
# Open yazi in a tmux popup; if you navigate somewhere and quit with q, cd the
# pane that opened the popup there too - same idea as the `y` shell wrapper
# (~/.zsh/35-yazi.zsh), so the popup isn't a dead end.
# Usage: yazi-popup.sh <pane_id>   (pane_id passed in by the keybinding, since
# this runs inside the popup - its own pane, not the one that should receive
# the cd)
set -euo pipefail

pane="$1"
start_dir="$PWD"

cwd_file="$(mktemp)"
trap 'rm -f "$cwd_file"' EXIT

yazi --cwd-file="$cwd_file"

new_dir="$(cat -- "$cwd_file" 2>/dev/null || true)"
[ -z "$new_dir" ] && exit 0
[ "$new_dir" = "$start_dir" ] && exit 0
[ -d "$new_dir" ] || exit 0

# Only send keystrokes into a pane that's actually sitting at a shell prompt -
# doing this into nvim or a REPL would type a stray `cd ...` into a buffer.
case "$(tmux display-message -p -t "$pane" '#{pane_current_command}')" in
  zsh|bash|sh|fish) tmux send-keys -t "$pane" "cd -- $(printf '%q' "$new_dir")" Enter ;;
esac
