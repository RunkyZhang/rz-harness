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

run_expect_pass "control audit default mode is no-fail" \
  "$root/scripts/harness-control-audit.sh"

if grep -q '^REGISTRY_MISSING_GATES=0$' "$out" \
  && grep -q '^CATEGORY registry_coverage ' "$out" \
  && grep -q '^PASS: harness control audit completed' "$out"; then
  pass "control audit prints registry coverage summary"
else
  fail "control audit should print registry coverage summary"
  sed -n '1,80p' "$out" >&2 || true
fi

run_expect_pass "registry check mode exits zero for current registry" \
  "$root/scripts/harness-control-audit.sh" --check registry

if grep -q '^REGISTRY_EXTRA_GATES=0$' "$out"; then
  pass "registry check reports no extra gates"
else
  fail "registry check should report no extra gates"
  sed -n '1,80p' "$out" >&2 || true
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: harness control audit test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness control audit test passed\n'
