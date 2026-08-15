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

readiness="$root/scripts/harness-eval-trend-readiness.sh"
doc="$root/docs/architecture/harness-eval-suite.md"

[[ -x "$readiness" ]] || fail "eval trend readiness script exists"
assert_contains "$doc" 'harness-eval-trend-readiness.sh' "eval suite doc references trend readiness"
assert_contains "$root/docs/README.md" 'harness-eval-trend-readiness.sh' "docs index references trend readiness"
assert_contains "$root/docs/README.md" 'harness-eval-trend-readiness-test.sh' "docs index references trend readiness test"

telemetry_dir="$tmpdir/telemetry"

record_suite() {
  local timestamp="$1" result="$2" decision="$3" failed="$4"
  "$root/scripts/harness-telemetry-record.sh" \
    --telemetry-dir "$telemetry_dir" \
    --event-type eval_suite_event \
    --change-id harness-replay-eval-foundation \
    --suite-id harness-eval-suite \
    --result "$result" \
    --decision "$decision" \
    --suite-total 12 \
    --suite-passed "$((10 - failed))" \
    --suite-failed "$failed" \
    --business-golden-total 6 \
    --business-golden-matched 6 \
    --business-golden-promoted 3 \
    --replay-fixture-total 8 \
    --replay-fixture-matched 8 \
    --pass-power-k 1 \
    --source-ref changes/harness-replay-eval-foundation/evidence.md \
    --timestamp "$timestamp" >/dev/null
}

record_suite 2026-06-01T00:00:00Z PASS PASS_EVAL_SUITE 0

not_ready="$tmpdir/not-ready.out"
"$readiness" --telemetry-dir "$telemetry_dir" >"$not_ready"
assert_contains "$not_ready" 'TOTAL_SUITE_RUNS=1' "single run should be counted"
assert_contains "$not_ready" 'DISTINCT_SUITE_WEEKS=1' "single week should be counted"
assert_contains "$not_ready" 'CI_TRIAL_READY=0' "single run should not be CI trial ready"
assert_contains "$not_ready" 'GATE_ADJUSTMENT_REVIEW_READY=0' "single run should not be gate review ready"
assert_contains "$not_ready" 'DECISION=WAIT_EVAL_TREND' "not-ready trend decision missing"
assert_not_contains "$not_ready" 'source_ref' "trend readiness leaked source_ref"
printf 'PASS: trend readiness waits for enough suite data\n'

record_suite 2026-06-08T00:00:00Z PASS PASS_EVAL_SUITE 0
record_suite 2026-06-15T00:00:00Z PASS PASS_EVAL_SUITE 0
record_suite 2026-06-22T00:00:00Z PASS PASS_EVAL_SUITE 0

ready="$tmpdir/ready.out"
"$readiness" --telemetry-dir "$telemetry_dir" >"$ready"
assert_contains "$ready" 'TOTAL_SUITE_RUNS=4' "four suite runs should be counted"
assert_contains "$ready" 'DISTINCT_SUITE_WEEKS=4' "four weeks should be counted"
assert_contains "$ready" 'FAILED_SUITE_RUNS=0' "ready window should have zero failures"
assert_contains "$ready" 'LATEST_BUSINESS_GOLDEN_TOTAL=6' "latest business golden total missing"
assert_contains "$ready" 'LATEST_REPLAY_FIXTURE_TOTAL=8' "latest replay total missing"
assert_contains "$ready" 'LATEST_PASS_POWER_K=1' "latest pass power missing"
assert_contains "$ready" 'CI_TRIAL_READY=1' "ready window should allow CI trial proposal"
assert_contains "$ready" 'GATE_ADJUSTMENT_REVIEW_READY=1' "ready window should allow gate adjustment review proposal"
assert_contains "$ready" 'DECISION=READY_FOR_EVAL_ADOPTION_REVIEW' "ready trend decision missing"
printf 'PASS: trend readiness passes with stable four-week suite data\n'

failure_dir="$tmpdir/failure-telemetry"
"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$failure_dir" \
  --event-type eval_suite_event \
  --change-id harness-replay-eval-foundation \
  --suite-id harness-eval-suite \
  --result FAIL \
  --decision FAIL_EVAL_SUITE \
  --suite-total 12 \
  --suite-passed 9 \
  --suite-failed 1 \
  --business-golden-total 6 \
  --business-golden-matched 6 \
  --business-golden-promoted 3 \
  --replay-fixture-total 8 \
  --replay-fixture-matched 8 \
  --pass-power-k 1 \
  --source-ref changes/harness-replay-eval-foundation/evidence.md \
  --timestamp 2026-06-01T00:00:00Z >/dev/null

failed_window="$tmpdir/failed-window.out"
"$readiness" --telemetry-dir "$failure_dir" --min-runs 1 --min-weeks 1 >"$failed_window"
assert_contains "$failed_window" 'FAILED_SUITE_RUNS=1' "failed run should be counted"
assert_contains "$failed_window" 'CI_TRIAL_READY=0' "failed suite window should not be CI trial ready"
assert_contains "$failed_window" 'DECISION=WAIT_EVAL_TREND' "failed suite trend should wait"
printf 'PASS: trend readiness blocks failed suite windows\n'

printf 'PASS: harness eval trend readiness test passed\n'
