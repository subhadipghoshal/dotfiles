---
name: tmux-config-debugging
description: "Verify tmux configuration changes against tmux's silent-failure modes. Use when adding or debugging tmux bindings, format strings, status lines, or plugins; general shell, dotfile, and chezmoi change-safety belongs to macos-shell-config."
---

# Tmux Config Debugging

Tmux silently fails in ways that few tools catch. This skill documents 8 discovery-based verification techniques drawn from rebuilding `~/.config/tmux` from scratch. Use these rules whenever you modify bindings, format strings, status lines, or install plugins — they will save you hours chasing phantom configuration bugs.

For general shell and dotfile change-safety patterns, see `macos-shell-config` instead. For tmux feature scope and design philosophy, refer to `~/.config/agents/MACHINE.md` (keyboard/terminal constraints) and `~/.config/tmux/run-sandbox.sh` (sandbox testing).

## Which tool proves what

- **`send-keys` writes bytes to the pane pty and never exercises root-table bindings.** Only a real attached client or PTY does. Use `send-keys` to test shell behavior only; for key-binding logic, test pieces separately (`if-shell` detection, `select-pane` commands) or attach a real client via `~/.config/tmux/run-sandbox.sh` and press keys directly.
- **`display-message -p` reliably tests `#[...]` and `#{?...}` logic but returns empty for `#(shell)` async jobs.** Format-string ternaries and color tags render correctly; shell commands that spawn async "jobs" always return empty on a one-off call (they cache and return on a *later* evaluation, which a recurring option like `status-right` sees, but `display-message -p` does not). For `#(...)` formats, attach a real client and wait for the job to complete and redraw.
- **`show-options -gv | xxd` is unreliable for verifying non-ASCII bytes.** It gave false negatives for arrow glyphs that were unambiguously present in a real rendered status line. For embedded non-ASCII sequences, check real rendered client output — `display-message -p` and `show-options` are fine for plain-ASCII format logic, not proven reliable for bytes.

## Silent failure modes

- **`#{?cond,TRUE,FALSE}` splits on every comma, including ones inside embedded `#[fg=,bg=]` tags.** The comma between `fg=` and `bg=` gets read as the TRUE/FALSE delimiter. Fix: chain single-attribute tags instead: `#[fg=colour232]#[bg=colour208]` (no comma, no ambiguity). Test with `display-message -p`.
- **A prefix-then-symbol binding dies silently if Ctrl stays held down.** `prefix + -` sends byte `0x2d` if Ctrl is released between prefix and `-`, but byte `0x1f` if held through both (same as `Ctrl-_`, since Ctrl-code generation depends only on the key's low 5 bits). Neither byte was bound to anything, so the split failed silently. Fix: bind both the symbol and its Ctrl-held byte: add `bind -T root C-_ 'split-window -h'` alongside `bind C-a - 'split-window -h'`. Same applies to `|` and `Ctrl-\` (`0x1c`). Confirm end-to-end with a real attached client, not `send-keys`.
- **An embedded `#[fg=...,bg=...]` tag inside a format string wins over the separate base `*-style` option for that same span.** The base style is not a fallback for anything the format string explicitly colors. If a themed plugin (e.g., catppuccin/tmux) builds format strings with inline color tags baked in, a `set status-style ...` override only visibly dims the bar's uncovered background, not the colorful segments. Check whether the theme uses inline tags before relying on a style override.

## After installing a plugin

- **Config is applied in read order with no clobber protection, and the plugin file is sourced last, so any unguarded plugin binding or option wins.** Diff `tmux list-keys` and `show-options` before and after the install; a clean load proves nothing. Plugin changes are invisible until you actually compare full state.
- **TPM re-parses `~/.config/tmux/tmux.conf` from disk for `@plugin` discovery regardless of which file loaded it.** If your config lives elsewhere during development (e.g., `~/.config/tmux-scratch`), TPM's install/update flow cannot see `@plugin` lines there. Once promoted to the real path, the discovery works; add a `run-shell` fallback of the plugin's `.tmux` file as belt-and-suspenders anyway — sourcing twice is a no-op.
