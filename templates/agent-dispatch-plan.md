# Agent Dispatch Plan：<change-id>

> 由主 Agent 填写。RZ 不使用标本的 `agent-dispatch-plan.sh` / `agent-registry.yml`。
> 派发前对照 `subagents/dispatch_subagent.md`；角色人设在 `subagents/<role>_agent.md`。
> 不派某个角色时，Status 写 `N/A` 并在备注写原因。本文件不是创建进程的 API。

```yaml
change_id: <change-id>
plan_status: PENDING
runtime: cursor
```

`plan_status` 可选值：`PENDING` / `READY` / `N/A`。

## Planned Agents

| Agent Label | Role | Scope | Read inputs | Write scope | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `<change-id> / Explorer / pre-implementation-facts` | Explorer | 方案或实现前只读查证 | `subagents/explorer_agent.md`、`spec.md` | `READ_ONLY` | `PENDING / N/A` |  |
| `<change-id> / Test Strategy / ai-test-plan` | Test Strategy | 方案确认后写测试方案 | `subagents/test_strategy_agent.md`、方案、契约 | `ai-test-plan.md` | `PENDING / N/A` | 主 Agent 不得代写 |
| `<change-id> / Tester / ai-test-plan` | Tester | 对照已确认测试方案独立验收 | `subagents/tester_agent.md`、`ai-test-plan.md` | `test-agent-verification.md` only | `PENDING / N/A` | 主 Agent 不得代裁 |
| `<change-id> / Reviewer / final-readonly-review` | Reviewer | 人审 / PR 前只读审查 | `subagents/reviewer_agent.md`、diff、evidence | `review.md` only | `PENDING / N/A` | 主 Agent 不得代裁 |
| `<change-id> / Backend / <scope>` | Backend | 隔离 worktree 后端实现 | `subagents/backend_agent.md`、契约 | 允许路径 | `N/A / PENDING` | 须 `agent-candidate-confirmation.md` |
| `<change-id> / Frontend / <scope>` | Frontend | 隔离 worktree 前端实现 | `subagents/frontend_agent.md`、契约只读 | 允许路径 | `N/A / PENDING` | 须 `agent-candidate-confirmation.md` |
| `<change-id> / Mobile / <scope>` | Mobile | 隔离 worktree 移动端实现 | `subagents/mobile_agent.md` | 允许路径 | `N/A / PENDING` | 须 `agent-candidate-confirmation.md` |

## 派发约束

- 每个子 Agent prompt 第一行：`Agent Label: <change-id> / <role> / <scope>`。
- 子 Agent 最终回复第一行：`<role>: <DONE|PASS|BLOCKED|NEEDS_CONTEXT|ISSUES_FOUND>`。
- 主 Agent 把同一标签写入 `harness-status.md` 的 Agent Roster。
- 控制面默认只允许主 Agent 写。
- 派 Backend / Frontend / Mobile 前须契约 v0.1、`allowed_paths`、隔离 worktree，以及用户确认后的 `agent-candidate-confirmation.md`。
