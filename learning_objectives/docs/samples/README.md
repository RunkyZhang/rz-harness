# SFA Samples 可模仿样板库

> 记录"可模仿的代码样板"索引，**不直接复制业务代码**。每条样板按 `docs/samples/TEMPLATE.md` 写：repo id、file path、适合模仿的点、不应模仿的点、适用 lane。
>
> 这是 Layer-B 分类清单（catalog）：每条一行摘要，按需点进完整条目。

## 条目索引

| ID | 标题 | repo | 适用 lane | 成熟度 | 最近引用 |
| --- | --- | --- | --- | --- | --- |
| _(empty)_ | 第一条样板由首个真实 change 的 ARCHIVE 阶段产生 | - | - | - | - |

## 维护规则

- 新增条目时在上表追加一行，保持 catalog 与文件同步。
- 成熟度与衰减元数据约定见 `docs/decision-log/2026-05-29-knowledge-lifecycle.md`。
- 样板被某次 change 引用后，更新该条 `last_referenced`，并按需提升 `maturity`。
