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
10-completion.zsh    completion zstyles + fzf-tab previews
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
| `deagent` | clear a stuck CLAUDECODE/CODEX_SANDBOX/CURSOR_AGENT/OPENCODE/ZSH_AGENT_MODE marker and reload — for a tmux pane that inherited one and is wrongly treated as an agent shell |

## Decisions worth knowing

**`typeset -U` lives in `~/.zshenv`, not `.zprofile`.** `.zprofile` is only read
by login shells. While the dedupe lived there, typing `zsh` produced a
differently-hashed `fpath` (4,823 chars vs 1,862), oh-my-zsh compared it against
the compdump, decided it was stale and **deleted** it — so the next login shell
paid a cold `compinit` of 213–480 ms. That was the intermittent slow start.

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
(oh-my-zsh runs it at line 129, before sourcing plugins at line 205) and before
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

**Agent markers must not decide human tmux behavior.** `99-agent-guard.zsh`
uses `ZSH_AGENT_MODE=1` for an agent PTY and `[[ ! -t 1 ]]` for captured
output. Ambient `CLAUDECODE`/`CODEX_SANDBOX`/`CURSOR_AGENT`/`OPENCODE`/`CI`
markers remain a fallback outside tmux, but are ignored in a human tmux TTY
because they can be inherited by the server. `agent()` sets the explicit
marker only on the agent process, and the tmux sessionizer gives new sessions
safe marker values. For an existing poisoned session, run `deagent` to set a
session-local human override and reload the login shell.

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
