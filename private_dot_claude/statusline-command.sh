#!/usr/bin/env bash
# ~/.claude/statusline-command.sh
# Claude Code status line - mirrors the p10k lean prompt (dir vcs context time).
# Receives Claude Code JSON on stdin; outputs a coloured one-line status string.

input=$(cat)

# ── Extract JSON fields ───────────────────────────────────────────────────────
cwd=$(printf '%s' "$input"      | jq -r '.workspace.current_dir // .cwd // empty')
model=$(printf '%s' "$input"    | jq -r '.model.display_name // empty')
remaining=$(printf '%s' "$input" | jq -r '.context_window.remaining_percentage // empty')
repo_name=$(printf '%s' "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')
worktree=$(printf '%s' "$input" | jq -r '.workspace.git_worktree // empty')
vim_mode=$(printf '%s' "$input" | jq -r '.vim.mode // empty')

# ── Static context ────────────────────────────────────────────────────────────
user=$(whoami)
host=$(hostname -s)

# Shorten cwd: replace $HOME prefix with ~
short_cwd="${cwd/#$HOME/~}"

# ── Git branch (GIT_OPTIONAL_LOCKS skips index-lock contention) ──────────────
branch=""
if [ -n "$cwd" ]; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" branch --show-current 2>/dev/null)
fi

# ── ANSI colours (the status line dims these automatically) ───────────────────
R='\033[0m'
CYAN='\033[36m'
BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
BOLD='\033[1m'

# ── Assemble the line ─────────────────────────────────────────────────────────
out=""

# user@host  (mirrors p10k `context` segment)
out="${out}$(printf "${CYAN}%s@%s${R}" "$user" "$host")"

# directory  (mirrors p10k `dir` segment)
out="${out} $(printf "${BLUE}%s${R}" "$short_cwd")"

# git        (mirrors p10k `vcs` segment: branch > worktree > repo)
if [ -n "$branch" ]; then
  out="${out} $(printf "${GREEN}[%s]${R}" "$branch")"
elif [ -n "$worktree" ]; then
  out="${out} $(printf "${GREEN}[wt:%s]${R}" "$worktree")"
elif [ -n "$repo_name" ]; then
  out="${out} $(printf "${GREEN}[%s]${R}" "$repo_name")"
fi

# vim mode   (present only when vim mode is active)
if [ -n "$vim_mode" ]; then
  out="${out} $(printf "${YELLOW}[%s]${R}" "$vim_mode")"
fi

# divider
out="${out} |"

# model
if [ -n "$model" ]; then
  out="${out} $(printf "${MAGENTA}%s${R}" "$model")"
fi

# context window remaining (colour shifts as headroom shrinks)
if [ -n "$remaining" ]; then
  pct=$(printf "%.0f" "$remaining")
  if   [ "$pct" -lt 20 ]; then CTX_COLOR="${RED}"
  elif [ "$pct" -lt 40 ]; then CTX_COLOR="${YELLOW}"
  else                          CTX_COLOR="${GREEN}"
  fi
  out="${out} $(printf "${CTX_COLOR}ctx:%s%% free%s" "$pct" "${R}")"
fi

printf '%s' "$out"
