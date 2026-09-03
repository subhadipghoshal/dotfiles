# 99-agent-guard.zsh — make this config safe for agent and non-interactive shells.
#
# Sourced LAST from .zshrc, explicitly and outside the [0-8]*.zsh glob, because
# it has to run after every alias in the config exists — including ones added by
# sdkman, gcloud and the oh-my-zsh tmux plugin further down the file.
#
# Why this exists: three things in this config hang or break a shell that no
# human is watching. Reproduced under `script -q /dev/null` (a real pty, which
# is what codex and opencode allocate); exit 124 is the timeout firing.
#
#   git show / git diff   exit 124, HANG.  core.pager = delta in ~/.gitconfig:5.
#                         delta spawns its own `less` and does not inherit -F.
#                         Verified that LESS=-FRX does NOT rescue it.
#                         (`git log --oneline` does not hang — short lines let
#                         less exit on its own. show/diff are the real cases.)
#
#   man <anything>        exit 124, HANG.  MANPAGER in .zprofile uses bat as
#                         an interactive pager. Agent mode replaces it with
#                         MANPAGER=cat before a command can block.
#
#   tmux ls               command not found: _zsh_tmux_plugin_run. The oh-my-zsh
#                         tmux plugin's alias survives a captured shell snapshot;
#                         the function backing it does not.
#
# Detection cannot key off `[[ ! -t 1 ]]` alone. That is true for Claude Code's
# pipe-based Bash tool (which does NOT hang) and FALSE under a pty harness
# (which does). A non-TTY always gets safe behavior. Within a TTY,
# ZSH_AGENT_MODE is tri-state: 1 means agent, 0 means human, and an unset or
# invalid value falls back to agent-marker detection. A human 0 remains visible
# in this shell but is deliberately not exported, so a bare agent child can
# still identify itself with a real marker.

typeset _zsh_agent_guard=0
typeset _zsh_agent_stdout_tty=0
if [[ ${ZSH_AGENT_MODE:-} == 0 ]]; then
  typeset +x ZSH_AGENT_MODE
fi

if [[ -t 1 ]]; then
  _zsh_agent_stdout_tty=1
elif (( ${+__p9k_instant_prompt_active} && ${+__p9k_fd_1} )) \
     && [[ -t $__p9k_fd_1 ]]; then
  # Powerlevel10k instant prompt saves the pane's real stdout descriptor, then
  # redirects fd 1 to a cache file until the first prompt is ready. Classify
  # against that saved descriptor so a real tmux pane stays human while a
  # genuinely captured shell remains pager-safe.
  _zsh_agent_stdout_tty=1
fi

if (( ! _zsh_agent_stdout_tty )); then
  _zsh_agent_guard=1
else
  case ${ZSH_AGENT_MODE:-} in
    1)
      _zsh_agent_guard=1
      ;;
    0)
      ;;
    *)
      if [[ -n ${CLAUDECODE:-} || -n ${CI:-} \
            || -n ${CODEX_SANDBOX:-} || -n ${CURSOR_AGENT:-} \
            || -n ${OPENCODE:-} ]]; then
        _zsh_agent_guard=1
      fi
      ;;
  esac
fi

if (( _zsh_agent_guard )); then

  export PAGER=cat
  export MANPAGER=cat
  export GIT_PAGER=cat
  export DELTA_PAGER=cat
  export LESS=-FRX

  # batpipe is a less preprocessor. Nothing should be preprocessing output
  # that no human is reading.
  unset LESSOPEN LESSCLOSE BATPIPE

  # p10k's instant-prompt warnings land in captured stdout otherwise.
  export POWERLEVEL9K_INSTANT_PROMPT=quiet

  # correct_all prompts [nyae] against 585 aliases with nobody there to answer.
  unsetopt correct correct_all 2>/dev/null

  # bat/eza are not flag-compatible with cat/ls (verified: `cat -v` fails), and
  # the tmux alias points at a function that will not exist.
  unalias tmux cat ls 2>/dev/null

  # Agents should get the real tool, not a wrapper that opens an editor.
  unalias v vim 2>/dev/null

  # yazi (35-yazi.zsh's `y` wrapper) is a full-screen TUI - exactly the class
  # of thing that hangs a shell no human is watching, same reasoning as the
  # git/man cases documented above. Unset so it fails fast with "command not
  # found" instead of blocking until timeout.
  unset -f y 2>/dev/null

else

  # A non-login human shell may inherit pager exports from a former agent
  # parent, so restore the complete interactive state here as well as in
  # .zprofile.
  export PAGER=less
  export MANPAGER="sh -c 'col -bx | bat --theme=default -l man --style=plain --color=always --paging=auto'"
  unset GIT_PAGER DELTA_PAGER

  # batpipe: teaches `less` to syntax-highlight, and to open directories and
  # archives (*.tar, *.tar.gz, *.zip, *.jar, *.gz, *.xz). Costs ~40ms per
  # interactive shell. The eval is regenerated each start on purpose: batpipe
  # emits a Cellar-versioned path that a static copy would outlive.
  eval "$(batpipe)"
  export LESS=-R

fi
unset _zsh_agent_guard _zsh_agent_stdout_tty

# deagent clears a stuck agent marker and reloads a login shell. If this pane's
# session inherited ZSH_AGENT_MODE=1 from an older tmux server, a session-local
# zero prevents the server-wide value from coming back into the new shell. The
# new login shell consumes the explicit zero and removes its export attribute.
deagent() {
  local session
  session=$(command tmux display-message -p '#{session_name}' 2>/dev/null) || session=
  if [[ -n $session ]]; then
    command tmux set-environment -t "$session" ZSH_AGENT_MODE=0 2>/dev/null || true
  fi
  unset CLAUDECODE CI CODEX_SANDBOX CURSOR_AGENT OPENCODE
  export ZSH_AGENT_MODE=0
  exec zsh -l
}
