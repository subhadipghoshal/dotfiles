# 20-git.zsh — worktrees and repo context.
#
# Deliberately small: oh-my-zsh's git plugin already provides ~35 aliases with
# 298 recorded uses, plus `grt` (cd to repo root) and `gwt` (git worktree).
# Nothing here re-implements those. `wt` does not shadow `gwt`.

# ── Worktrees ─────────────────────────────────────────────────────────────
# The problem this solves: running several agents against one repo means they
# share a working tree and overwrite each other's edits. A worktree gives each
# one its own checkout of its own branch, sharing the object store, so they
# genuinely cannot collide.
#
# Layout is a sibling directory, not a nested one, so `rg`/`fd`/agent file
# scans in the main repo never walk into the other checkouts:
#     ~/Practice/myapp                  main
#     ~/Practice/myapp-feat-parser      feat/parser
#
# ⚠️ Worktrees do NOT share .venv, node_modules or Go build cache. With a Go +
# Python stack, expect one `uv sync` / `go mod download` per worktree. If the
# repo has a .envrc, direnv handles it on cd.
#
#   wt              fzf over existing worktrees, jump to one
#   wt <branch>     create (or attach to) a worktree for <branch>
#   wt -l           list worktrees
#   wt -r <branch>  remove that worktree; the branch itself is left alone
wt() {
  emulate -L zsh
  local root dir name branch

  root=$(git rev-parse --show-toplevel 2>/dev/null) \
    || { print -u2 "wt: not inside a git repository"; return 1 }

  # The main checkout's own name, even when called from inside a worktree,
  # so `myapp-feat-a` + `wt feat-b` still yields `myapp-feat-b`, not
  # `myapp-feat-a-feat-b`.
  local base=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
  base=${base:-$root}

  case $1 in
    -l|--list)
      git worktree list
      return
      ;;
    -r|--remove)
      [[ -n $2 ]] || { print -u2 "wt -r <branch>"; return 1 }
      name=${${2//\//-}//[.:]/_}
      dir=${base:h}/${base:t}-$name
      [[ -d $dir ]] || { print -u2 "wt: no worktree at $dir"; return 1 }
      git worktree remove "$dir" && git worktree prune && print "removed $dir"
      return
      ;;
    -h|--help)
      print "wt            pick an existing worktree"
      print "wt <branch>   create/attach a worktree for <branch>"
      print "wt -l         list · wt -r <branch>  remove"
      return
      ;;
  esac

  if (( $# == 0 )); then
    dir=$(git worktree list --porcelain \
          | awk '/^worktree /{print $2}' \
          | fzf --prompt='worktree> ' \
                --preview 'git -C {} log --oneline --decorate -15 --color=always') \
      || return
    [[ -n $dir ]] || return
  else
    branch=$1
    name=${${branch//\//-}//[.:]/_}
    dir=${base:h}/${base:t}-$name

    if [[ ! -d $dir ]]; then
      if git show-ref --verify --quiet "refs/heads/$branch"; then
        git worktree add "$dir" "$branch" || return
      else
        git worktree add -b "$branch" "$dir" || return
      fi
      print "wt: created $dir"
    fi
  fi

  # cd FIRST, unconditionally, so this shell always ends up in the worktree
  # whatever happens next. Then hand off to the tmux sessionizer for a session
  # named after the directory. Ordered this way because the sessionizer fails
  # when tmux is installed but has no server it can reach — testing for the
  # binary is not enough, and a failed handoff should never leave you in the
  # directory you started from wondering whether anything happened.
  cd -- "$dir" || return

  # Strip agent markers before handing off: `wt`/`agent` is exactly how a
  # running agent spins up its own worktree+session (50-ai.zsh), and these
  # vars are exported, so an agent-flagged shell would otherwise bake
  # CLAUDECODE/etc. into the new tmux session's environment permanently.
  # Every pane opened in that session afterward — including a human typing
  # into it later — would then keep failing 99-agent-guard.zsh's check
  # forever. See `deagent` in 99-agent-guard.zsh for clearing an already-
  # poisoned pane.
  local sessionizer=$HOME/.config/tmux/scripts/sessionizer.sh
  if [[ -x $sessionizer ]] && command -v tmux >/dev/null 2>&1; then
    env -u CLAUDECODE -u CI -u CODEX_SANDBOX -u CURSOR_AGENT -u OPENCODE -u ZSH_AGENT_MODE \
      "$sessionizer" "$dir" 2>/dev/null || true
  fi
}

# ── Context ───────────────────────────────────────────────────────────────
# gctx  compact, paste-ready repo state.
#
# Mostly redundant for claude and codex, which inspect git themselves — its
# real use is opencode, cursor-agent and web UIs, and as the tail end of `ctx`.
gctx() {
  emulate -L zsh
  git rev-parse --git-dir >/dev/null 2>&1 \
    || { print -u2 "gctx: not inside a git repository"; return 1 }

  local up ahead_behind stashes worktrees

  print -r -- "## repo:   $(git rev-parse --show-toplevel)"
  print -r -- "## branch: $(git branch --show-current 2>/dev/null || print detached) @ $(git rev-parse --short HEAD 2>/dev/null)"

  if up=$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null); then
    ahead_behind=$(git rev-list --left-right --count "@{u}...HEAD" 2>/dev/null \
                   | awk '{printf "behind %s, ahead %s", $1, $2}')
    print -r -- "## upstream: $up ($ahead_behind)"
  else
    print -r -- "## upstream: none"
  fi

  print -r -- ""
  print -r -- "## status (porcelain)"
  git status --porcelain=v1 2>/dev/null | head -40
  [[ $(git status --porcelain=v1 2>/dev/null | wc -l) -gt 40 ]] \
    && print -r -- "   ... truncated at 40 entries"

  print -r -- ""
  print -r -- "## recent commits"
  git log --oneline --no-decorate -8 2>/dev/null

  stashes=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
  (( stashes > 0 )) && { print -r -- ""; print -r -- "## stashes: $stashes" }

  worktrees=$(git worktree list 2>/dev/null | wc -l | tr -d ' ')
  if (( worktrees > 1 )); then
    print -r -- ""
    print -r -- "## worktrees"
    git worktree list
  fi
}
