#!/usr/bin/env bash
# List currently open tmux sessions and switch to the selected one.
# Complements sessionizer.sh: that one jumps to a *project* (creating a
# session if needed), this one picks among sessions that already exist.
set -euo pipefail

current=$(tmux display-message -p '#S')

selected=$(tmux list-sessions -F '#{session_name}: #{session_windows} windows#{?session_attached, (attached),}' \
  | fzf --prompt="switch> " --header="current: $current" \
  | cut -d: -f1)

[ -z "${selected:-}" ] && exit 0

if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$selected"
else
  tmux attach-session -t "$selected"
fi
