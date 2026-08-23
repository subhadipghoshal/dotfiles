# 60-vi.zsh — vi mode. Replaces the old ~/.zsh/zsh_vi.
#
# What was deleted from the old file and why:
#
#   All 15 POWERLEVEL9K_VI_* exports. The names were correct, but p10k only
#   declares them when the `vi_mode` SEGMENT is in use, and .p10k.zsh has zero
#   vi_mode references. They rendered nowhere. The real mode indicator is
#   p10k's prompt_char (❯ insert / ❮ normal / V visual / ▶ overwrite), which
#   p10k redraws itself on zle-keymap-select.
#
#   The PROMPT/RPROMPT appends and MODE_INDICATOR vars that used to live in
#   .zshrc are gone for the same reason: p10k rebuilds both from scratch in
#   _p9k_precmd, so appending to them had no effect. (%F{orange} was not a
#   valid zsh color either — it emitted SGR 39, reset-to-default.)
#
# KEYTIMEOUT lives in 00-options.zsh, not here.

# ── Cursor shape per mode ─────────────────────────────────────────────────
# Was: INSERT=0 (blinking block) vs NORMAL=2 (steady block) — the two modes you
# switch between constantly differed only by blink. VISUAL and OPPEND were both
# 4, mutually indistinguishable. Now each mode you actually notice has its own
# unmistakable shape.
#
# Terminal side is already correct: tmux-256color carries Ss/Se, and tmux's
# terminal-features includes cstyle, so DECSCUSR passes through.
VI_MODE_SET_CURSOR=true
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_CURSOR_INSERT=6      # steady bar
VI_MODE_CURSOR_NORMAL=2      # steady block
VI_MODE_CURSOR_VISUAL=2      # steady block
VI_MODE_CURSOR_OPPEND=4      # steady underline

# ── Text objects ──────────────────────────────────────────────────────────
# select-bracketed, select-quoted and surround all ship with zsh 5.9 in
# /usr/share/zsh/5.9/functions/ and were simply never autoloaded — only
# select-quoted was, so `ci"` worked but `ci(`, `da[`, `yi{` silently did
# nothing, and cs/ds/ys did not exist at all.
autoload -Uz select-bracketed select-quoted surround
zle -N select-bracketed
zle -N select-quoted

for _km in viopp visual; do
  for _c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do bindkey -M $_km $_c select-quoted;    done
  for _c in {a,i}${(s..)^:-'()[]{}<>bB'};      do bindkey -M $_km $_c select-bracketed; done
done
unset _km _c

zle -N delete-surround surround
zle -N change-surround surround
zle -N add-surround    surround
bindkey -M vicmd  cs change-surround   # cs"'  swap double quotes for single
bindkey -M vicmd  ds delete-surround   # ds"   strip the quotes
bindkey -M vicmd  ys add-surround      # ysiw" wrap the word
bindkey -M visual S  add-surround

# ── Fixes ─────────────────────────────────────────────────────────────────
# `vv` was bound to edit-command-line, which made it a prefix of `v` — so
# entering visual mode stalled for the full KEYTIMEOUT. With KEYTIMEOUT now at
# 2 that stall would be 20ms rather than 400ms, but there is no reason to keep
# paying it: ^X^E below is the better binding for "edit this in $EDITOR".
bindkey -M vicmd -r 'vv'

# ^X^E in both keymaps. The vi-mode plugin runs `bindkey -v` AFTER oh-my-zsh's
# lib/key-bindings.zsh ran `bindkey -e`, which silently dropped five bindings
# made without an explicit -M: they landed in the `emacs` keymap only and are
# undefined-key in viins. This is one of them.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M viins '^X^E' edit-command-line
bindkey -M vicmd '^X^E' edit-command-line

# magic-space was another casualty of that same `bindkey -v`, which is why
# `!!<space>` and `!$<space>` stopped expanding.
bindkey -M viins ' ' magic-space

# History search that respects what you have already typed. vicmd k/j are
# up/down-line-or-history, which ignores the current buffer.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey -M viins '^P' up-line-or-beginning-search
bindkey -M viins '^N' down-line-or-beginning-search
bindkey -M vicmd 'k'  up-line-or-beginning-search
bindkey -M vicmd 'j'  down-line-or-beginning-search

# There was no redo binding anywhere. Deliberately NOT bound to ^R, which is
# vim's key for it — in a shell ^R is history search, bound in both keymaps by
# fzf (and later by atuin), and that is worth far more than redo. `U` is vim's
# undo-line, which has no real use on a single command line, so it is free.
bindkey -M vicmd 'U' redo
