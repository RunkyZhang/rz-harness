# Java 规范门禁说明

## 目标

把《阿里巴巴 Java 开发规范（嵩山版）》接入 SFA harness，用于约束 Backend Agent、Reviewer Agent 和人工 review。

本目录不承诺“Agent 首次生成代码一定 100% 符合规范”。这是不可验证承诺，尤其在多 Agent、上下文压缩、工具差异和规则含主观判断时更不成立。

harness 能承诺的是：后端代码不得在未通过规范门禁和 Reviewer 审查的情况下进入交付。

## 规范来源

| 文件 | 用途 |
| --- | --- |
| `alibaba-java-songshan-fulltext.txt` | 从用户提供 PDF 抽取的带页码全文，作为规范原文来源 |
| `alibaba-java-review-checklist.md` | 面向 Backend Agent / Reviewer Agent 的可执行审查清单 |
| `../../rules/backend-java.mdc` | 后端 Agent 写代码前必须读取的工作规则 |
| `../../../scripts/java-mechanical-quality.sh` | 本次改动 Java/XML 文件的机械门禁 |

原始文件位置：

```text
/Users/00555733/Desktop/wushaonan/阿里巴巴Java开发规范（嵩山版）.pdf
```

## 渐进式披露

Agent 不应一开始把规范全文全部塞进上下文，而是按下面顺序读取：

1. 先读 `rules/backend-java.mdc`，获得后端工作硬约束。
2. 再读本文件，确认门禁模型和多 Agent 要求。
3. 再读 `alibaba-java-review-checklist.md`，用于编码自查或 review。
4. 只有当 checklist 命中风险、规则理解不确定、Reviewer 需要引用依据时，才查 `alibaba-java-songshan-fulltext.txt` 对应章节。
5. 输出给人工 review 时，只写结论、证据和必要引用，不粘贴大段规范原文。

## 强制等级

| 类型 | 能否硬阻断 | 处理方式 |
| --- | --- | --- |
| 可机器判断规则 | 是 | `java-mechanical-quality.sh` 失败即阻断 |
| 可半自动判断规则 | 部分 | Agent 自查 + Reviewer 检查，发现 HIGH/MEDIUM 不得进入人工 review |
| 依赖业务语义规则 | 否 | Reviewer 列为人工确认项，由用户最终确认 |

## Backend Agent 要求

Backend Agent 写 Java / Mapper / SQL 前必须：

1. 读取 `rules/backend-java.mdc`。
2. 读取本文件和 `alibaba-java-review-checklist.md`。
3. 对不确定规则按渐进式披露查 `alibaba-java-songshan-fulltext.txt` 原文。
4. 只修改 spec 允许的后端路径。
5. 在独立 worktree 中运行本次改动文件的机械门禁。
6. 把命令和结果写入 `changes/<change-id>/evidence.md`。

## 多 Agent 要求

并行前后端开发时：

1. Backend Agent 和 Frontend Agent 使用独立 git worktree。
2. Backend Agent 必须独立运行 Java 规范门禁。
3. Orchestrator 集成后必须再次运行 Java 规范门禁。
4. Reviewer Agent 必须按 `alibaba-java-review-checklist.md` 复核后端 diff。
5. 只要 Java 规范审查存在 HIGH/MEDIUM，不能进入 PR 或人工验收。

## 当前机械门禁覆盖

第一版只覆盖高信号、低误伤的规则：

- 禁止 `System.out` / `System.err`
- 禁止 `printStackTrace()`
- 禁止空 `catch`
- 禁止日志参数字符串拼接
- 禁止 Mapper XML 中 `select *`
- 禁止 Mapper XML 中 `${}` 拼接
- 提醒字段注入 `@Autowired`，由 Reviewer 判断是否为新增问题
- 提醒 Controller 直接依赖 Mapper，由 Reviewer 判断是否为新增问题

更多 P3C / Checkstyle / PMD / ArchUnit 接入放到后续阶段，避免一开始侵入业务仓并产生大面积历史代码噪音。
