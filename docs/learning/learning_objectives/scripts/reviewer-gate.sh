#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/reviewer-gate.sh <review.md | change-dir>

Fails closed unless the independent Reviewer Agent output proves it reviewed:
  - technical solution alignment
  - harness constraints
  - architecture drift
  - comment/log quality
  - maintainability/readability
  - test evidence
and records high_risk_count: 0.
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

require_field_pass() {
  local file="$1" key="$2"
  local value
  value="$(field_value "$file" "$key")"
  if [[ "$value" != "PASS" ]]; then
    fail \
      "REVIEWER_GATE/CHECK_NOT_PASS" \
      "$key is '${value:-missing}', not PASS" \
      "Have the independent Reviewer Agent review this surface and set $key: PASS only with evidence; otherwise fix or block the change." \
      "templates/review.md"
  fi
}

require_field_one_of() {
  local file="$1" key="$2"
  shift 2
  local value allowed
  value="$(field_value "$file" "$key")"
  for allowed in "$@"; do
    if [[ "$value" == "$allowed" ]]; then
      return
    fi
  done
  fail \
    "REVIEWER_GATE/CHECK_INVALID" \
    "$key is '${value:-missing}', not one of: $*" \
    "Have the independent Reviewer Agent review this surface, or record N/A with a concrete reason in the review body." \
    "templates/review.md"
}

require_input_reference() {
  local file="$1" pattern="$2" label="$3"
  if ! grep -Eq "$pattern" "$file"; then
    fail \
      "REVIEWER_GATE/MISSING_REVIEW_INPUT" \
      "review.md does not reference $label" \
      "Add the reviewed input under Reviewed Inputs, or record why the input is not applicable before rerunning the gate." \
      "templates/review.md"
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

target="${1:-}"
[[ -n "$target" ]] || fail \
  "REVIEWER_GATE/MISSING_PATH" \
  "missing review path" \
  "Pass changes/<change-id>/review.md or changes/<change-id>/." \
  "templates/review.md"

if [[ -d "$target" ]]; then
  review="$target/review.md"
else
  review="$target"
fi

[[ -f "$review" ]] || fail \
  "REVIEWER_GATE/MISSING_FILE" \
  "review file not found: $review" \
  "Have the independent Reviewer Agent create changes/<change-id>/review.md before human review or PR." \
  "changes/<change-id>/review.md"

status="$(field_value "$review" "review_status")"
if [[ "$status" != "PASS" ]]; then
  fail \
    "REVIEWER_GATE/STATUS_NOT_PASS" \
    "review_status is '${status:-missing}', not PASS" \
    "Resolve Reviewer findings, rerun required gates, and update review_status only after the independent review passes." \
    "review_status: PASS"
fi

independence="$(field_value "$review" "reviewer_independence")"
if [[ "$independence" != "READ_ONLY" ]]; then
  fail \
    "REVIEWER_GATE/NOT_READ_ONLY" \
    "reviewer_independence is '${independence:-missing}', not READ_ONLY" \
    "Use a read-only Reviewer Agent. The reviewer must not modify files while producing review.md." \
    "reviewer_independence: READ_ONLY"
fi

for key in \
  technical_solution_alignment \
  harness_constraints \
  architecture_drift \
  comment_log_quality \
  maintainability_readability \
  test_evidence; do
  require_field_pass "$review" "$key"
done

require_field_one_of "$review" "style_conformance" "PASS" "N/A"

high_count="$(field_value "$review" "high_risk_count")"
if [[ "$high_count" != "0" ]]; then
  fail \
    "REVIEWER_GATE/HIGH_RISK_NOT_ZERO" \
    "high_risk_count is '${high_count:-missing}', not 0" \
    "Fix or explicitly block on HIGH findings. This gate does not allow unresolved HIGH risk into human review or PR." \
    "high_risk_count: 0"
fi

medium_status="$(field_value "$review" "medium_risk_status")"
if [[ ! "$medium_status" =~ ^(FIXED|RECORDED|N/A)$ ]]; then
  fail \
    "REVIEWER_GATE/MEDIUM_STATUS_INVALID" \
    "medium_risk_status is '${medium_status:-missing}', not FIXED / RECORDED / N/A" \
    "Fix MEDIUM findings, or record them with residual risk and owner before human review." \
    "medium_risk_status: RECORDED"
fi

require_input_reference "$review" 'spec\.md' "spec.md"
require_input_reference "$review" 'technical-solution\.md' "technical-solution.md"
require_input_reference "$review" 'evidence\.md' "evidence.md"
require_input_reference "$review" 'git diff|diff' "diff"

for heading in '## HIGH' '## MEDIUM' '## LOW' '## 结论'; do
  if ! grep -qF "$heading" "$review"; then
    fail \
      "REVIEWER_GATE/MISSING_SECTION" \
      "review.md is missing section: $heading" \
      "Use the Reviewer output format so risks are reviewable by severity." \
      "skills/reviewer/SKILL.md"
  fi
done

if grep -nE '\b(TODO|TBD)\b|待补|未定|<[^>]+>' "$review" >/tmp/sfa-reviewer-placeholders.out; then
  printf 'Unresolved placeholders:\n' >&2
  sed -n '1,20p' /tmp/sfa-reviewer-placeholders.out >&2
  rm -f /tmp/sfa-reviewer-placeholders.out
  fail \
    "REVIEWER_GATE/UNRESOLVED_PLACEHOLDER" \
    "review.md contains unresolved placeholders" \
    "Replace placeholders with concrete findings, explicit N/A reasons, or final review decisions." \
    "templates/review.md"
fi
rm -f /tmp/sfa-reviewer-placeholders.out

printf 'PASS: independent Reviewer Agent gate passed for %s\n' "$review"
