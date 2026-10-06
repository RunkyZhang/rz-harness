#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/local-routing-gate.sh <local-routing.yml>

Checks harness local routing:
  - route config exists and is parseable
  - no catch-all frontend routes
  - each local target points to localhost / 127.0.0.1 / ::1
  - each route has a contract source and reason
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

config="${1:-}"
if [[ -z "$config" ]]; then
  printf 'FAIL: missing local routing config\n' >&2
  printf 'CODE: LOCAL_ROUTING/MISSING_CONFIG\n' >&2
  printf 'FIX: Pass the generated local-routing.yml path before running the gate.\n' >&2
  printf 'SAMPLE: templates/local-routing.yml\n' >&2
  exit 1
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
node "$root/scripts/harness-local-proxy.mjs" --check "$config"
