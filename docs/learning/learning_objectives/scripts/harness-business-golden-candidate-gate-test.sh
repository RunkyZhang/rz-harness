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

runner="$root/scripts/harness-business-golden-candidate-gate.sh"
doc="$root/docs/architecture/harness-business-golden-eval.md"
candidates="$root/evals/business-golden/candidates"

[[ -f "$runner" ]] || fail "business golden candidate gate exists"
[[ -d "$candidates" ]] || fail "business golden candidate directory exists"
[[ -f "$candidates/add-distribution-qr-estimated-reward-amount.env" ]] || fail "distribution QR candidate exists"
[[ -f "$candidates/download-center-export-integration.env" ]] || fail "download center candidate exists"
[[ -f "$candidates/long-promo-sku-single-pack-unit.env" ]] || fail "long promo candidate exists"
expect_grep 'Candidate Intake' "$doc" "business golden doc describes candidate intake"
expect_grep 'harness-business-golden-candidate-gate.sh' "$root/docs/README.md" "docs index references candidate gate"
expect_grep 'harness-business-golden-candidate-gate-test.sh' "$root/docs/README.md" "docs index references candidate gate test"

run_expect_pass "committed business golden candidates pass intake gate" \
  "$runner"

expect_grep '^EVAL_TYPE=BUSINESS_GOLDEN_CANDIDATE$' "$out" "summary declares candidate eval type"
expect_grep '^BUSINESS_GOLDEN_CANDIDATE_TOTAL=3$' "$out" "summary reports three candidates"
expect_grep '^BUSINESS_GOLDEN_READY=0$' "$out" "summary reports no ready candidates"
expect_grep '^BUSINESS_GOLDEN_PROMOTED=3$' "$out" "summary reports three promoted candidates"
expect_grep 'CANDIDATE add-distribution-qr-estimated-reward-amount STATE=PROMOTED REDACTION=SANITIZED' "$out" "distribution QR candidate is promoted"
expect_grep 'CANDIDATE download-center-export-integration STATE=PROMOTED REDACTION=SANITIZED' "$out" "download center candidate is promoted"
expect_grep 'CANDIDATE long-promo-sku-single-pack-unit STATE=PROMOTED REDACTION=SANITIZED' "$out" "long promo candidate is promoted"
expect_grep 'REDACTION_REVIEW=' "$out" "promoted candidates print redaction review evidence"
if grep -q 'SOURCE=' "$out"; then
  fail "candidate gate output leaked source change path"
else
  pass "candidate gate output hides source change path"
fi

bad_root="$tmpdir/bad-root"
mkdir -p "$bad_root/evals/business-golden/candidates" "$bad_root/changes/existing"
cat >"$bad_root/evals/business-golden/candidates/bad-ready.env" <<'FIXTURE'
CANDIDATE_ID=bad-ready
SOURCE_CHANGE_ID=existing
SOURCE_CHANGE_PATH=changes/existing
LANE=backend
PROMOTION_STATE=READY
REDACTION_STATUS=NEEDS_REVIEW
BUSINESS_REPO_ACCESS=NO
GOLDEN_CASE_ID=bad-ready
FIXTURE

run_expect_fail_with_code "ready candidate must be sanitized" \
  "HARNESS_BUSINESS_GOLDEN_CANDIDATE/READY_NOT_SANITIZED" \
  "$runner" --root "$bad_root"

missing_root="$tmpdir/missing-root"
mkdir -p "$missing_root/evals/business-golden/candidates"
cat >"$missing_root/evals/business-golden/candidates/missing.env" <<'FIXTURE'
CANDIDATE_ID=missing
SOURCE_CHANGE_ID=missing-change
SOURCE_CHANGE_PATH=changes/missing-change
LANE=backend
PROMOTION_STATE=CANDIDATE
REDACTION_STATUS=NEEDS_REVIEW
BUSINESS_REPO_ACCESS=NO
GOLDEN_CASE_ID=
FIXTURE

run_expect_fail_with_code "missing source change is rejected" \
  "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_SOURCE_CHANGE" \
  "$runner" --root "$missing_root"

unsafe_source_root="$tmpdir/unsafe-source-root"
mkdir -p "$unsafe_source_root/evals/business-golden/candidates" "$unsafe_source_root/other"
cat >"$unsafe_source_root/evals/business-golden/candidates/unsafe.env" <<'FIXTURE'
CANDIDATE_ID=unsafe
SOURCE_CHANGE_ID=unsafe
SOURCE_CHANGE_PATH=changes/../other
LANE=backend
PROMOTION_STATE=CANDIDATE
REDACTION_STATUS=NEEDS_REVIEW
BUSINESS_REPO_ACCESS=NO
GOLDEN_CASE_ID=
FIXTURE

run_expect_fail_with_code "unsafe source change traversal is rejected" \
  "HARNESS_BUSINESS_GOLDEN_CANDIDATE/INVALID_SOURCE_CHANGE_PATH" \
  "$runner" --root "$unsafe_source_root"

promoted_root="$tmpdir/promoted-root"
mkdir -p "$promoted_root/evals/business-golden/candidates" "$promoted_root/evals/business-golden/candidates/redaction-reviews" "$promoted_root/changes/promoted"
cat >"$promoted_root/evals/business-golden/candidates/redaction-reviews/promoted.md" <<'FIXTURE'
# Redaction Review
| redaction_status | `SANITIZED` |
| business_repo_access | `NO` |
## Decision
Approved for `PROMOTED` candidate state.
FIXTURE
cat >"$promoted_root/evals/business-golden/candidates/promoted.env" <<'FIXTURE'
CANDIDATE_ID=promoted
SOURCE_CHANGE_ID=promoted
SOURCE_CHANGE_PATH=changes/promoted
LANE=backend
PROMOTION_STATE=PROMOTED
REDACTION_STATUS=SANITIZED
BUSINESS_REPO_ACCESS=NO
GOLDEN_CASE_ID=missing-case
REDACTION_REVIEW_PATH=evals/business-golden/candidates/redaction-reviews/promoted.md
FIXTURE

run_expect_fail_with_code "promoted candidate requires golden case fixture" \
  "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_PROMOTED_CASE" \
  "$runner" --root "$promoted_root"

review_root="$tmpdir/review-root"
mkdir -p "$review_root/evals/business-golden/candidates" "$review_root/evals/business-golden/promoted-case" "$review_root/changes/promoted"
cat >"$review_root/evals/business-golden/promoted-case/metadata.env" <<'FIXTURE'
CASE_ID=promoted-case
CHANGE_ID=bg-promoted-case
EXPECTED_RESULT=PASS
CHANGED_FILES=repo/src/example.java
FIXTURE
cat >"$review_root/evals/business-golden/candidates/promoted.env" <<'FIXTURE'
CANDIDATE_ID=promoted
SOURCE_CHANGE_ID=promoted
SOURCE_CHANGE_PATH=changes/promoted
LANE=backend
PROMOTION_STATE=PROMOTED
REDACTION_STATUS=SANITIZED
BUSINESS_REPO_ACCESS=NO
GOLDEN_CASE_ID=promoted-case
FIXTURE

run_expect_fail_with_code "promoted candidate requires redaction review evidence" \
  "HARNESS_BUSINESS_GOLDEN_CANDIDATE/MISSING_REDACTION_REVIEW_PATH" \
  "$runner" --root "$review_root"

blank_review_root="$tmpdir/blank-review-root"
mkdir -p "$blank_review_root/evals/business-golden/candidates/redaction-reviews" "$blank_review_root/evals/business-golden/promoted-case" "$blank_review_root/changes/promoted"
cat >"$blank_review_root/evals/business-golden/promoted-case/metadata.env" <<'FIXTURE'
CASE_ID=promoted-case
CHANGE_ID=bg-promoted-case
EXPECTED_RESULT=PASS
CHANGED_FILES=repo/src/example.java
FIXTURE
: >"$blank_review_root/evals/business-golden/candidates/redaction-reviews/promoted.md"
cat >"$blank_review_root/evals/business-golden/candidates/promoted.env" <<'FIXTURE'
CANDIDATE_ID=promoted
SOURCE_CHANGE_ID=promoted
SOURCE_CHANGE_PATH=changes/promoted
LANE=backend
PROMOTION_STATE=PROMOTED
REDACTION_STATUS=SANITIZED
BUSINESS_REPO_ACCESS=NO
GOLDEN_CASE_ID=promoted-case
REDACTION_REVIEW_PATH=evals/business-golden/candidates/redaction-reviews/promoted.md
FIXTURE

run_expect_fail_with_code "redaction review evidence must contain required sections" \
  "HARNESS_BUSINESS_GOLDEN_CANDIDATE/INVALID_REDACTION_REVIEW" \
  "$runner" --root "$blank_review_root"

rejected_review_root="$tmpdir/rejected-review-root"
mkdir -p "$rejected_review_root/evals/business-golden/candidates/redaction-reviews" "$rejected_review_root/evals/business-golden/promoted-case" "$rejected_review_root/changes/promoted"
cat >"$rejected_review_root/evals/business-golden/promoted-case/metadata.env" <<'FIXTURE'
CASE_ID=promoted-case
CHANGE_ID=bg-promoted-case
EXPECTED_RESULT=PASS
CHANGED_FILES=repo/src/example.java
FIXTURE
cat >"$rejected_review_root/evals/business-golden/candidates/redaction-reviews/promoted.md" <<'FIXTURE'
# Redaction Review
| redaction_status | `SANITIZED` |
| business_repo_access | `NO` |
## Decision
Rejected for `PROMOTED` candidate state.
FIXTURE
cat >"$rejected_review_root/evals/business-golden/candidates/promoted.env" <<'FIXTURE'
CANDIDATE_ID=promoted
SOURCE_CHANGE_ID=promoted
SOURCE_CHANGE_PATH=changes/promoted
LANE=backend
PROMOTION_STATE=PROMOTED
REDACTION_STATUS=SANITIZED
BUSINESS_REPO_ACCESS=NO
GOLDEN_CASE_ID=promoted-case
REDACTION_REVIEW_PATH=evals/business-golden/candidates/redaction-reviews/promoted.md
FIXTURE

run_expect_fail_with_code "redaction review rejected decision is blocked" \
  "HARNESS_BUSINESS_GOLDEN_CANDIDATE/INVALID_REDACTION_REVIEW" \
  "$runner" --root "$rejected_review_root"

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: harness business golden candidate gate test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness business golden candidate gate test passed\n'
