#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-business-golden-candidate-gate.sh [--root <repo-root>]

Validates candidate records under evals/business-golden/candidates before they
are promoted into sanitized business golden cases.
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
        "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_ROOT" \
        "missing value for --root" \
        "Pass a repository root containing evals/business-golden/candidates." \
        "scripts/harness-business-golden-candidate-gate.sh --root /path/to/repo"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail \
        "HARNESS_BUSINESS_GOLDEN_CANDIDATE/UNKNOWN_ARG" \
        "unknown argument: $1" \
        "Use --root only when validating a fixture copy." \
        "scripts/harness-business-golden-candidate-gate.sh"
      ;;
  esac
done

candidates_dir="$root/evals/business-golden/candidates"
[[ -d "$candidates_dir" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_CANDIDATES_DIR" \
  "missing candidate directory: $candidates_dir" \
  "Create evals/business-golden/candidates/<candidate-id>.env." \
  "evals/business-golden/candidates/add-distribution-qr-estimated-reward-amount.env"

validate_candidate() {
  local file="$1"

  CANDIDATE_ID=""
  SOURCE_CHANGE_ID=""
  SOURCE_CHANGE_PATH=""
  LANE=""
  PROMOTION_STATE=""
  REDACTION_STATUS=""
  BUSINESS_REPO_ACCESS=""
  GOLDEN_CASE_ID=""
  REDACTION_REVIEW_PATH=""

  # Candidate metadata is versioned, trusted harness input.
  # shellcheck disable=SC1090
  . "$file"

  local rel="${file#"$candidates_dir"/}"
  [[ -n "$CANDIDATE_ID" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_REQUIRED_FIELD" \
    "candidate missing CANDIDATE_ID: $rel" \
    "Set CANDIDATE_ID to a stable candidate id." \
    "CANDIDATE_ID=add-distribution-qr-estimated-reward-amount"
  [[ -n "$SOURCE_CHANGE_ID" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_REQUIRED_FIELD" \
    "candidate missing SOURCE_CHANGE_ID: $CANDIDATE_ID" \
    "Set SOURCE_CHANGE_ID to the historical change id." \
    "SOURCE_CHANGE_ID=add-distribution-qr-estimated-reward-amount"
  [[ -n "$SOURCE_CHANGE_PATH" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_REQUIRED_FIELD" \
    "candidate missing SOURCE_CHANGE_PATH: $CANDIDATE_ID" \
    "Set SOURCE_CHANGE_PATH to a relative changes/<id> path." \
    "SOURCE_CHANGE_PATH=changes/add-distribution-qr-estimated-reward-amount"
  [[ -n "$LANE" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_REQUIRED_FIELD" \
    "candidate missing LANE: $CANDIDATE_ID" \
    "Set LANE to backend, frontend, fullstack, mobile, or control-plane." \
    "LANE=backend"
  [[ -n "$PROMOTION_STATE" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_REQUIRED_FIELD" \
    "candidate missing PROMOTION_STATE: $CANDIDATE_ID" \
    "Use CANDIDATE, READY, PROMOTED, or REJECTED." \
    "PROMOTION_STATE=CANDIDATE"
  [[ -n "$REDACTION_STATUS" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_REQUIRED_FIELD" \
    "candidate missing REDACTION_STATUS: $CANDIDATE_ID" \
    "Use NEEDS_REVIEW, SANITIZED, or BLOCKED." \
    "REDACTION_STATUS=NEEDS_REVIEW"
  [[ -n "$BUSINESS_REPO_ACCESS" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_REQUIRED_FIELD" \
    "candidate missing BUSINESS_REPO_ACCESS: $CANDIDATE_ID" \
    "Use NO or READ_ONLY_PLANNED." \
    "BUSINESS_REPO_ACCESS=NO"

  case "$PROMOTION_STATE" in
    CANDIDATE|READY|PROMOTED|REJECTED) ;;
    *)
      fail \
        "HARNESS_BUSINESS_GOLDEN_CANDIDATE/INVALID_PROMOTION_STATE" \
        "invalid PROMOTION_STATE for $CANDIDATE_ID: $PROMOTION_STATE" \
        "Use CANDIDATE, READY, PROMOTED, or REJECTED." \
        "PROMOTION_STATE=CANDIDATE"
      ;;
  esac

  case "$REDACTION_STATUS" in
    NEEDS_REVIEW|SANITIZED|BLOCKED) ;;
    *)
      fail \
        "HARNESS_BUSINESS_GOLDEN_CANDIDATE/INVALID_REDACTION_STATUS" \
        "invalid REDACTION_STATUS for $CANDIDATE_ID: $REDACTION_STATUS" \
        "Use NEEDS_REVIEW, SANITIZED, or BLOCKED." \
        "REDACTION_STATUS=NEEDS_REVIEW"
      ;;
  esac

  case "$BUSINESS_REPO_ACCESS" in
    NO|READ_ONLY_PLANNED) ;;
    *)
      fail \
        "HARNESS_BUSINESS_GOLDEN_CANDIDATE/INVALID_BUSINESS_REPO_ACCESS" \
        "invalid BUSINESS_REPO_ACCESS for $CANDIDATE_ID: $BUSINESS_REPO_ACCESS" \
        "Use NO or READ_ONLY_PLANNED." \
        "BUSINESS_REPO_ACCESS=NO"
      ;;
  esac

  [[ "$SOURCE_CHANGE_PATH" == changes/* && "$SOURCE_CHANGE_PATH" != *".."* && "$SOURCE_CHANGE_PATH" != *" "* ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_CANDIDATE/INVALID_SOURCE_CHANGE_PATH" \
    "SOURCE_CHANGE_PATH must be a safe changes/<id> path for $CANDIDATE_ID" \
    "Use a repo-relative changes/<id> path without spaces or parent traversal." \
    "SOURCE_CHANGE_PATH=changes/add-distribution-qr-estimated-reward-amount"

  [[ "$SOURCE_CHANGE_PATH" != /* ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_CANDIDATE/ABSOLUTE_SOURCE_PATH" \
    "SOURCE_CHANGE_PATH must be relative for $CANDIDATE_ID" \
    "Use a repo-relative changes/<id> path; do not store local personal paths." \
    "SOURCE_CHANGE_PATH=changes/add-distribution-qr-estimated-reward-amount"

  [[ -d "$root/$SOURCE_CHANGE_PATH" ]] || fail \
    "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_SOURCE_CHANGE" \
    "source change path not found for $CANDIDATE_ID: $SOURCE_CHANGE_PATH" \
    "Point SOURCE_CHANGE_PATH to an existing local changes/<id> directory." \
    "SOURCE_CHANGE_PATH=changes/add-distribution-qr-estimated-reward-amount"

  if [[ "$PROMOTION_STATE" == "READY" || "$PROMOTION_STATE" == "PROMOTED" ]]; then
    [[ "$REDACTION_STATUS" == "SANITIZED" ]] || fail \
      "HARNESS_BUSINESS_GOLDEN_CANDIDATE/READY_NOT_SANITIZED" \
      "ready or promoted candidate is not sanitized: $CANDIDATE_ID" \
      "Complete redaction review before marking a candidate READY or PROMOTED." \
      "REDACTION_STATUS=SANITIZED"
    [[ -n "$GOLDEN_CASE_ID" ]] || fail \
      "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_GOLDEN_CASE_ID" \
      "ready or promoted candidate missing GOLDEN_CASE_ID: $CANDIDATE_ID" \
      "Set GOLDEN_CASE_ID to the target evals/business-golden case id." \
      "GOLDEN_CASE_ID=distribution-qr-estimated-reward"
    [[ -n "$REDACTION_REVIEW_PATH" ]] || fail \
      "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_REDACTION_REVIEW_PATH" \
      "ready or promoted candidate missing REDACTION_REVIEW_PATH: $CANDIDATE_ID" \
      "Set REDACTION_REVIEW_PATH to a repo-relative redaction review evidence file." \
      "REDACTION_REVIEW_PATH=evals/business-golden/candidates/redaction-reviews/distribution-qr-estimated-reward.md"
    [[ "$REDACTION_REVIEW_PATH" != /* ]] || fail \
      "HARNESS_BUSINESS_GOLDEN_CANDIDATE/ABSOLUTE_REDACTION_REVIEW_PATH" \
      "REDACTION_REVIEW_PATH must be relative for $CANDIDATE_ID" \
      "Use a repo-relative path; do not store local personal paths." \
      "REDACTION_REVIEW_PATH=evals/business-golden/candidates/redaction-reviews/distribution-qr-estimated-reward.md"
    [[ "$REDACTION_REVIEW_PATH" != *".."* && "$REDACTION_REVIEW_PATH" != *" "* ]] || fail \
      "HARNESS_BUSINESS_GOLDEN_CANDIDATE/INVALID_REDACTION_REVIEW_PATH" \
      "REDACTION_REVIEW_PATH contains unsafe characters for $CANDIDATE_ID" \
      "Use a simple repo-relative path without spaces or parent traversal." \
      "REDACTION_REVIEW_PATH=evals/business-golden/candidates/redaction-reviews/distribution-qr-estimated-reward.md"
    [[ -f "$root/$REDACTION_REVIEW_PATH" ]] || fail \
      "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_REDACTION_REVIEW" \
      "redaction review evidence not found for $CANDIDATE_ID: $REDACTION_REVIEW_PATH" \
      "Create the redaction review file before marking a candidate READY or PROMOTED." \
      "evals/business-golden/candidates/redaction-reviews/distribution-qr-estimated-reward.md"
    grep -Eq '^\|[[:space:]]*redaction_status[[:space:]]*\|[[:space:]]*`?SANITIZED`?[[:space:]]*\|' "$root/$REDACTION_REVIEW_PATH" || fail \
      "HARNESS_BUSINESS_GOLDEN_CANDIDATE/INVALID_REDACTION_REVIEW" \
      "redaction review evidence must explicitly approve redaction_status SANITIZED for $CANDIDATE_ID" \
      "Use a structured table row with redaction_status set to SANITIZED." \
      "| redaction_status | \`SANITIZED\` |"
    grep -Eq '^\|[[:space:]]*business_repo_access[[:space:]]*\|[[:space:]]*`?NO`?[[:space:]]*\|' "$root/$REDACTION_REVIEW_PATH" || fail \
      "HARNESS_BUSINESS_GOLDEN_CANDIDATE/INVALID_REDACTION_REVIEW" \
      "redaction review evidence must explicitly approve business_repo_access NO for $CANDIDATE_ID" \
      "Use a structured table row with business_repo_access set to NO." \
      "| business_repo_access | \`NO\` |"
    grep -Eq '^Approved for `?PROMOTED`? candidate state' "$root/$REDACTION_REVIEW_PATH" || fail \
      "HARNESS_BUSINESS_GOLDEN_CANDIDATE/INVALID_REDACTION_REVIEW" \
      "redaction review evidence must explicitly approve PROMOTED candidate state for $CANDIDATE_ID" \
      "Use an approved decision line, not a rejected or ambiguous decision." \
      "Approved for \`PROMOTED\` candidate state."
    personal_path_re='/'"Users/"'[^/[:space:]]+|C:\\'"Users"'\\[^[:space:]\\]+'
    if grep -Eq "$personal_path_re" "$root/$REDACTION_REVIEW_PATH"; then
      fail \
        "HARNESS_BUSINESS_GOLDEN_CANDIDATE/INVALID_REDACTION_REVIEW" \
        "redaction review evidence contains a personal path for $CANDIDATE_ID" \
        "Remove personal paths from versioned redaction review evidence." \
        "Use repo-relative paths only."
    fi
  fi

  if [[ "$PROMOTION_STATE" == "PROMOTED" ]]; then
    [[ -f "$root/evals/business-golden/$GOLDEN_CASE_ID/metadata.env" ]] || fail \
      "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_PROMOTED_CASE" \
      "promoted candidate has no golden case fixture: $CANDIDATE_ID -> $GOLDEN_CASE_ID" \
      "Create evals/business-golden/<golden-case-id>/metadata.env before marking PROMOTED." \
      "evals/business-golden/distribution-qr-estimated-reward/metadata.env"
  fi

  printf 'CANDIDATE %s STATE=%s REDACTION=%s LANE=%s REDACTION_REVIEW=%s\n' \
    "$CANDIDATE_ID" "$PROMOTION_STATE" "$REDACTION_STATUS" "$LANE" "${REDACTION_REVIEW_PATH:-none}"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
candidate_files="$tmpdir/candidates"

find "$candidates_dir" -maxdepth 1 -type f -name '*.env' | sort >"$candidate_files"
[[ -s "$candidate_files" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_CANDIDATES" \
  "no business golden candidate files found under $candidates_dir" \
  "Add at least one candidate .env file." \
  "evals/business-golden/candidates/add-distribution-qr-estimated-reward-amount.env"

total=0
ready=0
promoted=0
while IFS= read -r file; do
  validate_candidate "$file"
  total=$((total + 1))
  case "$PROMOTION_STATE" in
    READY) ready=$((ready + 1)) ;;
    PROMOTED) promoted=$((promoted + 1)) ;;
  esac
done <"$candidate_files"

printf 'EVAL_TYPE=BUSINESS_GOLDEN_CANDIDATE\n'
printf 'BUSINESS_GOLDEN_CANDIDATE_TOTAL=%s\n' "$total"
printf 'BUSINESS_GOLDEN_READY=%s\n' "$ready"
printf 'BUSINESS_GOLDEN_PROMOTED=%s\n' "$promoted"
printf 'PASS: business golden candidate gate completed\n'
