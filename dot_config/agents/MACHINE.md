# Machine-specific agent context

Last verified 2026-08-24. Read this file when work depends on this machine’s configuration, shell behavior, local commands, or agent-harness setup. Re-check a fact when observed state disagrees with this document.

## Host and toolchain

- The host runs macOS 26.5.2 on Apple Silicon (`arm64`). The default shell is `/bin/zsh`.
- Homebrew is installed at `/opt/homebrew/bin/brew`; do not assume Intel Homebrew paths under `/usr/local`.
- The local timezone is Asia/Kolkata (IST). The home directory is `/Users/subhadip`.
- `XDG_CONFIG_HOME` is currently unset, so the XDG default is `~/.config`. Agent configuration therefore lives under `~/.config/agents`.
- Use explicit, validated absolute paths for destructive operations. Never use the home directory, `/`, or a workspace root as a recursive target.

## Configuration ownership and precedence

- Chezmoi manages durable configuration from `~/.local/share/chezmoi`. Its Git remote is the public `subhadipghoshal/dotfiles` repository; never add credentials, tokens, private keys, host identifiers, or sensitive machine data to the source.
- Inspect both source and target before editing. Change the chezmoi source and apply only intended targets. A live-only edit can be reverted by a later `chezmoi apply`.
- Do not commit unless requested. Uncommitted chezmoi changes survive local applies but not a fresh checkout; report that distinction.
- Global, portable policy belongs in `~/.config/agents/AGENTS.md`. Host-specific facts belong here. Repository instructions remain closer to the code and override global guidance only for their scope.
- Claude Code loads the global policy through `~/.claude/CLAUDE.md`. Codex and OpenCode link to it; Gemini imports it from `GEMINI.md`. Preserve those harness adapters rather than duplicating the policy.

## Shared skills across harnesses

The canonical skill root is `~/.config/agents/skills`. `~/.agents` is a compatibility symlink to `~/.config/agents`, retained for tools that conventionally discover `~/.agents/skills` or store `.skill-lock.json` there. Do not create a second real skill tree under the compatibility path.

Chezmoi-managed personal skills live in `~/.local/share/chezmoi/dot_config/agents/skills`. Upstream-installed packages are tracked by `~/.config/agents/.skill-lock.json`; keep complete skill packages together, including `SKILL.md`, scripts, references, metadata, and agent manifests. Do not vendor upstream packages into the public dotfiles source unless that is an explicit choice.

| Harness | Personal skill discovery |
|---|---|
| Codex | Discovers `~/.agents/skills` through the compatibility symlink |
| OpenCode | Its local plugin registers the XDG skill root |
| Claude Code | Per-skill links under `~/.claude/skills` |
| Gemini / Antigravity | Per-skill links under `~/.gemini/config/skills` |
| Cursor | Per-skill links under `~/.cursor/skills` |
| Pi | Per-skill links under `~/.pi/agent/skills` |

For a shared skill, update the canonical package first, validate it, then add chezmoi-managed per-skill links only where the harness requires them. Existing links through `~/.agents` remain valid, but new configuration should name the XDG root directly. Restart a harness or open a new task when its skill catalog is cached.

## Applying and recovering configuration

- Use `chezmoi diff`, targeted `chezmoi apply`, and `chezmoi status` before broad application. Verify both link targets and the final files they resolve to.
- Keep migration backups under `~/.local/state/agents/migration-backup`; this state is intentionally outside the public dotfiles repository. Retain a backup until all harnesses resolve the global policy and every expected `SKILL.md`.
- When moving a skill root, compare package names, file counts, and content hashes before replacing the old path with a compatibility symlink.
- Preserve the skill lock during moves so upstream update tooling continues to recognize installed packages.

## Shell configuration and validation

- `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, and `~/.zsh/` are managed by chezmoi. `.zshrc` is bootstrap only; real configuration lives in `~/.zsh/NN-*.zsh`, one concern per file.
- Read `~/.zsh/README.md` before changing shell configuration because it records non-obvious design decisions.
- Test zsh changes with `~/.config/zsh-sandbox/run-sandbox.sh` and tmux changes with `~/.config/tmux/run-sandbox.sh` before applying them live.

## Agent-shell behavior and local commands

`~/.zsh/99-agent-guard.zsh` sets agent pagers to `cat`, disables `correct_all`, and removes the `cat`, `ls`, `tmux`, and `vim` aliases. Do not add `| cat`, `--no-pager`, temporary pager overrides, or change the intentional interactive pager configuration. In agent shells those commands are real binaries; interactively they map to `bat`, `eza`, and `nvim`.

| Command | Purpose |
|---|---|
| `manx <page> <SECTION>` | Read one man-page section |
| `mopt <page> <flag>` | Read one option paragraph |
| `mh <page>` | List a man page’s section headers |
| `gctx` | Show compact repository state |
| `wt <branch>` | Create a sibling worktree and tmux session |

Prefer `manx` and `mopt` over a full man page. The `s <pattern>` command is interactive and intended for humans. Use `wt` for parallel agents because agents sharing one working tree can overwrite each other.

## Hazards and data caveats

- Never run `tempclean`, or `safe_clean` with `trash` or `delete`. They affect broad cache, log, temporary, and system directories. `safe_clean dry` is the only permitted agent invocation.
- Atuin records reliable exit codes only from 2026-08-23 onward. The 6,950 commands imported from plain zsh history have `exit = -1`, meaning unknown rather than failed.
