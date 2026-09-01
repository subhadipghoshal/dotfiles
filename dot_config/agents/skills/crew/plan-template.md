# Plan template

Sections in order. The builder sees this file and nothing else — write for a cold reader.

1. **Problem**: what and why, acceptance criteria.
2. **Findings**: existing code to reuse, with `file:line`.
3. **Decision**: one chosen approach with rationale. No option menus.
4. **Data design** (only when data is touched): entities, ownership, migration shape, plus the
   `data-architect: required | not-required` flag and its one-line rationale.
5. **Work packages**: `WP-1`, `WP-2`, and so on, each with exclusive file scope, dependencies
   (`none` or `WP-n`), acceptance criteria, unit-test expectations, verification command.
6. **Integration**: merge order, conflict-prone seams.
7. **Verification**: how to prove it end to end.

The work-package table is what makes parallelism mechanically decidable: packages with
`dependencies: none` and disjoint scopes run concurrently. Every adapter reads the same table.
