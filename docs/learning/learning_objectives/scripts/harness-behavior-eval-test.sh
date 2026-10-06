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

run_expect_pass() {
  local name="$1"
  shift
  if "$@" >"$out" 2>"$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,40p' "$out" >&2 || true
    sed -n '1,40p' "$err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local name="$1"
  local expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$name"
    sed -n '1,40p' "$out" >&2 || true
    return
  fi
  if grep -q "^CODE: ${expected_code}$" "$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,40p' "$out" >&2 || true
    sed -n '1,40p' "$err" >&2 || true
  fi
}

run_expect_pass "behavior eval passes required scenarios" \
  "$root/scripts/harness-behavior-eval.sh"

if grep -q '^BEHAVIOR_EVAL_TOTAL=5$' "$out" \
  && grep -q '^PASS: behavior eval scenario technical-solution-stop' "$out" \
  && grep -q '^PASS: harness behavior eval completed' "$out"; then
  pass "behavior eval prints required scenario summary"
else
  fail "behavior eval should print required scenario summary"
  sed -n '1,80p' "$out" >&2 || true
fi

fixture="$tmpdir/fixture"
mkdir -p "$fixture/evals"
cp -R "$root/evals/harness-behavior" "$fixture/evals/"
rm -f "$fixture/evals/harness-behavior/expected/reviewer-readonly.yaml"

run_expect_fail_with_code "behavior eval fails when expected file is missing" \
  "HARNESS_BEHAVIOR_EVAL/MISSING_EXPECTED" \
  "$root/scripts/harness-behavior-eval.sh" --root "$fixture"

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: harness behavior eval test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness behavior eval test passed\n'
