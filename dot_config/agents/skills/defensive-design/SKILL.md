---
name: defensive-design
description: "Design or review resilient system boundaries. Use for APIs, authentication, persisted data, files, queues, webhooks, retries, concurrency, resource limits, migrations, or other failure-prone integration work."
---

# Defensive Design

Apply the guidance relevant to the boundary under review. Do not expand an ordinary task into a general security audit.

## Boundaries and invariants

Treat user input, network responses, internal callers, configuration, persisted data, files, queues, and webhooks as untrusted. Validate and normalize at the boundary, enforce domain invariants, and fail closed with explicit, actionable errors. Never hide failure behind a silent fallback.

Enforce authentication and authorization at the server-side boundary. Use least privilege and keep secrets out of source, logs, error messages, and fixtures.

## Failure behavior

Account for retries, duplicate delivery, timeouts, stale or malformed data, partial outages, concurrent updates, and interrupted work. Make retryable side effects idempotent and clean up resources reliably.

Bound resource use. Define timeouts, cancellation, and backpressure for operations that wait on external work or process untrusted input.

## Change safety

Preserve compatibility only for a concrete persisted or external contract. For breaking changes, define migration, rollout, and rollback behavior. Document important tradeoffs near the design or in an architecture decision record.

Make failures observable through the logs, metrics, traces, or health signals appropriate to the system. Verify each important invariant and failure path at the highest practical boundary.
