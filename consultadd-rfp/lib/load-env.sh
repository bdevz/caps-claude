#!/bin/bash
# Load consultadd-rfp .env into the current shell. Idempotent — safe to source from any skill.
#
# Lookup order (first hit wins):
#   1. $CONSULTADD_RFP_ENV_FILE (explicit override)
#   2. ~/.claude/skills/consultadd-rfp/.env (installed location, follows symlink)
#   3. The directory two levels up from this file (dev tree)
#
# Variables in .env are exported via `set -a`, so curl/sub-skills inherit them.

_load_env_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$file"
    set +a
    return 0
  fi
  return 1
}

if [[ -n "${CONSULTADD_RFP_ENV_FILE:-}" ]]; then
  _load_env_file "$CONSULTADD_RFP_ENV_FILE" && return 0 2>/dev/null
fi

if _load_env_file "$HOME/.claude/skills/consultadd-rfp/.env"; then
  return 0 2>/dev/null
fi

# Fallback: dev tree relative to this script
_self_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" 2>/dev/null && pwd )"
if [[ -n "$_self_dir" ]]; then
  _load_env_file "${_self_dir}/../.env" || true
fi
