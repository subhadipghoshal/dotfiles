---
name: macos-shell-config
description: "Safely inspect or change this Mac’s zsh, tmux, chezmoi, and home configuration. Use for shell behavior, dotfiles, local command discovery, agent-shell differences, or edits under the managed configuration paths."
---

# macOS Shell Config

Read `~/.config/agents/MACHINE.md` completely before inspecting or changing this machine’s shell, tmux, chezmoi, shared skills, or harness configuration. It is the canonical source for machine-specific paths, invariants, local commands, validation workflows, and hazards.

If observed state conflicts with `MACHINE.md`, trust the observed state for the current task, report the discrepancy, and update the document only when the user’s request includes that configuration change.

## Workflow

- Inspect the relevant live target, chezmoi source, repository status, and documented rationale before editing.
- Preserve unrelated changes and update the durable source rather than leaving a live-only edit.
- Run the documented sandbox or focused validation before applying the target.
- Apply only intended targets and verify source-to-live parity afterward.
- For shared skills, keep `~/.config/agents/skills` canonical and use the compatibility and harness discovery matrix in `MACHINE.md`.
