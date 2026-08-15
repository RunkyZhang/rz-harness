#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
planner="$root/scripts/agent-dispatch-plan.sh"
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

write_candidate_confirmation() {
  local target="$1" allowed_agent_ids="$2"
  cat >"$target" <<MARKDOWN
# Agent Candidate Confirmation: demo-change

candidate_dispatch_confirmation: CONFIRMED
change_id: demo-change
allowed_agent_ids: $allowed_agent_ids
business_code_start_gate: PASS
allowed_paths_confirmed: yes
isolated_worktree_required: yes
protected_actions_allowed: no
global_config_write_allowed: no
db_or_release_actions_allowed: no
confirmed_by: test
confirmed_at: 2026-07-03T00:00:00+08:00
MARKDOWN
}

run_expect_pass "review stage selects generated reviewer from registry" \
  "$planner" --stage pre_pr_or_human_review --runtime codex_generated

if grep -q '^AGENT_ID=sfa-harness-reviewer$' "$out" \
  && grep -q '^OUTPUT_CONTRACT=review_findings$' "$out" \
  && grep -q '^REQUIRED_GATES=scripts/reviewer-gate.sh$' "$out" \
  && ! grep -q '^AGENT_ID=sfa-backend-agent$' "$out"; then
  pass "review dispatch output contains reviewer contract only"
else
  fail "review dispatch output contains reviewer contract only"
  sed -n '1,160p' "$out" >&2 || true
fi

run_expect_fail "candidate implementation agents require explicit opt-in" "candidate agent requires --allow-candidate" \
  "$planner" --stage implementation_after_contract_v0_1 --runtime codex_generated

run_expect_fail "candidate implementation agents require confirmation file after opt-in" "candidate agent requires --candidate-confirmation" \
  "$planner" --stage implementation_after_contract_v0_1 --runtime codex_generated --allow-candidate

candidate_confirmation="$tmp_dir/candidate-confirmation.md"
write_candidate_confirmation "$candidate_confirmation" "[sfa-backend-agent,sfa-frontend-agent,sfa-mobile-agent]"

run_expect_pass "candidate implementation agent can be planned with explicit opt-in" \
  "$planner" --stage implementation_after_contract_v0_1 --runtime codex_generated --allow-candidate --candidate-confirmation "$candidate_confirmation"

if grep -q '^AGENT_ID=sfa-backend-agent$' "$out" \
  && grep -q '^PERMISSION=implementation_write_with_contract$' "$out" \
  && grep -q '^DEGRADATION=MAIN_AGENT_ONLY_OR_BLOCKED$' "$out" \
  && grep -q "^CANDIDATE_CONFIRMATION=$candidate_confirmation$" "$out"; then
  pass "candidate dispatch output keeps implementation constraints"
else
  fail "candidate dispatch output keeps implementation constraints"
  sed -n '1,160p' "$out" >&2 || true
fi

plan_file="$tmp_dir/dispatch-plan.md"
run_expect_pass "dispatch planner writes handoff plan when output is provided" \
  "$planner" --agent-id sfa-harness-reviewer --runtime codex_generated --change-id demo-change --output "$plan_file"

if [[ -f "$plan_file" ]] \
  && grep -q '# Agent Dispatch Plan: demo-change' "$plan_file" \
  && grep -q 'agent_id: sfa-harness-reviewer' "$plan_file" \
  && grep -q 'output_contract: review_findings' "$plan_file" \
  && grep -q 'required_gates: scripts/reviewer-gate.sh' "$plan_file"; then
  pass "handoff plan includes registry contract"
else
  fail "handoff plan includes registry contract"
  sed -n '1,160p' "$plan_file" >&2 || true
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: agent dispatch plan test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: agent dispatch plan test passed\n'
