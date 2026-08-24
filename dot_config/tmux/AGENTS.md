# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Status: promoted, active config

This is a from-scratch, hand-rolled replacement for the old Oh My Tmux!-based setup that
used to live here. It was designed and tested in isolation at `~/.config/tmux-scratch`
(kept around, see "Sandbox testing" below) before being promoted to this, the real path,
on **2026-08-22**. This file documents what was actually built and why, plus what's still
open.

**The previous config (Oh My Tmux! + tmux-themepack + tmux-copycat + tmux-continuum, and
their plugin clones) is fully preserved at `~/.config/tmux.pre-rebuild-backup-2026-08-22`**
if anything here ever needs rolling back - copy `tmux.conf`, `tmux.conf.local`, and
`plugins/` back from there and it's exactly as it was.

## Design philosophy

Everything here is intentionally small and legible over "handled by a framework." Oh My
Tmux! was ~2000 lines nobody had read end to end. Every file below is short enough to read
top to bottom. Native tmux features (display-popup, copy-mode regex search, resize/zoom)
are used in place of plugins wherever tmux ≥3.2 already does the job; TPM is kept only
because its install/update/uninstall hotkeys are explicitly wanted, and only one plugin is
actually declared through it.

## Layout

```
tmux.conf                   entrypoint - sources everything else, nothing else lives here
conf/options.conf            terminal/rendering, indexing, window naming, copy-mode/clipboard opts
conf/bindings.conf           prefix, splits, resize, window nav, nested-tmux passthrough,
                              sessionizer, session switcher, popups, extras, cheat sheet
conf/status.conf             hand-written powerline-style status line (no theme plugin)
conf/plugins.conf            TPM + the one plugin kept (vim-tmux-navigator)
scripts/sessionizer.sh       fzf project picker -> creates/attaches a session per project
scripts/session-switcher.sh  fzf list of already-open sessions -> switch to one
scripts/open-url.sh          fzf-pick a URL out of pane scrollback -> open it
scripts/clip.sh              copy-mode yank target: pbcopy locally, OSC 52 over ssh
CHEATSHEET.txt               plain-text reference for every binding defined here (prefix + h)
plugins/                     TPM + vim-tmux-navigator (fresh clones - the old themepack/
                              copycat/continuum/catppuccin clones stayed in the backup dir)
run-sandbox.sh                launches this config on an isolated tmux server (see below)
```

## Sandbox testing

`./run-sandbox.sh` starts tmux with `-L tmux-sandbox` (a separate server/socket) and
`-f tmux.conf`, so it's a fully isolated server — it cannot see or touch your real
sessions on the default socket. Safe to run anytime, including while your normal tmux is
up. Kill it entirely with `tmux -L tmux-sandbox kill-server`. Use this for any future
change here too: edit, test in isolation, `prefix + r` (or a fresh `tmux source-file
~/.config/tmux/tmux.conf`) to load it live once you're happy - no separate staging copy
needed anymore now that this *is* the real path.

`~/.config/tmux-scratch` (where this was built and validated before promotion) still
exists as-is - historical record of the design process, safe to delete whenever, not
kept in sync with this directory going forward.

This is also how the config was verified while building it: an isolated `-L` server plus
`list-keys`, `show-messages`, `capture-pane`, `display-message -p` (to render format
strings like a real status line - see the comma gotcha below), and occasionally a real
PTY-attached client, to check for load errors and confirm bindings/rendering without a
human at a terminal. Two real gaps in this approach, both hit and worked around while
building - see "Things discovered while building."

## Prefix key: `C-a`

Not the default `C-b` (which is what the old Oh My Tmux! setup actually ran with -
unchanged from stock, never customized). `C-Space` was tried first for the rebuild (avoids
shadowing readline's beginning-of-line, unlike `C-a`) but turned out to be intercepted by
macOS's system-wide "select previous input source" shortcut before it ever reached the
terminal - the keystroke never made it to tmux at all. `C-a` doesn't have that OS-level
collision, and its cost (shadowing readline's beginning-of-line, and Neovim's `Ctrl-a`
increment-number in normal mode) is a well-understood, learnable one: double-tapping it
(`C-a a`) sends one literal prefix keystroke through to whatever's running in the pane - a
nested/remote tmux, or just the shell/program that wanted the raw keystroke - same
mechanism `C-b C-b` gives you by default, tmux sets it up automatically whenever you
change `prefix`.

**Note on the promotion itself:** flipping this live via `source-file`/`prefix + r`
changes the prefix (and everything else) for every session already running on the default
server at once, not just new ones - worth doing at a moment you're not mid-task in one of
those sessions.

## Key bindings — see CHEATSHEET.txt for the full list

`prefix + h` opens a popup with a curated, human-readable list of every binding defined in
this config (organized by category, plain-English descriptions). It's `CHEATSHEET.txt` at
the root of this directory, rendered through `less` - a **plain static file, not
generated**, so it will drift if you add a binding to `conf/bindings.conf` without also
updating it by hand. `prefix + ?` is left as tmux's own default (raw, unfiltered
`list-keys` dump of everything, including tmux's own bindings and any plugin's) precisely
so that escape hatch still exists.

Highlights not obvious from the key alone:

- `prefix + f` / `prefix + s` are a pair: `f` fuzzy-jumps to a *project*, creating its
  session if it doesn't exist yet (via `sessionizer.sh`); `s` fuzzy-picks among sessions
  that are *already open* (via `session-switcher.sh`, and **overrides** tmux's default
  `prefix + s` choose-session tree view to match).
- `prefix + b` toggles broadcast/sync-panes (same keystrokes to every pane in the window -
  useful for running one command across several ssh panes at once). Status bar shows a
  `SYNC` flag while active, same visual pattern as the `PASSTHROUGH`/`COPY` flags.
- `prefix + o` pops up an fzf picker over URLs found in the current pane's scrollback and
  opens the selection - a full-screen, mouse-light workflow doesn't get click-to-open.
- `prefix + T` hides/shows the status bar entirely (more vertical space on demand).
  `prefix + t` (lowercase) is a different toggle - flips the bar between top/bottom for
  the running session only, for a quick live A/B; the persistent default lives in
  `conf/status.conf`'s `status-position` line.
- `prefix + X` kills the whole session with confirmation, mirroring the default
  `prefix + x` for kill-pane - useful once the sessionizer accumulates sessions.
- `Alt+1`-`9` and `Alt+h`/`Alt+l` jump/cycle windows with **no prefix at all**, mirroring
  the `Ctrl-h/j/k/l` you already use for panes (Ctrl = panes, Alt = windows). Requires your
  terminal to send Option/Alt as a Meta key (iTerm2: Profiles → Keys → Option Key sends
  Esc+; Terminal.app: Preferences → Profiles → Keyboard) - harmless if that's off, they
  just won't fire until it's on.

## Design decisions

- **Sessionizer over resurrect/continuum.** `prefix + f` opens a popup, fzf over
  `SESSIONIZER_DIRS` (edit the variable at the top of `sessionizer.sh` — currently
  `~/Experiments ~/Practice ~/reference ~/Soft ~/interview ~/Stuff ~/.config`, set from
  your actual project layout at promotion time - add/remove freely, it's just a
  space-separated list), creates a session named after the directory if one doesn't exist,
  switches to it. Sessions are cheap and reproducible instead of serialized/restored -
  simpler mental model, nothing "magic" to debug when it doesn't restore right.
- **SSH-aware, not SSH-blind.** `pane_current_command == ssh` recolors the hostname
  status segment red, so it's visually obvious when a pane is on a remote box. `F12`
  toggles a "passthrough" mode (dims the status bar, disables the outer prefix) for
  extended work inside a nested tmux; a bare double-prefix-tap (`C-a a`) already passes
  one keystroke through by tmux default, no config needed for the common case.
- **OSC 52 clipboard.** `set-clipboard on` handles most terminal/copy-mode cases
  automatically; `clip.sh` (bound to `y` in copy-mode-vi) is the explicit fallback that
  crafts the OSC 52 sequence by hand when on a remote pane, so copies land in your local
  macOS clipboard even from a box you SSHed into.
- **Popups instead of extra panes.** `prefix + g` = lazygit, `prefix + Space` = scratch
  session, `prefix + o` = URL picker, `prefix + s` / `prefix + f` = fzf pickers, `prefix +
  h` = cheat sheet - all `display-popup -E` overlays so they don't disturb your pane
  layout.
- **Status line: same color/segment structure as the old powerline/double/cyan theme,
  arrow separators back on top by explicit request.** Reverse-engineered the real theme's
  colors and layout by reading `tmux-themepack`'s `powerline/double/cyan.tmuxtheme` source
  directly (confirmed with a real PTY-attached client, see "Things discovered" below):
  status-left is session name → whoami → window:pane; status-right is time → date →
  hostname, each block bolder toward the outer edge, current window highlighted in
  black/cyan. The theme itself turned out to use **flat, directly-adjacent color blocks
  with zero separator glyphs** (no Nerd/Powerline font dependency) - that was tried first
  for fidelity, but the arrow/triangle look was specifically wanted back, so `conf/
  status.conf` now has both: the real theme's colors and segments, with powerline arrows
  reintroduced at every block boundary (font dependency is back too - same tradeoff the
  old theme actually had, since oh-my-tmux's separator variables were never actually
  reaching tmux-themepack's flat output before). `status-position` was tried at `top`
  first (keeps the bar visually separate from Neovim's own statusline+cmdline, which
  already own the bottom two rows of a pane) but turned out to actually be preferred at
  `bottom` in practice, so that's the current default - it's a single clearly-commented
  line in `conf/status.conf` to flip back, and `prefix + t` toggles it live for the
  running session (doesn't persist across reload - that line is still what a fresh
  attach starts from). `status-justify absolute-centre` is this rebuild's own choice too.
  The PASSTHROUGH/COPY/SYNC mode flags
  and the SSH-aware hostname segment (flips red over `ssh`) are also this rebuild's own
  additions, arrow-bounded like everything else, except each flag itself stays a flat
  block with no leading arrow - reads as an interruption/alert rather than a permanent
  part of the flow.
- **Window titles carry real status, not just the process name.** `allow-rename on` (the
  old config had this off) lets programs push a descriptive title via terminal escape
  sequences; `automatic-rename on` still falls back to the plain process name for
  anything that doesn't. This is what lets a window show "file.lua (~/project)" instead
  of just "nvim" - **but it depends on the program actually emitting that title**, which
  tmux can't force. See "Neovim titles" below for the piece that lives outside this repo.

## Neovim titles (action needed outside this repo — not yet done)

For Neovim windows to show the open file/directory instead of just "nvim", Neovim itself
needs `'title'` enabled and a `titlestring` that includes what you want to see - this is
not a tmux setting. Add to your Neovim config (e.g. `~/.config/nvim/init.lua`):

```lua
vim.opt.title = true
vim.opt.titlestring = "%t %m (%{expand('%:~:h')})"
```

`%t` = filename tail, `%m` = modified flag, the last part = home-relative parent
directory. **Not yet added** — ask if you want it wired in directly.

**Claude Code's own title:** untested here. Some terminal-based agent CLIs push a
descriptive running-status title via the same escape sequence mechanism; if Claude Code
does, `allow-rename on` is now in place to surface it automatically. If it doesn't emit
anything richer than the process name, tmux has nothing to show beyond "claude" - that's
a property of the program in the pane, not something fixable from this config.

## TPM plugin lifecycle

Hotkeys are TPM's own defaults (not rebound here):

- `prefix + I` install plugins listed in `plugins.conf`
- `prefix + U` update installed plugins
- `prefix + alt + u` uninstall plugins no longer listed

## Things discovered while building (worth knowing before you extend this)

- **TPM hardcodes its config-file location for plugin *discovery*.** Its helper scripts
  re-parse `~/.config/tmux/tmux.conf` (or `~/.tmux.conf`) from disk, unconditionally, to
  find `@plugin` lines - there's no env override for this specific step (there is one for
  *where plugins install to*: `TMUX_PLUGIN_MANAGER_PATH`, set explicitly in
  `plugins.conf`). While this lived at `~/.config/tmux-scratch` during development, TPM's
  install/update flow couldn't see `@plugin 'christoomey/vim-tmux-navigator'` because it
  was reading the wrong file - fixed with a direct `run-shell` of the plugin's `.tmux`
  file as a belt-and-suspenders fallback (see the comment in `plugins.conf`). Moot now
  that this lives at the real `~/.config/tmux/tmux.conf` path (exactly what TPM expects by
  default), but left in permanently anyway - safe, sourcing it twice is a no-op.
- **A prefix'd symbol key can silently do nothing if Ctrl is still held down when you
  press it - and this turned out to affect both split bindings, not just one.**
  `prefix + -` (stacked split) reads as `C-a` then a released-Ctrl `-` keypress
  (byte `0x2d`) - but it's easy to keep holding Ctrl through both keys, which sends the
  control byte `0x1f` instead (same code as `Ctrl-_`, since `-`/`_` share a key).
  Initially assumed `prefix + |` wouldn't have the same problem (holding Ctrl through
  Shift+\\ seemed like a less natural hand position) - wrong: hit it there too. `|` shares
  its physical key with `\\`, and Ctrl-key control-code generation for the `0x40`-`0x5f`
  block only depends on the key's low 5 bits, which are identical for `\\` (`0x5c`) and
  its shifted form `|` (`0x7c`) - so holding Ctrl through either sends the same byte,
  `0x1c`. Neither `0x1f` nor `0x1c` was bound to anything, so both splits could silently
  fail to fire - no error, no message, just looked broken. Confirmed both mechanisms with
  a real PTY-attached client sending each byte explicitly (`send-keys` can't be used here
  either - see the next point). Fixed by binding `C-_` (`0x1f`) and `C-\\` (`0x1c`) -
  tmux's names for those bytes - to the same `split-window` commands as `-` and `|`
  respectively, so both work regardless of whether Ctrl gets released in between (see
  `conf/bindings.conf`). Generalize this to *any* prefix-then-symbol binding you add
  later: check whether the symbol's Ctrl-held control code collides with a physical
  neighbor key, and add a fallback bind for that byte if so.
- **`tmux send-keys` does not exercise root-table key bindings.** It writes bytes
  directly to the target pane's pty, bypassing tmux's own client-side key dispatch
  entirely - so `send-keys C-l` just sends a literal Ctrl-L to whatever's running in the
  pane (e.g. "clear screen" in zsh), it does *not* trigger the `bind -T root C-l`
  vim-tmux-navigator binding. Confirmed the binding logic is sound by testing its pieces
  directly instead (`if-shell` vim-detection, `select-pane`), and separately by attaching
  a real client via a Python-spawned PTY and reading its actual output. Pressing keys as
  a real attached client (or a PTY that mimics one) is the only way to test root-table
  bindings end to end - `run-sandbox.sh` for the former.
- **`#{?cond,TRUE,FALSE}` ternaries split on *every* comma, including ones inside an
  embedded `#[...]` style tag.** `#{?synchronize-panes,#[fg=colour232,bg=colour208] SYNC
  ,}` looks reasonable but silently truncates: the comma between `fg=` and `bg=` gets read
  as the TRUE/FALSE delimiter, and everything after it is lost. This sat unnoticed in the
  `PASSTHROUGH`/`COPY` status flags for a while because their condition was never true
  during earlier testing - only surfaced once `SYNC` was added and actually toggled on.
  Fixed by chaining single-attribute tags instead: `#[fg=colour232]#[bg=colour208]`, no
  comma, no ambiguity. Confirmed `tmux display-message -p <format-string>` reproduces the
  same truncation a real status line does, so it's a reliable (and fast) way to test
  format strings like this without attaching a real client.
- **But `display-message -p` has its own blind spot: `#(shell command)` formats.** These
  are async "jobs" - tmux spawns the shell command in the background the first time the
  format is evaluated and returns whatever's cached (nothing, yet); the result only shows
  up on a *later* evaluation after the job completes. A recurring option like
  `status-right` gets re-evaluated every `status-interval` tick and picks it up
  naturally; a one-off `display-message -p '#(whoami)'` call evaluates once and returns
  immediately, so it reliably renders empty even though the real status line renders it
  fine. Looked exactly like a bug until double-checked with a real PTY-attached client
  over a few seconds (long enough for the job to finish and a redraw to happen) - use that
  method specifically for anything involving `#(...)`, `display-message -p` for
  everything else involving `#[...]`/`#{?...}`.
- **`tmux show-options -gv <name> | xxd` is not reliable for verifying non-ASCII bytes
  (like the arrow glyphs) made it into an option's stored value.** It gave a false
  negative - zero arrow bytes found - on a status line that, when actually attached to
  and rendered through a real PTY client, unambiguously contained them (confirmed by
  grepping the raw captured bytes directly, dozens of correct occurrences). Cost real time
  chasing a phantom bug this way before switching to the PTY-attach method. Lesson: for
  anything involving embedded non-ASCII byte sequences specifically, skip `show-options`
  entirely and check real rendered client output - `display-message -p` and
  `show-options` are both fine for plain ASCII format-string logic (the ternary/comma
  bug above, e.g.), just not proven reliable for this.

## Open questions

- **Neovim titlestring**: see "Neovim titles" above - not yet added to your nvim config.
- **`~/.config/tmux-scratch`**: no longer kept in sync with this directory - safe to
  delete whenever, or keep as a historical record of how this was designed.
