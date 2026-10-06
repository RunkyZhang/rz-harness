# Changes Retention Policy

> 目的：控制 `changes/` 的长期体积，让它保留可审计事实，而不是变成过程数据堆。

## 适用范围

本策略适用于所有 `changes/<change-id>/` 目录、PC E2E Smoke 产物、复杂 UI HTML 原型、验证日志、截图、录屏和 Reviewer / 人工验收材料。

## 设计原则

- `changes/` 是当前变更的事实源，不是无限期保存所有中间过程的仓库。
- Git 长期保存可 review、可审计、可复用的 Markdown 摘要。
- 大文件、重复截图、原始日志、录屏、临时草稿和多版本原型默认不进 Git。
- AI 默认只读取当前 active change；历史 change 只能按 change-id、接口、模块、字段或明确问题定向检索。
- 已归档 change 不作为默认上下文，除非用户或当前任务明确引用。

## 必须提交到 Git

每个业务 change 默认只提交以下轻量文件：

| 文件 | 用途 |
| --- | --- |
| `changes/<change-id>/spec.md` | 事实、范围、问题、允许路径 |
| `changes/<change-id>/plan.md` | 已确认实施步骤、验证和停点 |
| `changes/<change-id>/evidence.md` | 精简命令证据、结果和阻塞摘要 |
| `changes/<change-id>/review.md` | Reviewer 结论和风险处理 |
| `changes/<change-id>/pre-pr.md` | PR 前自审和残余风险 |
| `changes/<change-id>/retro.md` | 有复盘价值时保留 |
| `changes/<change-id>/contract-delta.md` | 并行开发发生契约变更时保留 |
| `changes/<change-id>/pc-e2e-smoke-report.md` | 只保留浏览器冒烟摘要、截图路径和结论 |

契约文档继续放在 `docs/contracts/<change-id>-api.md`。

## 不提交到 Git

以下内容默认放到 `artifacts/<change-id>/`、CI artifact、对象存储或飞书附件：

- 截图、录屏、HAR、trace、coverage、浏览器缓存。
- Maven / npm / Playwright / 浏览器自动化完整原始日志。
- 临时 HTML 原型的多个版本和草稿。
- 大型数据快照、导出 Excel、SQL dump、接口全量响应。
- 重复失败尝试的长输出。

Git 中只记录这些产物的路径、摘要、关键错误、最终结论和是否影响人工验收。

## 原型与截图规则

- 复杂 UI 原型的“确认版”可以提交到 `changes/<change-id>/prototype/`，但草稿、多版本和大体积资源放到 `artifacts/<change-id>/prototype/`。
- PC E2E Smoke 截图默认放到 `artifacts/<change-id>/pc-e2e-smoke/`，report 中记录路径和用途。
- 如某张截图必须随 PR 长期保留，应说明原因，并控制数量。

## Evidence 写法

`evidence.md` 记录可复核摘要，不粘贴完整长日志。

推荐格式：

```text
Command: <exact command>
Result: PASS / FAIL / BLOCKED
Summary: <关键输出 1-5 行>
Artifact: artifacts/<change-id>/<file> 或外部链接
Impact: <是否阻塞人工验收 / PR>
```

如果命令输出很长，只保留关键错误和 artifact 路径。

## 归档策略

| 状态 | 处理 |
| --- | --- |
| active | 保留在 `changes/<change-id>/`，AI 必须读取 |
| merged / shipped | 保留精简 Markdown，删除或外移大文件和草稿 |
| abandoned | 保留 `spec.md`、`evidence.md` 中的放弃原因，其余草稿可删除 |
| historical reference | 如确有复用价值，沉淀到 `docs/decision-log/`、`docs/samples/` 或规则 / 模板 |

不建议让 `docs/README.md` 长期列出所有历史 change；只列 active、template-level 或有复用价值的 change。

## AI 检索规则

AI 工作时按下面顺序读上下文：

1. 当前 `changes/<change-id>/`。
2. 当前 lane、template、rule 和 contract。
3. `docs/architecture/repo-registry.md` 和对应 baseline。
4. 只有在需要找历史样板或用户明确要求时，才用 `rg` 定向检索历史 `changes/`。

禁止默认全量读取所有 `changes/` 作为上下文。

## 团队规模口径

当多人使用时，`changes/` 应该像 PR 审计索引，而不是日志仓库。每天大量需求只应增加少量 Markdown 摘要；截图、原始日志和临时文件的增长必须从 Git 中隔离出去。
