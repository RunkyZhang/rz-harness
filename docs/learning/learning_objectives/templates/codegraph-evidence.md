# CodeGraph Evidence：<change-id>

> CodeGraph 是结构索引和影响面辅助。HIT 不需要默认 `rg` 复验；MISS / PARTIAL / UNAVAILABLE 不能解释成“无影响”，必须记录降级证据。

codegraph_evidence_status: PENDING
projectPath: -
result: -

| Step | Evidence |
| --- | --- |
| preflight | `scripts/codegraph-preflight.sh <repo-id-or-path>` |
| codegraph_explore | `task="<module route symbol flow>", projectPath=<CODEGRAPH_PROJECT_PATH>` |
| follow-up | `codegraph_node` / `codegraph_search` / `codegraph_callers` / `codegraph_trace` / `codegraph impact` as needed |
| freshness | `Freshness note: no staleness banner reported` or direct-read evidence for stale files |
| downgrade fallback | Only for PARTIAL / MISS / UNAVAILABLE: `rg` / direct reads / compile / tests / Reviewer evidence |

Downgrade note: CodeGraph MISS/PARTIAL/UNAVAILABLE does not prove no impact; use `rg`、直接读文件、编译 / 测试和 Reviewer 证据兜底。
