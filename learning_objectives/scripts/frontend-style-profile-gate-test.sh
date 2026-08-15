#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0
out="$tmp_dir/out"
err="$tmp_dir/err"

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

run_expect_pass() {
  local label="$1"
  shift
  if "$@" >"$out" 2>"$err"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,80p' "$out" >&2 || true
    sed -n '1,80p' "$err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local label="$1" expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$label"
    sed -n '1,80p' "$out" >&2 || true
    return
  fi
  if grep -q "^CODE: ${expected_code}$" "$err"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,80p' "$out" >&2 || true
    sed -n '1,80p' "$err" >&2 || true
  fi
}

if [[ -f "$root/templates/frontend-style-profile.md" ]] \
  && grep -q 'style_profile_status' "$root/templates/frontend-style-profile.md" \
  && grep -q 'Positive Samples' "$root/templates/frontend-style-profile.md"; then
  pass "frontend style profile template exists"
else
  fail "frontend style profile template exists"
fi

if grep -q 'style_sample_references_status' "$root/templates/plan-tier-m.md" \
  && grep -q '样板引用' "$root/templates/plan-tier-m.md"; then
  pass "plan template requires frontend sample references"
else
  fail "plan template requires frontend sample references"
fi

if grep -q '^style_conformance:' "$root/templates/review.md"; then
  pass "review template includes style_conformance verdict"
else
  fail "review template includes style_conformance verdict"
fi

review_change="$tmp_dir/review-change"
mkdir -p "$review_change"
cat >"$review_change/review.md" <<'SPEC'
# Reviewer Agent Review

review_status: PASS
reviewer_independence: READ_ONLY
technical_solution_alignment: PASS
harness_constraints: PASS
architecture_drift: PASS
comment_log_quality: PASS
maintainability_readability: PASS
test_evidence: PASS
style_conformance: N/A
high_risk_count: 0
medium_risk_status: RECORDED

## Reviewed Inputs

- changes/demo/spec.md
- changes/demo/technical-solution.md
- changes/demo/evidence.md
- git diff

## HIGH
- 无

## MEDIUM
- 无

## LOW
- 无

## 结论
- 建议进入人工 review。
SPEC
run_expect_pass "reviewer gate accepts explicit non-ui style N/A" \
  "$root/scripts/reviewer-gate.sh" "$review_change"

missing_style_change="$tmp_dir/missing-style-review-change"
mkdir -p "$missing_style_change"
awk '$0 !~ /^style_conformance:/' "$review_change/review.md" >"$missing_style_change/review.md"
run_expect_fail_with_code "reviewer gate blocks missing style_conformance verdict" \
  "REVIEWER_GATE/CHECK_INVALID" \
  "$root/scripts/reviewer-gate.sh" "$missing_style_change"

if grep -q 'templates/frontend-style-profile.md' "$root/docs/README.md" \
  && grep -q 'style_conformance' "$root/docs/README.md"; then
  pass "docs index lists frontend style profile and style_conformance"
else
  fail "docs index lists frontend style profile and style_conformance"
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: frontend style profile gate test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: frontend style profile gate test passed\n'
