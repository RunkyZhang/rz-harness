#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/temporary-state-ledger-gate.sh <temporary-state-ledger.md | change-dir>

Checks local/debug temporary state is either cleared, retained intentionally, or
owned by the user. Blocks OPEN items.
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

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

target="${1:-}"
[[ -n "$target" ]] || fail \
  "TEMPORARY_STATE/MISSING_PATH" \
  "missing temporary state ledger path" \
  "Pass changes/<change-id>/temporary-state-ledger.md or changes/<change-id>." \
  "templates/temporary-state-ledger.md"
if [[ -d "$target" ]]; then
  ledger="$target/temporary-state-ledger.md"
else
  ledger="$target"
fi
[[ -f "$ledger" ]] || fail \
  "TEMPORARY_STATE/MISSING_FILE" \
  "temporary state ledger not found: $ledger" \
  "Create a temporary state ledger for local services, storage overrides, test data, QR tokens, proxy logs, and vConsole/debug flags." \
  "templates/temporary-state-ledger.md"

status="$(awk '/^ledger_status:/ { sub(/^ledger_status:[[:space:]]*/, ""); print; exit }' "$ledger")"
[[ "$status" == "READY" ]] || fail \
  "TEMPORARY_STATE/NOT_READY" \
  "ledger_status is '${status:-missing}', not READY" \
  "Set ledger_status: READY after every temporary item has a cleanup decision." \
  "ledger_status: READY"

grep -qE '^\|[[:space:]]*Category[[:space:]]*\|[[:space:]]*Resource[[:space:]]*\|[[:space:]]*Owner[[:space:]]*\|[[:space:]]*Cleanup[[:space:]]*\|[[:space:]]*Status[[:space:]]*\|' "$ledger" || fail \
  "TEMPORARY_STATE/MISSING_TABLE" \
  "temporary state ledger table is missing or has wrong columns" \
  "Use columns exactly: Category, Resource, Owner, Cleanup, Status." \
  "| Category | Resource | Owner | Cleanup | Status |"

row_count="$(grep -cE '^\|[[:space:]]*[^|]+[[:space:]]*\|[[:space:]]*[^|]+[[:space:]]*\|[[:space:]]*[^|]+[[:space:]]*\|[[:space:]]*[^|]+[[:space:]]*\|[[:space:]]*(CLEARED|USER_OWNED|RETAINED|OPEN|N/A)' "$ledger" || true)"
[[ "$row_count" -gt 0 ]] || fail \
  "TEMPORARY_STATE/EMPTY_LEDGER" \
  "temporary state ledger has no state rows" \
  "Record at least one temporary state row or an explicit N/A row." \
  "| N/A | no temporary state | Codex | N/A | N/A |"

if grep -nE '^\|.*\|[[:space:]]*OPEN[[:space:]]*\|' "$ledger" >/tmp/sfa-temp-ledger-open.out; then
  sed -n '1,20p' /tmp/sfa-temp-ledger-open.out >&2
  rm -f /tmp/sfa-temp-ledger-open.out
  fail \
    "TEMPORARY_STATE/OPEN_ITEM" \
    "temporary state ledger contains OPEN item(s)" \
    "Clear the item, mark it USER_OWNED with owner decision, or mark RETAINED with reason before closing the work." \
    "| local-service | backend:31010 | Codex | stop service | CLEARED |"
fi
rm -f /tmp/sfa-temp-ledger-open.out

printf 'PASS: temporary state ledger gate passed for %s (%s row(s))\n' "$ledger" "$row_count"
