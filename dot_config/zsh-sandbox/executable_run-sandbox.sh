#!/usr/bin/env bash
# Launch an isolated zsh using this directory as ZDOTDIR.
#
# Same idea as ~/.config/tmux/run-sandbox.sh: edit and test here freely, with
# zero risk to the live shell. Nothing in this directory is read by a normal
# login shell — zsh only looks here because ZDOTDIR points at it.
#
# Usage:
#   ./run-sandbox.sh              interactive login shell in the sandbox
#   ./run-sandbox.sh -c '<cmd>'   run one command in the sandbox, non-interactive
#   ./run-sandbox.sh --time       measure sandbox startup (median of 10)
#
# What is isolated:
#   .zshenv / .zprofile / .zshrc   this directory's copies, not ~/
#   .zsh/*.zsh                     this directory's modules (via ${ZDOTDIR}/.zsh)
#   compdump                       sandbox-local, so it can't trigger the
#                                  delete/rebuild loop against the real one
#
# What is SHARED with the live shell (deliberately — these are the real thing):
#   ~/.oh-my-zsh, ~/.p10k.zsh, ~/.zsh_history, ~/.cache/gitstatus
set -euo pipefail

SB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export ZDOTDIR="$SB"
export ZSH_COMPDUMP="$SB/.zcompdump-sandbox"
export ZSH_SANDBOX=1

case "${1:-}" in
  --time)
    for _ in $(seq 10); do
      /usr/bin/time -p script -q /dev/null zsh -l -i -c exit
    done 2>&1 \
      | awk '/real/{print $2}' | sort -n \
      | awk '{a[NR]=$1} END{printf "sandbox startup median: %.3fs (n=%d)\n", a[int(NR/2)+1], NR}'
    ;;
  -c)
    shift
    exec zsh -l -i -c "$@"
    ;;
  *)
    echo "── zsh sandbox: ZDOTDIR=$SB ── (exit to leave) ──"
    exec zsh -l -i
    ;;
esac
