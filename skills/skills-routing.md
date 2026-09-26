# Harness Skill Routing

> `rz-harness/skills/` 是本仓的本地流程 skill。Agent 必须按本路由表显式读取对应 `SKILL.md`，并把使用情况写入 `changes/<change-id>/skill-usage.md` 或 `evidence.md`。
>
> 本文件是 RZ 技能路由正文，lane（尤其 `lanes/fullstack-crud.md`）读这一份。

## 路由表

| 触发场景 | 必读 skill | 读取时机 | 必须产物 |
| --- | --- | --- | --- |
| 复杂需求、跨仓、PRD 拆解、字段/权限/状态不清 | `skills/grill/SKILL.md` | 写 spec / contract 前 | `[FACT] / [ASSUMP] / [QUESTION]` 和用户确认点 |
| 查业务仓样板、入口、调用链、rg 证据 | `skills/explorer/SKILL.md` | 计划或实现前 | 证据路径、样板、不应模仿点 |
| bug、失败、回归、页面/接口异常、用户要求先分析 | `skills/diagnose/SKILL.md` | 提修复方案前 | 复现反馈环、假设、验证结论 |
| 后端行为变更、关键业务逻辑、测试要求 | `skills/tdd/SKILL.md` | 写行为代码前 | `backend-test-plan.md` 或 N/A，targeted test / 验证脚本 |
| Pre-PR、人工 review 前、合并前 | `skills/reviewer/SKILL.md` | 最终结论前 | HIGH / MEDIUM / LOW review 结论 |
| 长会话、上下文压缩、阶段移交、暂停到明天 | `skills/handoff/SKILL.md` | 停止或切线程前 | `handoff.md` 或等价交接记录 |
| 飞书 / Lark Wiki 节点、PRD Wiki 链接、知识库节点 | `feishu-cli` skill | 读取或写入前 | Wiki 节点解析、space/node 信息、证据记录 |
| 飞书 / Lark Docx/Wiki 文档正文读取、更新、创建 | `feishu-cli` skill | 读取或写入文档正文前 | 文档正文、outline、block/section 证据、写入回读 |

## 外部辅助 Lens

| 触发场景 | 可读参考 | 使用边界 |
| --- | --- | --- |
| Pre-PR、架构债、测试质量或技术债 | RZ 未引入 `skills/third-party/` → N/A | 不得用外部 lens 替代上表 harness skill |
| harness 工程能力、observability、验证闭环参考 | RZ 未引入 ECC → N/A | — |

## 使用规则

1. 命中场景时，先读对应 `SKILL.md`，再执行动作；不要只读 `AGENTS.md` / `rules`。
2. 多个场景同时命中时，顺序是 `grill -> explorer -> tdd/diagnose -> reviewer -> handoff`。
3. 如果决定某个 skill 不适用，必须在 `skill-usage.md` 写 N/A 原因。
4. `skills/explorer` 是只读，不允许借探索名义改文件。
5. `skills/reviewer` 是只读，不允许边 review 边修。Reviewer 子 Agent 只写 `changes/<change-id>/review.md`。
6. 外部 superpowers / Codex skill 可以辅助，但不能替代本仓 harness skill 的使用记录。
7. `brooks-review` / `brooks-sweep` 等外部 auto-fix 流程 RZ 默认不走。
8. 凡涉及飞书文档正文或 Wiki PRD 的操作，使用 `feishu-cli` skill 读取/写入并回读验证。

## 最小记录格式

复制 `templates/skill-usage.md` 到：

```text
changes/<change-id>/skill-usage.md
```

合并前运行：

```bash
gates/skill-usage-gate.sh changes/<change-id>
```
