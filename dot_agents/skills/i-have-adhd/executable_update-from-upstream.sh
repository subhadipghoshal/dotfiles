#!/usr/bin/env sh
# Pull rule updates from ayghri/i-have-adhd while keeping local frontmatter.
#
# The body below the frontmatter tracks upstream verbatim; only the
# description/trigger block differs on purpose (auto-invoke wording instead of
# slash-only). Upstream frontmatter changes are NOT merged — if upstream ever
# changes its description guidance, review it manually.
#
# Usage:
#   ./update-from-upstream.sh [ref]     ref defaults to main; a tag works too
#   ./update-from-upstream.sh --yes     apply without prompting

set -eu

skill_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
skill="$skill_dir/SKILL.md"
ref=main
yes=0
for arg in "$@"; do
	if [ "$arg" = "--yes" ]; then
		yes=1
	else
		ref=$arg
	fi
done

url="https://raw.githubusercontent.com/ayghri/i-have-adhd/$ref/skills/i-have-adhd/SKILL.md"
tmp=$(mktemp "${TMPDIR:-/tmp}/i-have-adhd-up.XXXXXX")
new=$(mktemp "${TMPDIR:-/tmp}/i-have-adhd-new.XXXXXX")
body=$(mktemp "${TMPDIR:-/tmp}/i-have-adhd-body.XXXXXX")
trap 'rm -f "$tmp" "$new" "$body"' EXIT

curl -fsSL "$url" -o "$tmp"

# Local frontmatter: from the opening --- through the closing one, inclusive.
awk '
	NR == 1 { print; infm = 1; next }
	infm { print; if (/^---[[:space:]]*$/) exit }
' "$skill" > "$new"

# Upstream body: everything after its own frontmatter block, verbatim.
awk '
	NR == 1 && /^---[[:space:]]*$/ { infm = 1; next }
	infm { if (/^---[[:space:]]*$/) { infm = 0; closed = 1 }; next }
	closed { print }
' "$tmp" | sed '/./,$!d' > "$body"

printf '\n' >> "$new"
cat "$body" >> "$new"

if cmp -s "$skill" "$new"; then
	echo "Already up to date with $ref."
	exit 0
fi

diff -u "$skill" "$new" || true

if [ "$yes" -ne 1 ]; then
	printf 'Apply update from %s? [y/N] ' "$ref"
	read -r answer
	case "$answer" in
	y | Y | yes) ;;
	*) echo "Aborted."; exit 1 ;;
	esac
fi

mv "$new" "$skill"
echo "Updated SKILL.md body from $ref. Frontmatter kept."
