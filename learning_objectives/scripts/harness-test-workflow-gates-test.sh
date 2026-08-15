#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

pass_change="$tmp/change-pass"
mkdir -p "$pass_change"

cat >"$pass_change/technical-solution.md" <<'EOF'
# sample-change 技术方案

## 确认状态

```yaml
change_id: sample-change
confirmation_status: CONFIRMED
confirmed_by: product-owner
confirmed_at: 2026-06-12 11:50
confirmed_scope: PC API mobile smoke fixture
allowed_next_stage: code_start
residual_risks_accepted: Native camera validation remains outside this fixture
```

## PRD 端到端覆盖矩阵

| PRD 项 | 影响端 | 实现仓/模块 | 技术方案章节 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Multiple photo display | PC Web / Backend / APP | sample fixture | 前端/客户端页面方案 | TC-001 screenshot and gate fixture | IN |
| Export | N/A | N/A | N/A | PRD 不涉及导出 | N/A |
| Analytics | N/A | N/A | N/A | PRD 不涉及埋点/分析 | N/A |

## 全栈范围

本 fixture 覆盖 Backend、PC Web、APP 展示链路；H5、小程序、导出、埋点/分析均为 N/A。

## 前端/客户端页面方案

PC Web 展示图片数量角标，APP 做展示 smoke。H5、小程序为 N/A，来源为 fixture 范围不涉及。
EOF

cat >"$pass_change/ai-test-plan.md" <<'EOF'
# AI 测试方案：sample-change

## 确认状态

```yaml
change_id: sample-change
test_plan_status: CONFIRMED
strategy_agent: Test Strategy Agent
created_at: 2026-06-12 12:00
confirmed_by: product-owner
confirmed_at: 2026-06-12 12:10
confirmed_scope: PC API mobile smoke
token_risk_level: MEDIUM
```

## 来源

| Source | Path / URL | Status |
| --- | --- | --- |
| PRD | Feishu PRD node recorded in change package | READ |
| Technical solution | changes/sample-change/technical-solution.md | READ |
| Contract | docs/contracts/sample-change-api.md | READ |
| Environment readiness | changes/sample-change/environment-readiness.md | READY |

## 系统运行依据

| System | Runtime standard | Integration topology | Evidence expected | Notes |
| --- | --- | --- | --- | --- |
| PC Web | SYS-001 | TOPO-001 | artifacts/sample/pc.png | Local frontend with test API |
| Android | APP-002 | TOPO-001 | artifacts/sample/android.png | Simulator covers display preview |

## 测试目标

| Goal | Success criteria | Evidence target |
| --- | --- | --- |
| Multiple photo display | Badge and preview show four photos | artifacts/sample/display.png |

## 角色与环境矩阵

| Role | Environment | Account source | Data source | Notes |
| --- | --- | --- | --- | --- |
| Region manager | test | Runtime credential source | Fixture data | No reusable credential in report |

## 测试用例矩阵

| Case ID | Priority | Role | End / Layer | Scenario | Preconditions | Steps | Expected | Evidence | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-001 | P0 | Region manager | PC | Display four uploaded photos | Environment ready | Open detail page and preview photo list | Badge shows 4 and preview starts at 1/4 | artifacts/sample/display.png | auto |

## 边界场景

| Boundary | Expected behavior | Test case | Notes |
| --- | --- | --- | --- |
| Required empty value | Submission is blocked | TC-001 | API fixture covers server guard |
| Min max over limit | Fifth photo is rejected | TC-001 | Service layer fixture |
| Permission role mismatch | User cannot see out of scope data | TC-001 | Role scope fixture |
| State mismatch | Closed item is read only | TC-001 | State fixture |
| Legacy data compatibility | Single string field still renders | TC-001 | Compatibility fixture |
| External dependency failure | Upload error is surfaced | TC-001 | Mocked failure |

## UI 检查

| UI item | Harness rule / baseline | PRD reference | Unknown gap? | Confirmation |
| --- | --- | --- | --- | --- |
| Photo badge | legacy-sfa-web rule pack | PRD screenshot evidence | no | product-owner confirmed |

## 高 token 风险提示

| Risk | Trigger | Mitigation | Accepted? |
| --- | --- | --- | --- |
| Multi-end screenshot evidence | PC and mobile validation in one run | Store screenshots in artifacts and summarize paths only | yes |

## 未覆盖项与阻塞

| Item | Reason | Impact | Required input / next action |
| --- | --- | --- | --- |
| Native camera | Simulator has no camera | Requires device joint test | Schedule device test |
EOF

cat >"$pass_change/environment-readiness.md" <<'EOF'
# 环境准备：sample-change

## 状态

```yaml
change_id: sample-change
environment_status: READY
target_environment: test
owner: orchestrator
```

## 环境矩阵

| Environment | Purpose | Access boundary | Status | Notes |
| --- | --- | --- | --- | --- |
| test | E2E validation | VPN and runtime auth | READY | No secret stored |

## 本轮必测系统

| Target ID | System | Required? | Runtime standard | Status | N/A reason |
| --- | --- | --- | --- | --- | --- |
| TGT-001 | PC Web | yes | SYS-001 | READY | N/A |
| TGT-002 | Backend API | yes | SYS-002 | READY | N/A |
| TGT-003 | Android | yes | APP-002 | READY | N/A |
| TGT-004 | iOS | no | N/A | N/A | Not touched by this fixture |

## 系统运行标准

| Standard ID | System | Repo ID | Local command or launch method | Env profile | Port or entry | Upstream dependencies | Health check | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SYS-001 | PC Web | frontend-map-system | scripts/frontend-dev-server.sh frontend-map-system 9527 | local frontend plus test API | http://localhost:9527 | VPN and proxy | login page screenshot | READY | artifacts/sample/pc.png |
| SYS-002 | Backend API | backend-sfa-root | mvn -DskipTests compile | test API fallback | http://127.0.0.1:30081 | VPN Nacos DB Redis | compile and smoke API | READY | artifacts/sample/api.txt |

## 本地联调拓扑

| Topology ID | Client system | API target | Data target | Fallback target | Network requirement | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TOPO-001 | PC Web and Android | local proxy for changed API | test fixture data | test API | VPN | READY | artifacts/sample/topology.md |

## App 端运行标准

| App ID | Platform | Repo ID | Scheme / flavor / variant | Build or launch command | Environment switch | Simulator coverage | Real device required for | Third-party SDK limits | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| APP-002 | Android | mobile-sfa-android | debug | ./gradlew :app:assembleDebug | debug menu selects test environment | login display preview | camera location push | map SDK not covered by this fixture | READY | artifacts/sample/android.png |

## 角色账号

| Role | Environment | Account identifier | Credential source | Data scope | Status |
| --- | --- | --- | --- | --- | --- |
| Region manager | test | redacted region manager account | Runtime secure source | Organization fixture | READY |

## 数据与权限

| Item | Environment | Permission | Rollback | Status |
| --- | --- | --- | --- | --- |
| Test fixture data | test | Write allowed for marked fixture rows | Rollback SQL stored outside report | READY |

## 测试数据准备

| Dataset | Purpose | Owner | Status | Notes |
| --- | --- | --- | --- | --- |
| MANUAL_4 | Display and preview | Main Agent | READY | Four near and four far photos |

## 设备与工具

| Tool | Purpose | Status | Notes |
| --- | --- | --- | --- |
| Chrome | PC validation | READY | Local browser |
| Android emulator | Display smoke | READY | Camera excluded |
EOF

cat >"$pass_change/ui-rule-checklist.md" <<'EOF'
# UI 规则检查：sample-change

## 状态

```yaml
change_id: sample-change
ui_rule_status: READY
rule_gap_status: NONE
prd_screen_breakdown_status: READY
checked_by: orchestrator
checked_at: 2026-06-12 12:20
```

## 规则与基线

| Source | Path / URL | Status |
| --- | --- | --- |
| Harness UI rules | rules/frontends/legacy-sfa/manifest.yml | READ |
| PRD UI source | Feishu PRD screenshot | READ |
| Online baseline | Existing detail page screenshot | CAPTURED |

## PRD 截图逐屏拆解表

| Screenshot ID | PRD screenshot reference | Area breakdown | Target skeleton / class mapping | Difference from sample | Decision | Status |
| --- | --- | --- | --- | --- | --- | --- |
| UI-001 | Feishu PRD screenshot | list/photo badge/action | legacy-sfa-web table image rule | badge position needs confirmation | keep badge at image corner | READY |

## UI 规范映射

| UI item | Rule source | PRD source | Decision | Status |
| --- | --- | --- | --- | --- |
| Photo badge | legacy-sfa-web table image rule | PRD screenshot | Keep badge at image corner | CONFIRMED |

## UI 规范缺口

| Gap ID | Gap | Options | Decision | Status |
| --- | --- | --- | --- | --- |
EOF

cat >"$pass_change/test-agent-verification.md" <<'EOF'
# 测试 Agent 独立验收：sample-change

## 验收状态

```yaml
change_id: sample-change
verification_status: GOAL_ACHIEVED
test_agent: Test Verification Agent
test_plan: changes/sample-change/ai-test-plan.md
latest_round: 2
confirmed_at: 2026-06-12 13:00
blocking_issues_open: 0
```

## 轮次记录

| Round | Trigger | Scope | Main Agent evidence checked | Result | Notes |
| --- | --- | --- | --- | --- | --- |
| 1 | implementation complete | TC-001 | evidence.md | ISSUES_FOUND | Badge evidence missing |
| 2 | fix complete | TC-001 | evidence.md | GOAL_ACHIEVED | Evidence added |

## 问题清单

| Issue ID | Severity | Source Case | Expected | Actual | Evidence | Returned to Main Agent | Retest Result | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TAV-001 | P2 | TC-001 | Badge evidence exists | Evidence was absent | artifacts/sample/round1.txt | yes | Evidence added and verified | FIXED |

## 主 Agent 修复回传

| Issue ID | Fix summary from Main Agent | Regular tests rerun | Evidence | Ready for retest |
| --- | --- | --- | --- | --- |
| TAV-001 | Added screenshot evidence | shell gate fixture | evidence.md | yes |

## 测试 Agent 复测结论

| Case ID / Issue ID | Retest steps | Retest evidence | Result | Notes |
| --- | --- | --- | --- | --- |
| TC-001 | Run fixture and inspect status | artifacts/sample/display.png | PASS | Meets test plan |

## BLOCKED 说明

| Blocker | Tried | Minimum required input / environment | Owner |
| --- | --- | --- | --- |

## 最终确认

```yaml
final_decision: GOAL_ACHIEVED
decision_by: Test Verification Agent
decision_at: 2026-06-12 13:05
goal_achieved_scope: TC-001 fixture flow
residual_risks: Native device camera remains outside this fixture
```
EOF

cat >"$pass_change/ai-test-report.md" <<'EOF'
# AI 测试报告：sample-change

## 确认状态

```yaml
change_id: sample-change
confirmation_status: CONFIRMED
recommendation: 允许进入预发
test_plan: changes/sample-change/ai-test-plan.md
test_agent_verification: changes/sample-change/test-agent-verification.md
confirmed_by: product-owner
confirmed_at: 2026-06-12 13:20
```

## 前置产物

- Test plan: changes/sample-change/ai-test-plan.md
- Test Agent verification: changes/sample-change/test-agent-verification.md

## 测试结论

| Layer | Status | Evidence |
| --- | --- | --- |
| Gate fixture | PASS | artifacts/sample/display.png |
EOF

assert_fail() {
  local label="$1"
  shift
  if "$@" >"$tmp/$label.out" 2>&1; then
    printf 'FAIL: expected command to fail: %s\n' "$label" >&2
    cat "$tmp/$label.out" >&2
    exit 1
  fi
}

"$repo_root/scripts/technical-solution-gate.sh" "$pass_change"
"$repo_root/scripts/ai-test-plan-gate.sh" "$pass_change"
"$repo_root/scripts/environment-readiness-gate.sh" "$pass_change"
"$repo_root/scripts/ui-rule-gate.sh" "$pass_change"
"$repo_root/scripts/test-agent-verification-gate.sh" "$pass_change"
"$repo_root/scripts/ai-test-report-gate.sh" "$pass_change"
"$repo_root/scripts/harness-status.sh" "$pass_change" >"$tmp/status.md"
grep -q '预发待发布' "$tmp/status.md"

pending_plan="$tmp/change-pending-plan"
cp -R "$pass_change" "$pending_plan"
LC_ALL=C LC_CTYPE=C LANG=C perl -0pi -e 's/test_plan_status: CONFIRMED/test_plan_status: PENDING/' "$pending_plan/ai-test-plan.md"
assert_fail pending-plan "$repo_root/scripts/ai-test-plan-gate.sh" "$pending_plan"

open_issue="$tmp/change-open-issue"
cp -R "$pass_change" "$open_issue"
printf '| TAV-002 | P1 | TC-001 | Expected | Actual | artifacts/sample/fail.png | yes | Awaiting retest | OPEN |\n' >>"$open_issue/test-agent-verification.md"
assert_fail open-issue "$repo_root/scripts/test-agent-verification-gate.sh" "$open_issue"

sensitive_env="$tmp/change-sensitive-env"
cp -R "$pass_change" "$sensitive_env"
printf '\npassword=example\n' >>"$sensitive_env/environment-readiness.md"
assert_fail sensitive-env "$repo_root/scripts/environment-readiness-gate.sh" "$sensitive_env"

missing_runtime="$tmp/change-missing-runtime"
cp -R "$pass_change" "$missing_runtime"
LC_ALL=C LC_CTYPE=C LANG=C perl -0pi -e 's/## 系统运行标准.*?## 角色账号/## 角色账号/s' "$missing_runtime/environment-readiness.md"
assert_fail missing-runtime "$repo_root/scripts/environment-readiness-gate.sh" "$missing_runtime"

missing_android_app="$tmp/change-missing-android-app"
cp -R "$pass_change" "$missing_android_app"
LC_ALL=C LC_CTYPE=C LANG=C perl -0pi -e 's/\n\| APP-002 \| Android [^\n]*//' "$missing_android_app/environment-readiness.md"
assert_fail missing-android-app "$repo_root/scripts/environment-readiness-gate.sh" "$missing_android_app"

ui_gap="$tmp/change-ui-gap"
cp -R "$pass_change" "$ui_gap"
printf '| UIG-001 | Delete button position | ask user | no decision | BLOCKED |\n' >>"$ui_gap/ui-rule-checklist.md"
assert_fail ui-gap "$repo_root/scripts/ui-rule-gate.sh" "$ui_gap"

missing_verification="$tmp/change-missing-verification"
cp -R "$pass_change" "$missing_verification"
rm "$missing_verification/test-agent-verification.md"
assert_fail missing-verification "$repo_root/scripts/ai-test-report-gate.sh" "$missing_verification"

printf 'PASS: harness test workflow gates fixture passed\n'
