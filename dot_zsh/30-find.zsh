# 30-find.zsh — finding files and finding text in files.
#
# History shows rg 44 uses, grep 38, fd 19, find 5 — the tools are already
# installed and already reached for. What was missing was the fzf layer that
# turns "list of matches" into "jump straight to the line".
#
# Every function here passes an explicit --preview, so none of them depend on
# what FZF_DEFAULT_OPTS happens to contain.

# f [pattern]   fuzzy-pick a file; prints the path.
#               Composable:  nvim "$(f)"   ·   cp "$(f)" /tmp
f() {
  emulate -L zsh
  fd --type f --hidden --follow --exclude .git --color=always "$@" 2>/dev/null \
    | fzf --ansi \
          --prompt='file> ' \
          --preview 'bat --color=always --style=numbers --line-range=:300 {}' \
          --preview-window='right,60%'
}

# fd_ / fdir [pattern]   same, for directories; prints the path.
fdir() {
  emulate -L zsh
  fd --type d --hidden --follow --exclude .git --color=always "$@" 2>/dev/null \
    | fzf --ansi \
          --prompt='dir> ' \
          --preview 'eza -1 --icons --color=always {}' \
          --preview-window='right,50%'
}

# fe [pattern]   pick a file and open it in $EDITOR.
fe() {
  emulate -L zsh
  local file
  file=$(f "$@") || return
  [[ -n $file ]] && ${EDITOR:-nvim} -- "$file"
}

# fcd [pattern]  pick a directory and cd into it.
# (zoxide's `zi` covers frecent directories; this covers "somewhere under here".)
fcd() {
  emulate -L zsh
  local dir
  dir=$(fdir "$@") || return
  [[ -n $dir ]] && cd -- "$dir"
}

# s [pattern]    live ripgrep across the tree. Every keystroke re-runs rg; the
#                preview scrolls to the hit; Enter opens nvim on that exact
#                line. This is the one to reach for instead of `rg foo | less`.
#
#                --disabled makes fzf stop doing its own fuzzy filtering, so
#                the query goes to ripgrep instead and you get real regex.
s() {
  emulate -L zsh
  local rg_cmd='rg --column --line-number --no-heading --color=always --smart-case --hidden --glob !.git'
  local initial=${1:-}

  FZF_DEFAULT_COMMAND="$rg_cmd -- ${(q)initial}" \
  fzf --ansi --disabled --query="$initial" \
      --prompt='rg> ' \
      --delimiter=: \
      --bind "change:reload:$rg_cmd -- {q} || true" \
      --bind 'enter:become(nvim {1} +{2})' \
      --bind 'ctrl-o:execute(nvim {1} +{2} < /dev/tty > /dev/tty)' \
      --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
      --preview-window 'right,60%,+{2}+3/3' \
      --header 'enter: open in nvim · ctrl-o: open and come back'
}
