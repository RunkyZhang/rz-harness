#!/usr/bin/env bash
set -euo pipefail

# Thin router only. Check logic lives in hooks/harness-sensor-runner.sh.
# Callers must pass adapter + event (same as the specimen's four one-liners).

usage() {
  cat <<'USAGE'
Usage:
  hooks/hook_adapter.sh <cursor|codex|opencode|plain> <event>

Forwards stdin unchanged to hooks/harness-sensor-runner.sh.
Both arguments are required. See hooks/hook_setup.md for each runtime's values.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

adapter="${1:-}"
event="${2:-}"
if [[ -z "$adapter" || -z "$event" ]]; then
  usage >&2
  printf 'FAIL: adapter and event are required\n' >&2
  exit 1
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
runner="$root/hooks/harness-sensor-runner.sh"
[[ -x "$runner" ]] || { printf 'FAIL: missing %s\n' "$runner" >&2; exit 1; }

exec "$runner" "$adapter" "$event"
