#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-eval-weekly-run.sh [--suite-root <repo-root>] [--telemetry-dir <dir>] [--summary-file <file>] [--week <YYYY-WW>]

Runs the harness eval suite with aggregate telemetry enabled, then writes an
aggregate-only weekly audit summary. Raw telemetry stays in the ignored local
telemetry directory.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  printf 'CODE: %s\n' "$2" >&2
  printf 'FIX: %s\n' "$3" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
suite_root="$root"
telemetry_dir="$root/.harness/telemetry"
week="$(date -u '+%Y-W%V')"
summary_file=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --suite-root)
      suite_root="${2:-}"
      [[ -n "$suite_root" ]] || fail "missing value for --suite-root" "EVAL_WEEKLY_RUN/MISSING_VALUE" "Pass a repository root path."
      shift 2
      ;;
    --telemetry-dir)
      telemetry_dir="${2:-}"
      [[ -n "$telemetry_dir" ]] || fail "missing value for --telemetry-dir" "EVAL_WEEKLY_RUN/MISSING_VALUE" "Pass a directory path."
      shift 2
      ;;
    --summary-file)
      summary_file="${2:-}"
      [[ -n "$summary_file" ]] || fail "missing value for --summary-file" "EVAL_WEEKLY_RUN/MISSING_VALUE" "Pass a Markdown output file path."
      shift 2
      ;;
    --week)
      week="${2:-}"
      [[ -n "$week" ]] || fail "missing value for --week" "EVAL_WEEKLY_RUN/MISSING_VALUE" "Pass a week label."
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1" "EVAL_WEEKLY_RUN/UNKNOWN_ARG" "Use --suite-root, --telemetry-dir, --summary-file, or --week."
      ;;
  esac
done

[[ -d "$suite_root" ]] || fail "suite root directory not found: $suite_root" "EVAL_WEEKLY_RUN/SUITE_ROOT_NOT_FOUND" "Pass an existing repository root."

if [[ -z "$summary_file" ]]; then
  summary_file="$telemetry_dir/weekly-summary-${week}.md"
fi

mkdir -p "$telemetry_dir"
mkdir -p "$(dirname "$summary_file")"

set +e
"$root/scripts/harness-eval-suite.sh" \
  --root "$suite_root" \
  --record-telemetry \
  --telemetry-dir "$telemetry_dir"
suite_exit_code="$?"
set -e

"$root/scripts/harness-weekly-audit-summary.sh" \
  --telemetry-dir "$telemetry_dir" \
  --week "$week" >"$summary_file"

printf '# Harness Eval Weekly Run\n'
printf 'WEEK=%s\n' "$week"
printf 'TELEMETRY_DIR=local ignored scratch\n'
printf 'SUMMARY_FILE=%s\n' "$summary_file"
printf 'SUITE_EXIT_CODE=%s\n' "$suite_exit_code"

if [[ "$suite_exit_code" -eq 0 ]]; then
  printf 'EVAL_WEEKLY_RUN_DECISION=PASS\n'
  printf 'PASS: harness eval weekly run completed\n'
  exit 0
fi

printf 'EVAL_WEEKLY_RUN_DECISION=FAIL\n'
printf 'FAIL: harness eval weekly run completed with suite failure\n' >&2
exit "$suite_exit_code"
