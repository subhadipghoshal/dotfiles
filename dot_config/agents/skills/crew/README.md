# `/crew`

One canonical package for a role-separated engineering crew, symlinked into every harness that
can carry a skill. `SKILL.md` is the manager's contract and the `/crew` entry point; the rest of
this directory holds the role contracts it dispatches.

## Model classes

Roles name a class, never a model ID. Adapters resolve the class.

| Class | Roles | Claude Code | OpenCode | Codex | Gemini |
|---|---|---|---|---|---|
| `frontier` | architect, data-architect, qa-lead, reviewer | `opus` | `anthropic/claude-opus-5` | `gpt-5.6-sol` | `gemini-3.1-pro` |
| `workhorse` | builder, qa-engineer | `sonnet` | `anthropic/claude-sonnet-5` | `gpt-5.6-luna` | `gemini-3.5-flash` |
| `intern` | intern | `haiku` (Haiku 4.5) | `anthropic/claude-haiku-4-5` | `gpt-5.4-mini` | flash-lite, unverified |

The `OpenCode` and `Gemini` `intern`/`workhorse` cells are unverified against the live catalog —
confirm before relying on them (see PLAN.md's harness capability survey).

## The crew matrix

| Risk class | Crew |
|---|---|
| Trivial / non-code / explanation, review, diagnosis | No crew |
| Low | `architect` → 1 `builder` → `reviewer` (+ `qa-lead`/`qa-engineer` if behavior changes) |
| Medium | `architect` → [`data-architect`?] → `qa-lead` → N `builder` → integrate → `qa-engineer` → `reviewer` |
| High | Same as medium, `qa-lead`/`reviewer` mandatory, human disposition on medium+ findings |

## Adapter index

- Claude Code: `~/.claude/agents/{architect,data-architect,qa-lead,builder,qa-engineer,reviewer,intern}.md`
- OpenCode: `~/.config/opencode/agent/{...}.md`
- Codex: `~/.codex/agents/{...}.md` + `~/.codex/config.toml` subagent keys
- Gemini: `~/.gemini/agents/{...}.md`
- Pi: no adapter, degrades per `SKILL.md`

## Adding a harness

1. Confirm it has a delegation primitive (subagents at minimum). If not, it gets the
   degradation clause, not a fake adapter.
2. Write one shim file per role: harness-specific frontmatter, one-line body pointing at the
   matching file in this directory (`Read <path> and follow it as your operating instructions.`).
3. Resolve the model-class table above against that harness's live catalog before shipping —
   do not assume a slug from memory.
4. Note whether it has a teammate/pane primitive. If not, it only ever gets auto mode.

See `/Users/subhadip/.claude/plans/i-want-my-general-wondrous-beaver.md` (mirrored at
`~/Practice/agents/claude/workflow/PLAN.md`) for the full design, including the tmux-pane
mechanics, the intern tier's triggers, and the verification checklist.
