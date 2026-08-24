#!/usr/bin/env bash
# Fuzzy-jump to a project directory, creating (or attaching to) a tmux session
# named after it. Works whether or not you're already inside tmux.
#
# Usage:
#   sessionizer.sh          fzf over SESSIONIZER_DIRS (one level deep)
#   sessionizer.sh <path>   jump straight to <path>, no picker

set -euo pipefail

# directories to search, one level deep - edit this to match your layout.
# set from your actual project directories at promotion time (2026-08-22):
# ~/code and ~/work don't exist on this machine, these do and hold real repos/
# projects one level down. add/remove freely - it's just a space-separated list.
SESSIONIZER_DIRS="${SESSIONIZER_DIRS:-$HOME/Experiments $HOME/Practice $HOME/reference $HOME/Soft $HOME/interview $HOME/Stuff $HOME/.config}"

if [ $# -eq 1 ]; then
  selected=$1
else
  # shellcheck disable=SC2086 # intentional word-splitting over the dir list
  selected=$(find $SESSIONIZER_DIRS -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | fzf)
fi

[ -z "${selected:-}" ] && exit 0
[ -d "$selected" ] || exit 0

# tmux session names can't contain '.' or ':'
selected_name=$(basename "$selected" | tr '.:' '__')

if ! command tmux has-session -t="$selected_name" 2>/dev/null; then
  # A tmux server may have been started from an agent shell. These explicit
  # values make a newly created human session override stale server markers.
  session_env=(
    -e 'ZSH_AGENT_MODE=0'
    -e 'CLAUDECODE='
    -e 'CI='
    -e 'CODEX_SANDBOX='
    -e 'CURSOR_AGENT='
    -e 'OPENCODE='
  )
  command tmux new-session -ds "$selected_name" "${session_env[@]}" -c "$selected"
fi

if [ -n "${TMUX:-}" ]; then
  command tmux switch-client -t "$selected_name"
else
  command tmux attach-session -t "$selected_name"
fi
