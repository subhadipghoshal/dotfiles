# CLAUDE.md

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
are used in place of plugins wherever tmux ≥3.2 already does the job. Four plugins earn
their place through TPM: `vim-tmux-navigator` (Neovim pane navigation, no native
equivalent), `tmux-logging` (pane logging/capture/history dump, no native equivalent),
`tmux-agent-sidebar` (cross-pane visibility into running Claude Code/Codex/OpenCode
agents), and `tpm` itself for its install/update/uninstall hotkeys. A batch of six more
(`tmux-sensible`, `tmux-resurrect`, `tmux-continuum`, `tmux-prefix-highlight`,
`tmux-copycat`, `tmux-yank`) was installed in one shot on 2026-09-01 and removed the next
day after an audit found each one either redundant with something already hand-written
here, actively wrong on tmux 3.7, or silently overriding a documented binding with no
guard - see `conf/plugins.conf`'s header comment and "Things discovered while building"
below for the load-order lesson that audit surfaced.

## Layout

```
tmux.conf                   entrypoint - sources everything else, nothing else lives here
conf/options.conf            terminal/rendering, indexing, window naming, copy-mode/clipboard opts
conf/bindings.conf           prefix, splits, resize, window nav, nested-tmux passthrough,
                              sessionizer, session switcher, popups, extras, cheat sheet
conf/status.conf             status-position only - catppuccin/tmux (plugins.conf) owns
                              the actual status line since 2026-09-02
conf/plugins.conf            TPM + tmux-logging + vim-tmux-navigator + tmux-agent-sidebar
                              + catppuccin/tmux
scripts/sessionizer.sh       fzf project picker -> creates/attaches a session per project,
                              runs layouts/<name>.sh once at creation if one exists
scripts/session-switcher.sh  fzf list of already-open sessions -> switch to one
scripts/open-url.sh          fzf-pick a URL out of pane scrollback -> open it
scripts/clip.sh              copy-mode yank target: pbcopy locally, OSC 52 over ssh
layouts/<session>.sh         optional per-project layout (see "Declarative per-project
                              layouts" below); absent for most sessions, that's expected
CHEATSHEET.txt               plain-text reference for every binding defined here (prefix + h)
AGENTS.md                    copy of this file for other agent runtimes — keep in sync
plugins/                     TPM-managed plugin clones (installed via prefix + I)
logs/                        tmux-logging output: pane logs, screen captures, history dumps
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
  useful for running one command across several ssh panes at once). Pops up a one-off
  "sync on/off" message toast (`bindings.conf`'s own `display` call) - no persistent status
  bar indicator since the switch to catppuccin/tmux dropped the hand-rolled
  PASSTHROUGH/COPY/SYNC flags (2026-09-02, see "Design decisions" below).
- `prefix + o` pops up an fzf picker over URLs found in the current pane's scrollback and
  opens the selection - a full-screen, mouse-light workflow doesn't get click-to-open.
- `prefix + T` hides/shows the status bar entirely (more vertical space on demand).
  `prefix + t` (lowercase) is a different toggle - flips the bar between top/bottom for
  the running session only, for a quick live A/B; the persistent default lives in
  `conf/status.conf`'s `status-position` line.
- `prefix + X` kills the whole session with confirmation, mirroring the default
  `prefix + x` for kill-pane - useful once the sessionizer accumulates sessions.
- `Ctrl+Alt+1`-`9` and `Ctrl+Alt+h`/`Ctrl+Alt+l` jump/cycle windows with **no prefix at
  all**, mirroring the `Ctrl-h/j/k/l` you already use for panes (Ctrl = panes, Ctrl+Alt =
  windows). These were plain `Alt+…` until 2026-09-03; AeroSpace now owns plain Alt
  machine-wide for GUI window management and intercepts those chords before any terminal
  sees them. Ctrl+Alt is not merely a free slot but the *robust* one on macOS - see
  "AeroSpace (GUI window manager) coexistence" under Design decisions.

## Design decisions

- **Sessionizer, not serialized session state.** `prefix + f` opens a popup, fzf over
  `SESSIONIZER_DIRS` (edit the variable at the top of `sessionizer.sh` — currently
  `~/github.com ~/github.docusignhq.com ~/.config`, real project roots confirmed to exist
  on this machine as of 2026-09-02 - add/remove freely, it's just a space-separated list;
  see the git-blame/history in this file for why the previous list, set at promotion time
  for a different machine, went stale). Within each root, discovery is by `.git` presence
  at any depth (pruned on `plugins`/`node_modules`/`vendor`/`.venv` first, so this repo's
  own TPM plugin clones under `plugins/` don't show up as false "projects" - confirmed they
  did, before that exclusion), **unioned with** a flat one-level listing so an untracked
  scratch/notes directory with no `.git` still shows up too. Replaced the previous uniform
  one-level-deep `find` on 2026-09-02: real projects here sit at different depths
  (`~/github.com/<org>/<repo>`, two levels; `~/github.docusignhq.com/<repo>`, one level),
  which a single fixed depth can never see correctly for both at once - confirmed against
  ThePrimeagen's own current `tmux-sessionizer` that this repo's original design was
  modeled on: it still uses the same flat one-level pattern, so the `.git`-recursive union
  is a deliberate addition on top, not something carried over from there. Creates a session
  named after the selected directory if one doesn't exist, switches to it. Sessions are
  cheap and reproducible instead of serialized/restored - simpler mental model, nothing
  "magic" to debug when it doesn't restore right.
  `tmux-resurrect` + `tmux-continuum` were tried for this on 2026-09-01 and removed the
  next day: continuum mutates `status-right` at load to install its save timer (it had
  silently prepended its own `#(...)` shell interpolation ahead of the hand-written value
  in `status.conf`), and restore was never actually wired up (`@continuum-restore` stays at
  its default `off` unless you explicitly set it) - so for 24 hours it was writing a
  snapshot to disk every 15 minutes that nothing ever read.
- **Declarative per-project layouts, not a snapshot.** For the handful of projects that
  need more than one blank pane, `sessionizer.sh` runs
  `~/.config/tmux/layouts/<session_name>.sh` once, immediately after creating that session,
  if the file exists and is executable - plain tmux commands (`split-window`,
  `select-pane`, `send-keys`, ...) targeting the new session; see `layouts/tmux.sh` for a
  worked example (the layout for this very repo's own session). Layouts live in this
  config directory, not inside project repos, deliberately: sessionizing into a cloned repo
  must never execute code that repo shipped. This is the direct replacement for what
  `tmux-resurrect` would have given you - a layout becomes a version-controlled, readable
  script instead of a serialized state file, matching this config's "nothing magic" stance.
  No layout file for a session is the common case and changes nothing: you get exactly the
  single plain pane you always did.
- **SSH-aware, not SSH-blind.** `pane_current_command == ssh` recolors the hostname
  status segment red, so it's visually obvious when a pane is on a remote box. `F12`
  toggles a "passthrough" mode (dims the status bar, disables the outer prefix) for
  extended work inside a nested tmux; a bare double-prefix-tap (`C-a a`) already passes
  one keystroke through by tmux default, no config needed for the common case.
- **OSC 52 clipboard.** `set-clipboard on` handles most terminal/copy-mode cases
  automatically; `clip.sh` (bound to `y` in copy-mode-vi) is the explicit fallback that
  crafts the OSC 52 sequence by hand when on a remote pane, so copies land in your local
  macOS clipboard even from a box you SSHed into.
- **Agent environment isolation.** `options.conf` seeds `ZSH_AGENT_MODE=0` and unsets
  `CLAUDECODE`, `CI`, `CODEX_SANDBOX`, `CURSOR_AGENT`, `OPENCODE` on the global server
  environment so a tmux server started from an agent shell doesn't infect every pane with
  those markers. `sessionizer.sh` repeats the same set for newly-created sessions. The
  scratch popup (`prefix + Space`) does it too. The pattern is: set human defaults on the
  server, clear agent env vars so interactive shells start clean.
- **Ghostty Kitty graphics passthrough.** `allow-passthrough on` (in `options.conf`) lets
  Ghostty's Kitty graphics protocol reach Neovim so `snacks.image` can render images and
  mermaid diagrams inline in a markdown buffer. Without it tmux silently swallows the
  escape sequences.
- **Popups instead of extra panes.** `prefix + g` = lazygit, `prefix + Space` = scratch
  session, `prefix + o` = URL picker, `prefix + s` / `prefix + f` = fzf pickers, `prefix +
  h` = cheat sheet - all `display-popup -E` overlays so they don't disturb your pane
  layout.
- **Status line: replaced with catppuccin/tmux on 2026-09-02, not another hand-rolled
  bar.** The original was a hand-built powerline imitation (arrow separators via
  octal-escaped Nerd Font glyphs, hand-tuned colourNNN segments, reverse-engineered from
  the old Oh My Tmux! + tmux-themepack theme) that broke the first time this config was
  ported to a different machine/terminal width. Root-caused, not guessed:
  `status-justify absolute-centre` centred the window list against the *full* terminal
  width with no reflow, while `status-left-length 40` + `status-right-length 100` reserved
  140 columns for content that included unbounded `#(whoami)`/`#H` (full hostname) - on a
  narrower terminal, the centred window list collided with those reserved blocks. A
  separate, compounding risk: the arrow glyphs were Private Use Area codepoints with
  Unicode-ambiguous width, so a font-metric mismatch between machines could desync tmux's
  column math from what the terminal actually drew, with no error either way.
  Rather than hand-fix that arithmetic and inherit the next version of the same fragility,
  the whole hand-rolled bar was replaced with **catppuccin/tmux** (`conf/plugins.conf`,
  pinned to `#v2.3.0`) - chosen over two other actively-maintained candidates checked
  (tmux2k, tmux-power) mainly for adoption/community weight (3,161★ vs 458★/700★ at the
  time), and confirmed via its own source that it sets neither `status-justify` nor a
  fixed-length budget, so adopting it doesn't just relocate the bug. Configured following
  the plugin's own documented "recommended default configuration" verbatim - Mocha flavor,
  `status-left` empty, segments composed into `status-right` via its pre-styled
  `#{E:@catppuccin_status_*}` tokens - rather than inventing a custom arrangement.
  Started with `session`, `user`, `host`, `date_time`; `host` (full hostname via `#H`) was
  dropped on 2026-09-02 for taking up space with no real benefit, leaving `session`,
  `user`, `date_time`. The old PASSTHROUGH/COPY/SYNC text flags and the
  SSH-aware red hostname were deliberately **not** re-implemented as custom segments on top
  of the plugin: that hand-written logic is exactly the maintenance burden this move was
  meant to end, and re-adding it as "custom segments" would have kept most of that burden
  under a new name. `conf/status.conf` keeps only `status-position bottom` (tmux's own
  default already, written down anyway for legibility) - everything else the old file
  hand-rolled (status-style, window-status-*, pane-border-style, message-style, clock-mode,
  display-panes-colour) is now the plugin's responsibility. One real, understood tradeoff
  from this switch: catppuccin embeds its own `#[fg=...,bg=...]` tags directly inside
  `window-status-format`/`window-status-current-format` and each status segment token,
  rather than using the separate `window-status-current-style`/`status-style` options the
  old bar relied on - which means `bindings.conf`'s F12 passthrough-mode dim override now
  only visibly dims the bar's *uncovered* background, not the colorful segments themselves
  (the prefix-disable behavior itself is unaffected). See `bindings.conf`'s F12 comment.
- **Window titles carry real status, not just the process name.** `allow-rename on` (the
  old config had this off) lets programs push a descriptive title via terminal escape
  sequences; `automatic-rename on` still falls back to the plain process name for
  anything that doesn't. This is what lets a window show "file.lua (~/project)" instead
  of just "nvim" - **but it depends on the program actually emitting that title**, which
  tmux can't force. See "Neovim titles" below for the piece that lives outside this repo.
- **AeroSpace (GUI window manager) coexistence, 2026-09-03.** Added AeroSpace
  (`~/.config/aerospace/aerospace.toml`, chezmoi-managed at
  `dot_config/aerospace/aerospace.toml`) as a tiling window manager scoped deliberately to
  GUI applications only - tmux keeps owning the TUI/terminal side, no overlap. The
  namespace split, so one keystroke never means two things depending on focus: `alt-*` →
  AeroSpace (workspace switch, window focus/move), `ctrl-*` → tmux panes
  (vim-tmux-navigator), `ctrl-alt-*` → tmux windows (this file, "Key bindings" above),
  `C-a` prefix → everything else in tmux.
  AeroSpace's idiomatic scheme claims `alt-1..9` and `alt-h/j/k/l` as global OS-level
  hotkeys - the exact chords this repo's `M-h`/`M-l`/`M-1`..`M-9` binds used from the
  2026-08-22 rebuild until this date. An OS-level grab means tmux would never see those
  keys again, full stop, not a conflict tmux could win by any config change on its side -
  so rather than fight AeroSpace's idiom (and permanently diverge from every published
  AeroSpace config you'll ever read), tmux's binds moved to `Ctrl+Alt` instead, verified
  free (`grep -rn "C-M-" conf/ tmux.conf` → zero matches before the change). This wasn't
  just "the free slot" - it's specifically the *robust* one: Ghostty only forwards Option
  as Meta when the Option-sequence produces no printable character
  (`macos-option-as-alt`, which defaults to `true` on a U.S. Standard layout, which is why
  the old plain-Alt binds worked in the first place), but Ghostty's own docs guarantee an
  Option chord that also holds Ctrl is treated as Alt *regardless* of that setting - so
  `C-M-<key>` survives a layout change, a `macos-option-as-alt` flip, or even a different
  terminal, none of which the old plain-Alt binds could claim. tmux 3.7 requests extended
  keys itself whenever the terminal advertises support (Ghostty does), which is what lets
  it distinguish `C-M-<digit>` from a bare digit - no explicit `extended-keys` setting was
  needed. Cost accepted knowingly: `opt-h/j/k/l` and `opt-<digit>` no longer produce their
  macOS Option-glyph characters anywhere (accented-character dead keys like `opt-e`/`opt-i`
  are untouched, since those don't collide with AeroSpace's bound keys). Because
  `conf/plugins.conf` is sourced last and can clobber a bind with no error (see "Things
  discovered while building" below), any future change here should be re-verified with
  `tmux list-keys -T root | grep C-M-` on the *live* server, not just in the sandbox.

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
- **An embedded `#[fg=...,bg=...]` tag inside a format string wins over the separate
  base `*-style` option for that same span - the base style isn't a true fallback for
  anything the format string explicitly colors itself.** Discovered on 2026-09-02 checking
  whether `bindings.conf`'s F12 passthrough binding (`set status-style ...` /
  `set window-status-current-style ...`, then `set -u` to undo) would still visibly dim the
  bar under catppuccin/tmux. It doesn't, not fully: confirmed by reading catppuccin's own
  source that it never sets `window-status-current-style` at all and instead builds
  `window-status-current-format` (and each status segment token) out of inline
  `#[fg=#{@thm_fg},bg=...]` tags baked in per-window. Those inline tags paint over whatever
  the base style says for the exact cells they cover, so F12's override now only dims the
  bar's uncovered background, not the colorful segments - no error, no warning, just a
  visibly weaker effect than before. General lesson: before assuming a `*-style` binding
  will visibly affect a themed status line, check whether the theme paints its own colors
  inline inside the format string for that region - if it does, the base style is
  decorative there, not a fallback.
- **`conf/plugins.conf` is sourced LAST** (see `tmux.conf`'s ordering: options, bindings,
  status, then plugins), so any plugin binding or option that carries no guard against an
  existing value always wins over anything set in
  `options.conf`/`bindings.conf`/`status.conf` - tmux applies commands in the order it
  reads them, full stop, there's no config-level protection against a later one clobbering
  an earlier one. Discovered on 2026-09-02 auditing the batch of six plugins added the day
  before: `tmux-yank` had silently taken over `copy-mode-vi y` from `scripts/clip.sh` with
  zero conflict detection (`tmux list-keys | grep clip.sh` returned nothing), and
  `tmux-continuum` had prepended its own save-timer shell interpolation onto the
  hand-written `status-right` from `status.conf`. `tmux-copycat` was worse than
  unconditional - it re-parses `list-keys` output and re-binds *whatever it finds* wrapped
  in `run-shell`, silently degrading `n`/`N`/`q`/`C-c`/`Enter`/`A`/`D`/`DoubleClick1Pane`/
  `TripleClick1Pane` in copy-mode-vi. None of this produced an error or a warning at load
  time - `tmux list-keys` and `tmux show-options -gv status-right` were what caught it.
  General lesson: after installing any new plugin here, diff `tmux list-keys` against what
  it looked like before, don't assume a clean `tmux source-file`/`prefix + I` means nothing
  else changed.

## Open questions

- **Neovim titlestring**: see "Neovim titles" above - not yet added to your nvim config.
- **`~/.config/tmux-scratch`**: no longer kept in sync with this directory - safe to
  delete whenever, or keep as a historical record of how this was designed.
- **tmux-agent-sidebar's Claude Code hooks**: `~/.claude/settings.json` pointed its
  marketplace registration at a truncated home directory (`/Users/subhadip/...` instead of
  `/Users/subhadip.ghoshal/...`) - fixed on 2026-09-02, but Claude Code resolves plugin
  marketplaces at startup, so the fix won't take effect until your next restart/new
  session. After that, confirm it worked: start a Claude Code session in a pane, check for
  a `/tmp/tmux-agent-activity*.log` file, then `prefix + e` should show populated
  status/prompt data instead of empty rows.
