# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Codex, OpenCode, Gemini) when working with code in this repository.

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
guard - see `conf/plugins.conf`'s header comment and "Debugging this config"
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
CLAUDE.md                    compatibility symlink to AGENTS.md for Claude Code
plugins/                     TPM-managed plugin clones (installed via prefix + I)
logs/                        tmux-logging output: pane logs, screen captures, history dumps
run-sandbox.sh                launches this config on an isolated tmux server (see below)
```

## Sandbox testing

`./run-sandbox.sh` starts tmux with `-L tmux-sandbox` (a separate server/socket) and
`-f tmux.conf`, so it's a fully isolated server - it cannot see or touch your real
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
building - see "Debugging this config."

## Prefix key: `C-a`

Not the default `C-b` (which is what the old Oh My Tmux! setup ran with). `C-Space` was tried
first for the rebuild, but macOS intercepts it system-wide for input-source switching before
tmux receives it (see `~/.config/agents/MACHINE.md`). `C-a` avoids that collision, and its cost
(shadowing readline's beginning-of-line and Neovim's increment-number) is handled by double-tapping
(`C-a a`) to send a literal prefix through to whatever is running in the pane.

**Note on the promotion itself:** flipping this live via `source-file`/`prefix + r`
changes the prefix (and everything else) for every session already running on the default
server at once, not just new ones - worth doing at a moment you're not mid-task in one of
those sessions.

## Key bindings - see CHEATSHEET.txt for the full list

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
  `SESSIONIZER_DIRS` (edit the variable at the top of `sessionizer.sh` - currently
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
  Ghostty's Kitty graphics protocol reach Neovim for `snacks.image` rendering (inline images
  and mermaid diagrams); see `~/.config/agents/MACHINE.md` for why tmux swallows the escape
  sequences without it.
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
- **AeroSpace (GUI window manager) coexistence, 2026-09-03.** AeroSpace
  (`~/.config/aerospace/aerospace.toml`) owns GUI window management and claims plain
  `alt-*` machine-wide, so this repo's window-nav binds moved from `M-h`/`M-l`/`M-1`..`M-9`
  to `Ctrl+Alt` - not just a free slot but the *robust* one, since it survives layout and
  terminal changes; see `~/.config/agents/MACHINE.md` for the full namespace contract and
  why. Because `conf/plugins.conf` sources last and can clobber a bind with no error (see
  "Debugging this config" above), re-verify any future change here against the *live*
  server: `tmux list-keys -T root | grep C-M-`.

## Neovim titles (action needed outside this repo - not yet done)

For Neovim windows to show the open file/directory instead of just "nvim", Neovim itself
needs `'title'` enabled and a `titlestring` that includes what you want to see - this is
not a tmux setting. Add to your Neovim config (e.g. `~/.config/nvim/init.lua`):

```lua
vim.opt.title = true
vim.opt.titlestring = "%t %m (%{expand('%:~:h')})"
```

`%t` = filename tail, `%m` = modified flag, the last part = home-relative parent
directory. **Not yet added** - ask if you want it wired in directly.

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

## Debugging this config

Tmux has several silent-failure modes (bindings that do nothing with no error, format
strings that truncate on a stray comma, plugins that clobber an earlier binding on load)
that cost real time to track down while building this. Those discoveries, and which tool
reliably proves what, are written up as a reusable skill,
`~/.config/agents/skills/tmux-config-debugging`, rather than repeated here - invoke it
before debugging a binding, format string, or plugin-load issue in this repo.

## Open questions

- **Neovim titlestring**: see "Neovim titles" above - not yet added to your nvim config.
- **`~/.config/tmux-scratch`**: no longer kept in sync with this directory - safe to
  delete whenever, or keep as a historical record of how this was designed.
- **tmux-agent-sidebar's Claude Code hooks**: `~/.claude/settings.json` pointed its
  marketplace registration at a truncated home directory (`$HOME/...` with incomplete suffix) - fixed on 2026-09-02, but Claude Code resolves plugin
  marketplaces at startup, so the fix won't take effect until your next restart/new
  session. After that, confirm it worked: start a Claude Code session in a pane, check for
  a `/tmp/tmux-agent-activity*.log` file, then `prefix + e` should show populated
  status/prompt data instead of empty rows.
