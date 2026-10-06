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
  fi
}

run_expect_pass() {
  local name="$1"
  shift
  if "$@" >"$out" 2>"$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,80p' "$out" >&2 || true
    sed -n '1,80p' "$err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local name="$1"
  local expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$name"
    sed -n '1,80p' "$out" >&2 || true
    return
  fi
  if grep -q "^CODE: ${expected_code}$" "$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,80p' "$out" >&2 || true
    sed -n '1,80p' "$err" >&2 || true
  fi
}

doc="$root/docs/architecture/harness-eval-reliability.md"
runner="$root/scripts/harness-behavior-reliability.sh"

if [[ -f "$doc" ]]; then
  pass "eval reliability doc exists"
  expect_grep 'pass@k' "$doc" "doc defines pass@k"
  expect_grep 'pass\^k' "$doc" "doc defines pass^k"
  expect_grep 'safety' "$doc" "doc defines safety mode"
  expect_grep 'exploratory' "$doc" "doc defines exploratory mode"
else
  fail "eval reliability doc exists"
fi

if [[ -x "$runner" || -f "$runner" ]]; then
  pass "behavior reliability runner exists"
else
  fail "behavior reliability runner exists"
fi

expect_grep 'harness-eval-reliability.md' "$root/docs/README.md" "docs index references eval reliability doc"
expect_grep 'harness-behavior-reliability.sh' "$root/docs/README.md" "docs index references behavior reliability runner"
expect_grep 'harness-behavior-reliability-test.sh' "$root/docs/README.md" "docs index references behavior reliability test"

always_pass="$tmpdir/always-pass.sh"
always_fail="$tmpdir/always-fail.sh"
flaky="$tmpdir/flaky.sh"
flaky_state="$tmpdir/flaky-state"

cat >"$always_pass" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT

cat >"$always_fail" <<'SCRIPT'
#!/usr/bin/env bash
exit 1
SCRIPT

cat >"$flaky" <<SCRIPT
#!/usr/bin/env bash
state="$flaky_state"
count="\$(cat "\$state" 2>/dev/null || printf '0')"
count=\$((count + 1))
printf '%s' "\$count" >"\$state"
if [[ "\$count" -eq 1 ]]; then
  exit 1
fi
exit 0
SCRIPT

chmod +x "$always_pass" "$always_fail" "$flaky"

if [[ -f "$runner" ]]; then
  run_expect_pass "safety mode passes when all runs pass" \
    "$runner" --runs 3 --mode safety --eval-command "bash '$always_pass'"

  if grep -q '^PASS_AT_K=1$' "$out" \
    && grep -q '^PASS_POWER_K=1$' "$out" \
    && grep -q '^HARNESS_BEHAVIOR_RELIABILITY_SUCCESSES=3$' "$out"; then
    pass "all-pass summary reports pass@k and pass^k"
  else
    fail "all-pass summary should report pass@k=1 and pass^k=1"
    sed -n '1,80p' "$out" >&2 || true
  fi

  rm -f "$flaky_state"
  run_expect_fail_with_code "safety mode rejects partial success" \
    "HARNESS_BEHAVIOR_RELIABILITY/SAFETY_NOT_STABLE" \
    "$runner" --runs 3 --mode safety --eval-command "bash '$flaky'"

  if grep -q '^PASS_AT_K=1$' "$out" \
    && grep -q '^PASS_POWER_K=0$' "$out"; then
    pass "safety partial-success output keeps both metrics visible"
  else
    fail "safety partial-success output should expose pass@k=1 and pass^k=0"
    sed -n '1,80p' "$out" >&2 || true
  fi

  rm -f "$flaky_state"
  run_expect_pass "exploratory mode allows at-least-one success" \
    "$runner" --runs 3 --mode exploratory --eval-command "bash '$flaky'"

  if grep -q '^PASS_AT_K=1$' "$out" \
    && grep -q '^PASS_POWER_K=0$' "$out" \
    && grep -q '^DECISION=PASS_EXPLORATORY_UNSTABLE$' "$out"; then
    pass "exploratory partial-success output reports instability"
  else
    fail "exploratory partial-success output should report unstable pass"
    sed -n '1,80p' "$out" >&2 || true
  fi

  run_expect_fail_with_code "all failed runs are rejected" \
    "HARNESS_BEHAVIOR_RELIABILITY/NO_PASSING_RUNS" \
    "$runner" --runs 2 --mode exploratory --eval-command "bash '$always_fail'"

  if grep -q '^PASS_AT_K=0$' "$out" \
    && grep -q '^PASS_POWER_K=0$' "$out"; then
    pass "all-fail output reports both metrics as zero"
  else
    fail "all-fail output should report pass@k=0 and pass^k=0"
    sed -n '1,80p' "$out" >&2 || true
  fi

  run_expect_fail_with_code "invalid runs value is rejected" \
    "HARNESS_BEHAVIOR_RELIABILITY/INVALID_RUNS" \
    "$runner" --runs 0 --mode safety --eval-command "bash '$always_pass'"

  run_expect_pass "current behavior eval declares static eval type" \
    scripts/harness-behavior-eval.sh

  if grep -q '^EVAL_TYPE=STATIC$' "$out" \
    && grep -q '^LIVE_AGENT_TRACE_SUPPORTED=0$' "$out"; then
    pass "static behavior eval output cannot be mistaken for live agent trace"
  else
    fail "static behavior eval output should declare EVAL_TYPE=STATIC and LIVE_AGENT_TRACE_SUPPORTED=0"
    sed -n '1,80p' "$out" >&2 || true
  fi

  run_expect_pass "current behavior eval works through reliability runner" \
    "$runner" --runs 2 --mode safety --eval-command "$root/scripts/harness-behavior-eval.sh"
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: harness behavior reliability test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness behavior reliability test passed\n'
