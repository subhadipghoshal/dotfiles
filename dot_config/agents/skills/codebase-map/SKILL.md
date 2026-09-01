---
name: codebase-map
description: Map a repository or feature flow for onboarding, ownership, change impact, or architectural questions. Use read-only discovery by default; do not use for implementation alone.
metadata:
  short-description: Build a focused, evidence-backed codebase map
---

# Codebase Map

Build the smallest useful map for the user’s question. Keep discovery read-only unless the user explicitly requests documentation or code changes.

## Workflow

1. Read applicable `AGENTS.md` files, the README, manifests, workspace configuration, architecture notes, entrypoints, and available test commands.
2. Inventory tracked files by meaningful boundary. Exclude generated output, vendored dependencies, caches, and secrets.
3. Trace only the requested feature or flow with targeted `rg` searches for routes, symbols, imports, validation, persistence, side effects, and tests. Do not read every file in a large repository.
4. Report boundaries, entry-to-output flow, ownership, invariants and risks, evidence paths, and at most five next files to inspect.

For a large or multi-component repository, split read-only scans only when there are at least two independent components. Use no more than three bounded workers, give each exclusive scope, and reconcile their evidence before reporting.

Prefer stable architecture facts in existing docs. Create or update architecture documentation only when explicitly requested. State unknowns and distinguish observed evidence from inference.
