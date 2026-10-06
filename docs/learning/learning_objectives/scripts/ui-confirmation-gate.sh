#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/ui-confirmation-gate.sh <ui-confirmation.md | change-dir>

For complex UI, fails closed unless ui-confirmation.md records:
  - Complexity: complex
  - Status: CONFIRMED
  - at least one artifact path/URL
  - a reviewer row with Decision CONFIRMED
Simple or not_applicable UI passes when explicitly recorded.
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
  "UI_CONFIRMATION/MISSING_PATH" \
  "missing UI confirmation path" \
  "Pass changes/<change-id>/ui-confirmation.md or changes/<change-id>." \
  "templates/ui-confirmation.md"
if [[ -d "$target" ]]; then
  ui_file="$target/ui-confirmation.md"
else
  ui_file="$target"
fi
[[ -f "$ui_file" ]] || fail \
  "UI_CONFIRMATION/MISSING_FILE" \
  "ui-confirmation.md not found: $ui_file" \
  "Create ui-confirmation.md for complex UI or record NOT_APPLICABLE." \
  "templates/ui-confirmation.md"

complexity="$(awk -F'|' 'tolower($2) ~ /complexity/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print tolower($3); exit }' "$ui_file")"
status="$(awk -F'|' 'tolower($2) ~ /^ *status *$/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print toupper($3); exit }' "$ui_file")"

case "$complexity" in
  simple|not_applicable)
    printf 'PASS: UI confirmation gate passed for %s (complexity=%s)\n' "$ui_file" "$complexity"
    exit 0
    ;;
  complex) ;;
  *)
    fail \
      "UI_CONFIRMATION/MISSING_COMPLEXITY" \
      "UI Complexity is '${complexity:-missing}'" \
      "Record Complexity as complex, simple, or not_applicable." \
      "| Complexity | complex |"
    ;;
esac

[[ "$status" == "CONFIRMED" ]] || fail \
  "UI_CONFIRMATION/PENDING_CONFIRMATION" \
  "complex UI confirmation status is '${status:-missing}', not CONFIRMED" \
  "Get human confirmation for the runnable page/prototype before claiming UI pass." \
  "| Status | CONFIRMED |"

grep -qE '^\|[[:space:]]*[^|]*(Prototype|runnable|page|screenshot)[^|]*[[:space:]]*\|[[:space:]]*([^<| -][^|]*|https?://[^|]+)[[:space:]]*\|' "$ui_file" || fail \
  "UI_CONFIRMATION/MISSING_ARTIFACT" \
  "complex UI confirmation lacks artifact path or URL" \
  "Record the prototype, runnable page, or screenshot path reviewed by the user." \
  "| Prototype or runnable page | artifacts/<change-id>/ui/page.png | reviewed |"

grep -qE '^\|[[:space:]]*[^|]+[[:space:]]*\|[[:space:]]*CONFIRMED[[:space:]]*\|' "$ui_file" || fail \
  "UI_CONFIRMATION/MISSING_REVIEWER_CONFIRMATION" \
  "complex UI confirmation lacks reviewer CONFIRMED row" \
  "Record the reviewer, decision, time, and notes." \
  "| user | CONFIRMED | 2026-06-12 10:00 | accepted |"

printf 'PASS: UI confirmation gate passed for %s (complex UI confirmed)\n' "$ui_file"
