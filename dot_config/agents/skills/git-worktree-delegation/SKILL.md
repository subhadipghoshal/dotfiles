---
name: git-worktree-delegation
description: "Create isolated Git worktrees whenever multiple write-capable sub-agents modify one repository, concurrently or sequentially. Not for read-only subtasks or separate repositories."
---

# Git Worktree Delegation

Use one worktree per write-capable agent for the full task, including later fixing agents. Worktrees isolate files, not merge conflicts, so give agents exclusive scopes even when their branches differ.

## Create before spawning

1. Confirm the write subtasks are independent. Every distinct author or fixer gets its own worktree; a read-only reviewer may inspect a paused author's worktree without another worktree.
2. Inspect `git status` and `git worktree list`; resolve the intended base to a commit. Uncommitted changes are never copied, stashed, or inferred into a new worktree.
3. Choose a unique new branch for each agent. Follow user or repository conventions; otherwise use `codex/<task>-<agent>`.
4. Run `scripts/create-worktree.sh <repository-path> <branch> <base-commit>`. If sandbox policy blocks sibling-directory creation, request approval for that exact command. Stop on failure; never retry with force.
5. Spawn the agent with the returned absolute path, branch, base commit, and exclusive scope. Require every tool call to use that worktree and first verify `git rev-parse --show-toplevel` equals the assigned path.

## Handoff and safety

- The script creates a new branch and sibling worktree, then prints only its absolute path to stdout. Diagnostics go to stderr.
- It disables repository checkout hooks during creation and never fetches, starts tmux, changes the caller's directory, stashes, copies changes, commits, pushes, removes worktrees, or deletes branches.
- Agents report changed files, diff, and verification. They do not commit unless the user or requested workflow authorizes it; the primary agent owns integration.
- If a different agent must continue uncommitted work, do not share the original worktree. Keep the original author or establish an authorized committed/integrated base before creating the fixer's worktree.
- Retain worktrees until integration and review finish. Cleanup requires an explicit, separately validated target; never remove a dirty worktree or branch automatically.
