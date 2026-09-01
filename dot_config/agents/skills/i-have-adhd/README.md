# i-have-adhd (local install notes)

`SKILL.md` tracks upstream (`ayghri/i-have-adhd`) verbatim below its frontmatter;
`update-from-upstream.sh` refreshes it. Everything else in this directory is
local wiring.

## Always-on, on every harness

One switch, one copy of the rules, four harnesses.

`sync-always-on.sh` keeps a marked block inside `~/.config/agents/AGENTS.md`
holding the body of `SKILL.md`. That file is the one instruction file every
agent here already loads:

| Harness     | Entry file                     | How it reaches the block |
| ----------- | ------------------------------ | ------------------------ |
| Claude Code | `~/.claude/CLAUDE.md`          | `@`-import               |
| Codex       | `~/.codex/AGENTS.md`           | symlink                  |
| OpenCode    | `~/.config/opencode/AGENTS.md` | symlink                  |
| Gemini CLI  | `~/.gemini/GEMINI.md`          | `@`-import               |

Codex has no session hook and no import syntax, which is why the rules are
inlined into the shared file rather than imported from a generated one.

## Commands

```sh
./sync-always-on.sh status   # flag, block, chezmoi, per-harness wiring
./sync-always-on.sh on       # turn always-on on everywhere
./sync-always-on.sh off      # turn it off everywhere
./sync-always-on.sh sync     # reconcile after editing SKILL.md
```

The switch is the flag file `~/.config/agents/.i-have-adhd-always`. The four
older per-harness flags (`~/.claude/.i-have-adhd-always` and friends) still
count as on, and `off` deletes them too.

`AGENTS.md` is chezmoi-managed, so `sync-always-on.sh` writes the same block
into the chezmoi source file. `chezmoi status` stays clean and `chezmoi apply`
will not revert the block. The flag file itself is runtime state and stays
unmanaged.

## Claude Code specifics

`always-on.sh` is the `SessionStart` hook wired up in `~/.claude/settings.json`.
It prints the one-line banner, re-syncs the block, and prints the full ruleset
only when the block was not already in context (first session after `on`, or a
`CLAUDE.md` that stopped importing the shared policy). `stop adhd mode` still
turns the rules off for one session anywhere.

## Left unwired on purpose

`~/.config/opencode/plugins/i-have-adhd.mjs` is upstream's OpenCode plugin. It
is not referenced from `opencode.jsonc` and OpenCode auto-loads from `plugin/`,
not `plugins/`, so it never runs. Leave it that way: wiring it up would inject
the ruleset a second time on top of the block OpenCode already reads from
`AGENTS.md`.

## Not covered

Cursor (`cursor-agent`) reads project-level `AGENTS.md` and `.cursor/rules`, and
its user rules live in Cursor's own settings, so there is no global file here to
write. Per-project setup only.
