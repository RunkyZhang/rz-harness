#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/miniapp-local-env-gate.sh <miniapp-local-env.md | change-dir>

Checks mini-program local smoke evidence records:
  - status: READY
  - env_override_key: bd_owner_env_override
  - current_value
  - actual_request_host
  - reentered_miniprogram: yes
  - clear_command containing wx.removeStorageSync('bd_owner_env_override')
USAGE
}

fail() {
  local code="$1" message="$2" fix="$3" sample="$4"
  printf 'FAIL: %s\n' "$message" >&2
  printf 'CODE: %s\n' "$code" >&2
  printf 'FIX: %s\n' "$fix" >&2
  printf 'SAMPLE: %s\n' "$sample" >&2
  exit 1
}

field_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*:" {
      sub("^[[:space:]]*" key "[[:space:]]*:[[:space:]]*", "")
      sub("[[:space:]]+$", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$file"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

target="${1:-}"
[[ -n "$target" ]] || fail \
  "MINIAPP_LOCAL_ENV/MISSING_PATH" \
  "missing miniapp local env evidence path" \
  "Pass changes/<change-id>/miniapp-local-env.md or changes/<change-id>." \
  "templates/miniapp-local-env.md"
if [[ -d "$target" ]]; then
  env_file="$target/miniapp-local-env.md"
else
  env_file="$target"
fi
[[ -f "$env_file" ]] || fail \
  "MINIAPP_LOCAL_ENV/MISSING_FILE" \
  "miniapp local env file not found: $env_file" \
  "Create miniapp-local-env.md before mini-program local smoke." \
  "templates/miniapp-local-env.md"

status="$(field_value "$env_file" status)"
key="$(field_value "$env_file" env_override_key)"
current_value="$(field_value "$env_file" current_value)"
host="$(field_value "$env_file" actual_request_host)"
reentered="$(field_value "$env_file" reentered_miniprogram)"
clear_command="$(field_value "$env_file" clear_command)"

[[ "$status" == "READY" ]] || fail \
  "MINIAPP_LOCAL_ENV/NOT_READY" \
  "miniapp local env status is '${status:-missing}', not READY" \
  "Set status: READY after recording the actual override value and request host." \
  "status: READY"
[[ "$key" == "bd_owner_env_override" ]] || fail \
  "MINIAPP_LOCAL_ENV/MISSING_OVERRIDE_KEY" \
  "env_override_key is '${key:-missing}', not bd_owner_env_override" \
  "Record the exact mini-program storage key used for local env override." \
  "env_override_key: bd_owner_env_override"
[[ -n "$current_value" && "$current_value" != "-" ]] || fail \
  "MINIAPP_LOCAL_ENV/MISSING_CURRENT_VALUE" \
  "current_value is missing" \
  "Record the value read from wx.getStorageSync('bd_owner_env_override')." \
  "current_value: local"
[[ -n "$host" && "$host" != "-" ]] || fail \
  "MINIAPP_LOCAL_ENV/MISSING_REQUEST_HOST" \
  "actual_request_host is missing" \
  "Record the actual mini-program request host observed in DevTools Network." \
  "actual_request_host: http://127.0.0.1:19080"
[[ "$reentered" == "yes" ]] || fail \
  "MINIAPP_LOCAL_ENV/NOT_REENTERED" \
  "reentered_miniprogram is '${reentered:-missing}', not yes" \
  "Re-enter or recompile the mini-program after changing storage override, then record reentered_miniprogram: yes." \
  "reentered_miniprogram: yes"
if [[ "$clear_command" != *"wx.removeStorageSync('bd_owner_env_override')"* && "$clear_command" != *'wx.removeStorageSync("bd_owner_env_override")'* ]]; then
  fail \
    "MINIAPP_LOCAL_ENV/MISSING_CLEAR_COMMAND" \
    "clear_command does not show how to clear bd_owner_env_override" \
    "Record the exact console command to clear the local override after smoke." \
    "clear_command: wx.removeStorageSync('bd_owner_env_override')"
fi

printf 'PASS: miniapp local env gate passed for %s (current_value=%s host=%s)\n' "$env_file" "$current_value" "$host"
