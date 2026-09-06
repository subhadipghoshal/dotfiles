#!/usr/bin/env bash
# ~/.claude/statusline-command.sh
# Layout:  <dir>  <branch>  <VIM-MODE>  <model>  <10-seg context bar + used%>  <cost>  <time>
#
# Colors use the standard 8-color ANSI SGR codes (30-37), never truecolor/hex
# escapes, so they always resolve through whatever palette the active
# terminal theme defines. Switching terminal themes re-colors this line
# automatically; no theme name is hardcoded here.
# Cost is read from .cost.total_cost_usd; the segment is omitted when the
# runtime doesn't send it (older Claude Code versions don't expose cost).

input=$(cat)

# ── Extract JSON fields ───────────────────────────────────────────────────────
cwd=$(printf '%s' "$input"      | jq -r '.workspace.current_dir // .cwd // empty')
model=$(printf '%s' "$input"    | jq -r '.model.display_name // empty')
used=$(printf '%s' "$input"     | jq -r '.context_window.used_percentage // empty')
vim_mode=$(printf '%s' "$input" | jq -r '.vim.mode // empty')
cost=$(printf '%s' "$input"     | jq -r '.cost.total_cost_usd // empty')

# ── ANSI colours (standard SGR codes, resolved via the terminal's own theme) ──
R='\033[0m'
BOLD='\033[1m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
MAGENTA='\033[35m'

# ── Current directory basename ────────────────────────────────────────────────
dir_name=$(basename "${cwd:-$(pwd)}")

# ── Git branch (skip optional locks so we never block on a stale index lock) ──
branch=""
if [ -d "${cwd:-$(pwd)}" ]; then
  branch=$(git --no-optional-locks -C "${cwd:-$(pwd)}" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git --no-optional-locks -C "${cwd:-$(pwd)}" rev-parse --short HEAD 2>/dev/null)
fi

# ── Vim mode indicator ────────────────────────────────────────────────────────
# Mode colors follow common editor convention (insert=green, normal=blue,
# visual=magenta, replace=red), all via standard ANSI codes.
vim_segment=""
if [ -n "$vim_mode" ]; then
  case "${vim_mode^^}" in
    NORMAL|NOR|N)  vim_segment="$(printf "${BOLD}${BLUE}NORMAL${R}")"   ;;
    INSERT|INS|I)  vim_segment="$(printf "${BOLD}${GREEN}INSERT${R}")"  ;;
    VISUAL|VIS|V)  vim_segment="$(printf "${BOLD}${MAGENTA}VISUAL${R}")";;
    V-LINE|VL)     vim_segment="$(printf "${BOLD}${MAGENTA}V-LINE${R}")";;
    V-BLOCK|VB)    vim_segment="$(printf "${BOLD}${MAGENTA}V-BLOCK${R}")";;
    REPLACE|REP|R) vim_segment="$(printf "${BOLD}${RED}REPLACE${R}")"  ;;
    COMMAND|CMD|C) vim_segment="$(printf "${BOLD}${YELLOW}COMMAND${R}")";;
    *)             vim_segment="$(printf "${BOLD}${CYAN}${vim_mode}${R}")";;
  esac
fi

# ── 10-segment context-usage bar ─────────────────────────────────────────────
bar_segment=""
if [ -n "$used" ]; then
  pct=$(printf "%.0f" "$used")
  filled=$(( pct * 10 / 100 ))
  [ "$filled" -gt 10 ] && filled=10

  if   [ "$pct" -lt 70 ]; then BAR_COLOR="${GREEN}"
  elif [ "$pct" -lt 90 ]; then BAR_COLOR="${YELLOW}"
  else                          BAR_COLOR="${RED}"
  fi

  bar_str=""
  for i in 1 2 3 4 5 6 7 8 9 10; do
    if [ "$i" -le "$filled" ]; then bar_str="${bar_str}█"
    else                            bar_str="${bar_str}░"
    fi
  done

  bar_segment="$(printf "${BAR_COLOR}%s${R} ${BAR_COLOR}%s%%${R}" "$bar_str" "$pct")"
fi

# ── Assemble the line ─────────────────────────────────────────────────────────
out="$(printf "${BLUE}%s${R}" "$dir_name")"

if [ -n "$branch" ]; then
  out="${out}  $(printf "${MAGENTA}%s${R}" "$branch")"
fi

if [ -n "$vim_segment" ]; then
  out="${out}  ${vim_segment}"
fi

if [ -n "$model" ]; then
  out="${out}  $(printf "${CYAN}%s${R}" "$model")"
fi

if [ -n "$bar_segment" ]; then
  out="${out}  ${bar_segment}"
fi

if [ -n "$cost" ]; then
  cost_str="\$$(printf '%.2f' "$cost")"
  out="${out}  $(printf "${YELLOW}%s${R}" "$cost_str")"
fi

out="${out}  $(date +%H:%M:%S)"

printf '%s' "$out"
