#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
script_path="$script_dir/create-worktree.sh"
if [ ! -f "$script_path" ]; then
  script_path="$script_dir/executable_create-worktree.sh"
fi
test_root=$(mktemp -d /tmp/git-worktree-delegation-test.XXXXXX)

cleanup() {
  case "$test_root" in
    /tmp/git-worktree-delegation-test.*) rm -rf -- "$test_root" ;;
  esac
}
trap cleanup EXIT HUP INT TERM

fail() {
  printf 'test-create-worktree: %s\n' "$*" >&2
  exit 1
}

initialize_repository() {
  repository_path=$1
  git init -b main "$repository_path" >/dev/null
  git -C "$repository_path" config user.name 'Worktree Skill Test'
  git -C "$repository_path" config user.email 'worktree-test@example.invalid'
  touch "$repository_path/README.md"
  git -C "$repository_path" add README.md
  git -C "$repository_path" commit -m 'Initial fixture' >/dev/null
}

repository_path="$test_root/main repo"
initialize_repository "$repository_path"
base_commit=$(git -C "$repository_path" rev-parse HEAD)

hook_dir="$test_root/hooks"
hook_marker="$test_root/hook-ran"
mkdir -p "$hook_dir"
printf '%s\n' '#!/bin/sh' 'touch "$WORKTREE_HOOK_MARKER"' >"$hook_dir/post-checkout"
chmod 755 "$hook_dir/post-checkout"
git -C "$repository_path" config core.hooksPath "$hook_dir"
export WORKTREE_HOOK_MARKER="$hook_marker"

first_stderr="$test_root/first.stderr"
first_path=$(sh "$script_path" "$repository_path" codex/author-a "$base_commit" 2>"$first_stderr")
[ -d "$first_path" ] || fail 'primary worktree was not created'
[ "$(git -C "$first_path" branch --show-current)" = 'codex/author-a' ] || fail 'wrong branch'
[ "$(git -C "$first_path" rev-parse HEAD)" = "$base_commit" ] || fail 'wrong base commit'
[ ! -e "$hook_marker" ] || fail 'post-checkout hook executed'

if sh "$script_path" "$repository_path" codex/author-a "$base_commit" >"$test_root/duplicate.stdout" 2>"$test_root/duplicate.stderr"; then
  fail 'duplicate branch unexpectedly succeeded'
fi
rg -q 'branch already exists' "$test_root/duplicate.stderr" || fail 'missing duplicate-branch error'

touch "$repository_path/uncommitted.tmp"
second_stderr="$test_root/second.stderr"
second_path=$(sh "$script_path" "$repository_path" codex/author-b "$base_commit" 2>"$second_stderr")
[ ! -e "$second_path/uncommitted.tmp" ] || fail 'uncommitted change was copied'
rg -q 'source worktree is dirty' "$second_stderr" || fail 'missing dirty-source warning'

third_path=$(sh "$script_path" "$first_path" codex/author-c "$base_commit" 2>"$test_root/third.stderr")
[ -d "$third_path" ] || fail 'linked-worktree invocation failed'

if sh "$script_path" "$repository_path" ../bad "$base_commit" >"$test_root/invalid.stdout" 2>"$test_root/invalid.stderr"; then
  fail 'invalid branch unexpectedly succeeded'
fi
rg -q 'invalid branch name' "$test_root/invalid.stderr" || fail 'missing invalid-branch error'

separate_worktree="$test_root/separate worktree"
separate_git_dir="$test_root/separate gitdir"
git init -b main --separate-git-dir "$separate_git_dir" "$separate_worktree" >/dev/null
git -C "$separate_worktree" config user.name 'Worktree Skill Test'
git -C "$separate_worktree" config user.email 'worktree-test@example.invalid'
touch "$separate_worktree/README.md"
git -C "$separate_worktree" add README.md
git -C "$separate_worktree" commit -m 'Separate gitdir fixture' >/dev/null
separate_base=$(git -C "$separate_worktree" rev-parse HEAD)
separate_path=$(sh "$script_path" "$separate_worktree" codex/separate "$separate_base" 2>"$test_root/separate.stderr")
[ -d "$separate_path" ] || fail 'separate-git-dir worktree failed'

submodule_source="$test_root/submodule source"
initialize_repository "$submodule_source"
superproject="$test_root/superproject"
initialize_repository "$superproject"
git -c protocol.file.allow=always -C "$superproject" submodule add "$submodule_source" modules/example >/dev/null
git -C "$superproject" commit -am 'Add submodule fixture' >/dev/null
submodule_path="$superproject/modules/example"
submodule_base=$(git -C "$submodule_path" rev-parse HEAD)
submodule_worktree=$(sh "$script_path" "$submodule_path" codex/submodule "$submodule_base" 2>"$test_root/submodule.stderr")
[ -d "$submodule_worktree" ] || fail 'submodule worktree failed'
case "$submodule_worktree" in
  "$superproject"/*) fail 'submodule worktree was created inside the superproject' ;;
esac

printf 'worktree scenarios: primary, hooks-disabled, duplicate, dirty, linked, invalid, separate-git-dir, submodule: ok\n'
