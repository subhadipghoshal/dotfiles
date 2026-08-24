#!/usr/bin/env bash
# Launch this config on its own isolated tmux server (separate socket), so it
# never touches your real sessions. Safe to run any time, even with your
# normal tmux already up.
#
# Kill the sandbox server entirely with:
#   tmux -L tmux-sandbox kill-server
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec command tmux -L tmux-sandbox -f "$DIR/tmux.conf" new-session -A -s sandbox
