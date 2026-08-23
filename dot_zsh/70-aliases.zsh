# 70-aliases.zsh — replaces the old ~/.zsh/zsh_aliases.

# `cat` and `ls` are replaced wholesale by bat and eza. These are only
# flag-compatible by coincidence — verified: `cat -v` fails outright, while
# `cat -A`, `cat -n`, `ls -1` and `ls --color=never` happen to work. Anything
# that sources this profile inherits the substitution, which is why
# 99-agent-guard.zsh unaliases both for non-interactive and agent shells.
alias cat=bat
alias ls="eza --icons=always"
alias v=vim
alias vim=nvim

alias krr="kubectl rollout restart"

# `lsa` (917 uses, the most-typed command here) is NOT defined in this file.
# It comes from oh-my-zsh's lib/directories.zsh as `lsa='ls -lah'`, which then
# chains through the `ls` alias above into `eza --icons=always -lah`. Defining
# it explicitly so it stops depending on that chain:
alias lsa='eza --icons=always -lah'

# Faster than `omz reload` (92 uses), which deletes the compdump every time it
# runs (lib/cli.zsh) and forces a full rebuild.
alias omzr='exec zsh'

safe_clean() {
  # This function had TWO bugs, either of which broke the shell permanently.
  #
  # 1. `set -euo pipefail` is NOT function-local in zsh — it leaked into the
  #    interactive shell and stayed. Verified: before, errexit=off nounset=off
  #    pipefail=off; after, all three on for the rest of the session. With
  #    nounset on, any unset-parameter reference becomes a hard error, breaking
  #    p10k, completion and most plugins.
  #
  # 2. The loop was `for path in "${SAFE_PATHS[@]}"`. In zsh `path` is the
  #    special array tied to $PATH, so each iteration overwrote it — leaving
  #    PATH set to the last element. Verified in a clean `zsh -f`:
  #        PATH before: /usr/bin:/bin:/usr/sbin
  #        PATH after:  /tmp
  #    After one `tempclean`, no command outside /tmp resolved any more.
  #
  # `emulate -L zsh` scopes options to this function; they revert on return.
  # The loop variable is now `path_`, and local, so it cannot touch PATH.
  #
  # errexit/nounset/pipefail are deliberately NOT re-enabled here, even scoped.
  # They were wrong for this function in the first place: ~/Library/Caches
  # contains TCC-protected subdirectories, so `du -sh path/* | sort -h | tail`
  # legitimately returns non-zero, and under errexit+pipefail that terminated
  # the whole shell on a plain `safe_clean dry`. Every failure mode that
  # actually matters here is checked explicitly below.
  emulate -L zsh

  local MODE="${1:-dry}"
  local -a SAFE_PATHS=(
    "$HOME/Library/Caches"
    "$HOME/Library/Logs"
    /private/var/folders
    /tmp
  )

  print "🔍 Safe Temp Cleanup Utility (macOS)"
  print -- "-----------------------------------"
  print "Mode: $MODE"
  print

  local path_
  for path_ in "${SAFE_PATHS[@]}"; do
    if [[ ! -d $path_ ]]; then
      print "⚠️  Skipping missing: $path_"
      continue
    fi

    print "📂 Target: $path_"

    case $MODE in
      dry)
        print "→ Dry run preview:"
        du -sh "$path_"/* 2>/dev/null | sort -h | tail -10 || true
        print
        ;;
      trash)
        print "→ Moving contents to Trash..."
        mv "$path_"/* ~/.Trash/ 2>/dev/null || true
        print "✔ Trashed $path_"
        ;;
      delete)
        print "🚨 PERMANENT DELETE MODE 🚨"
        local confirm
        read -r "confirm?Type DELETE to confirm: "
        if [[ $confirm == DELETE ]]; then
          rm -rf "$path_"/* || true
          print "✔ Permanently deleted $path_"
        else
          print "❌ Skipped $path_"
        fi
        ;;
      *)
        print -u2 "❌ Unknown mode: $MODE"
        return 1
        ;;
    esac
    print
  done

  print "✅ Cleanup complete."
}

alias tempclean='safe_clean trash'

loadenv() {
  emulate -L zsh
  [[ -f $1 ]] || { print -u2 "No such file: $1"; return 1 }

  local key value
  while IFS='=' read -r key value; do
    [[ $key == \#* || -z $key ]] && continue
    value=${value%\"}
    value=${value#\"}
    export "$key=$value"
  done < "$1"
}

check_port_usage() {
  lsof -n -i :"$1" | grep LISTEN
}
