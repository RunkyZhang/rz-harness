# AGENTS.md (sfa-ai-harness)
This repo is the AI harness control plane for SFA multi-repo work. Business repos use ignored `config/repos.local.sh`; do not copy business repos here.

## Language Policy
给人工 review / 用户确认的文档默认使用简体中文；代码标识、命令、API 路径、字段名、错误码、YAML key、日志 key 和引用原文保持原样。

## Repo Registry
Read `docs/architecture/repo-registry.md` first. Current repos: `sfa-sales-management`, `sfa-backend`, `sfa-root`, `backend-ceo-member`, `mapSystem`, `sign-up`, `merchant-wechatapp`, `SfaIntl`, `sfa-ios`, `sfa-android`.

## Mandatory Workflow

For Tier M/L, cross-repo, backend behavior, DB, or complex UI work, the first user-facing response must include "本次 harness 流程和停止点": spec/contract/solution/test-plan/env/code-start/UI/DB/Test-Agent/report/pre-merge gates. Keep `changes/<change-id>/harness-status.md` as the user-visible status card.

Before coding: read the active change, load `config/repos.local.sh` for business work, confirm allowed repos/paths, separate `[FACT]` / `[ASSUMP]` / `[QUESTION]`, never implement unresolved assumptions/questions, and prefer target-repo samples.
Before first business-code edit per target repo, create/switch to `codex/<change-id>` from `main`/`master` unless user asks otherwise; record base branch+commit, never edit on `main`/`master`, and pass `scripts/business-code-start-gate.sh` for planned files.

Strict execution notes:
- User phrases such as "开始开发", "进行下一步", "确认", or "ok" advance only to the next satisfied harness gate. They do not waive technical-solution confirmation, Feishu sync, AI test-plan confirmation, code-start, allowed-path, environment, Test Agent, or Reviewer gates.
- `harness-status.md` is not a summary written at the end. Update it when the phase changes, when a blocker appears or clears, when Test Agent / Reviewer Agent returns, and whenever code changes after a review invalidates prior verification.
- If any business code changes after Test Agent verification, rerun or refresh Test Agent verification before relying on the result.
- If any business code changes after Reviewer Agent output, mark the prior review stale, rerun Test Agent as needed, then rerun Reviewer Agent and `scripts/reviewer-gate.sh`.
- Main Agent may implement, integrate, and fix issues, but must not replace independent Test Agent or read-only Reviewer Agent verdicts.
- When subagents are used, record a readable role label in the dispatch prompt and in `harness-status.md` Agent Roster so the user can identify each agent's purpose even when the runtime assigns an opaque nickname.

Behavior/contract changes require spec, contract docs before implementation,
and evidence in `changes/<change-id>/evidence.md`. Apply
`docs/standards/comment-logging.md` before business code review.
Use local harness skills via `docs/skills-routing.md`; record
`changes/<change-id>/skill-usage.md` and run `scripts/skill-usage-gate.sh`.

Java backend behavior changes require `backend-test-plan.md` before
implementation, or explicit N/A evidence. Compile-only is insufficient.

For a backend repository with an active `rules/backends/*/manifest.yml` Swagger profile,
every newly added public REST response `*VO.java` in the configured response root must use
`@ApiModel` and annotate each declared serializable field with `@ApiModelProperty`. Run
`scripts/swagger-model-documentation-gate.sh <change-dir> <changed-files...>` at pre-commit;
the profile is non-retroactive and does not apply to export-only models or infrastructure DTOs.

Frontend/UI changes: decide complexity first. PRD UI / interaction coding requires `ui-rule-checklist.md`, PRD UI source, matching rules, and `scripts/ui-rule-gate.sh changes/<change-id>`.
If rules miss a layout/spacing/button/component state, stop for user confirmation. Complex UI needs `ui-confirmation.md` and a runnable prototype/page before UI can pass.
For `mapSystem`, read `docs/baseline/frontend-map-system.md`, use `scripts/frontend-dev-server.sh frontend-map-system 9527`, verify product group login and temporary route menu; `HomeIndex` redirect is a route failure.
Never record plaintext passwords/tokens/cookies.

Before real E2E or environment-dependent testing, fill `environment-readiness.md` and run `scripts/environment-readiness-gate.sh changes/<change-id>`; record env, required systems, local run standards, integration topology, role/account source, data, DB/write boundary, rollback, devices/tools, blockers, and no reusable credentials.

本地后端“已重启/可验收”只能在 local-service-lifecycle 的 HEALTH=UP 和 check-web-stack 成功后声明；Maven、nohup 或端口单独成功均不足以证明可用。
Successful `restart` or launch-command return alone is insufficient to establish readiness.
对应操作命令为 `scripts/local-service-lifecycle.sh`。

Tier M/L solution docs need confirmed `templates/technical-solution.md` and `scripts/technical-solution-gate.sh changes/<change-id>` before business code.
Technical solution docs must be 全栈技术方案; cover every PRD surface listed in the template. A backend-only solution is invalid when frontend, APP, export, analytics, or cross-repo behavior is in scope.
If the PRD source is a Feishu/Lark link, confirmed technical solution docs must be synced to a child Feishu document with `scripts/technical-solution-feishu-sync.sh`, and later local solution changes must be re-synced before the technical solution gate can pass.
After solution confirmation, an independent Test Strategy Agent creates `ai-test-plan.md`; user confirmation plus `scripts/ai-test-plan-gate.sh changes/<change-id>` is required before implementation.
Feishu flowcharts/ER/state diagrams must be whiteboards, not Mermaid code blocks.

`changes/<change-id>/` is the only harness change control plane for new work. Do not create top-level `openspec/` artifacts or require local OpenSpec CLI. Historical OpenSpec artifacts, when retained, live under `changes/<change-id>/legacy-openspec/` for audit only.
If a complex behavior/capability spec is needed, write it in the change package as `capability-spec.md` or `behavior-spec.md` and map it in `verification-map.md`.
DB changes need a data model doc with ER diagram, executable SQL, normalization checks, self-contained SQL comments, and field source/rationale.

Main Agent implements, fixes, reruns regular tests, and records evidence, but cannot claim final goal achievement.
A separate Test Agent maintains `test-agent-verification.md`, verifies against confirmed `ai-test-plan.md`, returns issues, and retests until `GOAL_ACHIEVED` or `BLOCKED`.
Before test/pre-release publishing, `ai-test-report.md` plus `scripts/ai-test-report-gate.sh changes/<change-id>` is required; the gate also requires confirmed test plan and Test Agent `GOAL_ACHIEVED`.

After implementation and verification, a read-only Reviewer Agent must write `changes/<change-id>/review.md` and run `scripts/reviewer-gate.sh changes/<change-id>` before human review or PR.
Reviewer gate requires technical solution alignment, harness constraints, architecture drift, comment/log quality, maintainability/readability, test evidence, and `high_risk_count: 0`.

CodeGraph is optional, not a gate. Before business CodeGraph review, run `scripts/codegraph-preflight.sh <repo-id-or-path>` and use that repo as the MCP `projectPath`.
Prefer `codegraph_explore` for broad structure/route questions; use node/search/callers/trace for exact symbol follow-up. Record staleness/downgrade; misses are not no-impact proof.

## Confidence Gate

`[FACT]` = sourced by PRD/user/code/contract; `[ASSUMP]` = unconfirmed and must not enter implementation; `[QUESTION]` = needs user decision.
Unsourced business rules, fields, statuses, permissions, error codes, defaults, or rollback rules are not facts.

## Protected Behavior

Do not modify without explicit spec permission: production config, secrets, `.env*`, deployment manifests, DB migrations, Nacos production config, release scripts, or unrelated modules outside allowed paths.
Real SIT/UAT/production DB access is read-only by default. Real-data writes, DDL, job-triggered data changes, or mutating APIs need target env, exact SQL/API, expected rows, rollback/cleanup plan, and explicit second user confirmation.
High-risk SQL is globally forbidden: `DROP DATABASE`, `DROP TABLE`, `TRUNCATE`, broad `DELETE`, broad `UPDATE`, or writes without precise scope.
Never persist plaintext DB passwords, tokens, or cookies in versioned files, harness docs, evidence, or memory.
Before merge, run `scripts/diff-hygiene-gate.sh <repo> [--base <ref>] <files...>` and `scripts/temp-hardcode-scan.sh <files...>` on changed business files.

## Subagents

Default subagents are read-only Explorer/Reviewer. Implementation agents require contract v0.1 and isolated git worktrees. Control plane is Orchestrator-only writable.
Frontend Agent is contract read-only; Backend Agent may propose deltas. Orchestrator waits, integrates, updates evidence/status, and continues until completion, blocker, or human decision.
Every subagent prompt must start with `Agent Label: <change-id> / <role> / <scope>` and must declare write scope, forbidden paths, required output, and whether the agent is read-only. Subagent final replies should start with `<role>: <DONE|PASS|BLOCKED|NEEDS_CONTEXT>`; the Orchestrator records the same label and status in `changes/<change-id>/harness-status.md`.
For detailed prompt and status-card conventions, use `docs/standards/subagent-dispatch.md`.

## Commands

Use repo-specific baseline files. Initial candidates: `mvn -DskipTests compile`, `scripts/frontend-lint-build.sh <repo> lint-files <files...>`, `scripts/frontend-dev-server.sh frontend-map-system 9527`, `npm run build:test`.
Run the narrowest useful check first.

## Definition Of Done

Done only when spec/plan/contract and Tier M/L technical solution agree; no unresolved assumption/question entered code; `ai-test-plan.md` is confirmed when required.
Environment readiness is clear for executed E2E; Test Agent has confirmed `GOAL_ACHIEVED` or documented `BLOCKED`; Reviewer output has passed `scripts/reviewer-gate.sh changes/<change-id>`.
Residual risks and rollback are recorded.
