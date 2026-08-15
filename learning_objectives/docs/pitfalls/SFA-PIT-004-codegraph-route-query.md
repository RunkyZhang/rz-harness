---
id: SFA-PIT-004
title: CodeGraph 自然语言查询 API route 可能命中无关符号
domain: harness-codegraph
maturity: verified
last_referenced: 2026-06-08
sources:
  - session route query test for /bsp/select
---

# SFA-PIT-004：CodeGraph 自然语言查询 API route 可能命中无关符号

## 现象

旧用法中，使用 `codegraph_context` 直接查 `/bsp/select` 这类 URL 字符串时，可能返回无关的 handler / service，而不是对应 Controller 或 API interface。当前推荐优先用 `codegraph_explore` 带业务模块词、route 和 repo `projectPath` 查询，再用 node/search/callers/trace 精确跟进。

## 原因

CodeGraph 官方已支持 Spring 等框架 route 节点，但 route 覆盖仍受静态分析上限、索引新鲜度和项目写法影响。SFA 里不能把自然语言 URL 查询的无关命中当作答案，也不能把无输出当作“无影响面”。

## 推荐流程

1. 先运行 `scripts/codegraph-preflight.sh <repo-id-or-path>`，复制输出的 `CODEGRAPH_PROJECT_PATH`。
2. 优先使用 `codegraph_explore`，query 同时包含业务模块词、route 片段和目标，例如 `Bsp /bsp/select controller service mapper`。
3. 如果 explore 命中候选符号，再使用 `codegraph_node(..., includeCode=true)` 或 `codegraph_callers` / `codegraph_trace` 精确跟进。
4. 如果 CodeGraph 报 stale/pending，先等待自动同步或运行 `scripts/codegraph-preflight.sh --sync <repo-id-or-path>`，并按 staleness banner 直接读指定文件。
5. 只有 PARTIAL / MISS / UNAVAILABLE 时，用 `rg "bsp/select|/bsp|Bsp"`、直接读文件、编译 / 测试和 Reviewer 证据兜底。

## 禁止口径

- 不要把 `codegraph_context` 或 `codegraph_explore` 查 URL 的无关结果当作答案。
- 不要把 CodeGraph 无输出解释成“无影响面”。
- 不要省略 `projectPath`，否则 MCP 可能默认查当前 harness 仓。
- 不要把 `rg` 作为每次 CodeGraph HIT 后的必选复验；它是降级证据，不是默认流程。
