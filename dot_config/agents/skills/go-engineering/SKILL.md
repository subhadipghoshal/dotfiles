---
name: go-engineering
description: "Apply idiomatic Go engineering guidance when modifying Go code. Use for Go implementations, packages, or concurrency; repository conventions take precedence."
---

# Go Engineering

- Inspect `go.mod`, the supported Go version, nearby packages, and repository commands before choosing patterns or tools.
- Prefer idiomatic Go over patterns imported from class-oriented languages. Keep packages cohesive and use composition.
- Define small interfaces near consumers. Do not create an interface for one implementation without a concrete boundary, substitution, or testing need.
- Return errors explicitly and add useful context while preserving the wrapped cause. Do not use panic for ordinary failures or ignore returned errors.
- Add concurrency only when it improves the solution. Make goroutine ownership, termination, cancellation, and shared-state synchronization explicit.
- Propagate `context.Context` across cancellable call boundaries; do not store it as long-lived object state.
- Use repository formatting, analysis, and test commands. Prefer table-driven tests only when they make cases easier to read and maintain.
