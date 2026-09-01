---
name: csharp-engineering
description: "Apply modern C# and .NET engineering guidance when modifying C# code. Use for .NET implementations and APIs; repository conventions take precedence."
---

# C# Engineering

- Inspect project files, `Directory.Build.*`, `.editorconfig`, target frameworks, analyzers, and nearby code before choosing patterns or tools.
- Respect nullable reference types. Model absence explicitly; do not use the null-forgiving operator merely to silence analysis.
- Keep asynchronous call paths async. Do not block tasks with `.Result` or `.Wait()`; propagate cancellation where the surrounding API supports it.
- Use dependency injection at architectural boundaries. Construct simple domain objects directly, and introduce interfaces only for a concrete abstraction need.
- Prefer records for value semantics and immutable data when appropriate; use classes when identity, mutable state, or lifecycle matters. Prefer composition over inheritance.
- Dispose resources deterministically with `using` or `await using` as required.
- Use repository build, formatting, analyzer, and test commands; do not weaken compiler or analyzer settings to make a change pass.
