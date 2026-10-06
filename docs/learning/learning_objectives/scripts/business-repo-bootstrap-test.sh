#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

expect_file() {
  local path="$1" label="$2"
  if [[ -f "$path" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

run_expect_pass() {
  local label="$1"
  shift
  if "$@" >"$tmp_dir/out" 2>"$tmp_dir/err"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,30p' "$tmp_dir/err" >&2 || true
  fi
}

repo="$tmp_dir/mapSystem"
mkdir -p "$repo"
git -C "$repo" init -q

run_expect_pass "business repo bootstrap installs local harness files" \
  env SFA_REPO_FRONTEND_MAP_SYSTEM="$repo" "$root/scripts/business-repo-bootstrap.sh" "$repo" sample-change

expect_file "$repo/AGENTS.md" "business AGENTS stub exists"
expect_file "$repo/.cursor/hooks.json" "business Cursor hooks exist"
expect_file "$repo/.codex/hooks.json" "business Codex hooks exist"
expect_file "$repo/.harness/active-change" "business active-change exists"
expect_file "$repo/.harness/bootstrap-status.env" "business bootstrap status exists"

if grep -q 'sfa-ai-harness business repo bootstrap' "$repo/AGENTS.md" \
  && grep -q 'SFA_HARNESS_ROOT' "$repo/AGENTS.md" \
  && grep -q 'Repo ID: frontend-map-system' "$repo/AGENTS.md" \
  && grep -q 'sfa-frontend-agent' "$repo/AGENTS.md" \
  && grep -q 'rules/frontend-vue2.mdc' "$repo/AGENTS.md"; then
  pass "business AGENTS stub has harness marker"
else
  fail "business AGENTS stub has harness marker"
fi

if grep -q 'REPO_ID=frontend-map-system' "$repo/.harness/bootstrap-status.env" \
  && grep -q 'REPO_TYPE=frontend' "$repo/.harness/bootstrap-status.env" \
  && grep -q 'RULE_ENTRYPOINT=rules/frontend-vue2.mdc' "$repo/.harness/bootstrap-status.env"; then
  pass "business bootstrap status records repo metadata"
else
  fail "business bootstrap status records repo metadata"
fi

if grep -q 'harness-sensor-runner.sh' "$repo/.cursor/hooks.json" \
  && grep -q 'harness-sensor-runner.sh' "$repo/.codex/hooks.json"; then
  pass "business hooks call harness sensor runner"
else
  fail "business hooks call harness sensor runner"
fi

if [[ "$(cat "$repo/.harness/active-change")" == "sample-change" ]]; then
  pass "business active-change contains change id"
else
  fail "business active-change contains change id"
fi

if git -C "$repo" check-ignore -q AGENTS.md \
  && git -C "$repo" check-ignore -q .cursor/hooks.json \
  && git -C "$repo" check-ignore -q .codex/hooks.json \
  && git -C "$repo" check-ignore -q .harness/active-change \
  && git -C "$repo" check-ignore -q .harness/bootstrap-status.env; then
  pass "business bootstrap files are locally ignored"
else
  fail "business bootstrap files are locally ignored"
fi

run_expect_pass "business repo bootstrap check passes" \
  env SFA_REPO_FRONTEND_MAP_SYSTEM="$repo" "$root/scripts/business-repo-bootstrap.sh" --check "$repo"
if grep -q 'BOOTSTRAP_STATUS=PASS' "$tmp_dir/out" \
  && grep -q 'REPO_ID=frontend-map-system' "$tmp_dir/out"; then
  pass "business repo bootstrap check emits machine-readable metadata"
else
  fail "business repo bootstrap check emits machine-readable metadata"
fi

run_expect_pass "business repo bootstrap remove passes" \
  "$root/scripts/business-repo-bootstrap.sh" --remove "$repo"

if [[ ! -e "$repo/.cursor/hooks.json" && ! -e "$repo/.codex/hooks.json" && ! -e "$repo/.harness/active-change" && ! -e "$repo/.harness/bootstrap-status.env" ]]; then
  pass "business repo bootstrap remove clears generated hook state"
else
  fail "business repo bootstrap remove clears generated hook state"
fi

tracked_repo="$tmp_dir/tracked-agents-repo"
mkdir -p "$tracked_repo"
git -C "$tracked_repo" init -q
git -C "$tracked_repo" config user.email harness@example.invalid
git -C "$tracked_repo" config user.name "Harness Test"
printf '# Existing AGENTS\n' >"$tracked_repo/AGENTS.md"
git -C "$tracked_repo" add AGENTS.md
git -C "$tracked_repo" commit -q -m "tracked agents"

run_expect_pass "business repo bootstrap preserves tracked AGENTS" \
  "$root/scripts/business-repo-bootstrap.sh" "$tracked_repo" sample-change
if grep -q '# Existing AGENTS' "$tracked_repo/AGENTS.md" \
  && ! grep -q 'sfa-ai-harness business repo bootstrap' "$tracked_repo/AGENTS.md"; then
  pass "tracked AGENTS was not overwritten"
else
  fail "tracked AGENTS was not overwritten"
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: business repo bootstrap test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: business repo bootstrap test passed\n'
