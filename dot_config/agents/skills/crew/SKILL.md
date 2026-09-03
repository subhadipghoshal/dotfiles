---
name: crew
description: "Run a task through a role-separated engineering crew: triage, plan, build, verify, review, with each role in its own tmux pane. User-invocable only; Claude does not convene a crew on its own."
disable-model-invocation: true
---

# `/crew`

You are the engineering manager. This is the session you type into — there is no separate
manager agent file. Everything below is your contract for the rest of this run.

## Arguments

Arguments: $ARGUMENTS

- `/crew <task>` — human-in-loop mode, the default and the point.
- `/crew auto <task>` — auto mode.
- `/crew` with no task — ask what the task is. Do not guess; a crew convened against a vague
  prompt produces a plan against a vague prompt.

## What you never delegate

Integration, conflict resolution, gate decisions, and the final response. These stay with you
regardless of mode.

## Triage (phase 0)

Load `complexity-assessment`, classify the task against the existing low/medium/high risk
classes in `AGENTS.md`'s `## Risk-gated execution`, and select the crew from the matrix in this
directory's `README.md`. Write `triage.md` (see Artifacts below), recording the risk class, its
drivers, the roster with a one-line reason per role, the expected parallelism, and **the mode**.

Trivial work is reported as not worth a crew, then either done directly or handed back — do not
run the machinery anyway just because `/crew` was typed.

**Gate 1 (human-in-loop only):** show the risk class and roster, and wait. This is the cheapest
gate in the run.

## The two modes

One parameter controls both: pass `name` to `Agent` for a teammate in its own tmux pane
(human-in-loop), omit it for an in-process subagent (auto). `subagent_type`, `model`, `prompt`,
`cwd`, and `isolation` are identical either way. Auto mode records gate decisions in the
artifacts instead of blocking on you; every role contract and every artifact path is otherwise
unchanged.

Auto mode is available today with the panes turned off. If a harness has no teammate primitive
at all (everything but Claude Code), it only ever runs auto mode — say so plainly.

## Dispatch (harness-neutral)

Every dispatch is cold: file paths, requirements, and a base ref, never a transcript. A teammate
in a pane is still dispatched cold — the pane lets a human watch it think, it does not let it
inherit anyone's context.

**Phase 1, plan.** Architect (writes `plan.md`) → data architect if flagged (writes
`data-model.md`, reconcile any amendment request against `plan.md` yourself rather than letting
the two files disagree) → QA lead once the design is final (writes `test-plan.md`).
**Gate 2:** resolve open questions across all three artifacts before any code exists. In
human-in-loop, close the planning panes here.

**Phase 2, build.** Count work packages with `dependencies: none` and disjoint scopes. 2+: one
builder per package, concurrent, each in its own worktree (`isolation: "worktree"`); cap a wave
at 3 in human-in-loop and run further packages in a second wave after the first merges. Exactly
1: one builder in place, no isolation. A builder whose own verification command fails goes back
to the same builder with its worktree intact — that is a self-check, not a gate.
**Integrate yourself**: merge branches, resolve conflicts, run the full relevant suite, and
consolidate the builders' coverage manifests into `coverage-manifest.md`.

**Phase 3, verify.** One QA engineer per scenario group from `test-plan.md`, on the integrated
commit, each carrying the test plan, requirements, diff surface, and `coverage-manifest.md` —
never a builder's report. Worktrees off the integrated commit for 2+ groups; same 3-per-wave cap
in human-in-loop. Verify each returned diff touches only its declared test scope
(`git diff --name-only` against the group's scope).
**Gate 3:** record results in `qa-r1.md`. Failing scenarios block. Defects route to a fresh
in-place builder on the integrated commit; a wrong test routes back to the QA engineer that
wrote it. Bounded at 2 rounds; re-run only affected scenario groups after each fix.

**Phase 4, review.** Dispatch the reviewer with **only** the original requirements, plan path,
base ref, repo path, applicable repo instructions — never builder or QA reports, never the
coverage manifest, never suspected defects. In human-in-loop, close every remaining crew pane
first, then run `TaskList` and confirm no entry names a defect, a suspicion, or a file (see the
coarse-board rule below) before dispatching.
**Gate 4:** apply the `adversarial-review` gate table. In priority order: multi-type findings go to human disposition and are logged; security findings (any severity) go to human disposition; documentation findings (any severity) go to agent fix; high/critical go to human disposition; medium with layer=design goes to human disposition; medium with confidence=suspected does not block; remaining medium go to agent fix; low does not block. In human-in-loop, medium is yours to call. Fix loop bounded at 2 rounds, fresh in-place builder each time, re-review every round.

For each multi-type finding (rule 1), before routing for human disposition: append an entry to `~/.local/state/agents/adversarial-review/multi-type-findings.md`, creating the file and its directory if absent. Entry format: `<date> | <task-slug> | <finding title> | types: <comma-list> | <one-line reason single-type classification was insufficient>`.

**Teardown (human-in-loop).** Close the reviewer pane and delete the team as each phase's
teammates go idle (`TeammateIdle` is the signal — act on it rather than polling).

## The two independence rules

- **The reviewer never sees builder or QA narrative.** Its dispatch is fixed (above); the
  artifacts carry the narrative, the reviewer's dispatch does not.
- **Neither side edits the other's tests.** Builders own unit tests in their package; QA owns
  behavior/integration tests from the test plan. A failing QA test is a source defect routed to
  a builder, not something QA rewrites; a wrong QA test routes back to QA, not to a builder.

## The coarse-board rule (human-in-loop)

The shared task board carries phase-level entries only — "Phase 3: verify" is legal,
"SG-2 login timeout fails, suspect the retry wrapper" is not. Anything a builder or QA engineer
learned goes in its artifact file, which you read and the reviewer never opens. Before
dispatching the reviewer, run `TaskList` and confirm no task subject or description names a
defect, a suspicion, or a file. If one does, rewrite the task before dispatching — do not
dispatch the reviewer against a contaminated board.

## The intern tier, in three lines

Mechanical work only (find every occurrence, run a command and report, a stated mechanical
edit, scaffolding, a factual inventory, fetch-and-summarize a document) — spawned by crew roles,
never by you — results owned by the caller, and interns write no artifacts.

## Degradation

A harness with no delegation primitive at all (Pi) says so plainly and does the task
single-context with the review gate satisfied by shelling out, rather than faking a split. A
harness with subagents but no teammate panes (OpenCode, Codex, Gemini) runs auto mode and says
which mode it is in.

## Artifacts

One directory per task, outside any repo:
`~/.local/state/agents/crew/<YYYY-MM-DD>-<slug>/`, holding `triage.md`, `plan.md`,
`data-model.md` (conditional), `test-plan.md`, `coverage-manifest.md`, `qa-r1.md`, `review-r1.md`,
and `qa-r2.md`/`review-r2.md` if a fix loop ran. Artifacts are the coordination medium in both
modes — the mailbox is for liveness and questions, not decisions, and does not survive teardown.

## Role contracts

Point every dispatch at the role contract by absolute path so the same body works from any
harness:

- `~/.config/agents/skills/crew/architect.md`
- `~/.config/agents/skills/crew/data-architect.md`
- `~/.config/agents/skills/crew/qa-lead.md`
- `~/.config/agents/skills/crew/builder.md`
- `~/.config/agents/skills/crew/qa-engineer.md`
- `~/.config/agents/skills/crew/reviewer.md`
- `~/.config/agents/skills/crew/intern.md`

Templates for the artifacts: `plan-template.md`, `data-model-template.md`,
`test-plan-template.md`, all in this directory.
