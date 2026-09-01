#!/usr/bin/env sh
# Cross-harness always-on for the i-have-adhd ruleset.
#
# Every agent harness on this machine already loads ~/.config/agents/AGENTS.md:
#
#   Claude Code  ~/.claude/CLAUDE.md            @-imports it
#   Codex        ~/.codex/AGENTS.md             symlink to it
#   OpenCode     ~/.config/opencode/AGENTS.md   symlink to it
#   Gemini CLI   ~/.gemini/GEMINI.md            @-imports it
#
# Codex has no session hook and no import syntax, so a literal copy of the
# ruleset inside that shared file is the only mechanism all four honor. This
# script keeps a marked block there in step with the opt-in flag: block written
# when the flag exists, block removed when it does not.
#
# AGENTS.md is chezmoi-managed, so the same edit is mirrored into the chezmoi
# source file and `chezmoi status` stays clean.
#
# Usage:
#   sync-always-on.sh [sync]   reconcile the block with the flag
#   sync-always-on.sh on       create the flag, then sync
#   sync-always-on.sh off      remove every flag, then sync
#   sync-always-on.sh status   report flag, block, chezmoi, harness wiring
#
# Hook helpers (exit status or stdout, no side effects):
#   sync-always-on.sh is-on          exit 0 when always-on is enabled
#   sync-always-on.sh block-present  exit 0 when AGENTS.md carries the block
#   sync-always-on.sh body           print SKILL.md without its frontmatter

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
agents_dir=$config_home/agents
policy=$agents_dir/AGENTS.md
skill=$script_dir/SKILL.md
flag=$agents_dir/.i-have-adhd-always

begin_marker='<!-- BEGIN i-have-adhd always-on (managed by ~/.config/agents/skills/i-have-adhd/sync-always-on.sh) -->'
end_marker='<!-- END i-have-adhd always-on -->'

# Flags this machine has carried before the switch moved to $flag (above).
# Any of them still counts as "on"; `off` clears all of them.
claude_flag=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.i-have-adhd-always
codex_flag=$HOME/.codex/.i-have-adhd-always
gemini_flag=$HOME/.gemini/.i-have-adhd-always
opencode_flag=$config_home/opencode/.i-have-adhd-always

# Prints the flag file that is switching always-on on, if any.
active_flag() {
	for f in "$flag" "$claude_flag" "$codex_flag" "$gemini_flag" "$opencode_flag"; do
		if [ -f "$f" ]; then
			printf '%s\n' "$f"
			return 0
		fi
	done
	return 1
}

always_on() {
	active_flag >/dev/null
}

# SKILL.md minus a leading YAML frontmatter block, trailing blank lines dropped.
# An unterminated fence is not frontmatter, so the file is kept whole unless the
# closing delimiter exists (two passes; matches the upstream Node hook).
body() {
	awk '
	  NR == FNR {
	    if (NR == 1 && $0 ~ /^---[[:space:]]*$/) { in_fm = 1; next }
	    if (in_fm && $0 ~ /^---[[:space:]]*$/)   { in_fm = 0; closed = 1 }
	    next
	  }
	  FNR == 1 { strip = closed }
	  strip && FNR == 1 && $0 ~ /^---[[:space:]]*$/ { skipping = 1; next }
	  skipping && $0 ~ /^---[[:space:]]*$/          { skipping = 0; next }
	  !skipping {
	    if ($0 ~ /^[[:space:]]*$/) { pending++; next }
	    if (started) { while (pending > 0) { print ""; pending-- } }
	    pending = 0
	    started = 1
	    print
	  }
	' "$skill" "$skill"
}

render_block() {
	printf '%s\n' "$begin_marker"
	printf 'ADHD MODE ACTIVE (always-on, every harness). The ruleset below applies to every response. "stop adhd mode" turns it off for the current session; `%s off` turns always-on off for good.\n\n' \
		"$script_dir/sync-always-on.sh"
	body
	printf '%s\n' "$end_marker"
}

# The given file with any existing block removed and trailing blanks dropped.
strip_block() {
	awk -v b="$begin_marker" -v e="$end_marker" '
	  $0 == b { skip = 1; next }
	  $0 == e { skip = 0; next }
	  skip    { next }
	  /^[[:space:]]*$/ { pending++; next }
	  {
	    if (started) { while (pending > 0) { print ""; pending-- } }
	    pending = 0
	    started = 1
	    print
	  }
	' "$1"
}

# Reconcile one AGENTS.md-shaped file. Prints a line only when it changed.
reconcile() {
	target=$1
	[ -f "$target" ] || return 0
	tmp=$(mktemp "${TMPDIR:-/tmp}/i-have-adhd-sync.XXXXXX")
	strip_block "$target" >"$tmp"
	if always_on; then
		printf '\n' >>"$tmp"
		render_block >>"$tmp"
	fi
	if cmp -s "$target" "$tmp"; then
		rm -f "$tmp"
		return 0
	fi
	cat "$tmp" >"$target"
	rm -f "$tmp"
	printf 'updated %s\n' "$target"
}

# Where chezmoi keeps the source of a managed file, when it is a plain file.
# Templates are left alone: appending to one would corrupt its syntax.
chezmoi_source_for() {
	command -v chezmoi >/dev/null 2>&1 || return 1
	src=$(chezmoi source-path "$1" 2>/dev/null) || return 1
	[ -n "$src" ] && [ -f "$src" ] || return 1
	case "$src" in *.tmpl) return 1 ;; esac
	printf '%s\n' "$src"
}

sync() {
	[ -f "$skill" ] || { echo "missing $skill" >&2; exit 1; }
	[ -f "$policy" ] || { echo "missing $policy" >&2; exit 1; }
	reconcile "$policy"
	if src=$(chezmoi_source_for "$policy"); then
		reconcile "$src"
	fi
}

link_target() {
	t=$(readlink "$1") || return 1
	case "$t" in
	/*) printf '%s\n' "$t" ;;
	*) printf '%s/%s\n' \
		"$(CDPATH= cd -- "$(dirname -- "$1")" && CDPATH= cd -- "$(dirname -- "$t")" && pwd)" \
		"$(basename -- "$t")" ;;
	esac
}

# Does this harness entry file reach the shared policy, by symlink or by import?
harness_state() {
	entry=$1
	[ -e "$entry" ] || { printf 'missing\n'; return 0; }
	if [ -L "$entry" ]; then
		if [ "$(link_target "$entry")" = "$policy" ]; then
			printf 'symlink to shared policy\n'
		else
			printf 'symlink elsewhere\n'
		fi
		return 0
	fi
	if grep -q 'agents/AGENTS.md' "$entry"; then
		printf 'imports shared policy\n'
	else
		printf 'no reference to shared policy\n'
	fi
}

status() {
	if on_flag=$(active_flag); then
		printf 'always-on: ON   (flag: %s)\n' "$on_flag"
	else
		printf 'always-on: OFF  (no flag; turn on with `%s on`)\n' "$script_dir/sync-always-on.sh"
	fi

	if grep -qF "$begin_marker" "$policy" 2>/dev/null; then
		printf 'block:     present in %s\n' "$policy"
	else
		printf 'block:     absent from %s\n' "$policy"
	fi

	if src=$(chezmoi_source_for "$policy"); then
		if cmp -s "$policy" "$src"; then
			printf 'chezmoi:   source in sync (%s)\n' "$src"
		else
			printf 'chezmoi:   source DIFFERS (%s) - run `%s sync`\n' "$src" "$script_dir/sync-always-on.sh"
		fi
	else
		printf 'chezmoi:   not tracking %s\n' "$policy"
	fi

	printf 'harnesses:\n'
	printf '  claude    %-44s %s\n' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/CLAUDE.md" \
		"$(harness_state "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/CLAUDE.md")"
	printf '  codex     %-44s %s\n' "$HOME/.codex/AGENTS.md" \
		"$(harness_state "$HOME/.codex/AGENTS.md")"
	printf '  opencode  %-44s %s\n' "$config_home/opencode/AGENTS.md" \
		"$(harness_state "$config_home/opencode/AGENTS.md")"
	printf '  gemini    %-44s %s\n' "$HOME/.gemini/GEMINI.md" \
		"$(harness_state "$HOME/.gemini/GEMINI.md")"
}

case "${1:-sync}" in
sync)
	sync
	;;
on)
	: >>"$flag"
	sync
	echo "always-on: ON"
	;;
off)
	rm -f "$flag" "$claude_flag" "$codex_flag" "$gemini_flag" "$opencode_flag"
	sync
	echo "always-on: OFF"
	;;
status)
	status
	;;
is-on)
	always_on || exit 1
	;;
block-present)
	grep -qF "$begin_marker" "$policy" 2>/dev/null || exit 1
	;;
body)
	body
	;;
*)
	echo "usage: $(basename "$0") [sync|on|off|status|is-on|block-present|body]" >&2
	exit 2
	;;
esac
