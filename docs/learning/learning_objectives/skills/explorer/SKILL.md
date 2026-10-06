---
name: sfa-harness-explorer
description: Use when a SFA harness task needs read-only evidence from business repos, existing samples, commands, or baseline files before planning or implementation.
---

# SFA Harness Explorer

## 目标

只读查证，不改文件。输出必须区分 `[FACT]`、`[ASSUMP]`、`[QUESTION]`，并给出证据路径。

## 输入

- `change-id`
- 目标 repo path
- 需要查证的问题

## 必须输出

```markdown
## FACTS
- [FACT] ... 证据：`/absolute/path/file:line`

## ASSUMPTIONS
- [ASSUMP] ... 为什么只是推断

## QUESTIONS
- [QUESTION] ... 谁需要确认

## SAMPLES
- `/absolute/path/file:line`：适合模仿的点；不应模仿的点
```

## 知识查询：三级渐进索引 + 查询预算

查知识库时按需逐级下钻，不要一次性灌入全部条目（避免上下文膨胀）：

1. 全景目录（零成本）：`AGENTS.md` + `docs/README.md`，先定位该读哪个分类。
2. 分类清单（低成本）：`docs/pitfalls/README.md`、`docs/samples/README.md` 的一行摘要，按 tags / 领域过滤。
3. 完整条目（按需）：只在确实相关时读 `SFA-PIT-*.md` / `SFA-SMP-*.md` 全文。

查询预算（默认）：单次探索完整读取的知识条目 ≤ 5 条；超出说明问题没收敛，先回到分类清单重新过滤。

引用过的条目写进 spec 的 `knowledge_refs:`，供 ARCHIVE 更新 `last_referenced`。

## 禁止

- 不编辑业务仓或控制面文件。
- 不把猜测写成 `[FACT]`。
- 不建议越过 spec 的 `allowed_paths`。
- 不输出没有证据路径的架构结论。
