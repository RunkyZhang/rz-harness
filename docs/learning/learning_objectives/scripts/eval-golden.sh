#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/eval-golden.sh <change-id> [changed-file...]

Checks the local fullstack CRUD golden scenario:
  - required change, contract, PC E2E, evidence, and review artifacts exist
  - confidence gate passes
  - assumption leak and allowed paths gates pass when changed files are supplied
  - evidence and review contain minimal handoff signals

Environment:
  SFA_EVAL_ROOT  Optional content root. Defaults to the harness repo root.
USAGE
}

fail() {
  local code="$1"
  local message="$2"
  local fix="$3"
  local sample="$4"
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

change_id="${1:-}"
[[ -n "$change_id" ]] || fail \
  "EVAL_GOLDEN/MISSING_CHANGE_ID" \
  "missing change id" \
  "Pass the active change id to grade." \
  "changes/pilot-crud-tbd/spec.md"
shift || true

harness_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
content_root="${SFA_EVAL_ROOT:-$harness_root}"
trap 'rm -f /tmp/sfa-eval-confidence.out /tmp/sfa-eval-assumption.out /tmp/sfa-eval-allowed.out' EXIT

spec="$content_root/changes/$change_id/spec.md"
contract="$content_root/docs/contracts/$change_id-api.md"
plan="$content_root/changes/$change_id/plan.md"
evidence="$content_root/changes/$change_id/evidence.md"
review="$content_root/changes/$change_id/review.md"
smoke_plan="$content_root/changes/$change_id/pc-e2e-smoke-plan.md"
smoke_report="$content_root/changes/$change_id/pc-e2e-smoke-report.md"

required=(
  "$spec"
  "$contract"
  "$plan"
  "$evidence"
  "$review"
  "$smoke_plan"
  "$smoke_report"
)

missing=()
for path in "${required[@]}"; do
  [[ -f "$path" ]] || missing+=("$path")
done

if [[ "${#missing[@]}" -gt 0 ]]; then
  printf 'FAIL: missing golden eval artifacts:\n' >&2
  printf 'CODE: EVAL_GOLDEN/MISSING_ARTIFACTS\n' >&2
  printf 'FIX: Create the missing spec, contract, plan, evidence, review, and PC smoke artifacts before grading the change.\n' >&2
  printf 'SAMPLE: changes/pilot-crud-tbd/spec.md\n' >&2
  printf ' - %s\n' "${missing[@]}" >&2
  exit 1
fi

"$harness_root/scripts/confidence-gate.sh" "$spec" >/tmp/sfa-eval-confidence.out

if [[ "$#" -gt 0 ]]; then
  "$harness_root/scripts/assumption-leak-gate.sh" "$spec" "$@" >/tmp/sfa-eval-assumption.out
  "$harness_root/scripts/allowed-paths.sh" "$spec" "$@" >/tmp/sfa-eval-allowed.out
else
  printf 'NOTICE: no changed files supplied; skipped assumption leak and allowed paths gates\n'
fi

grep -qE 'Result:[[:space:]]*(PASS|FAIL|BLOCKED)|Exit:[[:space:]]*0|PASS:' "$evidence" \
  || fail \
    "EVAL_GOLDEN/MISSING_EVIDENCE_RESULT" \
    "evidence must contain a concrete command result, exit code, PASS, FAIL, or BLOCKED signal" \
    "Record the command and observed result in changes/<change-id>/evidence.md." \
    "templates/pre-pr-review.md"

grep -q 'HIGH' "$review" \
  || fail \
    "EVAL_GOLDEN/MISSING_HIGH_REVIEW" \
    "review must contain HIGH risk section" \
    "Record Reviewer output with a HIGH section, even when there are no high-risk findings." \
    "templates/pre-pr-review.md"

grep -qE 'PASS|FAIL|BLOCKED|Result' "$smoke_report" \
  || fail \
    "EVAL_GOLDEN/MISSING_SMOKE_RESULT" \
    "pc-e2e-smoke-report must contain PASS, FAIL, BLOCKED, or Result" \
    "Record the PC smoke result or explicit BLOCKED reason before grading." \
    "templates/pc-e2e-smoke-report.md"

printf 'PASS: golden eval passed for %s\n' "$change_id"
