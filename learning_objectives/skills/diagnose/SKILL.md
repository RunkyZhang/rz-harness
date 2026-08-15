---
name: sfa-diagnose
description: Use when a SFA task reports a bug, failing behavior, regression, intermittent issue, performance problem, or "先分析/定位原因" before implementation.
---

# SFA Diagnose

> Adapted for this harness from Matt Pocock's MIT-licensed `diagnose` skill. See `skills/third-party/mattpocock-skills.md`.

## 目标

先建立可复现、可验证的反馈环，再定位原因。没有反馈环，不进入修复。

## 适用场景

- 用户说“先分析原因”“定位问题”“为什么失败”“有 bug”。
- 后端接口结果错误、异常、性能变慢。
- 前端页面交互、接口映射、状态显示异常。
- CI / Maven / npm 命令失败，需要找根因。

## 流程

1. **建立反馈环**
   - 优先：targeted test、接口调用、最小脚本、日志片段、浏览器复现。
   - 如果无法复现，记录已尝试方法，并向用户要日志、请求报文、截图、录屏或环境访问。
2. **确认症状**
   - 复现的必须是用户描述的问题，不是旁边另一个失败。
   - 记录输入、输出、错误、时间、分支、命令。
3. **列 3-5 个假设**
   - 每个假设必须可证伪。
   - 格式：如果原因是 X，那么观察/修改 Y 后应该出现 Z。
4. **有目标地验证**
   - 一次只验证一个变量。
   - 临时日志必须带唯一前缀，例如 `[DEBUG-<id>]`。
5. **修复与回归**
   - 能写回归测试时，先写失败测试，再修复。
   - 不能写测试时，说明缺口和原因。
6. **清理与记录**
   - 删除临时日志和脚本。
   - 把命令和结论写入 `changes/<change-id>/evidence.md`。
   - 把残余风险写入 `changes/<change-id>/review.md`。

## 输出格式

```markdown
## 复现反馈环
- 命令 / 输入：
- 结果：
- 是否复现用户问题：

## 假设
1. [FACT/ASSUMP] ...

## 验证
- 观察：
- 结论：

## 修复建议
- 最小修改范围：
- 验证命令：
- 回滚路径：
```

## 禁止

- 不复现就直接改代码。
- 不把猜测写成 `[FACT]`。
- 不保留未清理的 `[DEBUG-...]`。
- 不声称修复成功，除非原始反馈环已重新验证。
