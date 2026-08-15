#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-business-golden-eval.sh [--root <repo-root>]

Runs sanitized business golden cases under evals/business-golden.
Each case is a self-contained SFA_EVAL_ROOT and is graded by scripts/eval-golden.sh.
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

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --root)
      root="${2:-}"
      [[ -n "$root" ]] || fail \
        "HARNESS_BUSINESS_GOLDEN_EVAL/MISSING_ROOT" \
        "missing value for --root" \
        "Pass a repository root containing evals/business-golden." \
        "scripts/harness-business-golden-eval.sh --root /path/to/repo"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail \
        "HARNESS_BUSINESS_GOLDEN_EVAL/UNKNOWN_ARG" \
        "unknown argument: $1" \
        "Use --root only when validating a fixture copy." \
        "scripts/harness-business-golden-eval.sh"
      ;;
  esac
done

cases_dir="$root/evals/business-golden"
[[ -d "$cases_dir" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_EVAL/MISSING_CASES_DIR" \
  "missing business golden cases directory: $cases_dir" \
  "Create evals/business-golden/<case-id>/metadata.env." \
  "evals/business-golden/fullstack-crud-pass/metadata.env"

grade_case() {
  local case_dir="$1" rel="$2"
  local metadata="$case_dir/metadata.env"
  local out="$tmpdir/$rel.out"
  local err="$tmpdir/$rel.err"

  [[ -f "$metadata" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_EVAL/MISSING_METADATA" \
    "missing metadata.env for business golden case: $rel" \
    "Add metadata.env with CASE_ID, CHANGE_ID, EXPECTED_RESULT, and CHANGED_FILES." \
    "$rel/metadata.env"

  CASE_ID=""
  CHANGE_ID=""
  EXPECTED_RESULT=""
  CHANGED_FILES=""

  # Business golden metadata is versioned, trusted harness input.
  # shellcheck disable=SC1090
  . "$metadata"

  [[ -n "$CASE_ID" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_EVAL/MISSING_REQUIRED_FIELD" \
    "metadata missing CASE_ID: $rel" \
    "Set CASE_ID to the case directory name." \
    "CASE_ID=fullstack-crud-pass"
  [[ -n "$CHANGE_ID" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_EVAL/MISSING_REQUIRED_FIELD" \
    "metadata missing CHANGE_ID: $rel" \
    "Set CHANGE_ID to the fixture change id under changes/." \
    "CHANGE_ID=bg-fullstack-crud-pass"
  [[ -n "$EXPECTED_RESULT" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_EVAL/MISSING_REQUIRED_FIELD" \
    "metadata missing EXPECTED_RESULT: $rel" \
    "Set EXPECTED_RESULT to PASS or FAIL." \
    "EXPECTED_RESULT=PASS"
  [[ -n "$CHANGED_FILES" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_EVAL/MISSING_REQUIRED_FIELD" \
    "metadata missing CHANGED_FILES: $rel" \
    "List changed files relative to the case root." \
    "CHANGED_FILES=repo/src/example.java"

  case "$EXPECTED_RESULT" in
    PASS|FAIL) ;;
    *)
      fail \
        "HARNESS_BUSINESS_GOLDEN_EVAL/INVALID_EXPECTED_RESULT" \
        "EXPECTED_RESULT must be PASS or FAIL: $rel" \
        "Use deterministic expected result labels." \
        "EXPECTED_RESULT=FAIL"
      ;;
  esac

  local changed_args=()
  local changed
  for changed in $CHANGED_FILES; do
    changed_args+=("$changed")
  done

  local observed="PASS"
  local reason="matched"
  if ! (cd "$case_dir" && SFA_EVAL_ROOT="$case_dir" "$root/scripts/eval-golden.sh" "$CHANGE_ID" "${changed_args[@]}") >"$out" 2>"$err"; then
    observed="FAIL"
    reason="eval-golden failed"
  fi

  printf 'CASE %s EXPECTED=%s OBSERVED=%s REASON=%s\n' "$CASE_ID" "$EXPECTED_RESULT" "$observed" "$reason"

  if [[ "$EXPECTED_RESULT" != "$observed" ]]; then
    fail \
      "HARNESS_BUSINESS_GOLDEN_EVAL/UNEXPECTED_RESULT" \
      "business golden case result did not match expectation: $CASE_ID" \
      "Fix the case metadata, fixture artifacts, or eval-golden grading contract." \
      "EXPECTED=$EXPECTED_RESULT OBSERVED=$observed"
  fi
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cases="$tmpdir/cases"

find "$cases_dir" -mindepth 1 -maxdepth 1 -type d ! -name candidates | sort >"$cases"
[[ -s "$cases" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_EVAL/MISSING_CASES" \
  "no business golden cases found under $cases_dir" \
  "Add at least one case directory with metadata.env." \
  "evals/business-golden/fullstack-crud-pass/"

total=0
matched=0
while IFS= read -r case_dir; do
  rel="${case_dir#"$cases_dir"/}"
  grade_case "$case_dir" "$rel"
  total=$((total + 1))
  matched=$((matched + 1))
done <"$cases"

printf 'EVAL_TYPE=BUSINESS_GOLDEN\n'
printf 'BUSINESS_GOLDEN_TOTAL=%s\n' "$total"
printf 'BUSINESS_GOLDEN_MATCHED=%s\n' "$matched"
printf 'PASS: business golden eval completed\n'
