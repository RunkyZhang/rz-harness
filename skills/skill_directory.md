# Skill 字典目录（skills/skill_directory.md）

> 本仓 skill 的查找表和使用规则。命中场景先读对应 `SKILL.md`，再动手。不要只读 `AGENTS.md` 或 `rules/`。
> 用过或判定不适用的，写入 `changes/<change-id>/skill-usage.md`（没有这条文件时也可记 `evidence.md`）。不适用必须写 N/A 原因。合并前跑 `gates/skill-usage-gate.sh changes/<change-id>`。

| skill | 路径 | 何时读 | 产出 |
|---|---|---|---|
| grill | `skills/grill/SKILL.md` | 复杂需求、跨仓、PRD 拆解、字段 / 权限 / 状态不清；写 spec / contract 前 | `[FACT]` / `[ASSUMP]` / `[QUESTION]` 和用户确认点 |
| explorer | `skills/explorer/SKILL.md` | 查业务仓样板、入口、调用链；计划或实现前。只读，不得借探索改文件 | 证据路径、样板、不应模仿点 |
| diagnose | `skills/diagnose/SKILL.md` | bug、失败、回归、页面 / 接口异常；提修复方案前 | 复现反馈环、假设、验证结论 |
| tdd | `skills/tdd/SKILL.md` | 后端行为变更、关键业务逻辑；写行为代码前 | `backend-test-plan.md` 或 N/A，targeted test |
| reviewer | `skills/reviewer/SKILL.md` | Pre-PR、人工 review 前。只读，不改业务代码。Reviewer 子 Agent 只写 `review.md` | HIGH / MEDIUM / LOW |
| handoff | `skills/handoff/SKILL.md` | 长会话、上下文压缩、换线程、暂停到明天 | `handoff.md` 或等价交接 |

多个场景同时命中时的顺序：`grill` → `explorer` → `tdd` / `diagnose` → `reviewer` → `handoff`。

飞书 Wiki / 文档的读、写和回读用 `feishu-cli`，不在本目录。`skills/third-party/` 和 ECC 未引入，外部 lens 记 N/A，不得代替上表 skill，也不得走 `brooks-sweep` 这类自动改代码的流程。
