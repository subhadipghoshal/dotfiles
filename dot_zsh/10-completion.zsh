# 10-completion.zsh — completion behaviour and fzf-tab.
#
# Loaded after oh-my-zsh, so every zstyle here overrides the ones oh-my-zsh set
# in lib/completion.zsh. compinit has already run by this point (oh-my-zsh.sh
# line 129, well before it sources plugins at line 205), which is also why
# fzf-tab can live in the plugins=() array at all.

# ── Presentation ──────────────────────────────────────────────────────────
# Group results by what they ARE (branch / tag / file / builtin) with a header
# per group, instead of one undifferentiated wall of candidates.
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}── %d ──%f'
zstyle ':completion:*:messages'     format '%F{blue}── %d ──%f'
zstyle ':completion:*:warnings'     format '%F{red}── no matches ──%f'
zstyle ':completion:*:corrections'  format '%F{green}── %d (errors: %e) ──%f'

# Colour file candidates the same way ls does.
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# ── Matching ──────────────────────────────────────────────────────────────
# _extensions completes `*.go` from `vim *.<TAB>`.
# _approximate only engages after _complete finds nothing, so it costs nothing
# on the common path.
zstyle ':completion:*' completer _complete _extensions _match _approximate
zstyle ':completion:*:approximate:*' max-errors 2 numeric

# Offer --flags without having to type the leading dash first.
zstyle ':completion:*' complete-options true

# Most recently modified file first. In a build/output directory this is almost
# always the one you want.
zstyle ':completion:*' file-sort modification

# Notice newly installed binaries without needing an explicit `rehash`. Costs a
# stat of each PATH entry per completion — with 32 entries that is not
# measurable, and it removes a recurring "I just brew-installed it and tab
# doesn't see it" annoyance.
zstyle ':completion:*' rehash true

# ── fzf-tab ───────────────────────────────────────────────────────────────
# fzf-tab replaces zsh's completion MENU, not its completion engine — so every
# zstyle above still applies, and any completion any plugin defines works
# unchanged. It just renders the candidate list through fzf with a preview.
#
# Required: zsh's own menu selection must be off or the two fight over the
# keymap. oh-my-zsh sets `menu select` under the 5-colon pattern, which is more
# specific than ':completion:*', so it has to be overridden at the same depth.
zstyle ':completion:*:*:*:*:*' menu no

zstyle ':fzf-tab:*' fzf-flags --height=60% --layout=reverse --border --cycle
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' single-group color header

# Directories: list contents.
zstyle ':fzf-tab:complete:(cd|z|zi|pushd|rmdir):*' \
  fzf-preview 'eza -1 --icons --color=always $realpath 2>/dev/null || ls -1 $realpath'

# Files going into an editor or pager: show the file.
zstyle ':fzf-tab:complete:(nvim|vim|v|bat|cat|pcat|copycat|less|head|tail):*' \
  fzf-preview 'bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null \
               || eza -1 --icons --color=always $realpath 2>/dev/null'

# Git refs: show what the commit actually is before you check it out.
zstyle ':fzf-tab:complete:git-(checkout|switch|rebase|merge|log|show|diff|cherry-pick):*' \
  fzf-preview 'git log --color=always --oneline --graph --decorate -20 $word 2>/dev/null'

# Kubernetes: describe the resource under the cursor.
zstyle ':fzf-tab:complete:(kubectl|k|helm):*' \
  fzf-preview 'kubectl describe $word 2>/dev/null | head -40'

# Which process am I about to kill.
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' \
  fzf-preview 'ps -p $word -o pid=,user=,%cpu=,%mem=,comm=,args= 2>/dev/null'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:4:wrap

# Environment variables: show the value.
zstyle ':fzf-tab:complete:(export|unset|printenv|echo):parameter' \
  fzf-preview 'echo ${(P)word}'

# ── Command-specific ──────────────────────────────────────────────────────
# Allow `docker run -it` style stacked short flags to complete.
zstyle ':completion:*:*:docker:*'   option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes
