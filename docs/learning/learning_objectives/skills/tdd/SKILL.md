---
name: sfa-tdd
description: Use when a SFA feature or bugfix has testable behavior, critical business logic, risky branching, or the user asks for tests, regression coverage, or test-first work.
---

# SFA TDD

> Adapted for this harness from Matt Pocock's MIT-licensed `tdd` skill. See `skills/third-party/mattpocock-skills.md`.

## 目标

用最小行为切片建立测试反馈，避免一次写完一堆测试或一堆实现。

## 适用场景

- 后端业务规则、校验、状态判断、字段映射。
- 前端复杂表单、列表筛选、空态、错误态。
- bugfix 需要回归测试锁定。
- 用户明确要求测试先行。

## 原则

- 测试行为，不测试实现细节。
- 尽量通过公开接口、Controller、service API 或页面可观察行为验证。
- 一次只写一个行为测试，再写刚好能通过的实现。
- 不为了覆盖率写低价值测试。

## 每轮循环

1. 选一个最小行为。
2. 写一个失败测试或可失败的验证脚本。
3. 运行并确认失败原因正确。
4. 写最小实现。
5. 运行并确认通过。
6. 记录命令到 `changes/<change-id>/evidence.md`。

## SFA 后端优先测试点

- request 校验。
- response 字段映射。
- 权限/状态/错误码。
- 空数据、重复数据、边界日期、分页。
- 与旧逻辑保持一致的业务规则。

## SFA 前端优先测试点

- `src/api` 参数和响应映射。
- loading、空态、错误态。
- 表单校验和提交中状态。
- 列表筛选、分页、默认排序。

## 禁止

- 不写“想象中”的大批量测试。
- 不测试 private method 或纯内部形状。
- 不在 RED 状态重构。
- 不把没有验证过的测试当作证据。
