# 40-man.zsh — read PARTS of a man page instead of the whole thing.
#
# `man` is used 36 times in this history, and the problem with it is never
# finding the page — it is that `man git-rebase` is 1,300+ lines and you wanted
# 8 of them. These four functions all emit a bounded chunk, which also happens
# to be exactly what makes a man page usable as agent context rather than
# something that blows a context window.
#
# Verified against both man-page dialects present on macOS: groff-formatted
# pages (git-*, fd, curl) and BSD mdoc pages (ls, tar, ssh, rsync). Section
# headers sit at column 0 in both, which is what all of this keys off.

# Render a page to plain text. MANPAGER=cat bypasses the bat pager configured
# in .zprofile — that one blocks forever when nothing is attached to read it.
_man_render() {
  MANPAGER=cat MANWIDTH=${MANWIDTH:-100} man "$@" 2>/dev/null | col -bx
}

# mh <page>            list a page's section headers (with line numbers), so
#                      you know what to hand to manx.
#   $ mh git-rebase
#     3:NAME  6:SYNOPSIS  13:DESCRIPTION  157:MODE OPTIONS  187:OPTIONS ...
mh() {
  emulate -L zsh
  [[ -n $1 ]] || { print -u2 "usage: mh <page> [section]"; return 1 }
  _man_render "$@" | grep -nE '^[A-Z][A-Z0-9 _-]+$'
}

# manx <page> <SECTION>   print exactly one section.
#   $ manx rsync EXAMPLES        -> 32 lines instead of the whole page
#   $ manx git-rebase 'MODE OPTIONS'
manx() {
  emulate -L zsh
  [[ -n $2 ]] || { print -u2 "usage: manx <page> <SECTION>"; return 1 }
  _man_render "$1" | awk -v s="${(U)2}" '
    BEGIN { f = 0 }
    toupper($0) ~ "^" s "$" { f = 1; next }
    /^[A-Z][A-Z0-9 _-]+$/   { f = 0 }
    f'
}

# mopt <page> <flag>      print just that one flag's paragraph.
#   $ mopt tar -z
#   $ mopt git-rebase --autosquash
#   $ mopt fd --changed-within
#
# Searched inside OPTIONS first, because several pages (curl is the reproducible
# case) mention a flag mid-prose in DESCRIPTION before defining it, and a naive
# whole-page scan returns the prose. Falls back to the whole page for the BSD
# style that documents flags under DESCRIPTION instead (ls, tar).
mopt() {
  emulate -L zsh
  [[ -n $2 ]] || { print -u2 "usage: mopt <page> <flag>"; return 1 }

  local -a scopes=(OPTIONS 'MODE OPTIONS' DESCRIPTION)
  local scope body out
  for scope in $scopes; do
    body=$(manx "$1" "$scope")
    [[ -z $body ]] && continue
    out=$(print -r -- "$body" | _mopt_scan "$2")
    [[ -n $out ]] && { print -r -- "$out"; return 0 }
  done

  # Nothing in any named section — scan the whole page.
  out=$(_man_render "$1" | _mopt_scan "$2")
  [[ -n $out ]] && { print -r -- "$out"; return 0 }

  print -u2 "mopt: '$2' not found in $1(1). Try: mh $1"
  return 1
}

# Print the block starting at `flag` and ending when indentation returns to the
# same level or less.
#
# Two rules keep this honest:
#   1. The flag must appear in the line's LEADING FLAG LIST — the part before
#      the first run of two spaces, which is where man pages put the
#      description. That allows `-R, -r, --recursive` (BSD grep) to be found by
#      any of its three spellings, while still refusing to let `--delete` match
#      `--delete-before`, since the character after the flag must be a
#      delimiter.
#   2. When several lines qualify, the LEAST-INDENTED one wins. A real flag
#      definition sits at the section's base indent; a mention of the same flag
#      inside another flag's prose sits deeper. curl is the reproducible case:
#         indent=14  --retry is used then curl retries on some HTTP response...
#         indent=7   --retry <num>
#      Rule 1 alone returned the first; rule 2 returns the definition.
_mopt_scan() {
  awk -v flag="$1" '
    {
      L[NR] = $0
      line = $0; sub(/^[ \t]*/, "", line)
      ind = match($0, /[^ ]/) - 1
      I[NR] = ind

      head = line
      if (match(head, /  /)) head = substr(head, 1, RSTART - 1)

      if (head ~ "(^|[,[:space:]])" flag "([,=[:space:][]|$)")
        if (best == "" || ind < bi) { best = NR; bi = ind }
    }
    END {
      if (best == "") exit 1
      print L[best]
      for (i = best + 1; i <= NR; i++) {
        if (L[i] ~ /[^ ]/ && I[i] <= bi) break
        print L[i]
      }
    }
  '
}

# mans                 fzf over all 17,788 apropos entries, section-aware —
#                      this is how you tell printf(1) from printf(3).
mans() {
  emulate -L zsh
  local sel page sect
  sel=$(man -k . 2>/dev/null \
        | fzf --prompt='man> ' \
              --preview-window='right,65%' \
              --preview 'echo {} | sed -E "s/^([^ ,(]+)\(([0-9n])\).*/\2 \1/" | xargs man 2>/dev/null | col -bx') \
    || return
  [[ -n $sel ]] || return
  page=${sel%%[,( ]*}
  sect=${${(M)sel%%\(([0-9n])\)*}//[^0-9n]/}
  man ${sect:+$sect} -- "$page"
}
