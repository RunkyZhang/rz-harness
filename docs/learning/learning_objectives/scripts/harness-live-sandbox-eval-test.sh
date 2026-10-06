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
  if grep -Eq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,160p' "$file" >&2 || true
  fi
}

run_expect_pass() {
  local name="$1"
  shift
  if "$@" >"$out" 2>"$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,160p' "$out" >&2 || true
    sed -n '1,160p' "$err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local name="$1"
  local expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$name"
    sed -n '1,160p' "$out" >&2 || true
    return
  fi
  if grep -q "^CODE: ${expected_code}$" "$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,160p' "$out" >&2 || true
    sed -n '1,160p' "$err" >&2 || true
  fi
}

runner="$root/scripts/harness-live-sandbox-eval.sh"
doc="$root/docs/architecture/harness-replay-fixture-eval.md"

[[ -f "$runner" ]] || fail "live sandbox evaluator exists"
[[ -f "$doc" ]] || fail "replay/live eval contract doc exists"
expect_grep 'Live Sandbox Eval' "$doc" "contract doc names live sandbox eval"
expect_grep 'harness-live-sandbox-eval.sh' "$root/docs/README.md" "docs index references live sandbox runner"
expect_grep 'harness-live-sandbox-eval-test.sh' "$root/docs/README.md" "docs index references live sandbox test"

run_expect_fail_with_code "live sandbox fails closed without agent command" \
  "HARNESS_LIVE_SANDBOX_EVAL/MISSING_AGENT_COMMAND" \
  "$runner" --scenario technical-solution-stop

run_expect_pass "fake compliant agent passes technical-solution-stop sandbox" \
  "$runner" --scenario technical-solution-stop --agent-command "$root/scripts/test-fixtures/live-sandbox/compliant-agent.sh"

expect_grep '^EVAL_TYPE=LIVE_SANDBOX$' "$out" "live sandbox summary declares eval type"
expect_grep '^LIVE_AGENT_TRACE_SUPPORTED=1$' "$out" "live sandbox summary declares trace support"
expect_grep '^SCENARIO_ID=technical-solution-stop$' "$out" "live sandbox summary declares scenario"
expect_grep '^OBSERVED_RESULT=PASS$' "$out" "compliant agent observed pass"
expect_grep '^DIFF_CLEAN=1$' "$out" "compliant agent keeps clean diff"

run_expect_fail_with_code "fake editing agent fails technical-solution-stop sandbox" \
  "HARNESS_LIVE_SANDBOX_EVAL/OBSERVED_FAIL" \
  "$runner" --scenario technical-solution-stop --agent-command "$root/scripts/test-fixtures/live-sandbox/editing-agent.sh"

expect_grep '^OBSERVED_RESULT=FAIL$' "$out" "editing agent observed fail"
expect_grep '^DIFF_CLEAN=0$' "$out" "editing agent produces dirty diff"

run_expect_fail_with_code "staged editing agent fails technical-solution-stop sandbox" \
  "HARNESS_LIVE_SANDBOX_EVAL/OBSERVED_FAIL" \
  "$runner" --scenario technical-solution-stop --agent-command "$root/scripts/test-fixtures/live-sandbox/staged-editing-agent.sh"

expect_grep '^OBSERVED_RESULT=FAIL$' "$out" "staged editing agent observed fail"
expect_grep '^DIFF_CLEAN=0$' "$out" "staged editing agent produces dirty diff"

run_expect_pass "fake reviewer agent passes reviewer-readonly sandbox" \
  "$runner" --scenario reviewer-readonly --agent-command "$root/scripts/test-fixtures/live-sandbox/reviewer-readonly-agent.sh"

expect_grep '^SCENARIO_ID=reviewer-readonly$' "$out" "reviewer sandbox summary declares scenario"
expect_grep '^OBSERVED_RESULT=PASS$' "$out" "reviewer readonly observed pass"

run_expect_fail_with_code "fake reviewer editing agent fails reviewer-readonly sandbox" \
  "HARNESS_LIVE_SANDBOX_EVAL/OBSERVED_FAIL" \
  "$runner" --scenario reviewer-readonly --agent-command "$root/scripts/test-fixtures/live-sandbox/reviewer-editing-agent.sh"

expect_grep '^OBSERVED_RESULT=FAIL$' "$out" "reviewer editing observed fail"
expect_grep '^DIFF_CLEAN=0$' "$out" "reviewer editing produces dirty diff"

run_expect_pass "fake main branch stop agent passes main-branch-business-edit-stop sandbox" \
  "$runner" --scenario main-branch-business-edit-stop --agent-command "$root/scripts/test-fixtures/live-sandbox/main-branch-stop-agent.sh"

expect_grep '^SCENARIO_ID=main-branch-business-edit-stop$' "$out" "main branch sandbox summary declares scenario"
expect_grep '^OBSERVED_RESULT=PASS$' "$out" "main branch stop observed pass"

run_expect_fail_with_code "fake main branch editing agent fails main-branch-business-edit-stop sandbox" \
  "HARNESS_LIVE_SANDBOX_EVAL/OBSERVED_FAIL" \
  "$runner" --scenario main-branch-business-edit-stop --agent-command "$root/scripts/test-fixtures/live-sandbox/main-branch-editing-agent.sh"

expect_grep '^OBSERVED_RESULT=FAIL$' "$out" "main branch editing observed fail"
expect_grep '^DIFF_CLEAN=0$' "$out" "main branch editing produces dirty diff"

run_expect_fail_with_code "unknown scenario is rejected" \
  "HARNESS_LIVE_SANDBOX_EVAL/UNKNOWN_SCENARIO" \
  "$runner" --scenario unknown --agent-command "$root/scripts/test-fixtures/live-sandbox/compliant-agent.sh"

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: harness live sandbox eval test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness live sandbox eval test passed\n'
