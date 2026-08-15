# Subagent Dispatch Standard

> 用于 SFA harness 中 Codex / OpenCode / 其它运行时子 Agent 的派发、展示和结果回收。
> 目标是让用户从 `harness-status.md` 一眼看出每个 Agent 的职责，即使运行时自动分配了不可读 nickname。

## 1. Agent Label

每个子 Agent 派发 prompt 第一行必须使用固定格式：

```text
Agent Label: <change-id> / <role> / <scope>
```

示例：

```text
Agent Label: terminal-wechat-bind-query / Backend Worker / Query+Export
Agent Label: terminal-wechat-bind-query / Frontend Worker / Page+SourceJumps
Agent Label: terminal-wechat-bind-query / Test Agent / ai-test-plan
Agent Label: terminal-wechat-bind-query / Reviewer Agent / final-readonly-review
```

运行时 nickname 只作为辅助信息。对用户展示、状态卡、evidence、review 输入统一使用 `Agent Label`。

## 2. Prompt 必填项

每个子 Agent prompt 必须明确：

| Field | Required content |
| --- | --- |
| `Agent Label` | `<change-id> / <role> / <scope>` |
| `Role` | `Explorer / Backend Worker / Frontend Worker / Test Agent / Reviewer Agent / Fix Agent` |
| `Task` | 本次只做什么，不做什么 |
| `Read inputs` | 必读文件、方案、测试计划、diff 或截图 |
| `Write scope` | 允许写入的文件或 `READ_ONLY` |
| `Forbidden actions` | 禁止改动的路径、禁止真实环境写、禁止回滚用户改动 |
| `Verification` | 必跑命令或明确 N/A 原因 |
| `Output contract` | 结果文件、最终回复格式、状态枚举 |

禁止派发含糊 prompt，例如只写“帮我看看后端”或“做一下前端”。

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

Orchestrator 必须把每个子 Agent 写入 `changes/<change-id>/harness-status.md` 的 `Agent Roster`。

状态建议：

| Status | Meaning |
| --- | --- |
| `PENDING` | 已规划但未派发 |
| `RUNNING` | 已派发，未返回 |
| `DONE` | Worker 完成并交付输出 |
| `PASS` | Reviewer / gate 通过 |
| `ISSUES_FOUND` | Test Agent 或 Reviewer 发现需修复问题 |
| `BLOCKED` | Agent 不能继续，需要主 Agent、用户或环境处理 |
| `STALE` | 代码或方案变化导致既有 Agent 结论失效 |

如果运行时 nickname 不可控，`Runtime / Nickname` 填运行时返回值；`Agent Label` 仍是主键。

## 5. Independence Rules

- Explorer 默认只读，不写业务代码或 harness 控制面。
- Test Agent 只写 `changes/<change-id>/test-agent-verification.md`，不得修业务代码。
- Reviewer Agent 只写 `changes/<change-id>/review.md`，不得边 review 边修。
- Implementation Agent 必须有 confirmed contract、allowed paths、隔离 worktree 或明确写入边界；不得写主分支。
- Orchestrator 可以集成和修复，但不能用自己的判断替代 Test Agent / Reviewer Agent verdict。

## 6. Stale Rules

以下情况必须把既有 Agent 结论标记为 `STALE`，并重新走对应验证：

- Test Agent 后业务代码变化：重新 Test Agent verification。
- Reviewer Agent 后业务代码变化：重新 Test Agent verification，再重新 Reviewer Agent 和 `scripts/reviewer-gate.sh`。
- 技术方案确认后正文变化且 PRD 来源为飞书：重新 Feishu sync，再跑 `technical-solution-gate.sh`。
- AI test plan 确认后需求范围变化：重新生成或修订 `ai-test-plan.md` 并重新用户确认。

## 7. Minimal Dispatch Template

```text
Agent Label: <change-id> / <role> / <scope>

Role: <role>
Task: <one concrete bounded task>
Read inputs:
- <path>
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
