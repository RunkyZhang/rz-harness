# pitfalls/ —— 团队已知坑条目

这里存放**踩过的坑 / 故障模式**，让经验从单个 change 里沉淀回团队知识库，而不是随变更包删除。

## 什么时候写

- 收口（retro / pre-pr）时，如果这次需求踩到了值得记住的坑（并发、边界、状态机、兼容性、环境等），就记一条。
- 没有条目就在 `pre-pr.md` 里写 `N/A`，不要硬凑。

## 怎么建条目

复制 `templates/pitfalls_TEMPLATE.md`，在本目录下新建 `RZ-PIT-<NNN>.md`（例如 `RZ-PIT-001.md`），按模板填：

- `现象` / `根因` / `触发条件` / `规避做法` / `排查步骤` / `关联`。
- 每条结论必须可追溯（来源：change-id / PRD / 线上故障单 / 用户确认）。
- `maturity`：`draft` → `verified` → `proven`。

`gates/knowledge-reference-gate.sh` 会按每条文件里顶格的 `id: RZ-PIT-<NNN>` 解析引用。

## 索引

| id | 标题 | 状态 |
|---|---|---|
| （暂无条目） |  |  |

> 本目录是"给人看的团队知识"，不是变更包内的产物。变更包里的 `evidence.md` 只记本次命令痕迹，不要混用。
