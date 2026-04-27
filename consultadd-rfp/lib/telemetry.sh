#!/bin/bash
# Shared telemetry helper for Consultadd RFP skills.
# Source this file from a skill, then call tel_emit.
#
# Usage:
#   source ~/.claude/skills/consultadd-rfp/lib/telemetry.sh
#   tel_emit firm-background start
#   ... do work ...
#   tel_emit firm-background complete '{"sections_filled": 7, "gaps": 2}'
#
# Telemetry posts in background and silently no-ops if env vars are unset,
# so it never blocks skill execution.

# Pull values from .env if present (also populates Reducto vars for skills that need them).
_telemetry_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" 2>/dev/null && pwd )"
if [[ -f "${_telemetry_dir}/load-env.sh" ]]; then
  # shellcheck disable=SC1091
  source "${_telemetry_dir}/load-env.sh"
fi

CONSULTADD_TEL_ENDPOINT="${CONSULTADD_TEL_ENDPOINT:-}"
CONSULTADD_TEL_KEY="${CONSULTADD_TEL_KEY:-}"
CONSULTADD_ANALYST_ID="${CONSULTADD_ANALYST_ID:-${USER:-unknown}}"
CONSULTADD_RFP_ID="${CONSULTADD_RFP_ID:-}"

tel_emit() {
  local skill="$1"
  local event="$2"
  local extra="${3:-{\}}"

  if [[ -z "$CONSULTADD_TEL_ENDPOINT" || -z "$CONSULTADD_TEL_KEY" ]]; then
    return 0
  fi

  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  local payload
  payload=$(cat <<JSON
{
  "skill": "${skill}",
  "event": "${event}",
  "analyst": "${CONSULTADD_ANALYST_ID}",
  "rfp_id": "${CONSULTADD_RFP_ID}",
  "ts": "${ts}",
  "extra": ${extra}
}
JSON
)

  curl -s -X POST "$CONSULTADD_TEL_ENDPOINT" \
    -H "Authorization: Bearer $CONSULTADD_TEL_KEY" \
    -H "Content-Type: application/json" \
    --data "$payload" \
    --max-time 5 \
    > /dev/null 2>&1 &
}
