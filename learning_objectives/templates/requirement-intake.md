# Requirement Intake：<change-id>

> Tier M/L 或高风险需求在 spec/solution 前使用。目标不是多写文档，而是把 PRD 原文、信息缺口和用户确认点逐条摊开，避免 AI 用先验补业务规则。

```yaml
requirement_intake_status: PENDING
prd_item_count: 0
key_questions_complete: no
blocking_questions_status: OPEN
owner: Orchestrator
updated_at: -
```

`requirement_intake_status` 可选值：

- `PENDING`：仍在拆解 PRD 或追问。
- `READY`：PRD 条目已逐条编号，六类关键问题已回答或标为已解决问题。
- `BLOCKED`：存在未解决阻塞问题。

## PRD 逐条编号表

| ID | PRD item | Source | Classification | Status |
| --- | --- | --- | --- | --- |
| PRD-001 | `<逐条写 PRD 页面/字段/验收项，不整段概括>` | `<飞书章节 / 用户原话 / 截图编号>` | `[FACT] / [ASSUMP] / [QUESTION]` | `READY / RESOLVED / BLOCKED` |

## 六类关键问题

| Category | Answer / Source | Status |
| --- | --- | --- |
| 业务对象 | `<对象、主键、归属口径>` | `READY / RESOLVED / BLOCKED` |
| 入口和角色 | `<入口、菜单、端、角色、权限来源>` | `READY / RESOLVED / BLOCKED` |
| CRUD 范围 | `<新增/查询/编辑/删除/导入/导出/只读>` | `READY / RESOLVED / BLOCKED` |
| 字段口径 | `<默认值、必填、枚举、空态、错误码、排序、分页>` | `READY / RESOLVED / BLOCKED` |
| DB/权限/状态机/MQ/job 涉及面 | `<DB 表、权限、状态迁移、MQ、job、缓存、配置>` | `READY / RESOLVED / BLOCKED` |
| 最小回滚 | `<代码回滚、配置回滚、数据清理、开关关闭>` | `READY / RESOLVED / BLOCKED` |

## 质疑记录

| Question | User answer | Status |
| --- | --- | --- |
| `<本次向用户提出的问题>` | `<用户答复原文或 N/A: 无需提问原因>` | `RESOLVED / OPEN / BLOCKED` |

## Gate

```bash
scripts/requirement-intake-gate.sh changes/<change-id>
```
