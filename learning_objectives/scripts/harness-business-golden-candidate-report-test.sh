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

expect_not_grep() {
  local pattern="$1" file="$2" label="$3"
  if grep -Eq -- "$pattern" "$file"; then
    fail "$label"
    sed -n '1,160p' "$file" >&2 || true
  else
    pass "$label"
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

report="$root/scripts/harness-business-golden-candidate-report.sh"
doc="$root/docs/architecture/harness-business-golden-eval.md"

[[ -x "$report" ]] || fail "business golden candidate report script exists"
expect_grep 'harness-business-golden-candidate-report.sh' "$doc" "business golden doc references candidate report script"
expect_grep 'harness-business-golden-candidate-report.sh' "$root/docs/README.md" "docs index references candidate report script"
expect_grep 'harness-business-golden-candidate-report-test.sh' "$root/docs/README.md" "docs index references candidate report test"

run_expect_pass "committed candidate report summarizes queue" \
  "$report"

expect_grep '^# Business Golden Candidate Report$' "$out" "report title exists"
expect_grep '^BUSINESS_GOLDEN_CANDIDATE_TOTAL=3$' "$out" "report counts committed candidates"
expect_grep '^BUSINESS_GOLDEN_PROMOTED=3$' "$out" "report counts promoted candidates"
expect_grep '^BUSINESS_GOLDEN_NEEDS_REVIEW=0$' "$out" "report counts needs-review candidates"
expect_grep '\| add-distribution-qr-estimated-reward-amount \| PROMOTED \| SANITIZED \| fullstack \| add-distribution-qr-estimated-reward-amount-pass \| done \|' "$out" "report includes promoted distribution QR row"
expect_not_grep 'source_ref|/''Users/' "$out" "report should not leak source refs or personal paths"

fixture_root="$tmpdir/fixture-root"
mkdir -p "$fixture_root/evals/business-golden/candidates" "$fixture_root/changes/new-source"
cat >"$fixture_root/evals/business-golden/candidates/new-source.env" <<'FIXTURE'
CANDIDATE_ID=new-source
SOURCE_CHANGE_ID=new-source
SOURCE_CHANGE_PATH=changes/new-source
LANE=backend
PROMOTION_STATE=CANDIDATE
REDACTION_STATUS=NEEDS_REVIEW
BUSINESS_REPO_ACCESS=NO
GOLDEN_CASE_ID=
FIXTURE

run_expect_pass "candidate report flags needs-review next action" \
  "$report" --root "$fixture_root"

expect_grep '^BUSINESS_GOLDEN_CANDIDATE_TOTAL=1$' "$out" "fixture report counts one candidate"
expect_grep '^BUSINESS_GOLDEN_NEEDS_REVIEW=1$' "$out" "fixture report counts needs review"
expect_grep '\| new-source \| CANDIDATE \| NEEDS_REVIEW \| backend \| none \| redact_source_change \|' "$out" "fixture report recommends redaction next action"

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: harness business golden candidate report test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness business golden candidate report test passed\n'
