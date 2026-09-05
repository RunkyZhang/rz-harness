# Tester 独立验收：<change-id>

> 由独立 Tester 维护，用于验收主 Agent 的实现、常规测试和证据。
> 主 Agent 负责修复、补常规测试和补证据；最终目标是否达成，只能由 Tester
> 在本文件中确认。正文默认中文；代码标识、命令、API path、field、enum、error code
> 和截图路径保持原样。

## 验收状态

```yaml
change_id: <change-id>
verification_status: PENDING
test_agent: Tester
test_plan: changes/<change-id>/ai-test-plan.md
latest_round: 0
confirmed_at: -
blocking_issues_open: -
```

`verification_status` 可选值：

- `PENDING`：Tester 尚未开始验收。
- `ISSUES_FOUND`：已发现问题并回传主 Agent。
- `RETESTING`：主 Agent 已修复，等待或正在复测。
- `GOAL_ACHIEVED`：Tester 确认开发目标达成。
- `BLOCKED`：Tester 无法继续验收。

## 轮次记录

| Round | Trigger | Scope | Main Agent evidence checked | Result | Notes |
| --- | --- | --- | --- | --- | --- |
| 1 | `<实现完成/修复完成>` | `<测试范围>` | `<evidence/report path>` | `ISSUES_FOUND / RETESTING / GOAL_ACHIEVED / BLOCKED` |  |

## 问题清单

| Issue ID | Severity | Source Case | Expected | Actual | Evidence | Returned to Main Agent | Retest Result | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TAV-001 | `P0/P1/P2/P3` | `<TC-ID>` | `<预期>` | `<实际>` | `<截图/API/log>` | `yes/no` | `<复测结论>` | `OPEN / FIXED / ACCEPTED_RISK / BLOCKED` |

Severity 口径：

- `P0/P1/P2` 且 `Status=OPEN` 或 `Status=BLOCKED` 时，不允许进入最终 AI 测试报告确认。
- `P3` 可作为残余风险进入最终报告，但必须写影响、接受人和后续动作。

## 主 Agent 修复回传

| Issue ID | Fix summary from Main Agent | Regular tests rerun | Evidence | Ready for retest |
| --- | --- | --- | --- | --- |
| `<TAV-ID>` | `<修复说明>` | `<compile/unit/lint/smoke>` | `<路径>` | `yes/no` |

## Tester 复测结论

| Case ID / Issue ID | Retest steps | Retest evidence | Result | Notes |
| --- | --- | --- | --- | --- |
| `<TC-ID/TAV-ID>` | `<步骤>` | `<路径>` | `PASS / FAIL / BLOCKED` |  |

## BLOCKED 说明

仅当 `verification_status: BLOCKED` 时填写。

| Blocker | Tried | Minimum required input / environment | Owner |
| --- | --- | --- | --- |
| `<阻塞点>` | `<已尝试动作>` | `<最小所需输入>` | `<用户/测试/后端/运维>` |

## 最终确认

```yaml
final_decision: PENDING
decision_by: Test Verification Agent
decision_at: -
goal_achieved_scope: -
residual_risks: -
```

`final_decision` 可选值：`PENDING` / `GOAL_ACHIEVED` / `BLOCKED`。

