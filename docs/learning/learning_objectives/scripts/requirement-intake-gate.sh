#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/requirement-intake-gate.sh <change-dir>

Validates requirement-intake.md for Tier M/L or high-risk changes.
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

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }
[[ "$#" -eq 1 ]] || { usage; exit 2; }

change_dir="$1"
file="$change_dir/requirement-intake.md"
[[ -f "$file" ]] || fail \
  "REQUIREMENT_INTAKE/MISSING_FILE" \
  "missing requirement-intake.md: $file" \
  "Create the intake artifact from templates/requirement-intake.md for Tier M/L or high-risk changes." \
  "cp templates/requirement-intake.md $file"

field_value() {
  local key="$1"
  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*:" {
      sub("^[[:space:]]*" key "[[:space:]]*:[[:space:]]*", "")
      sub("[[:space:]]+$", "")
      print
      exit
    }
  ' "$file"
}

status="$(field_value "requirement_intake_status")"
[[ "$status" == "READY" ]] || fail \
  "REQUIREMENT_INTAKE/STATUS_NOT_READY" \
  "requirement_intake_status must be READY, got: ${status:-missing}" \
  "Finish PRD itemization, key questions, and question resolution before passing intake." \
  "requirement_intake_status: READY"

prd_count="$(field_value "prd_item_count")"
if ! [[ "$prd_count" =~ ^[0-9]+$ ]] || [[ "$prd_count" -lt 1 ]]; then
  fail \
    "REQUIREMENT_INTAKE/NO_PRD_ITEMS" \
    "prd_item_count must be a positive integer, got: ${prd_count:-missing}" \
    "List each PRD page/field/acceptance item in the PRD item table and update prd_item_count." \
    "prd_item_count: 3"
fi

complete="$(field_value "key_questions_complete")"
[[ "$complete" == "yes" ]] || fail \
  "REQUIREMENT_INTAKE/KEY_QUESTIONS_INCOMPLETE" \
  "key_questions_complete must be yes, got: ${complete:-missing}" \
  "Answer all six key question categories or record resolved questions." \
  "key_questions_complete: yes"

blocking_status="$(field_value "blocking_questions_status")"
case "$blocking_status" in
  RESOLVED|NONE|NOT_APPLICABLE)
    ;;
  *)
    fail \
      "REQUIREMENT_INTAKE/OPEN_QUESTIONS" \
      "blocking_questions_status must be RESOLVED/NONE/NOT_APPLICABLE, got: ${blocking_status:-missing}" \
      "Resolve blocking questions or mark this intake BLOCKED." \
      "blocking_questions_status: RESOLVED"
    ;;
esac

required_categories=(
  "业务对象"
  "入口和角色"
  "CRUD 范围"
  "字段口径"
  "DB/权限/状态机/MQ/job 涉及面"
  "最小回滚"
)

for category in "${required_categories[@]}"; do
  if ! grep -q "|[[:space:]]*$category[[:space:]]*|" "$file"; then
    fail \
      "REQUIREMENT_INTAKE/MISSING_KEY_CATEGORY" \
      "missing key question category: $category" \
      "Fill every required category in the 六类关键问题 table." \
      "| $category | [FACT] ... | READY |"
  fi
done

if grep -Eq '\|[^|]*\|[^|]*\[QUESTION\][^|]*\|[^|]*\|[[:space:]]*(OPEN|PENDING|BLOCKED)[[:space:]]*\|' "$file"; then
  fail \
    "REQUIREMENT_INTAKE/OPEN_QUESTIONS" \
    "requirement intake still contains open/blocking QUESTION rows" \
    "Resolve the question or keep requirement_intake_status as BLOCKED." \
    "| PRD-001 | ... | ... | [QUESTION] | RESOLVED |"
fi

printf 'PASS: requirement intake gate passed for %s\n' "$change_dir"
