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

expect_file() {
  local path="$1" label="$2"
  if [[ -f "$path" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

docs_spec="$root/docs/architecture/change-artifacts-spec.md"
if [[ -f "$docs_spec" ]]; then
  pass "change artifact matrix doc exists"
else
  fail "change artifact matrix doc exists"
fi

if [[ -f "$docs_spec" ]] \
  && grep -q 'tier-s' "$docs_spec" \
  && grep -q 'tier-m' "$docs_spec" \
  && grep -q 'tier-l' "$docs_spec"; then
  pass "change artifact matrix documents all tiers"
else
  fail "change artifact matrix documents all tiers"
fi

changes_dir="$tmp_dir/changes"

run_expect_pass "tier-s scaffold creates minimal change" \
  "$root/scripts/change-scaffold.sh" --tier S --changes-dir "$changes_dir" sample-s

sample_s="$changes_dir/sample-s"
expect_file "$sample_s/spec.md" "tier-s scaffold creates spec"
expect_file "$sample_s/harness-status.md" "tier-s scaffold creates status"
expect_file "$sample_s/evidence.md" "tier-s scaffold creates evidence"

if grep -q '^artifact_profile: tier-s$' "$sample_s/harness-status.md"; then
  pass "tier-s scaffold records artifact profile"
else
  fail "tier-s scaffold records artifact profile"
fi

run_expect_pass "tier-s artifact gate passes scaffold output" \
  "$root/scripts/change-artifacts-gate.sh" "$sample_s"

run_expect_pass "tier-m scaffold creates plan and verification artifacts" \
  "$root/scripts/change-scaffold.sh" --tier M --changes-dir "$changes_dir" sample-m

sample_m="$changes_dir/sample-m"
expect_file "$sample_m/plan.md" "tier-m scaffold creates plan"
expect_file "$sample_m/contract.md" "tier-m scaffold creates contract"
expect_file "$sample_m/technical-solution.md" "tier-m scaffold creates technical solution"
expect_file "$sample_m/verification-map.md" "tier-m scaffold creates verification map"
expect_file "$sample_m/ai-test-plan.md" "tier-m scaffold creates ai test plan"
expect_file "$sample_m/agent-dispatch-plan.md" "tier-m scaffold creates agent dispatch plan"
run_expect_pass "tier-m scaffolded agent dispatch plan passes gate" \
  "$root/scripts/agent-dispatch-plan-gate.sh" "$sample_m"
printf '# Agent Candidate Confirmation\n' >"$sample_m/agent-candidate-confirmation.md"
run_expect_pass "tier-m artifact gate accepts optional candidate confirmation" \
  "$root/scripts/change-artifacts-gate.sh" "$sample_m"
run_expect_pass "tier-m artifact gate passes scaffold output" \
  "$root/scripts/change-artifacts-gate.sh" "$sample_m"

run_expect_pass "tier-l scaffold creates environment and report artifacts" \
  "$root/scripts/change-scaffold.sh" --tier L --changes-dir "$changes_dir" sample-l

sample_l="$changes_dir/sample-l"
expect_file "$sample_l/environment-readiness.md" "tier-l scaffold creates environment readiness"
expect_file "$sample_l/ai-test-report.md" "tier-l scaffold creates ai test report"
expect_file "$sample_l/decisions.md" "tier-l scaffold creates decisions"
expect_file "$sample_l/agent-dispatch-plan.md" "tier-l scaffold creates agent dispatch plan"
run_expect_pass "tier-l artifact gate passes scaffold output" \
  "$root/scripts/change-artifacts-gate.sh" "$sample_l"

missing_profile="$tmp_dir/missing-profile-change"
mkdir -p "$missing_profile"
printf '# spec\n' >"$missing_profile/spec.md"
printf '# evidence\n' >"$missing_profile/evidence.md"
run_expect_fail_with_code "new change without artifact profile is blocked" \
  "CHANGE_ARTIFACTS/MISSING_PROFILE" \
  "$root/scripts/change-artifacts-gate.sh" "$missing_profile"

printf '# surprise\n' >"$sample_s/unplanned-note.md"
run_expect_fail_with_code "new change with unknown root artifact is blocked" \
  "CHANGE_ARTIFACTS/UNKNOWN_ROOT_FILE" \
  "$root/scripts/change-artifacts-gate.sh" "$sample_s"

historical="$tmp_dir/historical-change"
mkdir -p "$historical"
printf '# spec\n' >"$historical/spec.md"
printf '# old note\n' >"$historical/random-old-note.md"
run_expect_pass "historical change without profile warns but passes" \
  "$root/scripts/change-artifacts-gate.sh" --historical "$historical"
if grep -q '^WARN: historical change has no artifact_profile' "$err" \
  && grep -q '^WARN: historical change has unknown root artifact' "$err"; then
  pass "historical artifact gate prints migration warnings"
else
  fail "historical artifact gate prints migration warnings"
  sed -n '1,80p' "$err" >&2 || true
fi

if grep -q 'change-artifacts-spec.md' "$root/docs/README.md" \
  && grep -q 'scripts/change-scaffold.sh' "$root/docs/README.md" \
  && grep -q 'scripts/change-artifacts-gate.sh' "$root/docs/README.md"; then
  pass "docs index lists change artifact matrix and scripts"
else
  fail "docs index lists change artifact matrix and scripts"
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: change artifacts gate test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: change artifacts gate test passed\n'
