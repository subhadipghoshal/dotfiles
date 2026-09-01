# Test plan template

1. **Coverage boundary**: the unit-versus-behavior line in one paragraph.
2. **Scenario groups**: `SG-1`, `SG-2`, and so on. Each carries the observable behavior under
   test, the work packages it exercises, an exclusive test-file scope, the cases (happy path,
   validation and permission failures, boundary and empty states, failure injection, state
   transitions, migration and rollback when applicable), what is real versus mocked at each
   boundary, the verification command, and the acceptance bar.
3. **Cross-cutting**: performance, security, compatibility.
4. **Known gaps**: what this plan does not cover and why.

Scenario groups are to QA engineers exactly what work packages are to builders: disjoint scopes
make the fan-out mechanically decidable, and the same table is read by every adapter.
