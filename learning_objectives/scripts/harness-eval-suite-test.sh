#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

failures=0
tmpdir="$(mktemp -d)"
out="$tmpdir/out"
err="$tmpdir/err"
trap 'rm -rf "$tmpdir"' EXIT

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

expect_grep() {
  local pattern="$1" file="$2" label="$3"
  if grep -Eq -- "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,200p' "$file" >&2 || true
  fi
}

run_expect_pass() {
  local name="$1"
  shift
  if "$@" >"$out" 2>"$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,200p' "$out" >&2 || true
    sed -n '1,200p' "$err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local name="$1"
  local expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$name"
    sed -n '1,200p' "$out" >&2 || true
    return
  fi
  if grep -q "^CODE: ${expected_code}$" "$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,200p' "$out" >&2 || true
    sed -n '1,200p' "$err" >&2 || true
  fi
}

runner="$root/scripts/harness-eval-suite.sh"
doc="$root/docs/architecture/harness-eval-suite.md"

[[ -f "$runner" ]] || fail "eval suite runner exists"
[[ -f "$doc" ]] || fail "eval suite contract doc exists"
expect_grep 'Harness Eval Suite' "$doc" "contract doc names eval suite"
expect_grep 'harness-eval-suite.sh' "$root/docs/README.md" "docs index references eval suite runner"
expect_grep 'harness-eval-suite-test.sh' "$root/docs/README.md" "docs index references eval suite test"

run_expect_pass "eval suite default run passes" \
  "$runner"

expect_grep '^EVAL_TYPE=HARNESS_EVAL_SUITE$' "$out" "summary declares eval suite type"
expect_grep '^CHECK business_candidate_intake=PASS$' "$out" "summary includes business candidate intake check"
expect_grep '^CHECK business_candidate_report=PASS$' "$out" "summary includes business candidate report check"
expect_grep '^EVAL_SUITE_TOTAL=12$' "$out" "summary reports twelve suite checks"
expect_grep '^EVAL_SUITE_PASSED=12$' "$out" "summary reports all suite checks passed"
expect_grep '^EVAL_SUITE_FAILED=0$' "$out" "summary reports zero suite failures"
expect_grep '^BUSINESS_GOLDEN_TOTAL=6$' "$out" "summary includes business golden total"
expect_grep '^BUSINESS_GOLDEN_MATCHED=6$' "$out" "summary includes business golden matched"
expect_grep '^BUSINESS_GOLDEN_PROMOTED=3$' "$out" "summary includes promoted candidate count"
expect_grep '^REPLAY_FIXTURE_TOTAL=8$' "$out" "summary includes replay fixture total"
expect_grep '^REPLAY_FIXTURE_MATCHED=8$' "$out" "summary includes replay fixture matched"
expect_grep '^PASS_POWER_K=1$' "$out" "summary includes reliability pass power"
expect_grep '^DECISION=PASS_EVAL_SUITE$' "$out" "summary passes eval suite"

telemetry_dir="$tmpdir/suite-telemetry"
run_expect_pass "eval suite can record aggregate telemetry" \
  "$runner" --record-telemetry --telemetry-dir "$telemetry_dir"
events_file="$telemetry_dir/events.jsonl"
[[ -f "$events_file" ]] || fail "eval suite telemetry file exists"
expect_grep '"event_type":"eval_suite_event"' "$events_file" "eval suite telemetry event type recorded"
expect_grep '"suite_id":"harness-eval-suite"' "$events_file" "eval suite telemetry suite id recorded"
expect_grep '"suite_passed":"12"' "$events_file" "eval suite telemetry pass count recorded"

fail_root="$tmpdir/fail-root"
mkdir -p "$fail_root/scripts" "$fail_root/docs"
cat >"$fail_root/scripts/pass.sh" <<'FIXTURE'
#!/usr/bin/env bash
printf 'PASS: fixture\n'
FIXTURE
cat >"$fail_root/scripts/fail.sh" <<'FIXTURE'
#!/usr/bin/env bash
printf 'FAIL: fixture failed\n' >&2
exit 7
FIXTURE
chmod +x "$fail_root/scripts/pass.sh" "$fail_root/scripts/fail.sh"

run_expect_fail_with_code "eval suite fails closed when a suite command fails" \
  "HARNESS_EVAL_SUITE/CHECK_FAILED" \
  "$runner" --root "$fail_root" --check smoke:scripts/pass.sh --check broken:scripts/fail.sh

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: harness eval suite test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness eval suite test passed\n'
