#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/verification-map-gate.sh <verification-map.md | change-dir>

Checks that Tier M/L key constraints have explicit verification mapping before
implementation:
  - verification_map_status: READY
  - a markdown table with at least one VM-* row
  - no TODO/TBD/待补/未定 placeholders
  - no BLOCKED rows
  - N/A rows include an explicit N/A reason in the Evidence column
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
  "VERIFICATION_MAP/MISSING_PATH" \
  "missing verification map path" \
  "Pass changes/<change-id>/verification-map.md or changes/<change-id>/." \
  "templates/verification-map.md"

if [[ -d "$target" ]]; then
  map_file="$target/verification-map.md"
else
  map_file="$target"
fi

[[ -f "$map_file" ]] || fail \
  "VERIFICATION_MAP/MISSING_FILE" \
  "verification map file not found: $map_file" \
  "Copy templates/verification-map.md to changes/<change-id>/verification-map.md and map each key constraint to a verification method." \
  "templates/verification-map.md"

field_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*:" {
      sub("^[[:space:]]*" key "[[:space:]]*:[[:space:]]*", "")
      sub("[[:space:]]+$", "")
      print
      exit
    }
  ' "$file"
}

status="$(field_value "$map_file" "verification_map_status")"
if [[ "$status" != "READY" ]]; then
  fail \
    "VERIFICATION_MAP/NOT_READY" \
    "verification_map_status is '${status:-missing}', not READY" \
    "Set verification_map_status: READY only after every key constraint has a concrete verification method, evidence target, or N/A reason." \
    "verification_map_status: READY"
fi

if ! grep -qE '^\|[[:space:]]*ID[[:space:]]*\|[[:space:]]*Constraint[[:space:]]*\|[[:space:]]*Source[[:space:]]*\|[[:space:]]*Verification[[:space:]]*\|[[:space:]]*Evidence[[:space:]]*\|[[:space:]]*Status[[:space:]]*\|' "$map_file"; then
  fail \
    "VERIFICATION_MAP/MISSING_TABLE" \
    "verification map table header is missing or has wrong columns" \
    "Use the template table columns exactly: ID, Constraint, Source, Verification, Evidence, Status." \
    "| ID | Constraint | Source | Verification | Evidence | Status |"
fi

row_count="$(grep -cE '^\|[[:space:]]*VM-[0-9]+' "$map_file" || true)"
if [[ "$row_count" -eq 0 ]]; then
  fail \
    "VERIFICATION_MAP/EMPTY_MAP" \
    "verification map has no VM-* rows" \
    "Add at least one row for a key business, API, DB, permission, UI, or release constraint." \
    "| VM-001 | <constraint> | <source> | <command/manual/N/A> | <evidence or N/A reason> | PLANNED |"
fi

if grep -nE '\b(TODO|TBD)\b|待补|未定' "$map_file" >/tmp/sfa-verification-map-placeholder.out; then
  printf 'Unresolved placeholders:\n' >&2
  sed -n '1,20p' /tmp/sfa-verification-map-placeholder.out >&2
  rm -f /tmp/sfa-verification-map-placeholder.out
  fail \
    "VERIFICATION_MAP/UNRESOLVED_PLACEHOLDER" \
    "verification map contains unresolved placeholders" \
    "Replace placeholders with a concrete verification command, manual confirmation, evidence target, or explicit N/A reason." \
    "templates/verification-map.md"
fi
rm -f /tmp/sfa-verification-map-placeholder.out

if grep -nE '^\|[[:space:]]*VM-[0-9]+.*\|[[:space:]]*BLOCKED[[:space:]]*\|' "$map_file" >/tmp/sfa-verification-map-blocked.out; then
  printf 'Blocked verification rows:\n' >&2
  sed -n '1,20p' /tmp/sfa-verification-map-blocked.out >&2
  rm -f /tmp/sfa-verification-map-blocked.out
  fail \
    "VERIFICATION_MAP/BLOCKED_ROW" \
    "verification map contains BLOCKED rows" \
    "Resolve blocked verification rows or keep the change blocked before implementation." \
    "| VM-001 | <constraint> | <source> | <verification> | <evidence> | PLANNED |"
fi
rm -f /tmp/sfa-verification-map-blocked.out

if awk -F'|' '
  /^\|[[:space:]]*VM-[0-9]+/ {
    evidence=$6
    status=$7
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", evidence)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
    gsub(/^`|`$/, "", evidence)
    if (status == "N/A" && evidence !~ /^N\/A:/) {
      print NR ":" $0
    }
  }
' "$map_file" >/tmp/sfa-verification-map-na.out; then
  if [[ -s /tmp/sfa-verification-map-na.out ]]; then
    printf 'N/A rows without explicit reason:\n' >&2
    sed -n '1,20p' /tmp/sfa-verification-map-na.out >&2
    rm -f /tmp/sfa-verification-map-na.out
    fail \
      "VERIFICATION_MAP/MISSING_NA_REASON" \
      "verification map has N/A row(s) without an Evidence value starting with N/A:" \
      "Write a short reason in the Evidence column, for example N/A: backend-only change." \
      "| VM-003 | PC UI | spec | N/A | N/A: backend-only change | N/A |"
  fi
fi
rm -f /tmp/sfa-verification-map-na.out

printf 'PASS: verification map ready in %s (%s row(s))\n' "$map_file" "$row_count"
