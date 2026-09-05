# AI 测试报告：<change-id>

> AI 执行测试后的人工确认报告。进入测试 / 预发发布前必须由人工确认。
> 正文默认中文；URL、API path、field、enum、error code、命令、截图路径和引用原文保持原样。
> 不记录可复用的访问凭据、连接凭据、认证信息或个人敏感信息。

## 执行结论

```yaml
change_id: <change-id>
execute_time: <yyyy-MM-dd HH:mm>
executor: 主 Agent
environment: <local / SIT / UAT / pre-release>
result: PENDING
recommendation: 修复后重测
artifact_dir: artifacts/<change-id>/ai-test/
test_plan: changes/<change-id>/ai-test-plan.md
test_agent_verification: changes/<change-id>/test-agent-verification.md
```

`result` 可选值：`PASS` / `PASS_WITH_LIMITATIONS` / `FAIL` / `BLOCKED`。
`recommendation` 可选值：`允许进入预发` / `修复后重测` / `补齐环境后重跑` / `阻塞发布`。

## 前置产物

| Artifact | Required status | Path | Notes |
| --- | --- | --- | --- |
| AI test plan | `test_plan_status: CONFIRMED` | `changes/<change-id>/ai-test-plan.md` | 用户已确认测试方案 |
| Tester verification | `verification_status: GOAL_ACHIEVED` | `changes/<change-id>/test-agent-verification.md` | Tester 独立验收通过 |
| Evidence | present | `changes/<change-id>/evidence.md` | 主 Agent 常规测试与修复证据 |

## 执行分层

| Layer | Owner | Purpose | Final authority |
| --- | --- | --- | --- |
| 常规测试 | Main Agent | compile、unit test、lint/build、smoke、自测截图/API 摘要 | 否 |
| 独立验收 | Tester | 按已确认测试方案验收、反馈问题、复测修复 | 是 |
| 人工确认 | User / reviewer | 确认报告范围、残余风险和发布建议 | 发布前确认 |

## 测试范围

| Area | Covered | Evidence | Notes |
| --- | --- | --- | --- |
| Backend targeted tests | `yes/no/n/a/blocked` | `<command or path>` |  |
| Backend compile/package | `yes/no/n/a/blocked` | `<command or path>` |  |
| API smoke | `yes/no/n/a/blocked` | `<API summary>` |  |
| Frontend lint/build | `yes/no/n/a/blocked` | `<command or path>` |  |
| PC E2E smoke | `yes/no/n/a/blocked` | `changes/<change-id>/pc-e2e-smoke-report.md` |  |
| APP / H5 / mini program smoke | `yes/no/n/a/blocked` | `<path or reason>` |  |
| Job / MQ / async flow | `yes/no/n/a/blocked` | `<path or reason>` |  |
| DB verification | `read-only/write-confirmed/n/a/blocked` | `<SQL summary or reason>` |  |
| Permission / role coverage | `yes/no/n/a/blocked` | `<role and evidence>` |  |

## 测试用例

| Case ID | Role | Precondition | Steps | Expected | Actual | Evidence | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AI-TC-001 | `<角色>` | `<数据/状态/登录态>` | `<逐步写清怎么测>` | `<期望结果>` | `<实际结果>` | `<截图/API/SQL/命令路径>` | `PASS/FAIL/BLOCKED` |

要求：

- 每条用例必须写清角色、前置条件、步骤、期望、实际、证据和结果。
- 截图、trace、完整日志放 `artifacts/<change-id>/ai-test/` 或外部存储；本报告只写路径和摘要。
- 有状态 API、DB 写入、job 触发必须记录用户二次确认来源；没有确认时只能写 `BLOCKED`。

## 截图与证据

| Evidence | Path / URL | Purpose |
| --- | --- | --- |
| `<screenshot/API/log>` | `<artifact path>` | `<证明什么>` |

## 失败、阻塞与未覆盖项

| Type | Description | Impact | Next action |
| --- | --- | --- | --- |
| `FAIL / BLOCKED / NOT_COVERED` | `<说明>` | `<是否阻塞预发>` | `<修复/补测/人工确认>` |

## 残余风险

| Risk | Impact | Accepted by human? | Follow-up |
| --- | --- | --- | --- |
| `<risk>` | `<impact>` | `yes/no` | `<next step>` |

## 人工确认

```yaml
confirmation_status: PENDING
confirmed_by: -
confirmed_at: -
confirmed_scope: -
residual_risks_accepted: -
```

`confirmation_status` 可选值：`PENDING` / `CONFIRMED` / `CHANGE_REQUESTED` / `BLOCKED`。

人工确认语义：

- `CONFIRMED` 只表示确认本报告覆盖范围、测试结果、未覆盖项和残余风险。
- 进入测试 / 预发发布还必须满足 `recommendation: 允许进入预发`。
- 最终开发目标是否达成，以 `test-agent-verification.md` 中 `verification_status: GOAL_ACHIEVED` 和 `final_decision: GOAL_ACHIEVED` 为准。
- 主 Agent 的 compile、unit test、lint/build、smoke 和自测截图只作为证据，不作为最终验收判定。
- 如人工要求调整，本文件标记 `CHANGE_REQUESTED`，修复并重测后重新确认。
