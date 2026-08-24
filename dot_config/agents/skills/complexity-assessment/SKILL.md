---
name: complexity-assessment
description: "Assess technical complexity from scope, uncertainty, coupling, risk, and verification. Use when planning, sizing, estimating, or comparing engineering work; do not use for ordinary implementation without an estimation request."
---

# Complexity Assessment

Assess the work itself, not how quickly a particular human or agent could perform it.

## Assessment

Evaluate the factors that materially affect implementation and verification:

- Technical scope and number of affected components
- Uncertainty, unfamiliar dependencies, and missing contracts
- Coupling, data or interface changes, and compatibility requirements
- Failure modes, migration and rollback risk, and operational impact
- Verification effort across realistic boundaries

Do not use developer velocity, typing speed, familiarity, agent capability, or expected implementation duration as complexity inputs. If the user also requests a schedule estimate, report it separately and state its assumptions.

Before implementation, identify the affected behavior, dependencies, invariants, risks, rollout concerns, and evidence that would demonstrate completion.

## Output

Provide a concise complexity rating with its main drivers, affected surfaces, important uncertainty, and required verification. Distinguish a small code diff from a low-risk change: either can exist without the other.
