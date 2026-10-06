---
id: SFA-PIT-NNN
type: pitfall
title: <一句话故障模式，例：广告/订单预算高并发下超扣>
domain: <业务域，例：order / distribution / pricing / inventory / appraisal>
maturity: draft        # draft | verified | proven
sources:
  - <来源：change-id / PRD 链接 / 线上故障单 / 用户确认>
last_referenced: <YYYY-MM-DD 或 never>
referenced_by:
  - <引用过本条的 change-id>
tags:
  - <并发 / 边界 / 状态机 / 兼容性 ...>
---

# <标题>

## 现象

[FACT] 在什么场景、什么输入 / 时间窗口下，出现什么错误行为。

## 根因

[FACT] 为什么会发生（因果链）。来源必须可追溯：change / 故障单 / 代码 / 用户确认。

## 触发条件

- 入口：<哪个接口 / 页面 / 任务>
- 数据状态：<什么数据组合>
- 时间 / 并发窗口：<是否只在高并发 / 特定时段成立>

## 规避做法

[FACT] 怎么改才能避免。能链到 `rules/` 或 `docs/samples/` 的具体样板更好。

## 排查步骤

1. <定位用的日志 key / trace / SQL>
2. ...

## 关联

- 相关 decision：<decision-log 链接>
- 相关 guideline：<rules / standards 链接>
- 相关样板：<docs/samples 链接>
