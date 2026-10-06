# AGENTS.md

This repo is governed by `$SFA_HARNESS_ROOT`.

Repo profile:
- Repo ID: <repo-id>
- Repo type: <repo-type>
- Active change: <change-id>
- Rule entrypoint: `$SFA_HARNESS_ROOT/<rule-entrypoint>`
- Baseline doc: `<baseline-doc>`
- Candidate agents: `<agent-candidates>`

Read first:
- `$SFA_HARNESS_ROOT/AGENTS.md`
- `$SFA_HARNESS_ROOT/docs/onboarding.md`
- `$SFA_HARNESS_ROOT/docs/architecture/repo-registry.md`
- active change spec under `$SFA_HARNESS_ROOT/changes/<change-id>/spec.md`
- agent dispatch plan under `$SFA_HARNESS_ROOT/changes/<change-id>/agent-dispatch-plan.md` when present

Repo commands:
- Fill in compile / test / lint commands for this repo.

Agent usage:
- Default agents are read-only Explorer / Reviewer / Test Agent.
- Implementation candidate agents (`sfa-backend-agent`, `sfa-frontend-agent`, `sfa-mobile-agent`) require a confirmed contract, allowed paths, isolated worktree, and `business-code-start-gate.sh`.
- Candidate dispatch is blocked unless the active change has explicit `agent-candidate-confirmation.md` and the dispatch gate passes.

Protected paths:
- production config
- secrets and `.env*`
- deployment files
- DB migration unless explicitly allowed by spec
- unrelated modules outside allowed paths

Rules:
- 给人工 review / 用户确认的说明默认使用简体中文。
- 代码标识、命令、API 路径、字段名、错误码、YAML key、日志 key 和引用原文保持原样。
- 不得实现未解决的 `[ASSUMP]` 或阻塞性 `[QUESTION]`。
