#!/usr/bin/env bash
# Fuzzy-jump to a project directory, creating (or attaching to) a tmux session
# named after it. Works whether or not you're already inside tmux.
#
# Usage:
#   sessionizer.sh          fzf over discovered projects under SESSIONIZER_DIRS
#   sessionizer.sh <path>   jump straight to <path>, no picker

set -euo pipefail

# roots to search under - edit this to match your layout. Real project roots
# on this machine, confirmed to exist (2026-09-02; the previous list -
# ~/Experiments ~/Practice ~/reference ~/Soft ~/interview ~/Stuff - was set
# for a different machine and none of those six existed here, which is why
# the picker only ever showed ~/.config's children). $HOME/setup and
# $HOME/vaults also exist but weren't confirmed as project roots, so they're
# left commented rather than guessed in - add/remove freely, it's just a
# space-separated list.
SESSIONIZER_DIRS="${SESSIONIZER_DIRS:-$HOME/github.com $HOME/github.docusignhq.com $HOME/.config}"
# SESSIONIZER_DIRS="$SESSIONIZER_DIRS $HOME/setup $HOME/vaults"

# Discovery, not a fixed depth: a single uniform "-maxdepth 1" can't see a
# project at ~/github.com/<org>/<repo> (two levels) and a project at
# ~/github.docusignhq.com/<repo> (one level) at the same time, and it goes
# stale again the next time a root's layout differs. Union two passes
# instead, deduped:
#   1. any directory containing a .git folder, at any depth - pruned so find
#      doesn't recurse into a match (skip scanning full repo histories), and
#      pruned on common vendor/plugin directory names *before* the .git
#      check, or this repo's own TPM plugin clones
#      (~/.config/tmux/plugins/*) show up as false "projects" (confirmed:
#      they did, until this exclusion was added).
#   2. today's flat one-level listing, so an untracked scratch/notes
#      directory with no .git still shows up.
find_projects() {
  local root
  for root in $SESSIONIZER_DIRS; do
    [ -d "$root" ] || continue
    find "$root" \( -name plugins -o -name node_modules -o -name vendor -o -name '.venv' \) \
      -prune -o -type d -name .git -print 2>/dev/null | sed 's#/\.git$##'
    find "$root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
  done
}

if [ $# -eq 1 ]; then
  selected=$1
else
  selected=$(find_projects | sort -u | fzf)
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

  # Optional declarative layout, run once at creation only (not on every
  # jump back to an already-open session). Layouts live in this tmux config
  # directory, named after the session - NOT inside the project directory
  # itself, so that sessionizing into a cloned repo never executes code that
  # repo shipped. A layout script is plain tmux commands (split-window,
  # select-pane, send-keys, ...) targeting "$selected_name"; see
  # layouts/tmux.sh for a worked example. No layout file -> unchanged
  # behavior, a single plain pane.
  layout="$HOME/.config/tmux/layouts/$selected_name.sh"
  if [ -x "$layout" ]; then
    "$layout" "$selected_name"
  fi
fi

if [ -n "${TMUX:-}" ]; then
  command tmux switch-client -t "$selected_name"
else
  command tmux attach-session -t "$selected_name"
fi
