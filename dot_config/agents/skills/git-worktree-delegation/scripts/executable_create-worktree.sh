#!/bin/sh
set -eu

usage() {
  printf 'Usage: create-worktree.sh <repository-path> <new-branch> <base-ref>\n' >&2
  exit 64
}

fail() {
  printf 'create-worktree: %s\n' "$*" >&2
  exit 1
}

[ "$#" -eq 3 ] || usage

repository_path=$1
branch_name=$2
base_ref=$3

[ -d "$repository_path" ] || fail "repository path is not a directory: $repository_path"

case "$branch_name" in
  -*) fail "branch name cannot start with '-': $branch_name" ;;
esac

repository_root=$(git -C "$repository_path" rev-parse --show-toplevel 2>/dev/null) ||
  fail "not inside a non-bare Git worktree: $repository_path"
worktree_list=$(git -C "$repository_root" worktree list --porcelain 2>/dev/null) ||
  fail "cannot list repository worktrees"
primary_root=$(printf '%s\n' "$worktree_list" | sed -n 's/^worktree //p' | sed -n '1p')
[ -n "$primary_root" ] && [ -d "$primary_root" ] ||
  fail "cannot resolve the primary worktree"

git -C "$primary_root" check-ref-format --branch "$branch_name" >/dev/null 2>&1 ||
  fail "invalid branch name: $branch_name"

if git -C "$primary_root" show-ref --verify --quiet "refs/heads/$branch_name"; then
  fail "branch already exists: $branch_name"
fi

base_commit=$(git -C "$repository_root" rev-parse --verify --end-of-options "${base_ref}^{commit}" 2>/dev/null) ||
  fail "base does not resolve to a commit: $base_ref"

dirty_line=$(git -C "$repository_root" status --porcelain | sed -n '1p')
if [ -n "$dirty_line" ]; then
  printf 'create-worktree: source worktree is dirty; uncommitted changes are not included\n' >&2
fi

path_slug=$(printf '%s' "$branch_name" | LC_ALL=C tr -c 'A-Za-z0-9._-' '-' | cut -c1-72)
branch_hash=$(printf '%s' "$branch_name" | git -C "$primary_root" hash-object --stdin | cut -c1-8)
superproject_root=$(git -C "$primary_root" rev-parse --show-superproject-working-tree 2>/dev/null || true)
if [ -n "$superproject_root" ]; then
  repository_hash=$(printf '%s' "$primary_root" | git -C "$primary_root" hash-object --stdin | cut -c1-8)
  worktree_parent="$(dirname "$superproject_root")/$(basename "$superproject_root")-$(basename "$primary_root")-${repository_hash}.worktrees"
else
  worktree_parent="${primary_root}.worktrees"
fi
worktree_path="${worktree_parent}/${path_slug}-${branch_hash}"

[ ! -L "$worktree_parent" ] || fail "worktree parent cannot be a symlink: $worktree_parent"
if [ -e "$worktree_parent" ] && [ ! -d "$worktree_parent" ]; then
  fail "worktree parent is not a directory: $worktree_parent"
fi
if [ -e "$worktree_path" ] || [ -L "$worktree_path" ]; then
  fail "worktree path already exists: $worktree_path"
fi

mkdir -p "$worktree_parent" || fail "cannot create worktree parent: $worktree_parent"

if ! git -c core.hooksPath=/dev/null -C "$primary_root" worktree add -b "$branch_name" "$worktree_path" "$base_commit" 1>&2; then
  printf 'create-worktree: Git failed; inspect worktree and branch state before retrying\n' >&2
  exit 1
fi

printf '%s\n' "$worktree_path"
