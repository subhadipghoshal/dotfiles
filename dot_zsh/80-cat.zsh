# 80-cat.zsh — bat wrappers. Replaces the old ~/.zsh/zsh_cat.
#
# Unchanged in behaviour, with two cleanups: the hardcoded
# /opt/homebrew/bin/bat paths are now a single variable (so this survives a
# Homebrew prefix change), and jsoncat no longer pipes bat through bat.

_BAT=${commands[bat]:-/opt/homebrew/bin/bat}

# Print a file with syntax highlighting AND copy it to the clipboard.
copycat() {
  emulate -L zsh
  [[ -n $1 ]] || { print -u2 "usage: copycat <file>"; return 1 }
  $_BAT --style=plain "$1" | pbcopy
  $_BAT "$1"
}

# Print a file, highlighted, without the frame/line numbers.
pcat() {
  emulate -L zsh
  [[ -n $1 ]] || { print -u2 "usage: pcat <file>"; return 1 }
  $_BAT --style=plain "$1"
}

# Pretty-print JSON — from files, from stdin, or from a command's output.
# The old version piped `bat file | bat -l json`, which highlighted the already
# highlighted output. Now jq does the formatting and bat only colours it.
jsoncat() {
  emulate -L zsh
  if (( $# == 0 )); then
    jq . | $_BAT -l json --style=plain
    return
  fi
  local arg
  for arg in "$@"; do
    if [[ -f $arg ]]; then
      jq . "$arg" | $_BAT -l json --style=plain
    else
      # Not a file: treat it as a command whose output is JSON.
      eval "$arg" | jq . | $_BAT -l json --style=plain
    fi
  done
}
