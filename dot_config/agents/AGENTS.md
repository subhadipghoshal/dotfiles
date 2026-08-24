# Global Engineering Rules

These rules apply to every repository and task unless a more specific project
instruction is required. Prefer correctness, clarity, maintainability, and
operational safety over speed of implementation.

## Clean Code

- Prefer simple, explicit, and readable code over clever or compressed code.
- Use names that describe domain intent. Keep functions, modules, and types
  cohesive, with one clear responsibility and minimal hidden coupling.
- Keep pure decision logic separate from I/O and other side effects when doing
  so improves local reasoning.
- Prefer the smallest change that fully solves the requirement. Avoid
  speculative abstractions, premature generalization, and unrelated refactors.
- Remove dead code and avoid leaving silent fallbacks, ignored errors, or
  temporary workarounds without a concrete follow-up.
- Comments should explain non-obvious intent, constraints, or tradeoffs, not
  restate the code.

## Complexity And Estimation

- Do not use human developer velocity, typing speed, familiarity, agent
  capability, or expected implementation time as an input when estimating task
  complexity.
- Estimate complexity from technical scope, uncertainty, coupling, data and
  interface changes, failure modes, migration and rollback risk, operational
  impact, and verification effort.
- A task that is quick to implement can still be technically complex. A task
  that takes time to implement is not necessarily technically complex.
- Before implementation, identify affected behavior, dependencies, invariants,
  risks, rollout concerns, and the tests that demonstrate completion.

## Defensive Design

- Treat every boundary as untrusted, including user input, network requests,
  internal callers, configuration, persisted data, files, queues, and
  webhooks.
- Validate and normalize inputs at boundaries, enforce domain invariants, and
  fail closed with explicit, actionable errors. Never hide failures with a
  silent fallback.
- Assume retries, duplicate delivery, timeouts, stale data, malformed data,
  partial outages, concurrent updates, and interrupted work. Make side effects
  idempotent where retries are possible and clean up resources reliably.
- Bound resource use and define timeouts, cancellation, and backpressure where
  an operation can wait on external work or consume untrusted input.
- Enforce authentication and authorization at the server-side boundary. Use
  least privilege, protect sensitive data, and never put secrets in source,
  logs, error messages, or test fixtures.
- Preserve compatibility only for a concrete persisted or external contract;
  do not add speculative compatibility layers. For breaking changes, define a
  migration, rollout, and rollback strategy.
- Keep important decisions and tradeoffs documented near the relevant design
  or in an ADR. Make failures observable through appropriate logs, metrics,
  traces, or health signals.

## Testing Strategy

- Use end-to-end user behavior as the primary acceptance lens: start at the
  real user or public-caller entry point, exercise the relevant system
  boundaries, and verify the externally observable result and side effects.
- Derive scenarios from user journeys and requirements, not from the current
  implementation. Cover successful flows, validation failures, permissions,
  empty and boundary states, retries, timeouts, dependency failures, and
  important state transitions.
- Prefer realistic fixtures and real components at important boundaries. Mock
  only uncontrollable external systems or expensive dependencies, and verify
  mocked contracts separately.
- Assert behavior and outcomes rather than private implementation details.
  Every user-visible bug fix should have a regression test at the highest
  practical level.
- Use integration and unit tests to localize failures and cover detailed rules,
  but do not treat lower-level tests as the sole proof of a user-facing
  behavior. For libraries or services without a UI, treat the public API or
  command boundary as the user entry point.
- Keep tests deterministic, isolated, and representative of production data
  shapes. Run focused tests while iterating and the relevant full suite before
  declaring the work complete.

## Workflow

- Read the relevant code, project instructions, tests, and external contracts
  before changing behavior. Follow established project conventions unless
  there is a documented reason to change them.
- Surface ambiguity and state assumptions, especially around security, data
  integrity, failure handling, and externally visible behavior. Do not silently
  guess.
- Keep the change focused, verify it with the appropriate checks, and report
  any unverified risk or unavailable test environment clearly.

## Shell Environment (macOS, zsh)

Facts about this machine's shell that are not discoverable from a transcript.
Last verified 2026-08-23.

### Editing shell config

- `~/.zshrc`, `~/.zshenv`, `~/.zprofile` and `~/.zsh/` are **managed by
  chezmoi** (source: `~/.local/share/chezmoi`, public GitHub remote). Editing
  them in place is fine, but the change is not durable until it is re-added to
  the chezmoi source and committed. A later `chezmoi apply` silently reverts
  anything that was not.
- `.zshrc` is bootstrap only. Real configuration lives in `~/.zsh/NN-*.zsh`,
  one concern per file, loaded by a glob loop. Read `~/.zsh/README.md` before
  changing any of it — it records why each decision was made, and several look
  wrong until you know the reason.
- Test shell changes in `~/.config/zsh-sandbox/run-sandbox.sh` (isolated via
  `ZDOTDIR`) before touching the live files. Same convention as
  `~/.config/tmux/run-sandbox.sh`.

### What is already handled for you

`~/.zsh/99-agent-guard.zsh` detects agent and non-interactive shells and sets
`PAGER`/`GIT_PAGER`/`MANPAGER`/`DELTA_PAGER=cat`, disables `correct_all`, and
removes the `cat`/`ls`/`tmux`/`vim` aliases. Consequences:

- Do **not** add `| cat`, `--no-pager`, or `PAGER=cat` defensively. It is done.
- Do **not** "fix" `core.pager = delta` in `~/.gitconfig` or `MANPAGER` in
  `.zprofile`. Those are correct for interactive use and already neutralised
  for you. Without the guard, `git show`, `git diff` and `man` hang under a
  pty (verified: exit 124).
- In an agent shell `cat`, `ls` and `vim` are the real binaries. Interactively
  they are `bat`, `eza` and `nvim`.

### Useful local commands

Defined in `~/.zsh/`; prefer them over ad-hoc equivalents.

| Command | Use |
|---|---|
| `manx <page> <SECTION>` | one man-page section — `manx rsync EXAMPLES` is 32 lines, not 1,300 |
| `mopt <page> <flag>` | one flag's paragraph — `mopt tar -z` |
| `mh <page>` | list a page's section headers |
| `gctx` | compact repo state: branch, ahead/behind, dirty files, recent commits |
| `wt <branch>` | git worktree as a sibling dir (`repo-branch-name`) + its tmux session |
| `s <pattern>` | live ripgrep, interactive — for humans, not for agent use |

`manx` and `mopt` exist specifically so a man page can be consulted without
spending a context window on it. Reach for them instead of `man <page>`.

### Hazards

- **Never run `tempclean`, or `safe_clean` with `trash` or `delete`.** They
  move or remove the contents of `~/Library/Caches`, `~/Library/Logs`,
  `/private/var/folders` and `/tmp`. `safe_clean dry` is read-only and safe.
  This is not a hypothetical: it was triggered once by being mistaken for a
  read-only probe inside a verification one-liner.
- Parallel agents on one repository share a working tree and will overwrite
  each other. Use `wt <branch>` to give each one its own checkout.
- Atuin records exit codes only from 2026-08-23 onward; the 6,950 commands
  imported from `~/.zsh_history` all carry `exit = -1` (unknown), because a
  plain zsh history file never stored exit status.

## ADHD output mode

If your config directory contains an `.i-have-adhd-always` flag — check
`~/.claude/`, `~/.codex/`, `~/.gemini/`, or `~/.config/opencode/` for the one
matching the harness you are running in — read
`~/.agents/skills/i-have-adhd/SKILL.md` and follow it for every response until
the reader says "stop adhd mode". Skip this if the ruleset is already present
in your context (harnesses with hooks or plugins inject it themselves).
