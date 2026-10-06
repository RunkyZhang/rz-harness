#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
gate="$root/scripts/agent-output-contract-gate.sh"
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
    sed -n '1,120p' "$out" >&2 || true
    sed -n '1,120p' "$err" >&2 || true
  fi
}

run_expect_fail() {
  local label="$1" expected="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$label"
    sed -n '1,120p' "$out" >&2 || true
    return
  fi
  if grep -q "$expected" "$err"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,120p' "$out" >&2 || true
    sed -n '1,120p' "$err" >&2 || true
  fi
}

review_change="$tmp_dir/review-change"
mkdir -p "$review_change"
cat >"$review_change/review.md" <<'MARKDOWN'
# Review：demo-change

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

- changes/demo-change/spec.md
- changes/demo-change/technical-solution.md
- changes/demo-change/evidence.md
- git diff

## HIGH

- none.

## MEDIUM

- none.

## LOW

- none.

## 结论

- 建议进入人工 review。
MARKDOWN

run_expect_pass "reviewer output contract delegates to reviewer gate" \
  "$gate" "$review_change" sfa-harness-reviewer

missing_review="$tmp_dir/missing-review"
mkdir -p "$missing_review"
run_expect_fail "missing declared reviewer artifact is blocked" "missing output artifact" \
  "$gate" "$missing_review" sfa-harness-reviewer

test_change="$tmp_dir/test-change"
mkdir -p "$test_change"
cat >"$test_change/test-agent-verification.md" <<'MARKDOWN'
# 测试 Agent 独立验收：demo-change

verification_status: GOAL_ACHIEVED
final_decision: GOAL_ACHIEVED

| Issue ID | Severity | Source Case | Expected | Actual | Evidence | Returned to Main Agent | Retest Result | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TAV-001 | P3 | TC-001 | ok | ok | evidence.md | yes | PASS | FIXED |

## 结论

- Goal achieved with evidence.
MARKDOWN
cat >"$test_change/ai-test-report.md" <<'MARKDOWN'
# AI Test Report

Test Agent verification: changes/demo-change/test-agent-verification.md
MARKDOWN

run_expect_pass "test agent output contract delegates to test verification gate" \
  "$gate" "$test_change" sfa-test-agent

blocked_test_change="$tmp_dir/blocked-test-change"
mkdir -p "$blocked_test_change"
cat >"$blocked_test_change/test-agent-verification.md" <<'MARKDOWN'
# 测试 Agent 独立验收：demo-change

verification_status: BLOCKED
final_decision: BLOCKED

| Issue ID | Severity | Source Case | Expected | Actual | Evidence | Returned to Main Agent | Retest Result | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |

## BLOCKED 说明

| Blocker | Tried | Minimum required input / environment | Owner |
| --- | --- | --- | --- |
| SIT account unavailable | Checked local config and browser session | Test account from user | user |
MARKDOWN
cat >"$blocked_test_change/ai-test-report.md" <<'MARKDOWN'
# AI Test Report

Test Agent verification: changes/demo-change/test-agent-verification.md
MARKDOWN

run_expect_pass "test agent output contract allows explicit blocked handoff" \
  "$gate" "$blocked_test_change" sfa-test-agent

bad_test_change="$tmp_dir/bad-test-change"
mkdir -p "$bad_test_change"
cat >"$bad_test_change/test-agent-verification.md" <<'MARKDOWN'
# Test Agent Verification

verification_status: PENDING
final_decision: PENDING
MARKDOWN
cat >"$bad_test_change/ai-test-report.md" <<'MARKDOWN'
# AI Test Report
MARKDOWN

run_expect_fail "pending test agent output is blocked" "must be GOAL_ACHIEVED or BLOCKED" \
  "$gate" "$bad_test_change" sfa-test-agent

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: agent output contract gate test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: agent output contract gate test passed\n'
