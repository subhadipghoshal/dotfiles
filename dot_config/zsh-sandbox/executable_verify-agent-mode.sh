#!/usr/bin/env bash
# Verify the observable zsh agent-mode contract with an isolated tmux server.
set -euo pipefail

zdotdir=${ZSH_AGENT_ZDOTDIR:-"$HOME/.config/zsh-sandbox"}
tmux_options=${ZSH_AGENT_TMUX_OPTIONS:-"$HOME/.config/tmux/conf/options.conf"}
tmux_bin=${TMUX_BIN:-$(command -v tmux)}

if [[ ! -r "$zdotdir/.zprofile" || ! -r "$zdotdir/.zshrc" \
      || ! -r "$zdotdir/.zsh/99-agent-guard.zsh" ]]; then
  printf 'missing zsh sandbox files under %s\n' "$zdotdir" >&2
  exit 1
fi
if [[ ! -r "$tmux_options" ]]; then
  printf 'missing tmux options file: %s\n' "$tmux_options" >&2
  exit 1
fi

test_dir=$(mktemp -d "${ZSH_AGENT_TEST_TMPDIR:-/private/tmp}/zsh-agent-mode.XXXXXX")
results="$test_dir/results"
probe="$test_dir/probe.zsh"
driver="$test_dir/driver.zsh"
socket_path="$test_dir/tmux.sock"
mkdir -p "$results"

tmux_cmd() {
  "$tmux_bin" -S "$socket_path" "$@"
}

cleanup() {
  tmux_cmd kill-server >/dev/null 2>&1 || true
  rm -rf "$test_dir"
}
trap cleanup EXIT INT TERM

cat >"$probe" <<'ZSH_PROBE'
result_tmp="$ZSH_AGENT_RESULTS/$ZSH_AGENT_SCENARIO.tmp"
result_file="$ZSH_AGENT_RESULTS/$ZSH_AGENT_SCENARIO"
{
  print -r -- "mode=${ZSH_AGENT_MODE-<unset>}"
  if command env | command grep -q '^ZSH_AGENT_MODE='; then
    print -r -- 'mode_exported=yes'
  else
    print -r -- 'mode_exported=no'
  fi
  if (( ${+__p9k_used_instant_prompt} )); then
    print -r -- 'instant_prompt_used=yes'
  else
    print -r -- 'instant_prompt_used=no'
  fi
  print -r -- "PAGER=${PAGER-<unset>}"
  print -r -- "MANPAGER=${MANPAGER-<unset>}"
  print -r -- "GIT_PAGER=${GIT_PAGER-<unset>}"
  print -r -- "DELTA_PAGER=${DELTA_PAGER-<unset>}"
  print -r -- "LESS=${LESS-<unset>}"
  print -r -- "POWERLEVEL9K_INSTANT_PROMPT=${POWERLEVEL9K_INSTANT_PROMPT-<unset>}"

  for alias_name in cat ls v vim tmux; do
    if (( ${+aliases[$alias_name]} )); then
      print -r -- "alias_${alias_name}=${aliases[$alias_name]}"
    else
      print -r -- "alias_${alias_name}=<unset>"
    fi
  done

  for option_name in correct correct_all; do
    if [[ -o $option_name ]]; then
      print -r -- "option_${option_name}=on"
    else
      print -r -- "option_${option_name}=off"
    fi
  done

  for marker_name in CLAUDECODE CI CODEX_SANDBOX CURSOR_AGENT OPENCODE; do
    print -r -- "marker_${marker_name}=${(P)marker_name-<unset>}"
  done
} >| "$result_tmp"
command mv "$result_tmp" "$result_file"
ZSH_PROBE

cat >"$driver" <<'ZSH_DRIVER'
ZSH_AGENT_SCENARIO=poisoned-human source "$ZSH_AGENT_PROBE"

for marker_name in CLAUDECODE CI CODEX_SANDBOX CURSOR_AGENT OPENCODE; do
  command env "$marker_name=1" \
    ZSH_AGENT_SCENARIO="marker-$marker_name" \
    /bin/zsh -l -i "$ZSH_AGENT_PROBE"
done

command env ZSH_AGENT_MODE=1 ZSH_AGENT_SCENARIO=explicit-agent \
  /bin/zsh -l -i "$ZSH_AGENT_PROBE"

command env ZSH_AGENT_MODE=invalid ZSH_AGENT_SCENARIO=invalid-human \
  /bin/zsh -l -i "$ZSH_AGENT_PROBE"

command env ZSH_AGENT_MODE=invalid CLAUDECODE=1 \
  ZSH_AGENT_SCENARIO=invalid-agent /bin/zsh -l -i "$ZSH_AGENT_PROBE"

command env PAGER=cat MANPAGER=cat GIT_PAGER=cat DELTA_PAGER=cat LESS=-FRX \
  ZSH_AGENT_SCENARIO=nested-human /bin/zsh -i "$ZSH_AGENT_PROBE"

: >| "$ZSH_AGENT_RESULTS/driver-complete"
exec /bin/sleep 30
ZSH_DRIVER

/usr/bin/env \
  -u TMUX -u TMUX_PANE \
  ZDOTDIR="$zdotdir" \
  ZSH_COMPDUMP="$test_dir/.zcompdump" \
  ZSH_SANDBOX=1 \
  ZSH_AGENT_RESULTS="$results" \
  ZSH_AGENT_PROBE="$probe" \
  ZSH_AGENT_MODE=1 \
  CLAUDECODE=1 CI=1 CODEX_SANDBOX=1 CURSOR_AGENT=1 OPENCODE=1 \
  "$tmux_bin" -S "$socket_path" -f "$tmux_options" \
  new-session -d -s regression /bin/zsh -l -i "$driver"

for _ in $(seq 1 200); do
  [[ -e "$results/driver-complete" ]] && break
  sleep 0.05
done
if [[ ! -e "$results/driver-complete" ]]; then
  printf 'tmux driver did not complete\n' >&2
  tmux_cmd capture-pane -p -t regression -S -100 >&2 || true
  exit 1
fi

probe_default_shell() {
  local scenario=$1
  local pane_id=$2

  tmux_cmd send-keys -t "$pane_id" \
    "ZSH_AGENT_SCENARIO=$scenario source '$probe'" Enter
  for _ in $(seq 1 200); do
    [[ -e "$results/$scenario" ]] && return 0
    sleep 0.05
  done

  printf 'default tmux shell probe did not complete: %s\n' "$scenario" >&2
  tmux_cmd capture-pane -p -t "$pane_id" -S -100 >&2 || true
  exit 1
}

new_window_pane=$(tmux_cmd new-window -d -P -F '#{pane_id}' -t regression)
probe_default_shell tmux-new-window "$new_window_pane"

split_window_pane=$(tmux_cmd split-window -d -P -F '#{pane_id}' -t regression:1.1)
probe_default_shell tmux-split-window "$split_window_pane"

expect_line() {
  local scenario=$1
  local expected=$2
  if ! grep -Fqx -- "$expected" "$results/$scenario"; then
    printf 'FAIL %s: missing exact line %s\n' "$scenario" "$expected" >&2
    sed -n '1,120p' "$results/$scenario" >&2
    exit 1
  fi
}

expect_contains() {
  local scenario=$1
  local expected=$2
  if ! grep -Fq -- "$expected" "$results/$scenario"; then
    printf 'FAIL %s: missing text %s\n' "$scenario" "$expected" >&2
    sed -n '1,120p' "$results/$scenario" >&2
    exit 1
  fi
}

assert_human() {
  local scenario=$1
  expect_line "$scenario" 'mode_exported=no'
  assert_human_behavior "$scenario"
}

assert_human_behavior() {
  local scenario=$1
  expect_line "$scenario" 'PAGER=less'
  expect_contains "$scenario" 'MANPAGER='
  expect_contains "$scenario" 'bat --theme=default'
  expect_contains "$scenario" 'paging=auto'
  expect_line "$scenario" 'GIT_PAGER=<unset>'
  expect_line "$scenario" 'DELTA_PAGER=<unset>'
  expect_line "$scenario" 'LESS=-R'
  expect_line "$scenario" 'alias_cat=bat'
  expect_line "$scenario" 'alias_ls=eza --icons=always'
  expect_line "$scenario" 'alias_v=vim'
  expect_line "$scenario" 'alias_vim=nvim'
  expect_line "$scenario" 'alias_tmux=_zsh_tmux_plugin_run'
}

assert_pager_safe() {
  local scenario=$1
  expect_line "$scenario" 'PAGER=cat'
  expect_line "$scenario" 'MANPAGER=cat'
  expect_line "$scenario" 'GIT_PAGER=cat'
  expect_line "$scenario" 'DELTA_PAGER=cat'
  expect_line "$scenario" 'LESS=-FRX'
}

assert_agent() {
  local scenario=$1
  assert_pager_safe "$scenario"
  expect_line "$scenario" 'POWERLEVEL9K_INSTANT_PROMPT=quiet'
  expect_line "$scenario" 'option_correct=off'
  expect_line "$scenario" 'option_correct_all=off'
  for alias_name in cat ls v vim tmux; do
    expect_line "$scenario" "alias_${alias_name}=<unset>"
  done
}

expect_line poisoned-human 'mode=0'
assert_human poisoned-human
for marker_name in CLAUDECODE CI CODEX_SANDBOX CURSOR_AGENT OPENCODE; do
  expect_line poisoned-human "marker_${marker_name}=<unset>"
done

global_mode=$(tmux_cmd show-environment -g ZSH_AGENT_MODE)
if [[ "$global_mode" != 'ZSH_AGENT_MODE=0' ]]; then
  printf 'FAIL tmux global mode: %s\n' "$global_mode" >&2
  exit 1
fi
for marker_name in CLAUDECODE CI CODEX_SANDBOX CURSOR_AGENT OPENCODE; do
  marker_state=$(tmux_cmd show-environment -g "$marker_name" 2>/dev/null || true)
  if [[ -n "$marker_state" && "$marker_state" != "-$marker_name" ]]; then
    printf 'FAIL tmux marker %s: %s\n' "$marker_name" "$marker_state" >&2
    exit 1
  fi
done

for marker_name in CLAUDECODE CI CODEX_SANDBOX CURSOR_AGENT OPENCODE; do
  assert_agent "marker-$marker_name"
done
expect_line explicit-agent 'mode=1'
expect_line explicit-agent 'mode_exported=yes'
assert_agent explicit-agent
expect_line invalid-human 'mode=invalid'
assert_human_behavior invalid-human
expect_line invalid-agent 'mode=invalid'
assert_agent invalid-agent
expect_line nested-human 'mode=<unset>'
assert_human nested-human
for tmux_shell_scenario in tmux-new-window tmux-split-window; do
  expect_line "$tmux_shell_scenario" 'mode=0'
  expect_line "$tmux_shell_scenario" 'instant_prompt_used=yes'
  assert_human "$tmux_shell_scenario"
done

for captured_mode in auto 0 1; do
  captured_scenario="captured-$captured_mode"
  if [[ "$captured_mode" == auto ]]; then
    /usr/bin/env -u TMUX -u TMUX_PANE -u ZSH_AGENT_MODE \
      -u CLAUDECODE -u CI -u CODEX_SANDBOX -u CURSOR_AGENT -u OPENCODE \
      ZDOTDIR="$zdotdir" ZSH_COMPDUMP="$test_dir/.zcompdump-captured" \
      ZSH_SANDBOX=1 ZSH_AGENT_RESULTS="$results" \
      ZSH_AGENT_SCENARIO="$captured_scenario" \
      /bin/zsh -l -i "$probe" >"$test_dir/$captured_scenario.stdout" \
      2>"$test_dir/$captured_scenario.stderr"
  else
    /usr/bin/env -u TMUX -u TMUX_PANE \
      -u CLAUDECODE -u CI -u CODEX_SANDBOX -u CURSOR_AGENT -u OPENCODE \
      ZDOTDIR="$zdotdir" ZSH_COMPDUMP="$test_dir/.zcompdump-captured" \
      ZSH_SANDBOX=1 ZSH_AGENT_RESULTS="$results" \
      ZSH_AGENT_SCENARIO="$captured_scenario" ZSH_AGENT_MODE="$captured_mode" \
      /bin/zsh -l -i "$probe" >"$test_dir/$captured_scenario.stdout" \
      2>"$test_dir/$captured_scenario.stderr"
  fi
  assert_agent "$captured_scenario"
done

/usr/bin/env -u TMUX -u TMUX_PANE \
  ZDOTDIR="$zdotdir" ZSH_SANDBOX=1 ZSH_AGENT_RESULTS="$results" \
  ZSH_AGENT_SCENARIO=true-noninteractive ZSH_AGENT_MODE=0 \
  CLAUDECODE=1 CI=1 CODEX_SANDBOX=1 CURSOR_AGENT=1 OPENCODE=1 \
  PAGER=less \
  MANPAGER="sh -c 'col -bx | bat --paging=auto'" \
  GIT_PAGER=delta DELTA_PAGER=delta LESS=-R \
  /bin/zsh "$probe" >"$test_dir/true-noninteractive.stdout" \
  2>"$test_dir/true-noninteractive.stderr"
expect_line true-noninteractive 'mode=0'
expect_line true-noninteractive 'mode_exported=no'
assert_pager_safe true-noninteractive

printf 'PASS poisoned tmux server produces a human shell\n'
printf 'PASS explicit mode and all bare markers produce agent-safe shells\n'
printf 'PASS new windows, splits, nested human, captured, and non-interactive behavior\n'
