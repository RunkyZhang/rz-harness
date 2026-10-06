# Agent Registry

> 用途：把 harness 的 Agent 定义、触发点、权限、产物契约和 Codex/OpenCode runtime 适配统一到一个 source of truth，避免 agent 定义散落在 `.opencode/agents`、prompt、模板和脚本里。

## 结论

- `config/agent-registry.yml` 是唯一机器可读定义源。
- `.opencode/agents/*` 只是 OpenCode adapter 的实现文件，必须带 `Registry: <agent_id>` 标记并被 registry 引用。
- Codex 子 Agent 配置通过 `scripts/codex-agent-generator.sh` 从 registry 生成；默认 `--dry-run`，不会写 `~/.codex`。
- Tier M/L `change-scaffold` 会生成 `agent-dispatch-plan.md`，阶段门禁会在存在该文件时消费 dispatch plan 和 output contract gate；candidate implementation agent 还必须绑定 `agent-candidate-confirmation.md`。
- ECC 的借鉴边界是角色分工、review/build/test/skill taxonomy 和可视化启发，不直接引入 64 个 agent，不让 ECC 成为必装依赖。

## Registry 字段

| 字段 | 含义 | 约束 |
| --- | --- | --- |
| `agent_id` | 全局唯一 ID | 小写 kebab-case |
| `role_type` | 角色类型 | `orchestrator` / `explorer` / `reviewer` / `test` / `implementation` 等 |
| `adoption_level` | 接入级别 | `active` 可直接使用，`candidate` 需由 Orchestrator 按 gate 判断 |
| `source_files` | 规则来源 | 必须存在；OpenCode agent 文件必须含 registry marker |
| `runtime_targets` | Runtime 适配 | `codex_main_session` / `codex_generated` / `opencode` |
| `permission` | 权限边界 | `read_only` / `orchestrator_write` / `implementation_write_with_contract` / `test_execution_only` |
| `trigger_stage` | 触发阶段 | 对应 harness 状态卡和 gate 停止点 |
| `input_artifacts` | 输入产物 | 必须来自 spec / contract / plan / evidence 等受控产物 |
| `output_artifacts` | 输出产物 | 必须能被 gate 或人工 review 消费 |
| `output_contract` | 输出契约 | Codex generated agent 必填 |
| `required_gates` | 前置/后置 gate | 脚本路径必须存在 |
| `gate_consumers` | 消费该 agent 输出的 gate | 脚本路径必须存在 |
| `degradation` | 降级策略 | 缺 runtime 或未确认时必须阻断或显式 N/A |

## 当前精选 Agent

| Agent | 借鉴 ECC 的点 | Runtime | 权限 | 触发点 | 输出契约 |
| --- | --- | --- | --- | --- | --- |
| `sfa-harness-orchestrator` | 多 Agent 编排、阶段化 flow | Codex 主会话 | 控制面可写 | intake 到 closeout | `orchestration_status` |
| `sfa-harness-explorer` | Explorer / context 查证角色 | OpenCode + Codex generated | 只读 | 方案或实现前 | `fact_assumption_question` |
| `sfa-harness-reviewer` | Reviewer / quality gate 角色 | OpenCode + Codex generated | 只读 | pre-PR / 人工 review 前 | `review_findings` |
| `sfa-test-agent` | 独立 test / verify 角色 | Codex generated | 只执行测试 | 实现后、发布前 | `GOAL_ACHIEVED_OR_BLOCKED` |
| `sfa-backend-agent` | build resolver / language reviewer 分类 | Codex generated | contract 后可写 | 后端 contract 与测试计划确认后 | `implementation_delta_with_tests` |
| `sfa-frontend-agent` | React/Vue reviewer 与 build resolver 分类 | Codex generated | UI rules 后可写 | 前端方案、UI rules、contract 确认后 | `implementation_delta_with_ui_evidence` |
| `sfa-mobile-agent` | Swift/Kotlin reviewer 分类 | Codex generated | mobile contract 后可写 | 移动端 contract 与允许路径确认后 | `implementation_delta_with_mobile_evidence` |

## 触发与约束

1. Orchestrator 仍是唯一控制面写入者，负责维护 `changes/<change-id>/harness-status.md`、evidence、decision 和 gate 记录。
2. Explorer / Reviewer 默认只读；不得修改控制面或业务仓文件。
3. Backend / Frontend / Mobile implementation agent 只是候选能力，必须同时满足 contract、allowed paths、目标仓隔离分支和对应 gate；派发时必须同时提供 `--allow-candidate` 与 `--candidate-confirmation changes/<change-id>/agent-candidate-confirmation.md`。
4. Test Agent 必须基于已确认的 `ai-test-plan.md`，输出 `GOAL_ACHIEVED` 或 `BLOCKED`，并由 `ai-test-report-gate.sh` 消费。
5. Codex agent 配置只从 registry 生成；不再把 agent 定义散写到临时 prompt 作为长期机制。
6. Agent 派发前先运行 `scripts/agent-dispatch-plan.sh` 生成 registry-derived dispatch plan；implementation candidate 默认 fail-closed，必须显式 `--allow-candidate`，且确认文件中 `candidate_dispatch_confirmation: CONFIRMED`、`business_code_start_gate: PASS`、`allowed_paths_confirmed: yes`。
7. `changes/<change-id>/agent-dispatch-plan.md` 进入流程前先运行 `scripts/agent-dispatch-plan-gate.sh changes/<change-id>`，确保 plan 中 agent、权限、output contract、gate 引用和 candidate confirmation 仍匹配 registry。
8. Agent 产物进入下游 gate 前先运行 `scripts/agent-output-contract-gate.sh <change-dir> <agent-id>`，确保 registry 声明的输出文件存在，并把 Reviewer / Test Agent 产物交给对应 gate 校验。

## 和 Skill Routing 的关系

`config/agent-registry.yml` 管 Agent 身份、权限、runtime target、触发阶段和输出契约；`docs/skills-routing.md` 继续管本仓 `skills/*/SKILL.md` 的触发规则和使用记录。两者不互相替代：

- Agent registry 可以把 `skills/explorer/SKILL.md`、`skills/reviewer/SKILL.md` 等列为 `source_files`，保证生成的 Codex agent 继承本仓 skill 约束。
- 命中 skill 场景时，仍必须在 `changes/<change-id>/skill-usage.md` 记录 `USED` 或明确 `N/A reason`。
- `scripts/skill-usage-gate.sh` 仍是 skill 使用闭环的 gate；`scripts/agent-registry-gate.sh` 只负责 Agent 定义和 adapter 一致性。

## 命令

```bash
scripts/change-scaffold.sh --tier M <change-id>
scripts/agent-registry-gate.sh
scripts/codex-agent-generator.sh --dry-run
scripts/codex-agent-generator.sh --output-dir .harness/generated/codex-agents --apply
scripts/agent-dispatch-plan.sh --stage pre_pr_or_human_review --runtime codex_generated --change-id <change-id> --output changes/<change-id>/agent-dispatch-plan.md
cp templates/agent-candidate-confirmation.md changes/<change-id>/agent-candidate-confirmation.md
scripts/agent-dispatch-plan.sh --stage implementation_after_contract_v0_1 --runtime codex_generated --allow-candidate --candidate-confirmation changes/<change-id>/agent-candidate-confirmation.md --change-id <change-id> --output changes/<change-id>/agent-dispatch-plan.md
scripts/agent-dispatch-plan-gate.sh changes/<change-id>
scripts/agent-output-contract-gate.sh changes/<change-id> sfa-harness-reviewer
```

写入个人全局 Codex agent 目录必须显式确认并传入：

```bash
scripts/codex-agent-generator.sh --output-dir "$HOME/.codex/agents" --apply --allow-global
```

默认不写 `~/.codex`，也不修改 `.codex/config.toml`、`.codex/hooks.json`。

## 自检

```bash
scripts/agent-registry-gate-test.sh
scripts/codex-agent-generator-test.sh
scripts/agent-dispatch-plan-test.sh
scripts/agent-dispatch-plan-gate-test.sh
scripts/agent-output-contract-gate-test.sh
scripts/harness-self-audit.sh
```

`harness-self-audit.sh` 会检查 registry、生成器、dispatch plan、output contract gate、OpenCode marker、文档索引和相关测试是否仍然存在。
