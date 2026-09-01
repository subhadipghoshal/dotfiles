---
name: typescript-engineering
description: "Apply idiomatic TypeScript or typed JavaScript engineering guidance when modifying TS/JS code. Use for implementations and APIs; repository conventions take precedence."
---

# TypeScript Engineering

- Inspect `package.json`, the lockfile, `tsconfig`, lint and format configuration, framework conventions, and nearby code before choosing patterns or tools.
- Use the repository package manager and scripts. Preserve configured strictness; do not weaken type or lint settings to make a change pass.
- Prefer precise types, discriminated unions, and exhaustive narrowing. Avoid `any`, unchecked assertions, and non-null assertions unless a validated boundary makes the invariant explicit.
- Validate external data at runtime; TypeScript types do not validate network, file, environment, or user input.
- Keep promise ownership and failure handling explicit. Await or return promises, preserve useful error context, and avoid floating work.
- Keep types near their owners and prefer functions and composition. Add generics or shared abstractions only when multiple concrete uses justify them.
- For JavaScript projects, apply the same boundaries through configured JSDoc or `checkJs` without imposing a TypeScript migration.
