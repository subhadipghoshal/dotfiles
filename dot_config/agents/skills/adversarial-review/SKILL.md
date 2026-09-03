---
name: adversarial-review
description: "Independently review code changes as a fresh-context principal engineer with severity-gated findings. Use before completing any code-change task; review only, never author fixes."
---

# Adversarial Review

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
Confidence: confirmed | likely | suspected
Type: security | correctness | reliability | documentation  (comma-separate if multi-type)
Radius: local | component | system
Layer: impl | design
Location: <file:line>
Failure: <what breaks and under which conditions>
Evidence: <code path, contract, or reproducible behavior>
Required action: <specific resolution criteria>
```

All eight fields are required. When a dimension value is ambiguous, use the more conservative option and note the uncertainty in Evidence.

**Confidence** - evidence strength: `confirmed` means the failure is directly readable from the diff and no external assumptions are needed; `likely` means strong inferential evidence exists with one untested assumption (caller behavior, runtime ordering, or an implicit contract); `suspected` means the issue is plausible given the pattern but confirming it requires evidence outside the diff.

**Type** - issue category: `security` (auth, access-control, secret handling, injection, data exposure, cryptographic correctness); `correctness` (logic errors, data integrity, race conditions, concurrency, compatibility, migration); `reliability` (failure handling gaps, resource leaks, performance degradation, missing observability, config, or circuit protection); `documentation` (API contracts, public-facing docs, changelogs, ADRs, or in-code comments where inaccuracy materially increases misuse risk). Scope findings precisely enough that one type applies. If a finding genuinely straddles categories, list both comma-separated - multi-type is a meaningful signal, not a fallback; you must be able to articulate why single-type classification fails.

**Radius** - blast radius: `local` (one function or isolated path; no external callers affected); `component` (within a single module, service, or package); `system` (cross-component, public API, or shared contract; external callers or end users in scope). Informational - informs disposition scope but is not itself a gate trigger.

**Layer** - fix authority required: `impl` means the fix is contained within the existing design and no contract or boundary change is needed; `design` means the fix requires changing a public contract, interface, schema, or architectural boundary and design authority must decide the fix shape before implementation begins.

## Severity

- `critical`: Exploitable security failure, access-control bypass, secret exposure, irreversible data loss, or credible systemic outage.
- `high`: Major correctness, security, compatibility, migration, or reliability defect likely to cause substantial user or operational harm.
- `medium`: Concrete bounded defect, missing failure handling, or material test/maintainability gap that should be fixed before completion.
- `low`: Minor risk, clarity, or maintainability issue with no plausible material failure. Low findings do not block completion.

## Resolution gate

The reviewer's responsibility is to emit findings with all eight fields populated. Gate decisions belong to the caller (manager), not the reviewer.

Apply in priority order; first match wins:

| Priority | Condition | Outcome |
|---|---|---|
| 1 | type contains more than one value | Human disposition + log to memory |
| 2 | type = `security` (any severity) | Human disposition |
| 3 | type = `documentation` (any severity) | Agent fix |
| 4 | severity = `critical` or `high` | Human disposition |
| 5 | severity = `medium`, layer = `design` | Human disposition |
| 6 | severity = `medium`, confidence = `suspected` | No block |
| 7 | severity = `medium` | Agent fix |
| 8 | severity = `low` | No block |

**Rule 1:** A multi-type finding is a meaningful signal that the issue crosses category boundaries. It escalates to human disposition regardless of severity and must be logged to `~/.local/state/agents/adversarial-review/multi-type-findings.md` (entry: date, repo, finding title, types observed, reason single-type classification failed) for future taxonomy refinement.

**Rule 2:** Any security-typed finding goes to human disposition regardless of severity, confidence, or layer. A low-severity security observation still deserves human eyes.

**Rule 3:** Any documentation-typed finding goes to agent fix regardless of severity. If a documentation gap is severe enough to also have correctness or security implications, it spans types and hits rule 1 instead. Rule 3 fires before the severity and layer rules, so documentation bypasses design-layer and high/critical escalation paths.

Radius informs disposition scope but is not a gate trigger. In human-in-loop workflows, the manager may override any medium-tier outcome with direct disposition.

- A finding closes only after an independent reviewer verifies the fix, or a human explicitly disposes a high or critical finding. Re-review the resulting diff for regressions and new findings.
- Do not report completion or close a pull request while any medium, high, or critical finding remains open. Closing or merging an external pull request still requires explicit user authorization.
- If there are no findings, state that explicitly and list the diff and verification boundaries reviewed.
