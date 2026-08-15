#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_pass() {
  local description="$1"
  shift
  if ! "$@" >/tmp/sfa-harness-ux-pass.out 2>/tmp/sfa-harness-ux-pass.err; then
    printf 'STDOUT:\n%s\n' "$(cat /tmp/sfa-harness-ux-pass.out)" >&2
    printf 'STDERR:\n%s\n' "$(cat /tmp/sfa-harness-ux-pass.err)" >&2
    fail "$description should pass"
  fi
}

assert_fail_contains() {
  local description="$1"
  local expected="$2"
  shift 2
  if "$@" >/tmp/sfa-harness-ux-fail.out 2>/tmp/sfa-harness-ux-fail.err; then
    fail "$description should fail"
  fi
  if ! grep -q "$expected" /tmp/sfa-harness-ux-fail.out /tmp/sfa-harness-ux-fail.err; then
    printf 'STDOUT:\n%s\n' "$(cat /tmp/sfa-harness-ux-fail.out)" >&2
    printf 'STDERR:\n%s\n' "$(cat /tmp/sfa-harness-ux-fail.err)" >&2
    fail "$description should mention $expected"
  fi
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir" /tmp/sfa-harness-ux-pass.out /tmp/sfa-harness-ux-pass.err /tmp/sfa-harness-ux-fail.out /tmp/sfa-harness-ux-fail.err' EXIT

change_dir="$tmpdir/changes/demo-harness-ux"
mkdir -p "$change_dir"

cat >"$change_dir/technical-solution.md" <<'MARKDOWN'
# Demo 技术方案

## 确认状态

```yaml
confirmation_status: PENDING
allowed_next_stage: none
```
MARKDOWN

assert_fail_contains \
  "pending technical solution" \
  "TECHNICAL_SOLUTION_GATE/PENDING_CONFIRMATION" \
  "$root/scripts/technical-solution-gate.sh" "$change_dir"

cat >"$change_dir/technical-solution.md" <<'MARKDOWN'
# Demo 技术方案

## 确认状态

```yaml
confirmation_status: CONFIRMED
confirmed_by: user
confirmed_at: 2026-06-08 10:00
confirmed_scope: spec / contract / plan
allowed_next_stage: code_start
residual_risks_accepted: none
```

## PRD 端到端覆盖矩阵

本方案为全栈技术方案，覆盖 Backend、PC Web、H5 N/A、小程序 N/A、APP N/A、导出 N/A、埋点/分析 N/A、DB N/A、job/MQ N/A。

## 前端/客户端页面方案

PC Web: N/A；H5: N/A；小程序: N/A；APP: N/A。UI 参考: N/A，PRD 不涉及页面；路由: N/A；空态/加载态/失败态: N/A。

## 字段来源和处理逻辑

字段来源: N/A，PRD 不涉及接口字段变更；处理逻辑: N/A；筛选逻辑: N/A。

## 导出和埋点/分析

导出: N/A，PRD 不涉及。
埋点/分析: N/A，PRD 不涉及。
MARKDOWN

assert_pass \
  "confirmed technical solution" \
  "$root/scripts/technical-solution-gate.sh" "$change_dir"

cat >"$change_dir/data-model.md" <<'MARKDOWN'
# Data Model

```yaml
schema_change_required: yes
```

## DDL 草案

```sql
ALTER TABLE demo_table ADD COLUMN demo_status varchar(16) NOT NULL DEFAULT 'ACTIVE';
```
MARKDOWN

cat >"$change_dir/technical-solution.md" <<'MARKDOWN'
# Demo 技术方案

## 确认状态

```yaml
confirmation_status: CONFIRMED
confirmed_by: user
confirmed_at: 2026-06-08 10:00
confirmed_scope: spec / contract / plan
allowed_next_stage: code_start
residual_risks_accepted: none
```

## PRD 端到端覆盖矩阵

本方案为全栈技术方案，覆盖 Backend、PC Web、H5 N/A、小程序 N/A、APP N/A、导出 N/A、埋点/分析 N/A、DB。

## 前端/客户端页面方案

PC Web: N/A；H5: N/A；小程序: N/A；APP: N/A。UI 参考: N/A，PRD 不涉及页面；路由: N/A；空态/加载态/失败态: N/A。

## 后端和 DB 方案

DB 设计见 data-model.md。

## 字段来源和处理逻辑

字段来源: `demo_table.demo_status`；处理逻辑: exact match；筛选逻辑: N/A。

## 导出和埋点/分析

导出: N/A，PRD 不涉及。
埋点/分析: N/A，PRD 不涉及。
MARKDOWN

assert_fail_contains \
  "schema-change solution without inline DB details" \
  "TECHNICAL_SOLUTION_GATE/MISSING_INLINE_SCHEMA_CHANGE_DETAILS" \
  "$root/scripts/technical-solution-gate.sh" "$change_dir"

cat >"$change_dir/technical-solution.md" <<'MARKDOWN'
# Demo 技术方案

## 确认状态

```yaml
confirmation_status: CONFIRMED
confirmed_by: user
confirmed_at: 2026-06-08 10:00
confirmed_scope: spec / contract / plan
allowed_next_stage: code_start
residual_risks_accepted: none
```

## PRD 端到端覆盖矩阵

本方案为全栈技术方案，覆盖 Backend、PC Web、H5 N/A、小程序 N/A、APP N/A、导出 N/A、埋点/分析 N/A、DB。

## 前端/客户端页面方案

PC Web: N/A；H5: N/A；小程序: N/A；APP: N/A。UI 参考: N/A，PRD 不涉及页面；路由: N/A；空态/加载态/失败态: N/A。

## DB / 数据模型设计

涉及表：`demo_table`。

DDL 草案：

```sql
ALTER TABLE demo_table ADD COLUMN demo_status varchar(16) NOT NULL DEFAULT 'ACTIVE';
```

新增字段 `demo_status` 用于查询状态展示，回滚需确认是否可删除新增列。

## 字段来源和处理逻辑

字段来源: `demo_table.demo_status`；处理逻辑: exact match；筛选逻辑: N/A。

## 导出和埋点/分析

导出: N/A，PRD 不涉及。
埋点/分析: N/A，PRD 不涉及。
MARKDOWN

assert_pass \
  "schema-change solution with inline DB details" \
  "$root/scripts/technical-solution-gate.sh" "$change_dir"

rm -f "$change_dir/data-model.md"

cat >"$change_dir/technical-solution.md" <<'MARKDOWN'
# Demo 技术方案

## 确认状态

```yaml
confirmation_status: CONFIRMED
confirmed_by: user
confirmed_at: 2026-06-08 10:00
confirmed_scope: spec / contract / plan
allowed_next_stage: code_start
residual_risks_accepted: none
```

## PRD 端到端覆盖矩阵

本方案为全栈技术方案，覆盖 Backend、PC Web、H5 N/A、小程序 N/A、APP N/A、导出 N/A、埋点/分析 N/A、DB N/A。

## 前端/客户端页面方案

PC Web: N/A；H5: N/A；小程序: N/A；APP: N/A。UI 参考: N/A，PRD 不涉及页面；路由: N/A；空态/加载态/失败态: N/A。

## 字段来源和处理逻辑

字段来源: `demo_table.demo_status`；处理逻辑: READY_FOR_SQL；筛选逻辑: N/A。

## 导出和埋点/分析

导出: N/A，PRD 不涉及。
埋点/分析: N/A，PRD 不涉及。
MARKDOWN

assert_fail_contains \
  "confirmed technical solution with unresolved implementation marker" \
  "TECHNICAL_SOLUTION_GATE/UNRESOLVED_IMPLEMENTATION_DETAIL" \
  "$root/scripts/technical-solution-gate.sh" "$change_dir"

cat >"$change_dir/technical-solution.md" <<'MARKDOWN'
# Demo 技术方案

## 确认状态

```yaml
confirmation_status: CONFIRMED
confirmed_by: user
confirmed_at: 2026-06-08 10:00
confirmed_scope: spec / contract / plan
allowed_next_stage: code_start
residual_risks_accepted: none
```

## PRD 端到端覆盖矩阵

本方案为全栈技术方案，覆盖 Backend、PC Web、H5 N/A、小程序 N/A、APP N/A、导出 N/A、埋点/分析 N/A、DB N/A。

## 前端/客户端页面方案

PC Web: N/A；H5: N/A；小程序: N/A；APP: N/A。UI 参考: N/A，PRD 不涉及页面；路由: N/A；空态/加载态/失败态: N/A。

## 字段来源和处理逻辑

字段来源: N/A，PRD 不涉及接口字段变更；处理逻辑: N/A；筛选逻辑: N/A。

## 导出和埋点/分析

导出: N/A，PRD 不涉及。
埋点/分析: N/A，PRD 不涉及。
MARKDOWN

cat >"$change_dir/ai-test-plan.md" <<'MARKDOWN'
# AI 测试方案：demo-harness-ux

## 确认状态

```yaml
change_id: demo-harness-ux
test_plan_status: CONFIRMED
strategy_agent: Test Strategy Agent
created_at: 2026-06-08 10:20
confirmed_by: user
confirmed_at: 2026-06-08 10:30
confirmed_scope: UX gate fixture
token_risk_level: LOW
```

## 来源

| Source | Path / URL | Status |
| --- | --- | --- |
| PRD | docs/demo-prd.md | READ |
| Technical solution | changes/demo-harness-ux/technical-solution.md | READ |
| Contract | N/A | N/A |
| Environment readiness | N/A | N/A |

## 系统运行依据

| System | Runtime standard | Integration topology | Evidence expected | Notes |
| --- | --- | --- | --- | --- |
| Harness gate | shell fixture | local script | command output | no external env |

## 测试目标

| Goal | Success criteria | Evidence target |
| --- | --- | --- |
| Gate reports pending confirmation | expected code is emitted | command stderr |

## 角色与环境矩阵

| Role | Environment | Account source | Data source | Notes |
| --- | --- | --- | --- | --- |
| Tester | local | none | fixture | no credentials |

## 测试用例矩阵

| Case ID | Priority | Role | End / Layer | Scenario | Preconditions | Steps | Expected | Evidence | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-001 | P1 | Tester | Harness | pending report gate | fixture exists | run gate | pending confirmation code | stderr | auto |

## 边界场景

| Boundary | Expected behavior | Test case | Notes |
| --- | --- | --- | --- |
| Pending report | blocks pre-release | TC-001 | fixture only |

## UI 检查

| UI item | Harness rule / baseline | PRD reference | Unknown gap? | Confirmation |
| --- | --- | --- | --- | --- |
| N/A | N/A | N/A | no | N/A |

## 高 token 风险提示

| Risk | Trigger | Mitigation | Accepted? |
| --- | --- | --- | --- |
| none | local fixture | no large artifact | yes |

## 未覆盖项与阻塞

| Item | Reason | Impact | Required input / next action |
| --- | --- | --- | --- |
| none | all fixture scope covered | none | none |
MARKDOWN

cat >"$change_dir/test-agent-verification.md" <<'MARKDOWN'
# 测试 Agent 独立验收：demo-harness-ux

## 验收状态

```yaml
change_id: demo-harness-ux
verification_status: GOAL_ACHIEVED
test_agent: Test Verification Agent
test_plan: changes/demo-harness-ux/ai-test-plan.md
latest_round: 1
confirmed_at: 2026-06-08 10:40
blocking_issues_open: 0
```

## 问题清单

| Issue ID | Severity | Source Case | Expected | Actual | Evidence | Returned to Main Agent | Retest Result | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |

## 最终确认

```yaml
final_decision: GOAL_ACHIEVED
decision_by: Test Verification Agent
decision_at: 2026-06-08 10:45
goal_achieved_scope: UX gate fixture
residual_risks: none
```
MARKDOWN

cat >"$change_dir/ai-test-report.md" <<'MARKDOWN'
# AI 测试报告：demo-harness-ux

## 前置产物

- Test plan: changes/demo-harness-ux/ai-test-plan.md
- Test Agent verification: changes/demo-harness-ux/test-agent-verification.md

## 人工确认

```yaml
confirmation_status: PENDING
recommendation: 修复后重测
```
MARKDOWN

assert_fail_contains \
  "pending AI test report" \
  "AI_TEST_REPORT_GATE/PENDING_CONFIRMATION" \
  "$root/scripts/ai-test-report-gate.sh" "$change_dir"

cat >"$change_dir/ai-test-report.md" <<'MARKDOWN'
# AI 测试报告：demo-harness-ux

## 前置产物

- Test plan: changes/demo-harness-ux/ai-test-plan.md
- Test Agent verification: changes/demo-harness-ux/test-agent-verification.md

## 执行结论

```yaml
result: PASS_WITH_LIMITATIONS
recommendation: 允许进入预发
```

## 人工确认

```yaml
confirmation_status: CONFIRMED
confirmed_by: user
confirmed_at: 2026-06-08 11:00
```
MARKDOWN

assert_pass \
  "confirmed AI test report" \
  "$root/scripts/ai-test-report-gate.sh" "$change_dir"

cat >"$change_dir/ui-confirmation.md" <<'MARKDOWN'
# UI Confirmation：demo-harness-ux

## 判定

| Item | Value |
| --- | --- |
| UI scope | demo page |
| Complexity | complex |
| Decision source | PRD |
| Status | PENDING |
MARKDOWN

assert_fail_contains \
  "pending complex UI confirmation" \
  "UI_CONFIRMATION/PENDING_CONFIRMATION" \
  "$root/scripts/ui-confirmation-gate.sh" "$change_dir"

cat >"$change_dir/ui-confirmation.md" <<'MARKDOWN'
# UI Confirmation：demo-harness-ux

## 判定

| Item | Value |
| --- | --- |
| UI scope | demo page |
| Complexity | complex |
| Decision source | PRD |
| Status | CONFIRMED |

## 确认产物

| Artifact | Path / URL | Notes |
| --- | --- | --- |
| Prototype or runnable page | artifacts/demo/page.png | screenshot reviewed |

## 人工确认

| Reviewer | Decision | Time | Notes |
| --- | --- | --- | --- |
| user | CONFIRMED | 2026-06-08 11:10 | accepted |
MARKDOWN

assert_pass \
  "confirmed complex UI confirmation" \
  "$root/scripts/ui-confirmation-gate.sh" "$change_dir"

cat >"$change_dir/agent-dispatch-plan.md" <<'MARKDOWN'
# Agent Dispatch Plan：demo-harness-ux

```yaml
dispatch_plan_status: CONFIRMED
candidate_dispatch_confirmation: N/A
candidate_dispatch_allowed: false
business_code_start_gate: N/A
```

| Agent | Status | Scope | Notes |
| --- | --- | --- | --- |
| sfa-harness-orchestrator | ACTIVE | control-plane | main writable owner |
| sfa-test-agent | ACTIVE | verification | read-only |
MARKDOWN

cat >"$change_dir/verification-map.md" <<'MARKDOWN'
# Verification Map：demo-harness-ux

| ID | Verification | Runner | Command | Expected | Evidence |
| --- | --- | --- | --- | --- | --- |
| VM-001 | Harness status snapshot | shell | `scripts/harness-status.sh changes/demo-harness-ux` | PASS | changes/demo-harness-ux/verification-run-report.md |
MARKDOWN

cat >"$change_dir/verification-run-report.md" <<'MARKDOWN'
# Verification Run Report：demo-harness-ux

```yaml
run_status: PASS
dry_run: false
pass_count: 1
fail_count: 0
skip_count: 0
```

| ID | Result | Runner | Evidence |
| --- | --- | --- | --- |
| VM-001 | PASS | shell | scripts/harness-status.sh |
MARKDOWN

cat >"$change_dir/business-repo-bootstrap.md" <<'MARKDOWN'
# Business Repo Bootstrap：demo-harness-ux

```yaml
bootstrap_status: PASS
repo_count: 1
```

| Repo | Status | Evidence |
| --- | --- | --- |
| frontend-map-system | PASS | .harness/bootstrap-status.env |
MARKDOWN

telemetry_dir="$tmpdir/telemetry"
"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type gate_run \
  --change-id demo-harness-ux \
  --gate-id ux-status-fixture \
  --risk-tier L3 \
  --result PASS \
  --source-ref changes/demo-harness-ux/evidence.md

if ! "$root/scripts/harness-status.sh" "$change_dir" >"$tmpdir/status.out" 2>"$tmpdir/status.err"; then
  printf 'STDOUT:\n%s\n' "$(cat "$tmpdir/status.out")" >&2
  printf 'STDERR:\n%s\n' "$(cat "$tmpdir/status.err")" >&2
  fail "harness status should pass"
fi
[[ ! -s "$tmpdir/status.err" ]] || fail "status output should not write stderr"
grep -q "当前阶段" "$tmpdir/status.out" || fail "status output should include current phase"
grep -q "技术方案确认" "$tmpdir/status.out" || fail "status output should include technical solution confirmation"
grep -q "AI 测试报告确认" "$tmpdir/status.out" || fail "status output should include AI test report confirmation"
grep -q "Agent 派发计划" "$tmpdir/status.out" || fail "status output should include agent dispatch plan"
grep -q "Verification Run" "$tmpdir/status.out" || fail "status output should include verification run"
grep -q "业务仓本地约束" "$tmpdir/status.out" || fail "status output should include business repo bootstrap"
if ! SFA_HARNESS_TELEMETRY_DIR="$telemetry_dir" "$root/scripts/harness-status.sh" --json "$change_dir" >"$tmpdir/status.json" 2>"$tmpdir/status-json.err"; then
  printf 'STDOUT:\n%s\n' "$(cat "$tmpdir/status.json")" >&2
  printf 'STDERR:\n%s\n' "$(cat "$tmpdir/status-json.err")" >&2
  fail "harness status json should pass"
fi
grep -q '"owner_agent": "sfa-harness-orchestrator"' "$tmpdir/status.json" || fail "status json should include owner agent"
grep -q '"agent_dispatch_plan"' "$tmpdir/status.json" || fail "status json should include agent dispatch plan"
grep -q '"verification_map"' "$tmpdir/status.json" || fail "status json should include verification map"
grep -q '"verification_run"' "$tmpdir/status.json" || fail "status json should include verification run"
grep -q '"business_repo_bootstrap"' "$tmpdir/status.json" || fail "status json should include business repo bootstrap"
grep -q '"telemetry"' "$tmpdir/status.json" || fail "status json should include telemetry"

printf 'PASS: harness UX gates test passed\n'
