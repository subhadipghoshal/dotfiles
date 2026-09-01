---
name: python-engineering
description: "Apply idiomatic Python engineering guidance when modifying Python code. Use for Python implementations and APIs; repository configuration and conventions take precedence."
---

# Python Engineering

- Inspect `pyproject.toml`, lockfiles, supported Python versions, nearby code, and repository commands before choosing patterns or tools.
- Follow the configured environment, package manager, formatter, linter, type checker, and test framework. Do not substitute preferred tools for repository choices.
- Add type annotations to public APIs and non-trivial internal boundaries. Prefer explicit domain models over loosely structured dictionaries when the data has stable meaning.
- Raise exceptions for exceptional failures. Catch specific exceptions, preserve context when translating them, and catch broadly only at a boundary that reports or rethrows the failure.
- Keep synchronous and asynchronous boundaries explicit. Do not block an event loop or introduce async without an I/O or concurrency need.
- Prefer simple functions and composition. Add classes or structured models when identity, state, validation, or lifecycle makes them clearer.
- Use comprehensions only when they remain immediately readable.
