---
name: behavior-first-testing
description: "Design, implement, or review tests around observable behavior. Use for user-visible changes, public API or CLI behavior, regression coverage, test strategy, or acceptance verification."
---

# Behavior First Testing

Use end-to-end user behavior as the primary acceptance lens. Start at the real user or public-caller entry point, exercise relevant system boundaries, and verify observable results and side effects.

## Scenarios

Derive scenarios from user journeys and requirements rather than the current implementation. Cover the relevant successful flow, validation and permission failures, empty and boundary states, retries, timeouts, dependency failures, and important state transitions. Do not add irrelevant cases merely to satisfy a checklist.

Every user-visible bug fix should have a regression test at the highest practical level.

## Test boundaries

Prefer realistic fixtures and real components at important boundaries. Mock only uncontrollable external systems or prohibitively expensive dependencies, and verify mocked contracts separately.

Assert behavior and outcomes rather than private implementation details. For libraries and services without a user interface, treat the public API or command boundary as the user entry point. Use integration and unit tests to localize failures and cover detailed rules, not as the sole proof of user-facing behavior.

## Verification

Keep tests deterministic, isolated, and representative of production data shapes. Run focused tests while iterating and the relevant full suite before completion. Report the commands, results, and any behavior that could not be verified.
