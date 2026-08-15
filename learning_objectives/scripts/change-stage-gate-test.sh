#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

failures=0
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

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
  if "$@" >"$tmp_dir/out" 2>"$tmp_dir/err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,30p' "$tmp_dir/err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local name="$1"
  local expected_code="$2"
  shift 2
  if "$@" >"$tmp_dir/out" 2>"$tmp_dir/err"; then
    fail "$name"
    sed -n '1,20p' "$tmp_dir/out" >&2 || true
    return
  fi
  if grep -q "^CODE: ${expected_code}$" "$tmp_dir/err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,30p' "$tmp_dir/err" >&2 || true
  fi
}

repo="$tmp_dir/repo"
change="$tmp_dir/change"
mkdir -p "$repo/src" "$change"
changed_file="$repo/src/demo.js"
printf 'export const value = 1;\n' >"$changed_file"

write_common_change() {
  local target="$1"
  mkdir -p "$target"
  cat >"$target/spec.md" <<'SPEC'
# Stage gate fixture

- [FACT] Stage gate fixtures use explicit local paths and no unresolved questions.
- [ASSUMP] None.

non_blocking_questions:
  - [QUESTION] None.

allowed_paths:
  repo:
    - $STAGE_GATE_REPO/src/**
forbidden_paths:
  - "**/.env*"
SPEC

  cat >"$target/technical-solution.md" <<'SPEC'
# Stage Gate Technical Solution

confirmation_status: CONFIRMED
allowed_next_stage: code_start

全栈 PRD 覆盖矩阵：Backend / PC Web / H5 N/A / 小程序 N/A / APP N/A / 导出 N/A / 埋点 N/A。
SPEC

  cat >"$target/verification-map.md" <<'SPEC'
verification_map_status: READY

| ID | Constraint | Source | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| VM-001 | stage gate | harness | command | stage gate fixture | PLANNED |
SPEC

  cat >"$target/evidence.md" <<'SPEC'
# Evidence

- Stage gate fixture evidence.
SPEC

  cat >"$target/harness-status.md" <<'SPEC'
# Harness Status

- Stage gate fixture status.
SPEC
}

write_ai_test_plan() {
  local target="$1"
  local status="$2"
  cat >"$target/ai-test-plan.md" <<SPEC
# AI Test Plan

test_plan_status: $status
confirmed_by: fixture
confirmed_at: 2026-06-25
confirmed_scope: stage gate fixture

## 来源

- spec.md
- technical-solution.md

## 系统运行依据

- Fixture uses a temporary local repo and no external runtime.

## 测试用例矩阵

| ID | Priority | Role | End | Scenario | Expected | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| TC-001 | P0 | agent | harness | run stage gate | gate passes or fails with code | command output |

## 边界场景

- Missing AI test plan must block code-start.

## UI 检查

- N/A: harness script fixture has no UI.

## 高 token 风险提示

- N/A: fixture files are intentionally small.
SPEC
}

write_ready_environment() {
  local target="$1"
  cat >"$target/environment-readiness.md" <<'SPEC'
# Environment readiness

environment_status: READY

## 环境矩阵

| Environment | Purpose | Access boundary | Status | Notes |
| --- | --- | --- | --- | --- |
| test | gate fixture | local only | READY | no secrets |

## 本轮必测系统

| Target ID | System | Required? | Runtime standard | Status | N/A reason |
| --- | --- | --- | --- | --- | --- |
| TGT-001 | PC Web | yes | SYS-001 | READY | N/A |

## 系统运行标准

| Standard ID | System | Repo ID | Local command or launch method | Env profile | Port or entry | Upstream dependencies | Health check | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SYS-001 | PC Web | frontend-map-system | scripts/frontend-dev-server.sh frontend-map-system 9527 | local | http://localhost:9527 | none | fixture | READY | evidence.md |

## 本地联调拓扑

| Topology ID | Client system | API target | Data target | Fallback target | Network requirement | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TOPO-001 | PC Web | local fixture | fixture data | N/A | none | READY | evidence.md |

## App 端运行标准

| App ID | Platform | Repo ID | Scheme / flavor / variant | Build or launch command | Environment switch | Simulator coverage | Real device required for | Third-party SDK limits | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

## 角色账号

| Role | Environment | Account identifier | Credential source | Data scope | Status |
| --- | --- | --- | --- | --- | --- |
| Reviewer | test | redacted fixture account | runtime secure source | fixture | READY |

## 数据与权限

| Item | Environment | Permission | Rollback | Status |
| --- | --- | --- | --- | --- |
| Fixture data | test | local fixture | remove temp dir | READY |

## 测试数据准备

| Dataset | Purpose | Owner | Status | Notes |
| --- | --- | --- | --- | --- |
| Fixture | gate test | harness | READY | temp dir only |

## 设备与工具

| Tool | Purpose | Status | Notes |
| --- | --- | --- | --- |
| Shell | gate test | READY | local |
SPEC
}

write_test_agent_verification_goal() {
  local target="$1"
  cat >"$target/test-agent-verification.md" <<'SPEC'
# Test Agent Verification

verification_status: GOAL_ACHIEVED
final_decision: GOAL_ACHIEVED

| Issue ID | Severity | Source Case | Expected | Actual | Evidence | Returned to Main Agent | Retest Result | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TAV-001 | P3 | TC-001 | fixture passes | fixture passes | evidence.md | yes | PASS | FIXED |

## 结论

- Goal achieved.
SPEC
}

write_confirmed_ai_test_report() {
  local target="$1"
  cat >"$target/ai-test-report.md" <<'SPEC'
# AI Test Report

confirmation_status: CONFIRMED
recommendation: 允许进入预发

- ai-test-plan.md
- test-agent-verification.md
SPEC
}

write_passing_review() {
  local target="$1"
  cat >"$target/review.md" <<'SPEC'
# Review

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

- changes/stage-gate/spec.md
- changes/stage-gate/technical-solution.md
- changes/stage-gate/evidence.md
- git diff

## HIGH

- none.

## MEDIUM

- none.

## LOW

- none.

## 结论

- Pass.
SPEC
}

write_common_change "$change"

missing_plan="$tmp_dir/missing-plan"
cp -R "$change" "$missing_plan"

run_expect_fail_with_code "code-start blocks when AI test plan is missing" \
  "AI_TEST_PLAN_GATE/MISSING_FILE" \
  env STAGE_GATE_REPO="$repo" scripts/change-stage-gate.sh "$missing_plan" code-start "$changed_file"

write_ai_test_plan "$change" "CONFIRMED"

run_expect_pass "code-start passes with confirmed plan and file guards" \
  env STAGE_GATE_REPO="$repo" scripts/change-stage-gate.sh "$change" code-start "$changed_file"

telemetry_dir="$tmp_dir/stage-telemetry"
run_expect_pass "code-start records gate telemetry" \
  env STAGE_GATE_REPO="$repo" SFA_HARNESS_TELEMETRY_DIR="$telemetry_dir" scripts/change-stage-gate.sh "$change" code-start "$changed_file"
if [[ -f "$telemetry_dir/events.jsonl" ]] && \
  grep -q '"event_type":"gate_run"' "$telemetry_dir/events.jsonl" && \
  grep -q '"gate_id":"change-stage:code-start"' "$telemetry_dir/events.jsonl" && \
  grep -q '"result":"PASS"' "$telemetry_dir/events.jsonl"; then
  pass "code-start telemetry event recorded"
else
  fail "code-start telemetry event recorded"
fi

telemetry_blocker="$tmp_dir/telemetry-blocker"
touch "$telemetry_blocker"
run_expect_pass "code-start passes when telemetry write fails" \
  env STAGE_GATE_REPO="$repo" SFA_HARNESS_TELEMETRY_DIR="$telemetry_blocker/child" scripts/change-stage-gate.sh "$change" code-start "$changed_file"
if grep -q 'WARN: change-stage telemetry record failed' "$tmp_dir/err"; then
  pass "telemetry failure warning is visible"
else
  fail "telemetry failure warning is visible"
fi

partial_env="$tmp_dir/partial-env"
cp -R "$change" "$partial_env"
cat >"$partial_env/environment-readiness.md" <<'SPEC'
environment_status: PARTIAL
SPEC
cat >"$partial_env/test-agent-verification.md" <<'SPEC'
verification_status: BLOCKED
final_decision: BLOCKED

| Issue ID | Severity | Source Case | Expected | Actual | Evidence | Returned to Main Agent | Retest Result | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
SPEC
cat >"$partial_env/ai-test-report.md" <<'SPEC'
confirmation_status: PENDING
recommendation: 补齐环境后重测

- ai-test-plan.md
- test-agent-verification.md
SPEC

run_expect_fail_with_code "pre-test-release blocks partial environment" \
  "ENVIRONMENT_READINESS/NOT_READY" \
  scripts/change-stage-gate.sh "$partial_env" pre-test-release

review_ready="$tmp_dir/review-ready"
cp -R "$change" "$review_ready"
write_ai_test_plan "$review_ready" "CONFIRMED"
write_passing_review "$review_ready"
scripts/agent-dispatch-plan.sh --agent-id sfa-harness-reviewer --runtime codex_generated --change-id review-ready --output "$review_ready/agent-dispatch-plan.md" >/dev/null
run_expect_pass "pre-pr passes through agent dispatch and output contract gates" \
  scripts/change-stage-gate.sh "$review_ready" pre-pr

release_ready="$tmp_dir/release-ready"
cp -R "$change" "$release_ready"
write_ai_test_plan "$release_ready" "CONFIRMED"
write_ready_environment "$release_ready"
write_test_agent_verification_goal "$release_ready"
write_confirmed_ai_test_report "$release_ready"
scripts/agent-dispatch-plan.sh --agent-id sfa-test-agent --runtime codex_generated --change-id release-ready --output "$release_ready/agent-dispatch-plan.md" >/dev/null
run_expect_pass "pre-test-release passes through test agent output contract gate" \
  scripts/change-stage-gate.sh "$release_ready" pre-test-release

stale_dispatch="$tmp_dir/stale-dispatch"
cp -R "$review_ready" "$stale_dispatch"
sed 's/output_contract: review_findings/output_contract: stale_contract/' \
  "$stale_dispatch/agent-dispatch-plan.md" >"$stale_dispatch/agent-dispatch-plan.tmp"
mv "$stale_dispatch/agent-dispatch-plan.tmp" "$stale_dispatch/agent-dispatch-plan.md"
if scripts/change-stage-gate.sh "$stale_dispatch" pre-pr >"$tmp_dir/out" 2>"$tmp_dir/err"; then
  fail "pre-pr blocks stale agent dispatch plan"
else
  if grep -q "output_contract" "$tmp_dir/err"; then
    pass "pre-pr blocks stale agent dispatch plan"
  else
    fail "pre-pr blocks stale agent dispatch plan"
    sed -n '1,60p' "$tmp_dir/err" >&2 || true
  fi
fi

run_expect_fail_with_code "pre-pr blocks missing independent review" \
  "REVIEWER_GATE/MISSING_FILE" \
  scripts/change-stage-gate.sh "$change" pre-pr

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: change stage gate readiness found %s issue(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: change stage gate readiness tests passed\n'
