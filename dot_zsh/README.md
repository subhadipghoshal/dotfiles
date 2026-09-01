# ~/.zsh

Zsh configuration, one concern per file. Same shape and same reasoning as
`~/.config/tmux/conf/`: small and legible over handled-by-a-framework, every
file short enough to read top to bottom.

Rebuilt **2026-08-23**. What it replaced: a 305-line `.zshrc` with 28 oh-my-zsh
plugins, 585 aliases (504 of which had never been typed once in 6,886 recorded
commands), and three ad-hoc `zsh_*` include files.

Oh-my-zsh is still here and still the right call — trimming its plugin list got
most of the benefit of a migration for a fraction of the effort, and the parts
that actually earn their keep (the git and kubectl aliases, `lsa`, `md`, the
`omz` CLI) are worth ~1,750 real invocations of history.

## Layout

```
00-options.zsh       history sizes, KEYTIMEOUT, setopts, GPG_TTY
10-completion.zsh    completion zstyles + fzf-tab previews + gcloud bashcompinit
20-git.zsh           wt (worktrees), gctx (repo context)
30-find.zsh          f, fe, fdir, fcd, s
40-man.zsh           mh, manx, mopt, mans
50-ai.zsh            agent, ctx, fix, fails, worked, keys
60-vi.zsh            cursor shapes, text objects, surround, keymap repairs
65-adhd.zsh          adhd, adhd-on, adhd-off
70-aliases.zsh       aliases, safe_clean, loadenv
80-cat.zsh           bat wrappers: copycat, pcat, jsoncat
99-agent-guard.zsh   overrides for agent / non-interactive shells
```

`.zshrc` sources `[0-8]*.zsh` in one glob loop, immediately after oh-my-zsh, so
everything here wins any conflict with it. `99-agent-guard.zsh` is deliberately
outside that glob and sourced by name at the very bottom of `.zshrc` — it has to
run after every alias in the config exists, including ones added by sdkman,
gcloud and the oh-my-zsh tmux plugin.

Paths use `${ZDOTDIR:-$HOME}` so `~/.config/zsh-sandbox` can run the identical
`.zshrc` against its own copy of these modules.

## Sandbox

`~/.config/zsh-sandbox/run-sandbox.sh` — the same idea as the tmux sandbox.

```
./run-sandbox.sh            interactive login shell, fully isolated
./run-sandbox.sh -c '<cmd>' one command
./run-sandbox.sh --time     startup timing, median of 10
```

It sets `ZDOTDIR` to itself, so zsh reads that directory's `.zshenv`,
`.zprofile`, `.zshrc` and `.zsh/` instead of `~`. `~/.oh-my-zsh`, `~/.p10k.zsh`
and `~/.zsh_history` are shared on purpose — they are the real thing and
nothing here writes to them. Every change below was built and verified there
before being promoted.

## What the utilities are for

| | |
|---|---|
| `s <pattern>` | live ripgrep — re-runs on every keystroke, preview scrolls to the hit, Enter opens nvim on that line |
| `f` / `fe` / `fdir` / `fcd` | fuzzy file/dir pick; `f` prints a path so it composes (`nvim "$(f)"`) |
| `mh <page>` | list a man page's section headers |
| `manx <page> <SECTION>` | print exactly one section — `manx rsync EXAMPLES` is 32 lines, not 1,300 |
| `mopt <page> <flag>` | print one flag's paragraph — `mopt tar -z` |
| `mans` | fzf over all 17,788 apropos entries, section-aware (tells `printf(1)` from `printf(3)`) |
| `wt <branch>` | git worktree as a sibling dir + its tmux session |
| `gctx` | compact repo state, paste-ready |
| `ctx` | `gctx` plus what you have actually run in this directory, with exit codes |
| `fix` | last failing command + captured terminal output, formatted for an agent |
| `agent <name> [branch]` | launch claude/codex/opencode/cursor-agent, optionally isolated in a worktree |
| `keys [NAME...]` | export agent API keys from the `pass` store into this shell only, on demand |
| `deagent` | clear stuck agent markers, set a session-local human override, and reload a tmux pane that was wrongly treated as an agent shell |

## Decisions worth knowing

**`typeset -U` lives in `~/.zshenv`, not `.zprofile`.** `.zprofile` is only read
by login shells. While the dedupe lived there, typing `zsh` produced a
differently-hashed `fpath` (4,823 chars vs 1,862), oh-my-zsh compared it against
the compdump, decided it was stale and **deleted** it — so the next login shell
paid a cold `compinit` of 213–480 ms. That was the intermittent slow start.

**Vendor completions belong on `fpath`, not in `.zshrc`.** The installers for
bun, openclaw and hermes each append a `source` or `eval` line to `.zshrc`. All
three ship `#compdef`-tagged scripts, which is exactly the format `compinit`
autoloads on first Tab for free, so sourcing them eagerly buys nothing and is
charged to every shell start: `eval "$(hermes completion zsh)"` forked the
binary for 175.7 ms and `source ~/.openclaw/completions/openclaw.zsh` parsed
201 KB for 5.0 ms. Interleaved A/B in the sandbox, median of 15 runs each:
**610 ms with those two lines, 210 ms without**; floor to floor, 350 ms against
200 ms. Against the real `.zshrc` as it stood, kept at
`~/.local/state/agents/migration-backup/`, the live interleaved A/B is
**660 ms against 380 ms**, median of 12. Interleaving is load-bearing: run
sequentially the two orderings disagree and can even invert.

`~/.zfunc/_openclaw` and `~/.zfunc/_hermes` are thin loaders rather than copies.
Each sources the vendor script at completion time and then redefines itself, so
an `openclaw update` or a hermes upgrade needs no regeneration step here, and
the load happens once per shell rather than once per Tab. Because that pins
nothing, `_hermes` checks that the eval actually replaced it and bails with a
message if not: calling a `_hermes` the eval never defined would re-enter the
autoloaded stub and fork the binary once per level until `FUNCNEST`, which with
a 0.12-0.19 s fork is a wedged prompt rather than a failed completion.

Unlike `_claude` and `_fastapi`, which are regenerable vendor output, these two
are hand-written and **are** tracked in the chezmoi source at `dot_zfunc/`, so a
`chezmoi init --apply` on a new machine gets them. Without that the failure mode
is silent: Tab simply does nothing.

bun is a Homebrew install and Homebrew already ships a current `_bun` on
`fpath`, so the `.zshrc` line was sourcing a stale 1,001-line `~/.bun/_bun` that
*shadowed* the correct 1,197-line one from the Cellar. Dropping the line alone
was not enough, though: Homebrew's file also ends in `compdef _bun bun`, so
autoloading it spends the first Tab registering and completes nothing until the
second (`bun ru` + one Tab gave nothing, + two Tabs gave `run`). Shadowing it
from `~/.zfunc` is not available, because nothing may precede Homebrew's entry
on `fpath` -- see below. So `~/.zfunc/_bun_delegate` sources it and calls it, and
`10-completion.zsh` registers that by name with `compdef`. One Tab again.

gcloud is the one that stays in `10-completion.zsh`: `completion.zsh.inc`
registers bash functions through `bashcompinit`, so it has to run after
`compinit` instead of being autoloaded by it.

**`fpath` is declared in `~/.zshenv`, absolutely, and it took two goes.** The
entries for `~/.docker/completions`, `~/.zfunc` and Homebrew's `site-functions`
all arrived through `.zprofile`, which only login shells read. oh-my-zsh writes
the whole array into the compdump as an `#omz fpath:` line and re-checks it with
`grep -Fx` on every start (`oh-my-zsh.sh:113-122`), so any difference deletes the
dump. A non-login interactive shell built 26 entries against a login shell's 29.

Moving the declaration to `.zshenv` fixed that half and exposed the other half.
`brew shellenv` emits `export FPATH`, so an FPATH is inherited by every child
shell, and zsh folds it into `fpath` *before* `.zshenv` runs. Writing
`fpath=(new $fpath)` therefore built a longer array in any shell that inherited
one than in a clean start — the same bug wearing a different hat, and the case
that actually bites here, because tmux panes on this machine are login shells
(`default-command` is empty) and the server's environment carries FPATH. Cold
against warm start measured 769 ms against 196 ms.

Naming every entry outright settles it: a clean login shell, a non-login shell,
a nested shell and a tmux pane now produce the same array and the same
`#omz fpath:` line. `typeset +x FPATH` is not an alternative — by the time
`.zshenv` could run it, the import has already happened.

One constraint falls out of that and is easy to trip over: **Homebrew's entry
has to stay first.** `brew shellenv` re-inserts it from `.zprofile` with
`fpath[1,0]=`, and on a `typeset -U` array a slice insert *moves* an existing
element to the front rather than duplicating it. While it is already first that
is a no-op. Put anything ahead of it — `~/.zfunc`, say — and login shells get an
order non-login shells do not, which is this same bug for the third time. That
is why bun's wrapper is registered by name instead of by position.

**`KEYTIMEOUT=2`.** Unset means 40, i.e. 400 ms. `ESC` in viins is both a
complete binding and the prefix of 23 sequences, so zsh waited the full timeout
on every mode switch. That was the "vi mode feels laggy".

**`FORGIT_NO_ALIASES=1`.** forgit loads after git and overwrote 16 oh-my-zsh git
aliases with interactive fzf pickers taking a fuzzy query rather than git
arguments. History shows it silently breaking real commands after the
2025-12-14 clone: `gco --theirs customers/all.csv`, `gd HEAD~1 > commit_n.diff`,
`gbl dot_zshrc` eight times in one day. The `forgit::*` functions are still
available; only the alias hijacking is off.

**`SAVEHIST` was never set**, so oh-my-zsh's default of 10,000 was silently
winning over `HISTSIZE=1000000000`. The file was at 6,882 entries — about six
weeks from truncating. (`HISTFILESIZE`, which was set, is a *bash* variable and
zsh never read it.)

**`safe_clean` had two bugs, either of which broke the shell permanently.**
`set -euo pipefail` is not function-local in zsh, so it leaked into the
interactive session and stayed. And the loop was `for path in ...` — `path` is
the special array tied to `$PATH`, so it left `PATH=/tmp`. Verified in a clean
`zsh -f`. Both fixed; `emulate -L zsh` now scopes options, and the loop variable
is local and renamed.

**No starship, no oh-my-posh.** Measured on this machine in a real 7,782-file
repo: `starship prompt` blocks for 110–118 ms per prompt; p10k's `gitstatusd`
answers in ~20 ms *asynchronously*. The popular "p10k is on life support, switch
to starship" advice is, here, backwards by roughly an order of magnitude.

**No zsh-vi-mode.** The three things it is usually adopted to fix — fzf bound in
both keymaps, a working p10k mode indicator, clean F-Sy-H wrapping — already
work correctly. It would put all three at risk to buy text objects that zsh 5.9
ships in `/usr/share/zsh/5.9/functions/` and that `60-vi.zsh` now autoloads.

**fzf-tab is the one plugin added.** It replaces zsh's completion *menu*, not
its completion engine, so every zstyle and every plugin-supplied completion
still applies. Its position in `plugins=()` is load-bearing: after compinit
(oh-my-zsh runs it at line 134, before sourcing plugins at line 205) and before
zsh-autosuggestions and F-Sy-H, which wrap ZLE widgets.

## Known limitations

**Exit codes are not retroactive.** Atuin was installed 2026-08-23 and imported
6,950 commands from `~/.zsh_history`, but a plain zsh history file never stored
exit status — every imported row carries `exit = -1` (unknown). So `fix`,
`fails` and `worked` only see commands run from that date onward. They get more
useful daily; nothing can backfill them.

**`fix` needs tmux for the output half.** It reads pane scrollback via
`tmux capture-pane`, which is retroactive and free — but outside tmux there is
no scrollback, so you get the failed command and repo state without the error
text. `TRANSIENT_PROMPT=always` in `.p10k.zsh` also rewrites the prompt lines
it anchors on; `same-dir` would make boundary detection more reliable.

**Worktrees do not share `.venv`, `node_modules` or Go build cache.** With a
Go + Python stack, expect one `uv sync` / `go mod download` per worktree. If a
repo has an `.envrc`, direnv handles it on cd.

**`mopt` is a heuristic, not a parser.** It picks the least-indented line whose
leading flag list contains the flag. Verified correct on curl, tar, git-rebase,
rsync, ssh, fd, ls, grep, rg, find, git-log — including `grep -r`, which BSD
pages document as `-R, -r, --recursive`. Unusual layouts may still fool it;
`mh <page>` then `manx <page> <SECTION>` is the reliable fallback.

**`ZSH_AGENT_MODE` is a tri-state startup contract inside an interactive
TTY.** A value of `1` selects agent behavior, `0` selects human behavior, and
an unset or invalid value falls back to agent-marker detection. Real
`CLAUDECODE`/`CODEX_SANDBOX`/`CURSOR_AGENT`/`OPENCODE`/`CI` markers are checked
inside tmux too. A non-interactive or captured shell always gets pager-safe
behavior; `.zshenv` enforces that for true `zsh -c` calls that never read the
later startup files. A human shell keeps its `0` value locally but removes the
export attribute, so a bare agent child does not inherit the override and can
still select safe behavior from its own marker.

Powerlevel10k instant prompt temporarily redirects stdout while `.zshrc`
loads. During that interval the guard checks Powerlevel10k's saved original
stdout descriptor, not the cache-file descriptor currently occupying fd 1.
This keeps real tmux panes human without weakening captured-shell safety. The
human branch also restores the complete pager contract on every interactive
startup: `PAGER=less`, the bat-backed `MANPAGER`, unset Git pager overrides,
and `LESS=-R` after `batpipe` installs its preprocessor hooks.

At tmux server startup, `conf/options.conf` sets the global mode to `0` and
removes inherited agent markers before the first pane is created. This covers
direct `tmux new-session` launches as well as the sessionizer. For an existing
poisoned pane, run `deagent` to set the session-local human override and reload
the login shell.

## Still open

- **The `pass` store does not exist yet.** `pass` and `gpg` are installed and
  the GPG key `29434942FA84957FF31E18BB9499547C00A1A01A` is ready, so this is
  one `pass init` away. `keys` (50-ai.zsh) reads `ANTHROPIC_KEY` and `OPENCODE_ZEN_KEY` from
  `agents/anthropic` and `agents/opencode-zen`. Until those two entries exist it
  fails closed with the command to create them. `~/.secrets/keys` is still the
  only copy of both values — delete it only after `keys` works.
- **rbenv is effectively bypassed.** `.zshrc` prepends `/opt/homebrew/bin`
  *after* `.zprofile` runs, so the rbenv shims sit at PATH position 9 and
  `ruby` resolves to Homebrew's 4.0.6, not rbenv's 4.0.0. This predates the
  lazy-loading change and is unchanged by it. Either move the shims after the
  Homebrew prepend or drop rbenv entirely — with 1 `ruby` invocation in 6,950
  commands, the second is probably right.

## Recently closed

- **The `.zshrc` tail is bootstrap again.** The bun, openclaw, hermes and gcloud
  completion lines that installers had appended are gone. The openclaw and
  hermes blocks had been written *below* `99-agent-guard.zsh`, which has to run
  last. No hardcoded `/Users/subhadip` is left in `.zshrc`, `.zshenv` or
  `.zprofile` either. One pass at that had already been attempted live and had
  put `${HOME}` inside **single** quotes on the two gcloud lines, so the
  `[ -f ... ]` test could never be true and gcloud PATH and completion had been
  silently off.

- **rbenv no longer eval-ed at login.** Shims go on PATH statically and the
  dispatch function is defined on first call. Sandbox median-of-10 startup:
  **300 ms → 260 ms**. The previously recorded "140 ms" was the cost of running
  `rbenv init` as a standalone process, not its marginal cost inside startup —
  the real saving is ~40 ms.
- **gcloud moved out of `~/Downloads`** to `~/.local/share/google-cloud-sdk`.
  Auth was unaffected; it lives in `~/.config/gcloud`, which is unmanaged. (The
  store there was empty anyway — no account has ever been authenticated.)
- **The Microsoft AI Toolkit is gone**, reclaiming 2.0 GB. It was uninstalled
  through VS Code (`code --uninstall-extension`) rather than by deleting files,
  because Settings Sync had silently restored it after the Aug 7 reinstall and
  would have done so again. `~/.aitk` and the extension folder are deleted and
  `lastSyncextensions.json` no longer lists it.
- **`~/.config/direnv/lib/pass.sh` is now tracked.** It was untracked and not in
  `.chezmoiignore`, so a fresh checkout would have lost it.
