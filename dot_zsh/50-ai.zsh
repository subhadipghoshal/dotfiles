# 50-ai.zsh — the shell as a substrate for the agents, not another agent.
#
# History shows claude/codex/opencode/cursor-agent launched bare 57 times, from
# whatever directory happened to be current, with no project scoping and no way
# to hand state between them. Nothing here tries to be a fifth agent. It does
# three things: launch them somewhere sensible, and give them state they cannot
# easily get for themselves (a captured failure, a compact repo summary).
#
# The pager/alias fixes that stop agents hanging live in 99-agent-guard.zsh.

# ── Launching ─────────────────────────────────────────────────────────────
# agent <name> [branch]
#   agent claude              launch claude here
#   agent codex feat/parser   worktree + tmux session for feat/parser, then codex
#
# The branch form is the one that matters when more than one agent is running:
# each gets its own checkout via wt (see 20-git.zsh), so they cannot overwrite
# each other's edits.
agent() {
  emulate -L zsh
  local which=$1
  [[ -n $which ]] || {
    print -u2 "usage: agent <claude|codex|opencode|cursor-agent> [branch]"
    print -u2 "installed:"
    local a
    for a in claude codex opencode cursor-agent; do
      (( $+commands[$a] )) && print -u2 "  $a"
    done
    return 1
  }

  (( $+commands[$which] )) || { print -u2 "agent: '$which' is not installed"; return 1 }

  if [[ -n $2 ]]; then
    wt "$2" || return
  fi

  ZSH_AGENT_MODE=1 PAGER=cat MANPAGER=cat GIT_PAGER=cat DELTA_PAGER=cat LESS=-FRX \
    "$which" "${@:3}"
}

alias cc='agent claude'
alias cx='agent codex'
alias oc='agent opencode'

# ── Context ───────────────────────────────────────────────────────────────
# ctx [-c]   repo state + what you have actually been running in this directory.
#            -c copies to the clipboard instead of printing.
#
# The "recent commands here" half is the part agents cannot reconstruct: it
# comes from Atuin, scoped by cwd, and carries exit codes.
ctx() {
  emulate -L zsh
  local -a lines
  local copy=0
  [[ $1 == -c ]] && copy=1

  lines=( "$(gctx 2>/dev/null || print -r -- '## not a git repository')" )
  lines+=( "" "## cwd: $PWD" "" "## recent commands here (exit  command)" )

  if (( $+commands[atuin] )); then
    lines+=( "$(atuin search --cwd "$PWD" --limit 15 --format '{exit}  {command}' 2>/dev/null)" )
  else
    lines+=( "$(fc -ln -15 2>/dev/null)" )
  fi

  if (( copy )); then
    print -rl -- $lines | pbcopy
    print "ctx: copied $(print -rl -- $lines | wc -l | tr -d ' ') lines to clipboard"
  else
    print -rl -- $lines
  fi
}

# ── Failures ──────────────────────────────────────────────────────────────
# fix [-c]   the last command that exited non-zero, plus whatever output is
#            still on screen, formatted to hand straight to an agent.
#
# Why tmux capture-pane rather than instrumenting every command: it is
# retroactive. It reads the pane's real scrollback, so it captures output from
# a command you had no idea would fail, at zero per-command cost. The
# alternatives were all worse — `exec 2> >(tee)` breaks ZLE and p10k, TRAPZERR
# gives you the fact of failure but none of the output, and re-running with
# 2>&1 is dangerous for anything non-idempotent (bootdev run is the 4th most
# used command here).
#
# ⚠️ Outside tmux there is no scrollback to read, so you get the failed command
# and the repo state but not the error text.
fix() {
  emulate -L zsh
  local cmd out copy=0
  [[ $1 == -c ]] && copy=1

  if (( $+commands[atuin] )); then
    cmd=$(atuin search --exit 1 --limit 1 --format '{command}' 2>/dev/null | head -1)
  fi
  [[ -n $cmd ]] || { print -u2 "fix: no recent non-zero exit found in history"; return 1 }

  if [[ -n $TMUX ]]; then
    out=$(tmux capture-pane -p -S -300 2>/dev/null | tail -80)
  else
    out="(not running inside tmux — no pane scrollback to capture)"
  fi

  local -a lines=(
    "The following command failed."
    ""
    "    $cmd"
    ""
    "## terminal output"
    "$out"
    ""
    "$(gctx 2>/dev/null)"
  )

  if (( copy )); then
    print -rl -- $lines | pbcopy
    print "fix: copied to clipboard"
  else
    print -rl -- $lines
  fi
}

# ⚠️ EXIT CODES ARE ONLY RECORDED FROM THE MOMENT ATUIN WAS INSTALLED.
# The 6,950 commands imported from ~/.zsh_history all carry exit = -1
# ("unknown"), because a plain zsh history file never stored exit status —
# that is precisely the gap Atuin fills. So fix / fails / worked see only
# commands run after 2026-08-23. They get more useful every day; they are not
# retroactive, and no tool could make them so.

# fails [n]   the last n failing commands, with the directory they failed in.
#             "What have I been fighting with today."
fails() {
  emulate -L zsh
  (( $+commands[atuin] )) || { print -u2 "fails: requires atuin"; return 1 }
  local out
  out=$(atuin search --exit 1 --limit "${1:-20}" \
        --format '{time}  {directory}  {command}' 2>/dev/null)
  if [[ -z $out ]]; then
    print -u2 "fails: no recorded failures yet — exit codes only exist for"
    print -u2 "       commands run since atuin was installed (2026-08-23)."
    return 1
  fi
  print -r -- "$out"
}

# worked <pattern>   commands matching <pattern>, run IN THIS DIRECTORY, that
#                    did not fail. The query a flat history file cannot answer:
#                    "the kubectl invocation that actually worked, here".
#
#                    Uses --exclude-exit 1 rather than --exit 0 on purpose, so
#                    imported history (exit = -1, unknown) still shows up. That
#                    means the honest reading is "did not visibly fail" until
#                    enough post-install history accumulates.
worked() {
  emulate -L zsh
  (( $+commands[atuin] )) || { print -u2 "worked: requires atuin"; return 1 }
  [[ -n $1 ]] || { print -u2 "usage: worked <pattern>"; return 1 }
  atuin search --exclude-exit 1 --cwd "$PWD" --limit 30 \
    --format '{exit}  {command}' -- "$1" 2>/dev/null
}
