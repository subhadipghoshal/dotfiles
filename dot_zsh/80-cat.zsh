# 80-cat.zsh — bat wrappers. Replaces the old ~/.zsh/zsh_cat.
#
# Unchanged in behaviour for copycat/pcat, with one cleanup: the hardcoded
# /opt/homebrew/bin/bat paths are now a single variable (so this survives a
# Homebrew prefix change). jsoncat now delegates to prettybat (bat-extras)
# instead of hand-rolling jq | bat.

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

# Pretty-print JSON from files, from stdin, or from a command's output.
# Formatting and highlighting are prettybat's job now (yq backs the JSON and
# YAML formatters). The command-evaluating branch stays, because prettybat
# reads files and stdin but has no notion of "run this and format the result".
jsoncat() {
  emulate -L zsh
  if (( $# == 0 )); then
    prettybat --language=json
    return
  fi
  local arg
  for arg in "$@"; do
    if [[ -f $arg ]]; then
      prettybat --language=json "$arg"
    else
      # Not a file: treat it as a command whose output is JSON.
      eval "$arg" | prettybat --language=json
    fi
  done
}
