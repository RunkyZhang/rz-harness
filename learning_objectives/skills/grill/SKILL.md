---
name: sfa-grill
description: Use when a SFA requirement, CRUD pilot, API contract, business term, state, permission, field, or rollout risk is unclear before writing code or finalizing a spec.
---

# SFA Grill

> Adapted for SFA harness from Matt Pocock's MIT-licensed `grill-with-docs` idea. See `skills/third-party/mattpocock-skills.md`.

## 目标

把模糊需求问清楚，并把结论写回 `changes/<change-id>/spec.md`。能从代码和文档查证的问题先查证，不能查证的问题再问用户。

## 输入

- `change-id`
- 用户原始需求 / PRD / 飞书链接
- 目标仓库或候选仓库

## 流程

1. **读入口**
   - `AGENTS.md`
   - `docs/domain-glossary.md`
   - `docs/architecture/repo-registry.md`
   - 当前 `changes/<change-id>/spec.md`
2. **先查证**
   - 能通过代码、baseline、contract、PRD 查到的，不问用户。
   - 查到的只写 `[FACT]`，并带来源。
3. **术语澄清**
   - 如果用户词语和 `docs/domain-glossary.md` 冲突，先指出冲突。
   - 新术语只在用户确认后写入 glossary。
4. **逐个问题追问**
   - 一次只问一个阻塞问题。
   - 每个问题必须给默认建议和影响。
5. **写回 spec**
   - 已确认项移入 `[FACT]`。
   - 未确认推断放入 `[ASSUMP]`。
   - 阻塞项保留 `[QUESTION]`。

## 优先追问的问题

- 业务对象是什么？
- 入口用户是谁，在哪个页面操作？
- 列表、详情、新增、编辑、删除分别是否需要？
- 字段含义、默认值、必填、枚举、空态、错误码是什么？
- 是否涉及 DB schema、权限、状态机、MQ、定时任务、生产配置？
- 最小回滚方式是什么？

## 输出格式

```markdown
## 已查证事实
- [FACT] ... 来源：`path:line`

## 需要你拍板
1. 问题：
   - 默认建议：
   - 影响：

## 写回 spec 的变更
- `[FACT] ...`
- `[ASSUMP] ...`
- `[QUESTION] ...`
```

## 禁止

- 不直接写业务代码。
- 不一次抛出长问题列表。
- 不把默认建议写成用户已确认事实。
- 不修改 `docs/domain-glossary.md`，除非术语已被用户确认。
