# 65-adhd.zsh — toggle opt-in "ADHD mode" flags across the agent harnesses.
#
# adhd-on / adhd-off create or remove each harness's .i-have-adhd-always
# marker (claude, codex, gemini, opencode); `adhd` prints who is on.

typeset -a _adhd_flags=(
  "claude:$HOME/.claude/.i-have-adhd-always"
  "codex:$HOME/.codex/.i-have-adhd-always"
  "gemini:$HOME/.gemini/.i-have-adhd-always"
  "opencode:${XDG_CONFIG_HOME:-$HOME/.config}/opencode/.i-have-adhd-always"
)

adhd-on() {
  emulate -L zsh
  local f
  for f in $_adhd_flags; do
    mkdir -p -- "${${f#*:}:h}" || return
    touch "${f#*:}" || return
  done
}

adhd-off() {
  emulate -L zsh
  local f
  for f in $_adhd_flags; do
    command rm -f -- "${f#*:}"
  done
}

adhd() {
  emulate -L zsh
  local f
  for f in $_adhd_flags; do
    print -r -- "${f%%:*}: $([[ -f ${f#*:} ]] && print on || print off)"
  done
}
