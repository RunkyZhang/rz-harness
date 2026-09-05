# Change Whitelist Spec

> 目标：让新 change 的产物数量和文件名有清晰边界，避免小需求被迫复制 Tier L 流程，也避免历史产物继续无序增长。旧 change 迁移采用 warning，不追溯硬阻断。
>
> RZ 落点：本文件在 `changes/change-whitelist-spec.md`。建包用 `changes/change-scaffold.sh`，白名单检查用 `gates/change-artifacts-gate.sh`。本文件和 `change-scaffold.sh` 放在 `changes/` 根下，是控制面文件，不是某个 `changes/<change-id>/` 变更包内的产物。契约只允许 `changes/<change-id>/contract.md`，不用标本的 `docs/contracts/<id>-api.md`。M/L 的 `agent-dispatch-plan.md` 来自 `templates/agent-dispatch-plan.md`，不调用标本 registry 脚本。

```yaml
schema_version: 1
artifact_profiles:
  - tier-s
  - tier-m
  - tier-l
new_change_policy: fail_closed
historical_policy: warn_only
```

## Profiles

| Profile | 适用场景 | Required root artifacts | Notes |
| --- | --- | --- | --- |
| `tier-s` | 单仓小修、文档或低风险脚本变更 | `spec.md`, `harness-status.md`, `evidence.md` | 不强制技术方案、AI 测试方案和 Reviewer 包。 |
| `tier-m` | Tier M、普通全栈或多文件业务变更 | `spec.md`, `harness-status.md`, `evidence.md`, `plan.md`, `contract.md`, `technical-solution.md`, `verification-map.md`, `ai-test-plan.md`, `test-agent-verification.md`, `agent-dispatch-plan.md`, `skill-usage.md`, `review.md` | 把既有强制流程和 Agent 派发计划一次 scaffold 出来，减少手工漏文件。`agent-candidate-confirmation.md` 只在启用 candidate implementation agent 时可选新增。 |
| `tier-l` | Tier L、跨仓、高风险、真实环境依赖或发布前风险高的变更 | tier-m 全部文件 + `environment-readiness.md`, `ai-test-report.md`, `decisions.md` | DB、UI、临时状态、CodeGraph 等只在命中场景时再新增对应可选文件。 |

## Root File Policy

新 change 根目录只允许使用已登记文件名。未登记产物应放入明确目录，例如 `evidence/`、`runtime-smoke/`、`prd-ui/`、`tests/` 或 `artifacts/`。

允许的根文件：

- `spec.md`
- `requirement-intake.md`
- `harness-status.md`
- `plan.md`
- `contract.md`
- `api-contract.md`
- `technical-solution.md`
- `verification-map.md`
- `ai-test-plan.md`
- `test-agent-verification.md`
- `agent-dispatch-plan.md`
- `agent-candidate-confirmation.md`
- `ai-test-report.md`
- `verification-run-report.md`
- `review.md`
- `evidence.md`
- `retro.md`
- `skill-usage.md`
- `environment-readiness.md`
- `backend-test-plan.md`
- `ui-rule-checklist.md`
- `ui-confirmation.md`
- `data-model.md`
- `data-model-sql.md`
- `contract-delta.md`
- `decisions.md`
- `decision-matrix.md`
- `implementation-readiness.md`
- `pre-pr.md`
- `pre-pr-review.md`
- `pc-e2e-smoke-plan.md`
- `pc-e2e-smoke-report.md`
- `miniapp-local-env.md`
- `temporary-state-ledger.md`
- `codegraph-evidence.md`
- `local-routing.yml`
- `local-routing.env`
- `local-proxy.ndjson`
- `product-prd.md`
- `sit-checklist.md`
- `human-review-package.md`
- `test-data-readiness.md`
- `screenshot-test-evidence.md`
- `dirty-worktree-ledger.md`
- `handoff.md`
- `capability-spec.md`
- `behavior-spec.md`
- `README.md`

允许的根目录：

- `evidence/`
- `runtime-smoke/`
- `prd-ui/`
- `tests/`
- `artifacts/`

## Marker

新 scaffold 会在 `harness-status.md` 顶部写入：

```yaml
artifact_profile: tier-s
artifact_schema_version: 1
```

`gates/change-artifacts-gate.sh` 读取该 marker。新 change 缺失 marker 时 fail-closed；历史 change 可用 `--historical` 只输出 warning。

## Commands

```bash
changes/change-scaffold.sh --tier S <change-id>
gates/change-artifacts-gate.sh changes/<change-id>
gates/change-artifacts-gate.sh --historical changes/<old-change-id>
```
