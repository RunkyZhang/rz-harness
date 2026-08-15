# Implementation Decision Matrix：<change-id>

> Tier M/L 变更必填。任何会进入代码、SQL、接口、权限、状态机、默认值、adapter、capability / behavior spec 或回滚的决定都必须列出来源。

| Decision | Category | Source | Status | Can enter code? | Notes |
| --- | --- | --- | --- | --- | --- |
| [QUESTION] | business / API / DB / permission / status / error / SQL / adapter / capability-spec / rollback | PRD / 用户确认 / 现有代码 / contract | FACT / ASSUMP / QUESTION | Yes / No | [QUESTION] |

## Rules

- `Status=FACT` 才能 `Can enter code?=Yes`。
- `Status=ASSUMP` 或 `Status=QUESTION` 必须 `Can enter code?=No`。
- `Source` 不能只写“AI 推断”。
- SQL ID、枚举值、字段默认值、错误码、状态值和权限边界必须逐项列出。
- 如果实现中新增了矩阵外的决定，先更新矩阵和 spec，再继续代码。
