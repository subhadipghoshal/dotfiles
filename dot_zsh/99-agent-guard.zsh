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
#   man <anything>        exit 124, HANG.  MANPAGER in .zprofile uses
#                         `bat --paging=always`. Verified that switching to
#                         --paging=auto does NOT fix it: bat sees the pty as a
#                         terminal and pages regardless. Only PAGER=cat works.
#
#   tmux ls               command not found: _zsh_tmux_plugin_run. The oh-my-zsh
#                         tmux plugin's alias survives a captured shell snapshot;
#                         the function backing it does not.
#
# Detection cannot key off `[[ ! -t 1 ]]` alone. That is true for Claude Code's
# pipe-based Bash tool (which does NOT hang) and FALSE under a pty harness
# (which does). So both conditions are tested. CLAUDECODE is the real variable
# name — not CLAUDE_CODE.

if [[ ! -t 1 || -n ${CLAUDECODE:-} || -n ${CI:-} || -n ${CODEX_SANDBOX:-} \
      || -n ${CURSOR_AGENT:-} || -n ${OPENCODE:-} || -n ${ZSH_AGENT_MODE:-} ]]; then

  export PAGER=cat
  export MANPAGER=cat
  export GIT_PAGER=cat
  export DELTA_PAGER=cat
  export LESS=-FRX

  # p10k's instant-prompt warnings land in captured stdout otherwise.
  export POWERLEVEL9K_INSTANT_PROMPT=quiet

  # correct_all prompts [nyae] against 585 aliases with nobody there to answer.
  unsetopt correct correct_all 2>/dev/null

  # bat/eza are not flag-compatible with cat/ls (verified: `cat -v` fails), and
  # the tmux alias points at a function that will not exist.
  unalias tmux cat ls 2>/dev/null

  # Agents should get the real tool, not a wrapper that opens an editor.
  unalias v vim 2>/dev/null

  export ZSH_AGENT_MODE=1
fi
