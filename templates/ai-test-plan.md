# AI 测试方案：<change-id>

> 由独立 Test Strategy Agent 基于 PRD、技术方案、接口契约和当前环境信息生成。
> 本文件必须在业务代码实现前由用户确认。正文默认中文；代码标识、命令、API path、
> field、enum、error code、截图路径和引用原文保持原样。
> 不记录可复用的访问凭据、连接凭据或认证信息。

## 确认状态

```yaml
change_id: <change-id>
test_plan_status: PENDING
strategy_agent: Test Strategy Agent
created_at: <yyyy-MM-dd HH:mm>
confirmed_by: -
confirmed_at: -
confirmed_scope: -
token_risk_level: LOW / MEDIUM / HIGH
```

`test_plan_status` 可选值：`PENDING` / `CONFIRMED` / `CHANGE_REQUESTED` / `BLOCKED`。

确认语义：

- `CONFIRMED` 表示用户确认本测试方案足以指导后续 Tester 独立验收。
- 未 `CONFIRMED` 前，不允许进入业务代码实现。
- 如果测试方案存在高 token、真机、环境、账号或数据风险，必须在本文件中显式提示。

## 来源

| Source | Path / URL | Status |
| --- | --- | --- |
| PRD | `<PRD path or Feishu URL>` | `READ / BLOCKED` |
| Technical solution | `changes/<change-id>/technical-solution.md` | `READ / BLOCKED` |
| Contract | `changes/<change-id>/contract.md` | `READ / N/A / BLOCKED` |
| Environment readiness | `changes/<change-id>/environment-readiness.md` | `READY / PENDING / BLOCKED` |

## 系统运行依据

> 从 `environment-readiness.md` 引用本轮必测系统、系统运行标准、本地联调拓扑和
> App 端运行标准。测试方案不能只写“测试环境可用”，必须说明每个端怎么启动、
> 连哪个 API / 数据环境，以及哪些能力需要真机或联调。

| System | Runtime standard | Integration topology | Evidence expected | Notes |
| --- | --- | --- | --- | --- |
| `<PC Web / Backend / iOS / Android / etc.>` | `<SYS-ID / APP-ID>` | `<TOPO-ID>` | `<screenshot/API/log>` | `<simulator/device/SDK limits>` |

## 测试目标

| Goal | Success criteria | Evidence target |
| --- | --- | --- |
| `<目标>` | `<什么算通过>` | `<截图/API/DB/命令/人工确认>` |

## 角色与环境矩阵

| Role | Environment | Account source | Data source | Notes |
| --- | --- | --- | --- | --- |
| `<角色>` | `local / test / pre-release / production-readonly` | `<凭据来源，不写凭据>` | `<自然数据 / 造数 / fixture>` | `<限制>` |

## 测试用例矩阵

| Case ID | Priority | Role | End / Layer | Scenario | Preconditions | Steps | Expected | Evidence | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-001 | `P0/P1/P2/P3` | `<角色>` | `<PC/iOS/Android/API/DB/Job>` | `<场景>` | `<环境/数据/状态>` | `<逐步写清>` | `<预期>` | `<证据路径>` | `auto/manual/joint-test` |

## 边界场景

| Boundary | Expected behavior | Test case | Notes |
| --- | --- | --- | --- |
| Required / empty value | `<预期>` | `<TC-ID>` |  |
| Min / max / over limit | `<预期>` | `<TC-ID>` |  |
| Permission / role mismatch | `<预期>` | `<TC-ID>` |  |
| State mismatch | `<预期>` | `<TC-ID>` |  |
| Legacy data compatibility | `<预期>` | `<TC-ID>` |  |
| External dependency failure | `<预期>` | `<TC-ID or N/A>` |  |

## UI 检查

| UI item | Harness rule / baseline | PRD reference | Unknown gap? | Confirmation |
| --- | --- | --- | --- | --- |
| `<页面/组件/交互>` | `<rule pack / existing page>` | `<PRD 图/截图>` | `yes/no` | `<用户确认或 N/A>` |

要求：

- UI 编码前必须读取对应 Harness 交互规范。
- 规范中没有覆盖的布局、间距、按钮位置、交互状态或组件样式，必须先确认再实现。
- 每个 UI PASS 结论必须有真实截图或人工确认记录。

## 高 token 风险提示

| Risk | Trigger | Mitigation | Accepted? |
| --- | --- | --- | --- |
| `<大量截图/长日志/多端自动化/大接口响应>` | `<触发条件>` | `<保存到文件、只汇报摘要、分阶段执行>` | `yes/no/pending` |

## 未覆盖项与阻塞

| Item | Reason | Impact | Required input / next action |
| --- | --- | --- | --- |
| `<未覆盖项>` | `<原因>` | `<影响>` | `<需要谁提供什么>` |
