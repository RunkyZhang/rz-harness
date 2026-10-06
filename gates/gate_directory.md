# Gate 字典目录（gates/gate_directory.md）

> 每个 gate 检查什么、何时跑、前置依赖。所有 gate 遵守统一约定：exit `0` = PASS；非 `0` = FAIL 并输出 `FAIL / CODE / FIX / SAMPLE` 四要素诊断。
> 通用规则：gate 只裁决不创建文件；检查对象是本机 `changes/<change-id>/` 产物（整包不进 git）；命令证据记 evidence.md。
> `changes/status-card.sh` **不是 gate**：和 `change-scaffold.sh` 同级，只读收集阶段摘要，由主 Agent 合并进 `status-card.md`。不要拷进 `gates/`，也不要拷进变更包。

## 按流程阶段查

### 1. 建包后

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `change-artifacts-gate.sh` | `gates/change-artifacts-gate.sh <change-dir>` | marker（`artifact_profile` / `artifact_schema_version`）存在且合法；该档位根文件齐全；根目录无白名单外文件。旧变更包加 `--historical` 只警告不阻断 | scaffold 完成（拷模板 + 写 marker） |

### 2. Spec 阶段（停止点 1）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `confidence-gate.sh` | `gates/confidence-gate.sh <spec-file>` | spec 含 `[FACT]` / `[ASSUMP]` / `[QUESTION]` 三标签节；阻塞 `[QUESTION]` 已清零。`lane` 为 `lanes/bugfix-fast.md`、`lanes/fullstack-crud.md` 或 `none` 之一，且与同目录 `status-card.md` 的 `Lane` 一致。`STRICT_QUESTIONS=1` 时所有 QUESTION 都算阻塞 | `spec.md` 已按模板创建，且 `lane: TODO` 已改成唯一值 |
| `requirement-intake-gate.sh` | `gates/requirement-intake-gate.sh <change-dir>` | 命中"要结构化收需求"（M/L 或高风险）时，校验 `requirement-intake.md` 完整 | 先按 `templates/requirement-intake.md` 建 `requirement-intake.md` |

### 3. 方案阶段（停止点 2）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `technical-solution-gate.sh` | `gates/technical-solution-gate.sh <change-dir>` | `confirmation_status: CONFIRMED`、`allowed_next_stage` 非 `none`；未解决占位符不算过 | 用户已对话确认方案；内部自动级联飞书同步 gate |
| `technical-solution-feishu-sync-gate.sh` | `gates/technical-solution-feishu-sync-gate.sh <change-dir>` | PRD 来源为飞书/Lark 时：已同步子文档 + source hash 未过期（本地方案再改必须重新同步） | 方案 CONFIRMED；PRD 来源字段已填 |
| `decision-gate.sh` | `gates/decision-gate.sh <decisions.md \| change-dir>`（`--notify` 只提醒） | L 档过程内有拍板时，校验 `decisions.md` 记录完整（决策 / 依据 / 影响） | L 档有拍板；先建 `decisions.md` |

### 4. 测试方案阶段（停止点 3）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `ai-test-plan-gate.sh` | `gates/ai-test-plan-gate.sh <change-dir>` | `test_plan_status: CONFIRMED`、测试矩阵 / 边界场景 / UI 检查 / token 风险说明存在、无未解决占位符 | Test Strategy 已填内容；用户已确认 |
| `verification-map-gate.sh` | `gates/verification-map-gate.sh <change-dir>` | `verification_map_status: READY`；至少一行 `VM-*` 映射（约束 → 验证方式） | 方案确认后 |

### 5. 开工前（停止点 5：S 三重 / M/L 四重）

S/M/L 都跑：`confidence-gate`（见上节停止点 1）、`assumption-leak-gate`、`allowed-paths`。**M/L 再加** `business-code-start-gate`（它校验技术方案，S 不要跑）。脏仓再加 `business-dirty-worktree-gate`。

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `business-code-start-gate.sh` | `gates/business-code-start-gate.sh <change-dir> <changed-file>...` | **仅 M/L。** 方案已 CONFIRMED 且 `allowed_next_stage` 达 code_start；verification-map READY；业务仓不在 `main/master`（在 `harness/<id>` 分支） | 内部级联 technical-solution-gate + verification-map-gate |
| `allowed-paths.sh` | `gates/allowed-paths.sh <spec-file> <changed-file>...` | 待改文件都在 spec 的 `allowed_paths` 白名单内；含未展开 `$VAR` 路径时提示 source `config/runtime_local.sh` | spec 已写 allowed_paths |
| `assumption-leak-gate.sh` | `gates/assumption-leak-gate.sh <spec-file> <changed-file>...` | 实现文件不含 `[ASSUMP]` 字面标签；spec 中 ASSUMP 的高信号标识符未泄漏进实现 | spec 三标签已清 |
| `business-dirty-worktree-gate.sh` | `gates/business-dirty-worktree-gate.sh <repo> [--ledger <ledger.md>]` | 业务仓有脏 diff 时，每个脏文件必须记入台账（含 owner 和 decision），防止静默覆盖用户工作 | 脏仓时先建 `dirty-worktree-ledger.md` |

### 6. 实现阶段（条件触发）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `ui-rule-gate.sh` | `gates/ui-rule-gate.sh <change-dir>` | `ui_rule_status: READY / NOT_APPLICABLE`；`rule_gap_status: NONE / CONFIRMED / NOT_APPLICABLE`；无未确认规范缺口 | PRD UI 编码命中时先建 `ui-rule-checklist.md` |
| `ui-confirmation-gate.sh` | `gates/ui-confirmation-gate.sh <ui-confirmation.md \| change-dir>` | 复杂 UI（fail-closed）：`Complexity: complex`、`Status: CONFIRMED`、至少一条 artifact 路径/URL、reviewer 行 `Decision=CONFIRMED`；简单或未命中 UI 时显式记录即放行 | 页面可运行 + 用户看过（停止点 6） |
| `local-routing-gate.sh` | `gates/local-routing-gate.sh <local-routing.yml>` | 路由配置存在且可解析；无 catch-all 前端路由；每个本地目标指向 `localhost` / `127.0.0.1` / `::1`；每条有 contract source 与 reason | 本地前后端联调时先写 `local-routing.yml` |
| `local-routing-business-config-gate.sh` | `gates/local-routing-business-config-gate.sh [--allow-business-config] <changed-file>...` | 阻止本地 smoke 改业务前端代理 / 业务配置；要求走 harness 代理与 local routing | 本地 PC smoke 前 |
| `miniapp-local-env-gate.sh` | `gates/miniapp-local-env-gate.sh <miniapp-local-env.md \| change-dir>` | 小程序本地冒烟证据齐全：`status: READY`、`env_override_key: bd_owner_env_override`、`current_value`、`actual_request_host`、`reentered_miniprogram: yes`、含 `wx.removeStorageSync('bd_owner_env_override')` 的清理命令 | 改小程序本地环境时先建 `miniapp-local-env.md` |
| `temporary-state-ledger-gate.sh` | `gates/temporary-state-ledger-gate.sh <temporary-state-ledger.md \| change-dir>` | 本地 / 调试临时状态已清理、有意保留或归属用户；阻断 OPEN 项 | 命中本地服务 / 测试数据 / debug 开关时先建台账 |
| `swagger-model-documentation-gate.sh` | `gates/swagger-model-documentation-gate.sh <change-dir> <changed-file>...` | 活动 Swagger profile 下新增对外响应 `*VO.java`：类有 `@ApiModel`、每个非静态字段有 `@ApiModelProperty` | `rules/backends/*/manifest.yml` 配置 + `runtime_local.sh` 仓路径变量 |
| `contract-delta-gate.sh` | `gates/contract-delta-gate.sh <changed-file>...` | 契约文档有改动时，`contract-delta.md` 必须同步改动（前端通知行） | 实现中契约发生增量 |
| `canonical-command-gate.sh` | `gates/canonical-command-gate.sh -- <command> [args...]` | 在把验证命令记进 `evidence.md` 前，阻止已知无效 / 错误的命令（例如用错包管理或错模块）被记录 | 运行编译 / lint / 测试命令前 |

### 7. 真实 E2E 前（停止点 4）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `environment-readiness-gate.sh` | `gates/environment-readiness-gate.sh <change-dir>` | `environment_status: READY`；环境 / 运行时 / 拓扑 / 账号来源 / 权限 / 数据 / 设备各节齐全；至少一行 READY 的系统运行时；无可复用凭据。只查材料不探活、不查 CONFIRMED | `environment-readiness.md` 已填 |

### 8. 验收阶段（停止点 7 / 8 / 9）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `test-agent-verification-gate.sh` | `gates/test-agent-verification-gate.sh <change-dir>` | `verification_status: GOAL_ACHIEVED` + `final_decision: GOAL_ACHIEVED`；无未关闭 P0/P1/P2 问题 | Tester 已验收（主 Agent 不得代填） |
| `ai-test-report-gate.sh` | `gates/ai-test-report-gate.sh <change-dir>` | 报告 `confirmation_status: CONFIRMED`；内部级联检查：同目录测试方案已确认 + Tester `GOAL_ACHIEVED` | Tester 已过；用户已确认报告 |
| `reviewer-gate.sh` | `gates/reviewer-gate.sh <change-dir>` | `review.md` 证明 Reviewer 覆盖：方案对齐 / harness 约束 / 架构漂移 / 注释日志质量 / 可读性 / 测试证据；`high_risk_count: 0` | Reviewer 已产出（主 Agent 不得代填） |
| `architecture-drift-gate.sh` | `gates/architecture-drift-gate.sh <repo-root> [changed-file...]` | 变更业务文件的高信号架构漂移（分层越界、跨层直连等），供 Reviewer 参考 | 改过业务文件；Reviewer 审查时 |
| `skill-usage-gate.sh` | `gates/skill-usage-gate.sh changes/<change-id>` | `skill-usage.md` 存在且无 TODO 状态；不裁决 N/A 理由是否成立（交 Reviewer） | 用过 skill 或写 N/A |

### 9. 合并前（检查项，非决策停止点）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `diff-hygiene-gate.sh` | `gates/diff-hygiene-gate.sh <repo> [--base <ref>] <files>...` | 变更文件无纯空白噪音 diff；缺文件参数时取 `git diff --name-only`；默认 base 为 HEAD | Reviewer 已过 |
| `temp-hardcode-scan.sh` | `gates/temp-hardcode-scan.sh <changed-file-or-dir>...` | 临时硬编码标记扫描：`CODX` / `smoke` / `mock` / `localhost` / `token` / `password` / `TODO` / `FIXME`；只输出行号和标记，不打印整行防泄密 | 同上 |
| `knowledge-reference-gate.sh` | `gates/knowledge-reference-gate.sh <change-file>...`（`--audit` 全量审计） | 变更包 / 知识条目里的引用（`rules/`、baseline、决策）完整可追溯 | 收口前 |

## 速查：按停止点编号

| 停止点 | Gate |
|---|---|
| 1 Spec | `confidence-gate`（命中结构化收需求再加 `requirement-intake-gate`） |
| 2 方案（仅 M/L） | `technical-solution-gate`（含飞书同步级联）；L 档有拍板加 `decision-gate`；S 本停止点 N/A |
| 3 测试方案（仅 M/L） | `ai-test-plan-gate` + `verification-map-gate`；S 本停止点 N/A |
| 4 环境 | `environment-readiness-gate` |
| 5 开工 | S：`confidence-gate` + `assumption-leak-gate` + `allowed-paths`。M/L 再加 `business-code-start-gate`。脏仓再加 `business-dirty-worktree-gate` |
| 6 UI | `ui-rule-gate` + `ui-confirmation-gate`（复杂 UI） |
| 7 Tester | `test-agent-verification-gate` |
| 8 报告 | `ai-test-report-gate` |
| 9 Reviewer | `reviewer-gate`（辅助：`architecture-drift-gate`） |
| — 合并前 | `diff-hygiene-gate` + `temp-hardcode-scan` + `knowledge-reference-gate` |
| — 建包后 | `change-artifacts-gate` |
| — 实现中 | `swagger-model-documentation-gate` + `contract-delta-gate` + `ui-rule-gate` + `local-routing-gate` + `local-routing-business-config-gate` + `miniapp-local-env-gate` + `temporary-state-ledger-gate` + `canonical-command-gate` |
| — 验收（辅助） | `skill-usage-gate` |

## 尚未引入（标本有、RZ 未拷）

**本清单是「RZ 尚未引入的脚本」的唯一权威来源**；其它文档（如 `templates/`）引用本节点即可，不要另抄一份。

`workstream-dispatch-gate`、`parallel-worktree-gate`、`agent-output-contract-gate`、`agent-registry-gate`、`agent-dispatch-plan-gate`、`agent-task-brief`、`agent-review-package`、`retro-gate`、`change-stage-gate`、`codegraph-preflight`、`codegraph-evidence-gate`、`gitnexus-detect-changes`、`gitnexus-impact`。命中场景再从标本 `docs/learning/learning_objectives/scripts/` 拷贝并登记进本目录（变量 `SFA_`→`RZ_`、配置 `repos.local`→`runtime_local`）。
