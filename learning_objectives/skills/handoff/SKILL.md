---
name: sfa-handoff
description: Use when a SFA harness run is long, context is near compaction, work must continue in another thread, or a phase needs a precise handoff before implementation, review, PR, SIT, or retro.
---

# SFA Handoff

> Inspired by Matt Pocock's MIT-licensed `handoff` skill and adapted for this harness. See `skills/third-party/mattpocock-skills.md`.

## 目标

把当前阶段压缩成可继续执行的交接文档，避免新线程重新探索或丢失约束。

## 保存位置

优先写入当前 change：

```text
changes/<change-id>/handoff.md
```

如果还没有 change id，写入：

```text
docs/decision-log/YYYY-MM-DD-handoff-<topic>.md
```

## 必须包含

- 当前目标和阶段。
- 已确认 `[FACT]`。
- 未确认 `[ASSUMP]`。
- 阻塞 `[QUESTION]`。
- 已修改文件。
- 已运行命令和结果。
- 业务仓分支和 worktree 状态。
- 下一步最小动作。
- 禁止动作和受保护路径。

## 输出模板

```markdown
# Handoff：<change-id>

## 当前目标

## 已确认事实

## 未确认假设

## 阻塞问题

## 文件状态

## 验证证据

## 下一步

## 禁止动作
```

## 禁止

- 不把“应该可以”写成完成状态。
- 不省略失败命令。
- 不省略业务仓分支和未提交改动状态。
- 不把 handoff 当成 retro；retro 必须等真实试点完成后写。
