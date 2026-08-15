# SFA Pitfalls 已知坑库

> 这里沉淀 SFA 领域的 **pitfall（已知坑 / 故障模式 / 排查步骤）** 类知识——也就是"因果型 / 时空型"经验，是团队最难从模型获得、最值钱的护城河知识。
>
> 这是 Layer-B 分类清单（catalog）：每条一行摘要，按需再点进完整条目。完整条目按 `docs/pitfalls/TEMPLATE.md` 格式写。

## 为什么单独建库

`docs/` 其他位置覆盖了别的知识类型，唯独 pitfall 没有家：

| 知识类型 | 存放位置 |
| --- | --- |
| model（实体 / 术语 / 数据结构） | `docs/domain-glossary.md`、`docs/data-models/` |
| decision（技术选型 / 架构决策） | `docs/decision-log/` |
| guideline（推荐 / 禁止做法） | `rules/*.mdc`、`docs/standards/` |
| process（业务流程 / 状态机） | `lanes/`、契约文档 |
| **pitfall（已知坑 / 故障模式）** | **`docs/pitfalls/`（本目录）** |

## 命名与编号

- 文件名：`SFA-PIT-<NNN>-<short-slug>.md`（例：`SFA-PIT-001-order-concurrent-overdeduct.md`）。
- 每条 pitfall 只描述一个故障模式，遵循 MECE。

## 条目索引

| ID | 标题 | 领域 | 成熟度 | 最近引用 |
| --- | --- | --- | --- | --- |
| `SFA-PIT-001` | `mapSystem` 在高版本 Node 下启动失败 | `frontend-map-system` | `verified` | 2026-06-02 |
| `SFA-PIT-002` | `mapSystem` 登录必须先触发账号 blur 加载产品组 | `frontend-map-system` | `verified` | 2026-06-02 |
| `SFA-PIT-003` | `mapSystem` 新页面未挂临时路由会跳首页 | `frontend-map-system` | `verified` | 2026-06-02 |
| `SFA-PIT-004` | CodeGraph 自然语言查询 API route 可能命中无关符号 | `harness-codegraph` | `verified` | 2026-06-08 |

## 维护规则

- 新增条目时在上表追加一行，保持 catalog 与文件同步。
- 成熟度与衰减元数据约定见 `docs/decision-log/2026-05-29-knowledge-lifecycle.md`。
- 条目被某次 change 引用后，更新该条 `last_referenced`，并按需提升 `maturity`。
