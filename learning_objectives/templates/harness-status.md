# Harness 状态卡：<change-id>

> 用户可见的单一流程入口。每次阶段切换、阻塞、人工确认、进入预发前都应更新。
> 本文件只聚合状态，不替代 spec / contract / plan / technical solution / evidence / report。

| Item | Value |
| --- | --- |
| 当前阶段 | `需求理解 / 方案确认 / 允许开工 / 实现中 / AI测试待确认 / 预发待发布 / 已收口` |
| 下一步 | `<Codex 下一步要做什么>` |
| 是否允许进入下一阶段 | `YES / NO` |
| 当前阻塞 | `<无 / 阻塞原因>` |
| 需要人工确认 | `<无 / 需要确认的文件和问题>` |
| 最近更新时间 | `<yyyy-MM-dd HH:mm>` |

## Gate 状态

| Gate | Status | Evidence / Link | Notes |
| --- | --- | --- | --- |
| 技术方案确认 | `PENDING / CONFIRMED / CHANGE_REQUESTED / BLOCKED` | `changes/<change-id>/technical-solution.md` | 未 `CONFIRMED` 不得进入业务代码 |
| 技术方案飞书同步 | `N/A / PENDING / SYNCED / BLOCKED / STALE` | `changes/<change-id>/technical-solution.md` / `<Feishu solution child doc URL>` | PRD 来源为飞书 / Lark 时，确认后必须同步到 PRD 子文档；本地方案后续修改后必须重新同步 |
| Code start | `PENDING / PASS / BLOCKED` | `business-code-start-gate / confidence-gate / allowed-paths / assumption-leak` | 无阻塞假设和问题；业务仓不在 `main/master` |
| Workstream dispatch | `NOT_APPLICABLE / PENDING / PASS / DEGRADED / BLOCKED` | `scripts/workstream-dispatch-gate.sh changes/<change-id>` | 全栈/多仓需求必须先拆 backend / PC / 小程序等工作线 |
| Agent dispatch plan | `NOT_APPLICABLE / PENDING / PASS / DEGRADED / BLOCKED` | `scripts/agent-dispatch-plan-gate.sh changes/<change-id>` | 派发 Codex/OpenCode 子 Agent 前必须有 registry-derived plan；candidate implementation 需要 `agent-candidate-confirmation.md` |
| Business repo bootstrap | `NOT_APPLICABLE / PENDING / PASS / BLOCKED` | `business-repo/.harness/bootstrap-status.env` / `changes/<change-id>/business-repo-bootstrap.md` | 业务仓只写本地 ignored 约束文件；不得写全局 Codex/OpenCode 配置 |
| AI 测试方案确认 | `PENDING / CONFIRMED / CHANGE_REQUESTED / BLOCKED` | `changes/<change-id>/ai-test-plan.md` | 未 `CONFIRMED` 不得进入业务代码 |
| Environment readiness | `PENDING / READY / BLOCKED / NOT_APPLICABLE` | `changes/<change-id>/environment-readiness.md` | 真实 E2E 前必须 READY |
| UI rule checklist | `NOT_APPLICABLE / PENDING / READY / BLOCKED` | `changes/<change-id>/ui-rule-checklist.md` | PRD UI 编码前必须过规范缺口检查 |
| Complex UI | `NOT_APPLICABLE / PENDING / CONFIRMED / BLOCKED` | `changes/<change-id>/ui-confirmation.md` | 复杂 UI 未确认不得声明通过 |
| Backend test plan | `NOT_APPLICABLE / PENDING / PASS / BLOCKED` | `changes/<change-id>/backend-test-plan.md` | 后端行为变更必须有矩阵 |
| Verification run | `NOT_APPLICABLE / PENDING / PASS / FAIL / DRY_RUN / BLOCKED` | `changes/<change-id>/verification-run-report.md` | `verification-map.md` 有可执行行时，进入 Test Agent / Reviewer 前必须有运行报告 |
| Test Agent verification | `PENDING / ISSUES_FOUND / RETESTING / GOAL_ACHIEVED / BLOCKED` | `changes/<change-id>/test-agent-verification.md` | 未 `GOAL_ACHIEVED` 主 Agent 不得声明目标达成 |
| AI 测试报告确认 | `PENDING / CONFIRMED / CHANGE_REQUESTED / BLOCKED` | `changes/<change-id>/ai-test-report.md` | 未确认不得进入测试 / 预发发布 |
| Telemetry | `LOCAL_ONLY / MISSING / DEGRADED` | `.harness/telemetry/events.jsonl` / weekly summary | 仅记录 allowlisted control-plane 事件；原始事件本地 ignored，版本化摘要只能聚合 |
| Pre-merge | `PENDING / PASS / BLOCKED` | `changes/<change-id>/pre-pr.md` | Reviewer 和残余风险收口 |

## Agent Roster

> 运行时可能自动分配不可读 nickname；本表是用户查看子 Agent 职责的权威入口。
> 每次派发、完成、阻塞、复测或因代码变更导致结果 stale 时都必须更新。

| Agent Label | Runtime / Nickname | Role | Scope | Write Scope | Status | Output / Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `<change-id> / Orchestrator / control-plane` | `main-agent` | `Orchestrator` | `流程编排、集成、必要修复、证据记录` | `changes/<change-id>/*` 和明确允许的业务文件 | `ACTIVE / BLOCKED / DONE` | `harness-status.md / evidence.md` |
| `<change-id> / Backend Worker / <scope>` | `<runtime nickname or N/A>` | `Backend Worker` | `<controller/service/mapper/test>` | `<repo/path allowlist or isolated worktree>` | `PENDING / RUNNING / DONE / BLOCKED / STALE` | `<report / test command / changed files>` |
| `<change-id> / Frontend Worker / <scope>` | `<runtime nickname or N/A>` | `Frontend Worker` | `<page/api/router/smoke>` | `<repo/path allowlist or isolated worktree>` | `PENDING / RUNNING / DONE / BLOCKED / STALE` | `<report / lint / screenshot>` |
| `<change-id> / Test Agent / ai-test-plan` | `<runtime nickname or N/A>` | `Test Agent` | `按 confirmed ai-test-plan 独立验收` | `changes/<change-id>/test-agent-verification.md only` | `PENDING / RUNNING / ISSUES_FOUND / GOAL_ACHIEVED / BLOCKED / STALE` | `test-agent-verification.md` |
| `<change-id> / Reviewer Agent / final-readonly-review` | `<runtime nickname or N/A>` | `Reviewer Agent` | `只读审查方案一致性、harness 约束、代码质量、测试证据` | `changes/<change-id>/review.md only` | `PENDING / RUNNING / PASS / BLOCKED / STALE` | `review.md / reviewer-gate` |

## Workstream Dispatch

> 全栈或多仓需求进入业务代码前必填；如无法并行执行，`Agent mode` 写 `DEGRADED: <原因>`，不得静默串行。

| Repo | Scope | Agent mode | Verification | Status |
| --- | --- | --- | --- | --- |
| `<backend-repo>` | `<controller/service/mapper/job>` | `Backend Agent / DEGRADED: <原因>` | `<mvn -pl ... -am ...>` | `READY / IN_PROGRESS / DONE / DEGRADED` |
| `<frontend-repo>` | `<page/api/export>` | `Frontend Agent / DEGRADED: <原因>` | `<npm/lint/build/smoke command>` | `READY / IN_PROGRESS / DONE / DEGRADED` |

## 关键产物

| Artifact | Path / URL | Status |
| --- | --- | --- |
| Spec | `changes/<change-id>/spec.md` | `<status>` |
| Contract | `docs/contracts/<change-id>-api.md` | `<status>` |
| Plan | `changes/<change-id>/plan.md` | `<status>` |
| Agent dispatch plan | `changes/<change-id>/agent-dispatch-plan.md` | `<status>` |
| Business repo bootstrap | `changes/<change-id>/business-repo-bootstrap.md` | `<status>` |
| Technical solution | `changes/<change-id>/technical-solution.md` / `<Feishu URL>` | `<status>` |
| AI test plan | `changes/<change-id>/ai-test-plan.md` | `<status>` |
| Environment readiness | `changes/<change-id>/environment-readiness.md` | `<status>` |
| UI rule checklist | `changes/<change-id>/ui-rule-checklist.md` | `<status>` |
| Verification run report | `changes/<change-id>/verification-run-report.md` | `<status>` |
| Test Agent verification | `changes/<change-id>/test-agent-verification.md` | `<status>` |
| Evidence | `changes/<change-id>/evidence.md` | `<status>` |
| AI test report | `changes/<change-id>/ai-test-report.md` | `<status>` |
| Review | `changes/<change-id>/review.md` | `<status>` |

## 人工确认待办

| Item | Required decision | Owner | Status |
| --- | --- | --- | --- |
| `<确认项>` | `<确认什么，确认后允许进入哪一步>` | `<user/reviewer>` | `PENDING / CONFIRMED / BLOCKED` |

## 残余风险

| Risk | Impact | Accepted? | Follow-up |
| --- | --- | --- | --- |
| `<risk>` | `<impact>` | `yes/no` | `<next step>` |
