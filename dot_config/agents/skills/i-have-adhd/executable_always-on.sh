#!/usr/bin/env sh
# SessionStart hook: Claude Code's half of always-on.
# Never blocks session start: any failure exits 0.
#
# The ruleset itself now lives in a managed block inside
# ~/.config/agents/AGENTS.md, which every harness here loads (see
# sync-always-on.sh). Claude reads it through ~/.claude/CLAUDE.md, so this hook
# normally prints the banner only and re-syncs the block in the background.
#
# It falls back to printing the full ruleset when the block was not in the
# context Claude just loaded: the first session after turning always-on on, a
# CLAUDE.md that no longer imports the shared policy, or an unwritable
# AGENTS.md.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || exit 0
sync=$script_dir/sync-always-on.sh
[ -x "$sync" ] || exit 0

# Only fire when the user has opted in.
sh "$sync" is-on 2>/dev/null || exit 0

claude_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

# Did this session already load the ruleset through the shared policy file?
in_context=0
if sh "$sync" block-present 2>/dev/null &&
	grep -q 'agents/AGENTS.md' "$claude_dir/CLAUDE.md" 2>/dev/null; then
	in_context=1
fi

# Keep the block in step with the flag and with SKILL.md. Takes effect in the
# next session; this one is covered by the fallback below.
sh "$sync" sync >/dev/null 2>&1

banner=$(printf 'ADHD MODE ACTIVE (always-on, every harness). The ruleset applies to every response. "stop adhd mode" turns it off for this session; `%s off` turns always-on off for good.' "$sync")

if [ "$in_context" -eq 1 ]; then
	printf '%s The full rules are already in context via %s.\n' \
		"$banner" "$config_home/agents/AGENTS.md"
	exit 0
fi

body=$(sh "$sync" body 2>/dev/null) || exit 0
[ -n "$body" ] || exit 0
printf '%s\n\n%s\n' "$banner" "$body"
exit 0
