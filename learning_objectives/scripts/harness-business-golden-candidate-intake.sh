#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-business-golden-candidate-intake.sh --candidate-id <id> --source-change-id <id> --source-change-path <changes/id> --lane <lane> [--root <repo-root>]

Creates a safe business golden candidate metadata record. It does not read or
modify business repositories, does not mark the candidate sanitized, and does
not promote a golden case.
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
candidate_id=""
source_change_id=""
source_change_path=""
lane=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --root)
      root="${2:-}"
      [[ -n "$root" ]] || fail \
        "HARNESS_BUSINESS_GOLDEN_INTAKE/MISSING_ROOT" \
        "missing value for --root" \
        "Pass a repository root containing changes/." \
        "scripts/harness-business-golden-candidate-intake.sh --root /path/to/repo ..."
      shift 2
      ;;
    --candidate-id)
      candidate_id="${2:-}"
      [[ -n "$candidate_id" ]] || fail \
        "HARNESS_BUSINESS_GOLDEN_INTAKE/MISSING_CANDIDATE_ID" \
        "missing value for --candidate-id" \
        "Pass a stable lowercase candidate id." \
        "--candidate-id add-distribution-qr-estimated-reward-amount"
      shift 2
      ;;
    --source-change-id)
      source_change_id="${2:-}"
      [[ -n "$source_change_id" ]] || fail \
        "HARNESS_BUSINESS_GOLDEN_INTAKE/MISSING_SOURCE_CHANGE_ID" \
        "missing value for --source-change-id" \
        "Pass the historical change id." \
        "--source-change-id add-distribution-qr-estimated-reward-amount"
      shift 2
      ;;
    --source-change-path)
      source_change_path="${2:-}"
      [[ -n "$source_change_path" ]] || fail \
        "HARNESS_BUSINESS_GOLDEN_INTAKE/MISSING_SOURCE_CHANGE_PATH" \
        "missing value for --source-change-path" \
        "Pass a repo-relative changes/<id> path." \
        "--source-change-path changes/add-distribution-qr-estimated-reward-amount"
      shift 2
      ;;
    --lane)
      lane="${2:-}"
      [[ -n "$lane" ]] || fail \
        "HARNESS_BUSINESS_GOLDEN_INTAKE/MISSING_LANE" \
        "missing value for --lane" \
        "Pass backend, frontend, fullstack, mobile, or control-plane." \
        "--lane fullstack"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail \
        "HARNESS_BUSINESS_GOLDEN_INTAKE/UNKNOWN_ARG" \
        "unknown argument: $1" \
        "Use --candidate-id, --source-change-id, --source-change-path, --lane, and optional --root." \
        "scripts/harness-business-golden-candidate-intake.sh --help"
      ;;
  esac
done

[[ -d "$root" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/ROOT_NOT_FOUND" \
  "root directory not found: $root" \
  "Pass an existing harness repository root." \
  "--root /path/to/sfa-ai-harness"

[[ -n "$candidate_id" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/MISSING_CANDIDATE_ID" \
  "missing --candidate-id" \
  "Pass a stable lowercase candidate id." \
  "--candidate-id long-promo-sku-single-pack-unit"
[[ -n "$source_change_id" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/MISSING_SOURCE_CHANGE_ID" \
  "missing --source-change-id" \
  "Pass the historical change id." \
  "--source-change-id long-promo-sku-single-pack-unit"
[[ -n "$source_change_path" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/MISSING_SOURCE_CHANGE_PATH" \
  "missing --source-change-path" \
  "Pass a repo-relative changes/<id> path." \
  "--source-change-path changes/long-promo-sku-single-pack-unit"
[[ -n "$lane" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/MISSING_LANE" \
  "missing --lane" \
  "Pass backend, frontend, fullstack, mobile, or control-plane." \
  "--lane backend"

safe_id_re='^[a-z0-9][a-z0-9-]*$'
[[ "$candidate_id" =~ $safe_id_re ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/INVALID_CANDIDATE_ID" \
  "invalid candidate id: $candidate_id" \
  "Use lowercase letters, digits, and hyphens only." \
  "--candidate-id add-distribution-qr-estimated-reward-amount"
[[ "$source_change_id" =~ $safe_id_re ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/INVALID_SOURCE_CHANGE_ID" \
  "invalid source change id: $source_change_id" \
  "Use lowercase letters, digits, and hyphens only." \
  "--source-change-id add-distribution-qr-estimated-reward-amount"

case "$lane" in
  backend|frontend|fullstack|mobile|control-plane) ;;
  *)
    fail \
      "HARNESS_BUSINESS_GOLDEN_INTAKE/INVALID_LANE" \
      "invalid lane: $lane" \
      "Use backend, frontend, fullstack, mobile, or control-plane." \
      "--lane fullstack"
    ;;
esac

[[ "$source_change_path" != /* ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/ABSOLUTE_SOURCE_PATH" \
  "source change path must be repo-relative" \
  "Use changes/<id>; do not store local absolute paths." \
  "--source-change-path changes/add-distribution-qr-estimated-reward-amount"
[[ "$source_change_path" == changes/* ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/INVALID_SOURCE_CHANGE_PATH" \
  "source change path must start with changes/" \
  "Use a harness change artifact path." \
  "--source-change-path changes/add-distribution-qr-estimated-reward-amount"
[[ "$source_change_path" != *".."* && "$source_change_path" != *" "* ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/INVALID_SOURCE_CHANGE_PATH" \
  "source change path contains unsafe characters" \
  "Use a simple repo-relative path without spaces or parent traversal." \
  "--source-change-path changes/add-distribution-qr-estimated-reward-amount"
[[ -d "$root/$source_change_path" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/MISSING_SOURCE_CHANGE" \
  "source change path not found: $source_change_path" \
  "Create or point to an existing changes/<id> directory before intake." \
  "--source-change-path changes/add-distribution-qr-estimated-reward-amount"

candidates_dir="$root/evals/business-golden/candidates"
candidate_file="$candidates_dir/$candidate_id.env"
mkdir -p "$candidates_dir"

[[ ! -e "$candidate_file" ]] || fail \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/CANDIDATE_EXISTS" \
  "candidate metadata already exists: evals/business-golden/candidates/$candidate_id.env" \
  "Review or update the existing candidate instead of overwriting it." \
  "evals/business-golden/candidates/$candidate_id.env"

{
  printf 'CANDIDATE_ID=%s\n' "$candidate_id"
  printf 'SOURCE_CHANGE_ID=%s\n' "$source_change_id"
  printf 'SOURCE_CHANGE_PATH=%s\n' "$source_change_path"
  printf 'LANE=%s\n' "$lane"
  printf 'PROMOTION_STATE=CANDIDATE\n'
  printf 'REDACTION_STATUS=NEEDS_REVIEW\n'
  printf 'BUSINESS_REPO_ACCESS=NO\n'
  printf 'GOLDEN_CASE_ID=\n'
  printf 'REDACTION_REVIEW_PATH=\n'
} >"$candidate_file"

printf 'CANDIDATE_FILE=%s\n' "${candidate_file#"$root"/}"
printf 'PROMOTION_STATE=CANDIDATE\n'
printf 'REDACTION_STATUS=NEEDS_REVIEW\n'
printf 'BUSINESS_REPO_ACCESS=NO\n'
printf 'PASS: business golden candidate intake completed\n'
