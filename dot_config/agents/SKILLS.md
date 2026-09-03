# Engineering skill registry

This is an index, not an instruction layer. Skills are discovered from `~/.config/agents/skills`; combine the matching language overlay with any relevant workflow skill.

## Language overlays

- `python-engineering`: Python design, typing, exceptions, async, and tooling.
- `go-engineering`: Idiomatic Go, interfaces, errors, concurrency, and tooling.
- `csharp-engineering`: Modern C#/.NET nullability, async, DI, resources, and tooling.
- `typescript-engineering`: TypeScript/JavaScript types, runtime boundaries, async, and tooling.

## Workflow skills

- `behavior-first-testing`: Tests around observable behavior.
- `complexity-assessment`: Scope, coupling, risk, and verification assessment.
- `crew`: Role-separated engineering crew (triage, plan, build, verify, review), in tmux panes on Claude Code. User-invocable only; agents do not convene it automatically.
- `defensive-design`: Failure-prone boundaries, persistence, retries, and concurrency.
- `git-worktree-delegation`: Isolated worktrees for multiple authoring agents.
- `macos-shell-config`: Safe changes to this Mac's shell, dotfiles, and harness configuration.
- `adversarial-review`: Independent, severity-gated review of code changes.

## Effort ladder

- `quick`: Drop this turn to low effort - mechanical edits, single-file lookups.
- `deep`: Raise this turn to xhigh effort - hard debugging, design tradeoffs, review passes.
- `apex`: Raise this turn to max effort. User-invocable only; agents do not reach for it automatically.
