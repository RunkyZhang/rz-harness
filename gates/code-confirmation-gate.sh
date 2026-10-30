#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  gates/code-confirmation-gate.sh <change-dir>

Checks:
  - code-confirmation.md exists
  - code_confirmation_status is CONFIRMED, or NOT_APPLICABLE with a non-empty na_reason

Blocks Tester / Reviewer / full test gates until the user has confirmed the code diff.
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
      print
      exit
    }
  ' "$file"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

change_dir="${1:-}"
[[ -n "$change_dir" ]] || fail \
  "CODE_CONFIRMATION/MISSING_CHANGE_DIR" \
  "missing change directory" \
  "Pass the active change directory, for example changes/<change-id>." \
  "changes/<change-id>"

[[ -d "$change_dir" ]] || fail \
  "CODE_CONFIRMATION/CHANGE_DIR_NOT_FOUND" \
  "change directory not found: $change_dir" \
  "Pass the directory that contains code-confirmation.md." \
  "changes/<change-id>"

doc="$change_dir/code-confirmation.md"
[[ -f "$doc" ]] || fail \
  "CODE_CONFIRMATION/MISSING_DOC" \
  "code-confirmation.md not found in $change_dir" \
  "Copy templates/code-confirmation.md into the change package and record the user confirmation." \
  "cp templates/code-confirmation.md changes/<change-id>/code-confirmation.md"

status="$(field_value "$doc" "code_confirmation_status")"
na_reason="$(field_value "$doc" "na_reason")"

case "$status" in
  "")
    fail \
      "CODE_CONFIRMATION/MISSING_STATUS" \
      "code-confirmation.md has no code_confirmation_status" \
      "Set code_confirmation_status to PENDING, CHANGE_REQUESTED, CONFIRMED, or NOT_APPLICABLE." \
      "code_confirmation_status: PENDING"
    ;;
  CONFIRMED)
    printf 'PASS: code confirmation recorded as CONFIRMED for %s\n' "$change_dir"
    exit 0
    ;;
  NOT_APPLICABLE)
    if [[ -z "$na_reason" || "$na_reason" == "-" || "$na_reason" == "N/A" ]]; then
      fail \
        "CODE_CONFIRMATION/MISSING_NA_REASON" \
        "code_confirmation_status is NOT_APPLICABLE but na_reason is empty" \
        "Write why human code confirmation is not required, with a source." \
        "na_reason: 纯文档变更，用户 2026-10-30 确认免人审"
    fi
    printf 'PASS: code confirmation marked NOT_APPLICABLE for %s (reason: %s)\n' "$change_dir" "$na_reason"
    exit 0
    ;;
  *)
    fail \
      "CODE_CONFIRMATION/NOT_CONFIRMED" \
      "code_confirmation_status is '${status}', not CONFIRMED" \
      "Hand the diff to the user, apply requested changes, then set code_confirmation_status: CONFIRMED before running Tester / Reviewer." \
      "code_confirmation_status: CONFIRMED"
    ;;
esac
