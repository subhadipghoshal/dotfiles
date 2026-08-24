# Global engineering rules

These rules apply to every repository and task unless a more specific project instruction overrides them. Prefer correctness, clarity, maintainability, and operational safety over implementation speed.

## Operating boundaries

- Classify the request as explanation, review, diagnosis, or implementation. Explanation, review, and diagnosis are read-only unless the user requests a change; relevant non-mutating checks are allowed.
- Change and build requests authorize edits only within the requested scope. Do not infer permission to deploy, send messages, commit, push, or mutate external systems.
- Read applicable `AGENTS.md` files, project documentation, relevant code, tests, configuration, and external contracts before changing behavior.
- State assumptions when ambiguity affects security, data integrity, compatibility, rollout, or externally visible behavior. Stop for direction when a missing choice would materially change the result.

## Implementation

- Prefer explicit, readable code and names that describe domain intent. Keep functions, modules, and types cohesive with minimal hidden coupling.
- Separate decision logic from I/O and other side effects when that improves local reasoning.
- Make the smallest complete change. Avoid speculative abstractions, unrelated refactors, silent fallbacks, ignored errors, and compatibility layers without a concrete contract.
- Remove dead code. Comments should explain non-obvious intent, constraints, or tradeoffs rather than restating the code.

## Workspace and Git safety

- In an unfamiliar workspace, inspect the current directory, applicable instructions, repository status, and a concise file listing. Use `rg` or `rg --files` for search.
- Preserve unrelated user changes. Never reset, discard, overwrite, or reformat work outside the task. Use isolated worktrees for parallel agents.
- Do not run `git reset --hard`, `git checkout --`, force pushes, broad deletes, or destructive migrations without explicit confirmation. Resolve destructive targets first; never use `$HOME`, `~`, `/`, or a workspace root as a recursive target.
- Use `apply_patch` for focused edits. Avoid shell redirection, `cat`, Python, or ad-hoc scripts to overwrite files when a patch is suitable.
- Commit only when the user asks or the requested workflow explicitly requires it.

## Verification and handoff

- Use real user or public-caller behavior as the acceptance lens. Exercise relevant boundaries and verify externally observable results and side effects.
- Add regression coverage for user-visible bugs at the highest practical level. Keep tests deterministic, isolated, and representative of production data shapes.
- Run focused checks while iterating and the relevant full suite before completion. If verification is unavailable, report exactly what was not checked and why.
- Report changed files, verification commands and results, remaining risks, and one concrete next action when user work remains.

## Task-specific guidance

- Use `$complexity-assessment` for technical planning, scoping, or complexity estimates.
- Use `$defensive-design` for external boundaries, authentication, persistence, asynchronous work, retries, concurrency, resource limits, or migrations.
- Use `$behavior-first-testing` when changing user-visible behavior or designing, implementing, or reviewing tests.
- Use `$macos-shell-config` before changing zsh, tmux, chezmoi, or home configuration on this Mac.

## Machine safety and communication

- Machine-specific facts and harness topology live in `~/.config/agents/MACHINE.md`; read it when work depends on this Mac's configuration.
- Never run `tempclean`, or `safe_clean` with `trash` or `delete`. `safe_clean dry` is the only permitted agent invocation.
- The agent shell already neutralizes interactive pagers and aliases. Do not add `| cat`, `--no-pager`, or temporary pager overrides, and do not “fix” the interactive pager configuration.
- If the active harness has an `.i-have-adhd-always` flag, follow `~/.config/agents/skills/i-have-adhd/SKILL.md`. Skip reloading it when the rules are already present in context.
