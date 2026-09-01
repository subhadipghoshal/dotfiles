# 85-bat-extras.zsh — bat-extras as the primary path.
#
# Nothing here touches LESSOPEN. All human/agent divergence stays in
# 99-agent-guard.zsh, which is the only file that gets to know which kind of
# shell this is.

# man -> batman, for whole pages in colour.
#
# This is safe ONLY because of load order, and it is worth stating why. zsh
# expands aliases when a function BODY IS PARSED, not when it is called.
# 40-man.zsh is sourced at position 40, so `man` inside _man_render, mans and
# friends was already bound to the real binary before this line runs. Verified
# in a clean `zsh -f -i`: a function defined before the alias still reached
# /usr/bin/man, while a bare `man` at the prompt hit the alias.
#   Corollary: re-sourcing 40-man.zsh by hand AFTER startup would rebind those
#   functions to batman and break them. Use `omzr` (exec zsh), not `source`.
#
# BAT_THEME overrides the --theme=ansi in bat's config for man pages only.
# Verified honoured: the same page rendered under a pty with BAT_THEME set to
# "Monokai Extended" vs "ansi" produces different output (differing md5).
alias man='BAT_THEME="Monokai Extended" batman'

# sg — search and read. batgrep prints matches as highlighted source with
#      context, which is the job `rg foo | less` used to do badly.
#
# -p (tell less to pre-search the pattern) is gated on PAGER, because batgrep
# hard-errors when it is passed with paging disabled:
#   "[batgrep error]: The -p/--search-pattern option requires a pager, but the
#    pager was explicitly disabled by $BAT_PAGER or the --paging option."
# Agent shells run PAGER=cat (99-agent-guard.zsh:59), so an unconditional -p
# would break sg for exactly the shells that report failures worst.
sg() {
  emulate -L zsh
  [[ -n $1 ]] || { print -u2 "usage: sg <pattern> [path...]"; return 1 }
  local -a pager_opts=()
  [[ ${PAGER:-} == less* ]] && pager_opts=(-p)
  batgrep --smart-case --context=3 $pager_opts "$@"
}

# bd — diff two files, or a file against the git index.
#
# --delta is gated the same way. delta spawns its own less and does not inherit
# -F, which is the documented hang at 99-agent-guard.zsh:11; BATDIFF_USE_DELTA
# as a plain export would reintroduce it in every agent shell.
bd() {
  emulate -L zsh
  local -a delta_opts=()
  [[ ${PAGER:-} == less* ]] && delta_opts=(--delta)
  batdiff $delta_opts "$@"
}

# bw — reprint files as they change. entr is not installed, so this polls.
bw() {
  emulate -L zsh
  [[ -n $1 ]] || { print -u2 "usage: bw <file> [file...]"; return 1 }
  batwatch --file --watcher poll --clear "$@"
}
