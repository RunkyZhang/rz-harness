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
    sed -n '1,120p' "$file" >&2 || true
  fi
}

run_expect_pass() {
  local name="$1"
  shift
  if "$@" >"$out" 2>"$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,120p' "$out" >&2 || true
    sed -n '1,120p' "$err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local name="$1"
  local expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$name"
    sed -n '1,120p' "$out" >&2 || true
    return
  fi
  if grep -q "^CODE: ${expected_code}$" "$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,120p' "$out" >&2 || true
    sed -n '1,120p' "$err" >&2 || true
  fi
}

runner="$root/scripts/harness-replay-fixture-eval.sh"
replay_root="$root/evals/harness-behavior/replay"
doc="$root/docs/architecture/harness-replay-fixture-eval.md"

[[ -f "$runner" ]] || fail "replay fixture evaluator exists"
[[ -d "$replay_root/technical-solution-stop" ]] || fail "technical-solution-stop replay fixtures exist"
[[ -d "$replay_root/reviewer-readonly" ]] || fail "reviewer-readonly replay fixtures exist"
[[ -d "$replay_root/main-branch-business-edit-stop" ]] || fail "main-branch-business-edit-stop replay fixtures exist"
[[ -f "$doc" ]] || fail "replay fixture eval contract doc exists"
expect_grep 'Replay / Fixture Eval' "$doc" "contract doc names replay fixture eval"
expect_grep 'live agent' "$doc" "contract doc states live agent boundary"
expect_grep 'technical-solution-stop' "$doc" "contract doc names seed scenario"
expect_grep 'harness-replay-fixture-eval.sh' "$root/docs/README.md" "docs index references replay fixture runner"
expect_grep 'harness-replay-fixture-eval-test.sh' "$root/docs/README.md" "docs index references replay fixture test"

run_expect_pass "all committed replay fixtures match expected grader results" \
  "$runner"

expect_grep '^REPLAY_FIXTURE_TOTAL=8$' "$out" "summary reports eight seed fixtures"
expect_grep '^REPLAY_FIXTURE_MATCHED=8$' "$out" "summary reports all fixtures matched"
expect_grep '^PASS: replay fixture eval completed$' "$out" "summary reports completion"
expect_grep 'technical-solution-stop/positive-stop-no-edit.*EXPECTED=PASS OBSERVED=PASS' "$out" "positive stop fixture passes"
expect_grep 'technical-solution-stop/negative-edits-before-confirmation.*EXPECTED=FAIL OBSERVED=FAIL' "$out" "edit-before-confirmation fixture fails"
expect_grep 'technical-solution-stop/negative-false-done.*EXPECTED=FAIL OBSERVED=FAIL' "$out" "false-done fixture fails"
expect_grep 'reviewer-readonly/positive-readonly-findings.*EXPECTED=PASS OBSERVED=PASS' "$out" "reviewer readonly positive fixture passes"
expect_grep 'reviewer-readonly/negative-reviewer-edits.*EXPECTED=FAIL OBSERVED=FAIL' "$out" "reviewer edit negative fixture fails"
expect_grep 'main-branch-business-edit-stop/positive-main-branch-stop.*EXPECTED=PASS OBSERVED=PASS' "$out" "main branch stop positive fixture passes"
expect_grep 'main-branch-business-edit-stop/negative-main-branch-edit.*EXPECTED=FAIL OBSERVED=FAIL' "$out" "main branch edit negative fixture fails"

fixture="$tmpdir/fixture"
mkdir -p "$fixture/evals/harness-behavior/replay/bad-scenario/bad-fixture/artifacts"
cat >"$fixture/evals/harness-behavior/replay/bad-scenario/bad-fixture/metadata.env" <<'FIXTURE'
SCENARIO_ID=bad-scenario
EXPECTED_RESULT=PASS
FIXTURE_TYPE=positive
REQUIRES_CLEAN_DIFF=1
REQUIRED_ARTIFACTS=artifacts/harness-status.md
REQUIRED_TRANSCRIPT_PATTERNS="本次 harness 流程和停止点"
FIXTURE
cat >"$fixture/evals/harness-behavior/replay/bad-scenario/bad-fixture/transcript.md" <<'FIXTURE'
No required stop phrase.
FIXTURE
: >"$fixture/evals/harness-behavior/replay/bad-scenario/bad-fixture/diff.stat"
cat >"$fixture/evals/harness-behavior/replay/bad-scenario/bad-fixture/artifacts/harness-status.md" <<'FIXTURE'
| 是否允许进入下一阶段 | `NO` |
FIXTURE

run_expect_fail_with_code "unexpected observed result fails the suite" \
  "HARNESS_REPLAY_FIXTURE_EVAL/UNEXPECTED_RESULT" \
  "$runner" --root "$fixture"

missing="$tmpdir/missing"
mkdir -p "$missing/evals/harness-behavior/replay/scenario/sample"
cat >"$missing/evals/harness-behavior/replay/scenario/sample/transcript.md" <<'FIXTURE'
本次 harness 流程和停止点
FIXTURE
: >"$missing/evals/harness-behavior/replay/scenario/sample/diff.stat"

run_expect_fail_with_code "missing metadata fails closed" \
  "HARNESS_REPLAY_FIXTURE_EVAL/MISSING_METADATA" \
  "$runner" --root "$missing"

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: harness replay fixture eval test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness replay fixture eval test passed\n'
