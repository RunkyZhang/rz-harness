# 决策账本：<change-id>

> 实现中途冒出的、需要人类异步拍板的 BLOCKING 决策点登记在此。
> 用法：Agent 把待决项记为 `status: pending` 后，继续做**不依赖该决策**的工作；人类异步在本文件填决策；合并前 `scripts/decision-gate.sh` 校验无遗留 `pending`。
> spec 阶段的 `[QUESTION]` 仍由 `scripts/confidence-gate.sh` 管，不要重复登记。
>
> 字段说明：
> - `status`: `pending` | `approved` | `rejected`
> - `default`: 在未决期间采用的 fail-closed 默认（通常最保守 / 不前进）
> - `decided_by` / `decided_at`: 拍板人与日期，未决时填 `-`

## DEC-<change-id>-001

- status: pending
- question: <一句话决策点，例：list 默认排序是否纳入新增字段 priority？>
- options: <A / B / C>
- default: <未决期间采用的保守默认>
- requested_at: <YYYY-MM-DD>
- decided_by: -
- decided_at: -
- note: <补充上下文 / 链接>

<!-- 复制上面的块追加更多决策；编号递增。 -->
