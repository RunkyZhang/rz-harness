#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/ecc/ecc-sidecar.sh status
  scripts/ecc/ecc-sidecar.sh consult <query...>
  scripts/ecc/ecc-sidecar.sh harness-audit
  scripts/ecc/ecc-sidecar.sh observability-ready
  scripts/ecc/ecc-sidecar.sh install-plan [ECC install args...]
  scripts/ecc/ecc-sidecar.sh codex-sync-dry-run

ECC is optional. Set SFA_ECC_HOME to a pinned ECC checkout, or clone ECC to
artifacts/vendor/ECC. This wrapper never applies ECC installs; install-plan and
codex-sync-dry-run are dry-run only.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
ecc_home="${SFA_ECC_HOME:-$root/artifacts/vendor/ECC}"

is_ecc_home() {
  [[ -f "$ecc_home/package.json" && -f "$ecc_home/scripts/consult.js" ]]
}

print_unavailable() {
  cat <<EOF
ECC_STATUS=UNAVAILABLE
ECC_HOME=$ecc_home
FIX=Clone ECC to artifacts/vendor/ECC or set SFA_ECC_HOME to a pinned ECC checkout.
SAMPLE=git clone https://github.com/affaan-m/ECC artifacts/vendor/ECC
EOF
}

require_ecc() {
  if ! is_ecc_home; then
    print_unavailable >&2
    exit 2
  fi
}

command_name="${1:-}"
case "$command_name" in
  -h|--help|"")
    usage
    exit 0
    ;;
esac
shift || true

case "$command_name" in
  status)
    if is_ecc_home; then
      printf 'ECC_STATUS=AVAILABLE\n'
      printf 'ECC_HOME=%s\n' "$ecc_home"
      (cd "$ecc_home" && git rev-parse HEAD 2>/dev/null | sed 's/^/ECC_COMMIT=/') || true
    else
      print_unavailable
    fi
    ;;
  consult)
    require_ecc
    [[ "$#" -gt 0 ]] || fail "missing consult query"
    (cd "$ecc_home" && node scripts/consult.js "$@" --target codex --json)
    ;;
  harness-audit)
    require_ecc
    (cd "$ecc_home" && node scripts/harness-audit.js --format json)
    ;;
  observability-ready)
    require_ecc
    (cd "$ecc_home" && node scripts/observability-readiness.js --format json)
    ;;
  install-plan)
    require_ecc
    safe_args=()
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        --target)
          [[ "${2:-}" == "codex" ]] || fail "install-plan only supports --target codex"
          shift 2
          ;;
        --target=codex)
          shift
          ;;
        --target=*)
          fail "install-plan only supports --target codex"
          ;;
        --dry-run|--dry-run=true|--json|--json=true)
          shift
          ;;
        --dry-run=false|--json=false|--no-dry-run|--apply|apply|--write|--sync|--update|--update-mcp|--install|--global-sync|--force|--yes|-y)
          fail "install-plan rejects apply/write argument: $1"
          ;;
        *)
          safe_args+=("$1")
          shift
          ;;
      esac
    done
    (cd "$ecc_home" && bash install.sh --target codex "${safe_args[@]}" --dry-run --json)
    ;;
  codex-sync-dry-run)
    require_ecc
    (cd "$ecc_home" && bash scripts/sync-ecc-to-codex.sh --dry-run)
    ;;
  *)
    fail "unknown ECC sidecar command: $command_name"
    ;;
esac
