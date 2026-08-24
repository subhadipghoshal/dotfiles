#!/usr/bin/env bash
# Copy stdin to the clipboard.
#   - local pane on macOS: pbcopy
#   - remote pane over SSH: emit an OSC 52 escape sequence so the *local*
#     terminal's clipboard is set, even though this script runs on the remote box
set -euo pipefail

if [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ]; then
  data=$(cat | base64 | tr -d '\n')
  printf '\033]52;c;%s\a' "$data" > "$(tty)"
else
  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy
  else
    cat > /dev/null
  fi
fi
