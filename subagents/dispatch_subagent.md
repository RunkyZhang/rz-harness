# 子 Agent 派发协议

> 只给 **主 Agent** 读。用于 RZ Harness 在 Cursor / Codex / OpenCode 等 runtime 上派发、展示和回收子 Agent。
> 目标是让用户从 `harness-status.md` 一眼看出每个 Agent 的职责，即使 runtime 分配了不可读 nickname。

本文件不是创建进程的 API。主 Agent 按本协议写好 prompt 后，调用 **runtime 内置派发工具**（Cursor 为 `Task`）开启新 session。不要用 `agent-registry.yml` 去创建 Agent。角色人设在 `subagents/<role>_agent.md`，派发时列入 `Read inputs`，由子 Agent 自己读。

## 1. Agent Label

每个子 Agent 派发 prompt 第一行必须使用固定格式：

```text
Agent Label: <change-id> / <role> / <scope>
```

示例：

```text
Agent Label: promo-sku-unit / Explorer / pre-implementation-facts
Agent Label: promo-sku-unit / Tester / ai-test-plan
Agent Label: promo-sku-unit / Reviewer / final-readonly-review
Agent Label: promo-sku-unit / Backend / Query+Export
```

运行时 nickname 只作为辅助信息。对用户展示、状态卡、evidence、review 输入统一使用 `Agent Label`。

## 2. Prompt 必填项

每个子 Agent prompt 必须明确：

| Field | Required content |
| --- | --- |
| `Agent Label` | `<change-id> / <role> / <scope>` |
| `Role` | 只读默认：`Explorer` / `Reviewer`。方案确认后、实现前：`Test Strategy`。实现后、发布前：`Tester`。候选实现（须契约 v0.1 + 隔离 worktree）：`Backend` / `Frontend` / `Mobile` |
| `Task` | 本次只做什么，不做什么 |
| `Read inputs` | 对应 `subagents/<role>_agent.md`，以及 spec、方案、测试计划、diff 或截图 |
| `Write scope` | 允许写入的文件或 `READ_ONLY` |
| `Forbidden actions` | 禁止改动的路径、禁止真实环境写、禁止回滚用户改动 |
| `Verification` | 必跑命令或明确 N/A 原因 |
| `Output contract` | 结果文件、最终回复格式、状态枚举 |

禁止派发含糊 prompt，例如只写“帮我看看后端”或“做一下前端”。

不要把主会话里的实现辩护、或「不要报这个问题」写进 prompt。子 Agent 默认看不到主对话；磁盘上的 spec / diff 必须写进 `Read inputs` 并让它自己读。

## 3. Final Reply Format

子 Agent 最终回复第一行必须使用：

```text
<Role>: <DONE|PASS|BLOCKED|NEEDS_CONTEXT|ISSUES_FOUND>
```

后续只保留高信号内容：

- 改了哪些文件，或只读确认。
- 跑了哪些命令，结果是什么。
- HIGH / MEDIUM / LOW 或 blockers。
- 仍需主 Agent / 用户处理什么。

## 4. Status Card Mapping

主 Agent 必须把每个子 Agent 写入 `changes/<change-id>/harness-status.md` 的 `Agent Roster`。

状态建议：

| Status | Meaning |
| --- | --- |
| `PENDING` | 已规划但未派发 |
| `RUNNING` | 已派发，未返回 |
| `DONE` | Worker 完成并交付输出 |
| `PASS` | Reviewer / gate 通过 |
| `ISSUES_FOUND` | Tester 或 Reviewer 发现需修复问题 |
| `BLOCKED` | Agent 不能继续，需要主 Agent、用户或环境处理 |
| `STALE` | 代码或方案变化导致既有 Agent 结论失效 |

如果运行时 nickname 不可控，`Runtime / Nickname` 填运行时返回值；`Agent Label` 仍是主键。

## 5. Independence Rules

- Explorer 默认只读，不写业务代码或 harness 控制面。
- Reviewer 只写 `changes/<change-id>/review.md`，不得边 review 边修。
- Test Strategy 只写 `changes/<change-id>/ai-test-plan.md`，不实现业务代码。
- Tester 只写 `test-agent-verification.md` 与终态 `ai-test-report.md`，不得修业务代码。
- Backend / Frontend / Mobile 必须有已确认契约、allowed paths、隔离 worktree；不得写 `main`/`master`；不得当控制面唯一写入者。
- 主 Agent 可以集成和修复，但不能用自己的判断替代 Tester / Reviewer 的裁决。
- 控制面（`changes/`、本仓 harness 文档）默认只允许主 Agent 写。

## 6. Stale Rules

以下情况必须把既有 Agent 结论标记为 `STALE`，并重新走对应验证：

- Tester 后业务代码变化：重新 Tester 验收。
- Reviewer 后业务代码变化：重新 Tester 验收，再重新 Reviewer 和 `scripts/reviewer-gate.sh`。
- 技术方案确认后正文变化且 PRD 来源为飞书：重新 Feishu sync，再跑 `technical-solution-gate.sh`。
- AI test plan 确认后需求范围变化：重新生成或修订 `ai-test-plan.md` 并重新用户确认。

## 7. Minimal Dispatch Template

```text
Agent Label: <change-id> / <role> / <scope>

Role: <role>
Task: <one concrete bounded task>
Read inputs:
- subagents/<role>_agent.md
- <path>
Write scope:
- <READ_ONLY or exact files>
Forbidden actions:
- Do not modify files outside write scope.
- Do not revert user-owned dirty worktree changes.
- Do not access or mutate real SIT/UAT/production state unless explicitly authorized.
Verification:
- <command or N/A reason>
Output contract:
- Write <output path> if applicable.
- Final reply first line: `<Role>: <DONE|PASS|BLOCKED|NEEDS_CONTEXT|ISSUES_FOUND>`.
```
