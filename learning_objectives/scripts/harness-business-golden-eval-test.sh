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

runner="$root/scripts/harness-business-golden-eval.sh"
doc="$root/docs/architecture/harness-business-golden-eval.md"
cases_root="$root/evals/business-golden"

[[ -f "$runner" ]] || fail "business golden suite runner exists"
[[ -f "$doc" ]] || fail "business golden contract doc exists"
expect_grep 'Business Golden Eval' "$doc" "contract doc names business golden eval"
expect_grep 'harness-business-golden-eval.sh' "$root/docs/README.md" "docs index references business golden runner"
expect_grep 'harness-business-golden-eval-test.sh' "$root/docs/README.md" "docs index references business golden test"

[[ -d "$cases_root/fullstack-crud-pass" ]] || fail "fullstack-crud-pass case exists"
[[ -d "$cases_root/missing-smoke-report-fail" ]] || fail "missing-smoke-report-fail case exists"
[[ -d "$cases_root/allowed-path-violation-fail" ]] || fail "allowed-path-violation-fail case exists"
[[ -d "$cases_root/long-promo-sku-single-pack-unit-pass" ]] || fail "long promo historical pass case exists"
[[ -d "$cases_root/download-center-export-integration-pass" ]] || fail "download center historical pass case exists"
[[ -d "$cases_root/add-distribution-qr-estimated-reward-amount-pass" ]] || fail "distribution QR estimated reward historical pass case exists"

run_expect_pass "business golden suite matches all committed cases" \
  "$runner"

expect_grep '^EVAL_TYPE=BUSINESS_GOLDEN$' "$out" "summary declares business golden eval type"
expect_grep '^BUSINESS_GOLDEN_TOTAL=6$' "$out" "summary reports six business cases"
expect_grep '^BUSINESS_GOLDEN_MATCHED=6$' "$out" "summary reports all business cases matched"
expect_grep 'CASE fullstack-crud-pass EXPECTED=PASS OBSERVED=PASS' "$out" "fullstack pass case matches"
expect_grep 'CASE missing-smoke-report-fail EXPECTED=FAIL OBSERVED=FAIL' "$out" "missing smoke report fail case matches"
expect_grep 'CASE allowed-path-violation-fail EXPECTED=FAIL OBSERVED=FAIL' "$out" "allowed path violation fail case matches"
expect_grep 'CASE long-promo-sku-single-pack-unit-pass EXPECTED=PASS OBSERVED=PASS' "$out" "long promo historical pass case matches"
expect_grep 'CASE download-center-export-integration-pass EXPECTED=PASS OBSERVED=PASS' "$out" "download center historical pass case matches"
expect_grep 'CASE add-distribution-qr-estimated-reward-amount-pass EXPECTED=PASS OBSERVED=PASS' "$out" "distribution QR estimated reward historical pass case matches"

bad_root="$tmpdir/bad-root"
mkdir -p "$bad_root/evals/business-golden/bad-case"
cat >"$bad_root/evals/business-golden/bad-case/metadata.env" <<'FIXTURE'
CASE_ID=bad-case
CHANGE_ID=bad-change
EXPECTED_RESULT=PASS
CHANGED_FILES=repo/src/example.java
FIXTURE

run_expect_fail_with_code "unexpected business golden result fails closed" \
  "HARNESS_BUSINESS_GOLDEN_EVAL/UNEXPECTED_RESULT" \
  "$runner" --root "$bad_root"

missing="$tmpdir/missing-root"
mkdir -p "$missing/evals/business-golden/missing-metadata"

run_expect_fail_with_code "missing business golden metadata fails closed" \
  "HARNESS_BUSINESS_GOLDEN_EVAL/MISSING_METADATA" \
  "$runner" --root "$missing"

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: harness business golden eval test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness business golden eval test passed\n'
