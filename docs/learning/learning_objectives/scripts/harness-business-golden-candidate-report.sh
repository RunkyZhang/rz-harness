#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-business-golden-candidate-report.sh [--root <repo-root>]

Prints an aggregate, source-path-free report for business golden candidates.
It does not read or modify business repositories.
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
        "HARNESS_BUSINESS_GOLDEN_CANDIDATE_REPORT/MISSING_ROOT" \
        "missing value for --root" \
        "Pass a repository root containing evals/business-golden/candidates." \
        "--root /path/to/sfa-ai-harness"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail \
        "HARNESS_BUSINESS_GOLDEN_CANDIDATE_REPORT/UNKNOWN_ARG" \
        "unknown argument: $1" \
        "Use --root only when reporting on a fixture copy." \
        "scripts/harness-business-golden-candidate-report.sh"
      ;;
  esac
done

candidates_dir="$root/evals/business-golden/candidates"
[[ -d "$candidates_dir" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_CANDIDATE_REPORT/MISSING_CANDIDATES_DIR" \
  "missing candidate directory: $candidates_dir" \
  "Create candidate metadata with harness-business-golden-candidate-intake.sh." \
  "evals/business-golden/candidates/<candidate-id>.env"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
candidate_files="$tmpdir/candidates"

find "$candidates_dir" -maxdepth 1 -type f -name '*.env' | sort >"$candidate_files"
[[ -s "$candidate_files" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_CANDIDATE_REPORT/MISSING_CANDIDATES" \
  "no business golden candidate files found under $candidates_dir" \
  "Create at least one candidate metadata file." \
  "scripts/harness-business-golden-candidate-intake.sh --candidate-id demo --source-change-id demo --source-change-path changes/demo --lane backend"

total=0
candidate_count=0
ready_count=0
promoted_count=0
rejected_count=0
needs_review_count=0
sanitized_count=0
blocked_count=0
rows="$tmpdir/rows"
: >"$rows"

next_action() {
  local state="$1" redaction="$2" golden_case_id="$3"
  if [[ "$state" == "PROMOTED" ]]; then
    printf 'done'
  elif [[ "$state" == "REJECTED" ]]; then
    printf 'none'
  elif [[ "$redaction" == "NEEDS_REVIEW" ]]; then
    printf 'redact_source_change'
  elif [[ "$redaction" == "BLOCKED" ]]; then
    printf 'resolve_redaction_blocker'
  elif [[ "$state" == "READY" && -n "$golden_case_id" ]]; then
    printf 'create_or_verify_golden_case'
  else
    printf 'declare_golden_case_id'
  fi
}

while IFS= read -r file; do
  CANDIDATE_ID=""
  SOURCE_CHANGE_ID=""
  SOURCE_CHANGE_PATH=""
  LANE=""
  PROMOTION_STATE=""
  REDACTION_STATUS=""
  BUSINESS_REPO_ACCESS=""
  GOLDEN_CASE_ID=""

  # Candidate metadata is trusted harness input already validated by candidate gate.
  # shellcheck disable=SC1090
  . "$file"

  total=$((total + 1))
  case "$PROMOTION_STATE" in
    CANDIDATE) candidate_count=$((candidate_count + 1)) ;;
    READY) ready_count=$((ready_count + 1)) ;;
    PROMOTED) promoted_count=$((promoted_count + 1)) ;;
    REJECTED) rejected_count=$((rejected_count + 1)) ;;
  esac
  case "$REDACTION_STATUS" in
    NEEDS_REVIEW) needs_review_count=$((needs_review_count + 1)) ;;
    SANITIZED) sanitized_count=$((sanitized_count + 1)) ;;
    BLOCKED) blocked_count=$((blocked_count + 1)) ;;
  esac

  display_case="$GOLDEN_CASE_ID"
  [[ -n "$display_case" ]] || display_case="none"
  action="$(next_action "$PROMOTION_STATE" "$REDACTION_STATUS" "$GOLDEN_CASE_ID")"
  printf '| %s | %s | %s | %s | %s | %s |\n' \
    "$CANDIDATE_ID" "$PROMOTION_STATE" "$REDACTION_STATUS" "$LANE" "$display_case" "$action" >>"$rows"
done <"$candidate_files"

cat <<EOF
# Business Golden Candidate Report
BUSINESS_GOLDEN_CANDIDATE_TOTAL=$total
BUSINESS_GOLDEN_CANDIDATE_STATE=$candidate_count
BUSINESS_GOLDEN_READY=$ready_count
BUSINESS_GOLDEN_PROMOTED=$promoted_count
BUSINESS_GOLDEN_REJECTED=$rejected_count
BUSINESS_GOLDEN_NEEDS_REVIEW=$needs_review_count
BUSINESS_GOLDEN_SANITIZED=$sanitized_count
BUSINESS_GOLDEN_BLOCKED=$blocked_count

| candidate_id | state | redaction | lane | golden_case_id | next_action |
| --- | --- | --- | --- | --- | --- |
EOF

sort "$rows"
printf 'PASS: business golden candidate report completed\n'
