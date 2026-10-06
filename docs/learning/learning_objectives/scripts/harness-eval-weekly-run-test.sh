#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local file="$1" pattern="$2" label="$3"
  grep -qF "$pattern" "$file" || fail "$label"
}

assert_not_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -qF "$pattern" "$file"; then
    fail "$label"
  fi
}

runner="$root/scripts/harness-eval-weekly-run.sh"
doc="$root/docs/architecture/harness-eval-suite.md"

[[ -f "$runner" ]] || fail "weekly eval runner exists"
assert_contains "$doc" 'harness-eval-weekly-run.sh' "eval suite doc references weekly runner"
assert_contains "$root/docs/README.md" 'harness-eval-weekly-run.sh' "docs index references weekly runner"
assert_contains "$root/docs/README.md" 'harness-eval-weekly-run-test.sh' "docs index references weekly runner test"

telemetry_dir="$tmpdir/telemetry"
summary_file="$tmpdir/weekly-summary.md"
out="$tmpdir/weekly-run.out"

"$runner" \
  --telemetry-dir "$telemetry_dir" \
  --summary-file "$summary_file" \
  --week 2026-W27 >"$out"

events_file="$telemetry_dir/events.jsonl"
[[ -f "$events_file" ]] || fail "weekly eval run did not create telemetry events"
[[ -f "$summary_file" ]] || fail "weekly eval run did not create summary file"

assert_contains "$out" 'EVAL_WEEKLY_RUN_DECISION=PASS' "weekly run should pass"
assert_contains "$out" 'SUITE_EXIT_CODE=0' "weekly run should report suite exit code"
assert_contains "$events_file" '"event_type":"eval_suite_event"' "weekly run should record eval suite event"
assert_contains "$summary_file" '| harness-eval-suite | 1 | 1 | 0 | PASS_EVAL_SUITE |' "weekly summary should include suite trend"
assert_not_contains "$summary_file" 'source_ref' "weekly summary should not leak source refs"

fail_root="$tmpdir/fail-root"
mkdir -p "$fail_root"
fail_telemetry_dir="$tmpdir/fail-telemetry"
fail_summary_file="$tmpdir/fail-weekly-summary.md"
fail_out="$tmpdir/fail-weekly-run.out"
fail_err="$tmpdir/fail-weekly-run.err"

if "$runner" \
  --suite-root "$fail_root" \
  --telemetry-dir "$fail_telemetry_dir" \
  --summary-file "$fail_summary_file" \
  --week 2026-W27 >"$fail_out" 2>"$fail_err"; then
  fail "weekly eval run should return non-zero when suite fails"
fi

[[ -f "$fail_summary_file" ]] || fail "failed weekly eval run should still create summary file"
assert_contains "$fail_out" 'EVAL_WEEKLY_RUN_DECISION=FAIL' "failed weekly run should report fail decision"
assert_contains "$fail_summary_file" '| harness-eval-suite | 1 | 0 | 1 | FAIL_EVAL_SUITE |' "failed weekly summary should include failed suite trend"

printf 'PASS: harness eval weekly run test passed\n'
