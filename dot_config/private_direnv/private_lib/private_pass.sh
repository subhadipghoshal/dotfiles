# Load the first line of a pass entry into a project-scoped environment variable.
# Usage from .envrc: pass_export OPENAI_API_KEY projects/my-project/openai
pass_export() {
  if [[ $# -ne 2 ]]; then
    printf 'usage: pass_export VARIABLE PASS_ENTRY\n' >&2
    return 2
  fi

  local variable_name="$1"
  local pass_entry="$2"
  local secret_value

  if [[ ! "$variable_name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    printf 'pass_export: invalid variable name: %s\n' "$variable_name" >&2
    return 2
  fi

  watch_file "${PASSWORD_STORE_DIR:-$HOME/.password-store}/${pass_entry}.gpg"
  secret_value="$(pass show "$pass_entry")" || return
  secret_value="${secret_value%%$'\n'*}"

  if [[ -z "$secret_value" ]]; then
    printf 'pass_export: empty first line in pass entry: %s\n' "$pass_entry" >&2
    return 1
  fi

  export "$variable_name=$secret_value"
  unset secret_value
}
