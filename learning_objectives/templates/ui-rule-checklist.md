# UI Rule Checklist：<change-id>

> PRD UI / 交互编码前的规则对齐清单。复杂 UI 或用户提供截图/交互图的需求必须填写。
> 目标是避免 Agent 在规范未覆盖处自行发挥。

## 状态

```yaml
ui_rule_status: PENDING
owner: -
updated_at: -
rule_gap_status: PENDING
prd_screen_breakdown_status: PENDING
```

`ui_rule_status` 可选值：`PENDING` / `READY` / `BLOCKED` / `NOT_APPLICABLE`。
`rule_gap_status` 可选值：`NONE` / `CONFIRMED` / `BLOCKED` / `NOT_APPLICABLE`。
`prd_screen_breakdown_status` 可选值：`READY` / `PENDING` / `BLOCKED` / `NOT_APPLICABLE`。

## 规则与基线

| Item | Path / URL | Status | Notes |
| --- | --- | --- | --- |
| PRD UI source | `<PRD screenshot / Feishu image / prototype>` | `READ / BLOCKED / N/A` |  |
| Online baseline | `<online screenshot / route / app path>` | `CAPTURED / BLOCKED / N/A` |  |
| Harness rule pack | `<rules/...>` | `READ / BLOCKED / N/A` |  |
| Existing page sample | `<repo path / URL>` | `READ / BLOCKED / N/A` |  |

## PRD 截图逐屏拆解表

> 每张 PRD 截图或原型状态一行。没有截图或不涉及 UI 时，`prd_screen_breakdown_status: NOT_APPLICABLE` 并写 `N/A:` 原因。

| Screenshot ID | PRD screenshot reference | Area breakdown | Target skeleton / class mapping | Difference from sample | Decision | Status |
| --- | --- | --- | --- | --- | --- | --- |
| UI-001 | `<Feishu image / prototype state / N/A: reason>` | `<header/search/table/action/pagination/...>` | `<existing class/component/sample path>` | `<PRD 特有差异>` | `<reuse / user-confirmed deviation / N/A>` | `READY / CONFIRMED / BLOCKED / N/A` |

## UI 规范映射

| UI / Interaction | PRD expectation | Harness rule / baseline | Covered by rule? | Decision |
| --- | --- | --- | --- | --- |
| `<组件/布局/交互>` | `<PRD 要求>` | `<规则或线上基线>` | `yes/no` | `<实现口径/用户确认>` |

## 规范缺口

| Gap ID | Gap | Options considered | User decision | Status |
| --- | --- | --- | --- | --- |
| UIG-001 | `<规范未覆盖点>` | `<可选实现>` | `<用户确认>` | `CONFIRMED / BLOCKED` |

## 验收截图计划

| Screenshot | State | Purpose | Target path |
| --- | --- | --- | --- |
| `<截图名>` | `<页面状态>` | `<证明什么>` | `artifacts/<change-id>/ui/...` |

## Side-by-side 验收证据计划

| Screenshot ID | PRD screenshot | Implementation screenshot target | Difference marker | Status |
| --- | --- | --- | --- | --- |
| UI-001 | `<PRD screenshot>` | `artifacts/<change-id>/ui/ui-001-impl.png` | `<差异标注方式>` | `PLANNED / CAPTURED / N/A` |
