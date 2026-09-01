---
name: principal-code-review
description: "Independently review code changes as a fresh-context principal engineer with severity-gated findings. Use before completing any code-change task; review only, never author fixes."
---

# Principal Code Review

Be adversarial toward the code and professional toward people. Search aggressively for real failure modes; report only actionable, evidence-backed findings.

## Independence

- Use a new sub-agent with no authoring conversation or inherited context. The reviewer must not have authored the change.
- Run the reviewer as the `deep-work` agent (or otherwise at `xhigh` effort or above), regardless of the session's own baseline. A review is the one place where under-resourcing is the dangerous direction: a cheap reviewer that misses a defect manufactures confidence rather than catching one.
- If the harness cannot create a fresh non-authoring reviewer, completion is blocked and requires human disposition. Self-review never satisfies this gate.
- Provide only the original requirements and acceptance criteria, base ref, exact worktree path, and applicable repository instructions. Do not provide author reasoning, summaries, suspected defects, or prior conclusions.
- Pause writers during review. The reviewer may inspect files and run relevant verification but must not edit, commit, or fix code.

## Review

Inspect the complete diff and relevant surrounding callers, contracts, tests, configuration, migrations, and failure paths. Challenge correctness, security, data integrity, concurrency, compatibility, reliability, resource use, performance, operability, test coverage, and maintainability. Run focused checks when they materially improve confidence.

Report each finding as:

```text
[SEVERITY] R<number>: <title>
Location: <file:line>
Failure: <what breaks and under which conditions>
Evidence: <code path, contract, or reproducible behavior>
Required action: <specific resolution criteria>
```

## Severity

- `critical`: Exploitable security failure, access-control bypass, secret exposure, irreversible data loss, or credible systemic outage.
- `high`: Major correctness, security, compatibility, migration, or reliability defect likely to cause substantial user or operational harm.
- `medium`: Concrete bounded defect, missing failure handling, or material test/maintainability gap that should be fixed before completion.
- `low`: Minor risk, clarity, documentation, or maintainability issue with no plausible material failure. Low findings do not block completion.

## Resolution gate

- Medium and low findings may be assigned to an authoring or separate fixing agent. High and critical findings stop automatic fixes and require explicit human disposition.
- A finding closes only after an independent reviewer verifies the fix, or a human explicitly disposes a high/critical finding. Re-review the resulting diff for regressions and new findings.
- Do not report completion or close a pull request while any medium, high, or critical finding remains open. Closing or merging an external pull request still requires explicit user authorization.
- If there are no findings, state that explicitly and list the diff and verification boundaries reviewed.
