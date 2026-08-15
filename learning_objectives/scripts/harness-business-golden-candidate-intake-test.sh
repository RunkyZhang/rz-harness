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

runner="$root/scripts/harness-business-golden-candidate-intake.sh"
gate="$root/scripts/harness-business-golden-candidate-gate.sh"
doc="$root/docs/architecture/harness-business-golden-eval.md"

[[ -x "$runner" ]] || fail "business golden candidate intake script exists"
expect_grep 'harness-business-golden-candidate-intake.sh' "$doc" "business golden doc references candidate intake script"
expect_grep 'harness-business-golden-candidate-intake.sh' "$root/docs/README.md" "docs index references candidate intake script"
expect_grep 'harness-business-golden-candidate-intake-test.sh' "$root/docs/README.md" "docs index references candidate intake test"

fixture_root="$tmpdir/fixture-root"
mkdir -p "$fixture_root/changes/source-change" "$fixture_root/evals/business-golden/candidates"
printf '# Evidence\n' >"$fixture_root/changes/source-change/evidence.md"

run_expect_pass "candidate intake creates safe candidate metadata" \
  "$runner" \
  --root "$fixture_root" \
  --candidate-id source-change \
  --source-change-id source-change \
  --source-change-path changes/source-change \
  --lane backend

candidate_file="$fixture_root/evals/business-golden/candidates/source-change.env"
[[ -f "$candidate_file" ]] || fail "candidate metadata file created"
expect_grep '^CANDIDATE_ID=source-change$' "$candidate_file" "candidate id recorded"
expect_grep '^SOURCE_CHANGE_PATH=changes/source-change$' "$candidate_file" "source change path recorded"
expect_grep '^LANE=backend$' "$candidate_file" "lane recorded"
expect_grep '^PROMOTION_STATE=CANDIDATE$' "$candidate_file" "new candidate starts as candidate"
expect_grep '^REDACTION_STATUS=NEEDS_REVIEW$' "$candidate_file" "new candidate starts as needs review"
expect_grep '^BUSINESS_REPO_ACCESS=NO$' "$candidate_file" "new candidate does not assume business repo access"
expect_grep '^GOLDEN_CASE_ID=$' "$candidate_file" "new candidate has no golden case id"
expect_grep '^REDACTION_REVIEW_PATH=$' "$candidate_file" "new candidate has no redaction review path"

run_expect_pass "candidate gate accepts newly intaked candidate" \
  "$gate" --root "$fixture_root"

run_expect_fail_with_code "candidate intake rejects absolute source paths" \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/ABSOLUTE_SOURCE_PATH" \
  "$runner" \
  --root "$fixture_root" \
  --candidate-id absolute-path \
  --source-change-id source-change \
  --source-change-path /tmp/source-change \
  --lane backend

run_expect_fail_with_code "candidate intake rejects missing source changes" \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/MISSING_SOURCE_CHANGE" \
  "$runner" \
  --root "$fixture_root" \
  --candidate-id missing-source \
  --source-change-id missing-source \
  --source-change-path changes/missing-source \
  --lane backend

run_expect_fail_with_code "candidate intake rejects duplicate candidate files" \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/CANDIDATE_EXISTS" \
  "$runner" \
  --root "$fixture_root" \
  --candidate-id source-change \
  --source-change-id source-change \
  --source-change-path changes/source-change \
  --lane backend

run_expect_fail_with_code "candidate intake rejects invalid lanes" \
  "HARNESS_BUSINESS_GOLDEN_INTAKE/INVALID_LANE" \
  "$runner" \
  --root "$fixture_root" \
  --candidate-id invalid-lane \
  --source-change-id source-change \
  --source-change-path changes/source-change \
  --lane mystery

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: harness business golden candidate intake test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness business golden candidate intake test passed\n'
