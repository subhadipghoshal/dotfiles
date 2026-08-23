# 00-options.zsh — shell behaviour. No functions, no aliases, no plugins.
# Loaded first, so everything after can assume these are in effect.

# ── History ───────────────────────────────────────────────────────────────
# SAVEHIST was never set, so oh-my-zsh's default of 10000 was silently winning
# (lib/history.zsh:40) despite HISTSIZE being 1000000000. The file was at
# 6,882/10,000 entries — about six weeks from truncating.
#
# HISTSIZE is the in-memory list, SAVEHIST is what reaches disk. Keeping them
# equal avoids the surprise where a session drops history it appeared to have.
# The old HISTFILESIZE line is gone entirely: that is a *bash* variable and
# zsh never read it.
HISTSIZE=1000000
SAVEHIST=1000000

setopt HIST_FIND_NO_DUPS      # don't offer the same line twice while searching
setopt HIST_REDUCE_BLANKS     # tidy whitespace before storing
setopt HIST_IGNORE_SPACE      # leading space keeps a command out of history
setopt HIST_VERIFY            # expand !! onto the line instead of running it
# INC_APPEND_HISTORY deliberately not set: oh-my-zsh already sets share_history,
# which implies it. Setting both is redundant, not additive.

# ── Key timing ────────────────────────────────────────────────────────────
# Unset means 40, i.e. 400ms. In viins, ESC (^[) is both a complete binding
# (vi-cmd-mode) AND the prefix of 23 other sequences, so zsh must wait the full
# timeout before it can commit. That wait is the "vi mode feels laggy" symptom:
# it was paid on every single mode switch.
#
# 2 (20ms) is safe here. Sequences like `ci"` and `gg` are unaffected — `i`/`a`
# are undefined-key in viopp and `g` is undefined-key in vicmd, which makes them
# pure prefixes that wait indefinitely regardless of KEYTIMEOUT. The only real
# cost is that `cs"'` / `ds"` / `ys` must be typed as a quick digraph, exactly
# like vim's own timeoutlen behaves.
KEYTIMEOUT=2

# ── Misc ──────────────────────────────────────────────────────────────────
# zsh already tracks the tty in $TTY. `$(tty)` forked a process every startup
# to compute the identical string. Guarded because $TTY is empty when there is
# no terminal, and an empty GPG_TTY is worse than an unset one — gpg-agent
# treats it as a real (broken) tty path.
[[ -n $TTY ]] && export GPG_TTY=$TTY
