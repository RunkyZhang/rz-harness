# Harness Skill Routing

> `sfa-ai-harness/skills/` 是本仓的本地流程 skill，不一定会进入 Codex 全局 skill registry。Agent 必须按本路由表显式读取对应 `SKILL.md`，并把使用情况写入 `changes/<change-id>/skill-usage.md` 或 `evidence.md`。

## 路由表

| 触发场景 | 必读 skill | 读取时机 | 必须产物 |
| --- | --- | --- | --- |
| 复杂需求、跨仓、PRD 拆解、字段/权限/状态不清 | `skills/grill/SKILL.md` | 写 spec / contract 前 | `[FACT] / [ASSUMP] / [QUESTION]` 和用户确认点 |
| 查业务仓样板、入口、调用链、CodeGraph / rg 证据 | `skills/explorer/SKILL.md` | 计划或实现前 | 证据路径、样板、不应模仿点 |
| bug、失败、回归、页面/接口异常、用户要求先分析 | `skills/diagnose/SKILL.md` | 提修复方案前 | 复现反馈环、假设、验证结论 |
| 后端行为变更、关键业务逻辑、测试要求 | `skills/tdd/SKILL.md` | 写行为代码前 | `backend-test-plan.md` 或 N/A，targeted test / 验证脚本 |
| Pre-PR、人工 review 前、合并前 | `skills/reviewer/SKILL.md` | 最终结论前 | HIGH / MEDIUM / LOW review 结论 |
| 长会话、上下文压缩、阶段移交、暂停到明天 | `skills/handoff/SKILL.md` | 停止或切线程前 | `handoff.md` 或等价交接记录 |
| 飞书 / Lark Wiki 节点、PRD Wiki 链接、知识库节点创建/查询/层级操作 | `/Users/00555733/.agents/skills/lark-wiki/SKILL.md` | 读取或写入 Wiki 节点前 | Wiki 节点解析、space/node 信息、证据记录 |
| 飞书 / Lark Docx/Wiki 文档正文读取、更新、创建、素材读取 | `/Users/00555733/.agents/skills/lark-doc/SKILL.md` | 读取或写入文档正文前 | 文档正文、outline、block/section 证据、写入回读 |

## 外部辅助 Lens

| 触发场景 | 可读参考 | 使用边界 |
| --- | --- | --- |
| Pre-PR、架构债、测试质量、技术债或外部 Codex skill 取舍 | `skills/third-party/external-codex-skills.md` | 只作为 `skills/reviewer/SKILL.md` 的辅助 lens；不能替代 harness-local skill 和 `skill-usage.md` |
| harness 工程能力、adapter、observability、验证闭环参考 | `skills/third-party/ecc-skills.md` | 只作为 optional ECC sidecar lens；ECC 缺失不得阻断普通 harness 使用 |

## 使用规则

1. 命中场景时，先读对应 `SKILL.md`，再执行动作；不要只读 `AGENTS.md` / `rules`。
2. 多个场景同时命中时，顺序是 `grill -> explorer -> tdd/diagnose -> reviewer -> handoff`。
3. 如果决定某个 skill 不适用，必须在 `skill-usage.md` 写 N/A 原因。
4. `skills/explorer` 是只读，不允许借探索名义改文件。
5. `skills/reviewer` 是只读，不允许边 review 边修。
6. 外部 superpowers / Codex skill 可以辅助，但不能替代本仓 harness skill 的使用记录。
7. 使用 `brooks-review` / `brooks-test` 等外部 lens 时，只归并 findings；禁止启用 `brooks-sweep` 或其他 auto-fix 流程。
8. 凡涉及飞书文档正文或 Wiki PRD 的操作，必须使用 `/Users/00555733/.agents/skills/lark-doc` 和 `/Users/00555733/.agents/skills/lark-wiki` 的技能说明；不要回退到 `.codex/skills` 下的同名或旧版路径。读取 Wiki PRD 时，先用 `lark-wiki` 解析节点，再用 `lark-doc` 读取正文；写入技术方案子文档时同样按这两个技能执行并回读验证。

## 最小记录格式

复制 `templates/skill-usage.md` 到：

```text
changes/<change-id>/skill-usage.md
```

合并前运行：

```bash
scripts/skill-usage-gate.sh changes/<change-id>
```
