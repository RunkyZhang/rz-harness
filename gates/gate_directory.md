# Gate 字典目录（gates/gate_directory.md）

> 每个 gate 检查什么、何时跑、前置依赖。所有 gate 遵守统一约定：exit `0` = PASS；非 `0` = FAIL 并输出 `FAIL / CODE / FIX / SAMPLE` 四要素诊断。
> 通用规则：gate 只裁决不创建文件；检查对象是 `changes/<change-id>/` 产物；命令证据记 evidence.md。

## 按流程阶段查

### 1. 建包后

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `change-artifacts-gate.sh` | `gates/change-artifacts-gate.sh <change-dir>` | marker（`artifact_profile` / `artifact_schema_version`）存在且合法；该档位根文件齐全；根目录无白名单外文件。旧变更包加 `--historical` 只警告不阻断 | scaffold 完成（拷模板 + 写 marker） |

### 2. Spec 阶段（停止点 1）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `confidence-gate.sh` | `gates/confidence-gate.sh <spec-file>` | spec 含 `[FACT]` / `[ASSUMP]` / `[QUESTION]` 三标签节；阻塞 `[QUESTION]` 已清零。`STRICT_QUESTIONS=1` 时所有 QUESTION 都算阻塞 | `spec.md` 已按模板创建 |

### 3. 方案阶段（停止点 2）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `technical-solution-gate.sh` | `gates/technical-solution-gate.sh <change-dir>` | `confirmation_status: CONFIRMED`、`allowed_next_stage` 非 `none`；未解决占位符不算过 | 用户已对话确认方案；内部自动级联飞书同步 gate |
| `technical-solution-feishu-sync-gate.sh` | `gates/technical-solution-feishu-sync-gate.sh <change-dir>` | PRD 来源为飞书/Lark 时：已同步子文档 + source hash 未过期（本地方案再改必须重新同步） | 方案 CONFIRMED；PRD 来源字段已填 |

### 4. 测试方案阶段（停止点 3）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `ai-test-plan-gate.sh` | `gates/ai-test-plan-gate.sh <change-dir>` | `test_plan_status: CONFIRMED`、测试矩阵 / 边界场景 / UI 检查 / token 风险说明存在、无未解决占位符 | Test Strategy 已填内容；用户已确认 |
| `verification-map-gate.sh` | `gates/verification-map-gate.sh <change-dir>` | `verification_map_status: READY`；至少一行 `VM-*` 映射（约束 → 验证方式） | 方案确认后 |

### 5. 开工前（停止点 5，四重门禁）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `business-code-start-gate.sh` | `gates/business-code-start-gate.sh <change-dir> <changed-file>...` | 方案已 CONFIRMED 且 `allowed_next_stage` 达 code_start；verification-map READY；业务仓不在 `main/master`（在 `harness/<id>` 分支） | 内部级联 technical-solution-gate + verification-map-gate |
| `allowed-paths.sh` | `gates/allowed-paths.sh <spec-file> <changed-file>...` | 待改文件都在 spec 的 `allowed_paths` 白名单内；含未展开 `$VAR` 路径时提示 source `config/runtime_local.sh` | spec 已写 allowed_paths |
| `assumption-leak-gate.sh` | `gates/assumption-leak-gate.sh <spec-file> <changed-file>...` | 实现文件不含 `[ASSUMP]` 字面标签；spec 中 ASSUMP 的高信号标识符未泄漏进实现 | spec 三标签已清 |
| `business-dirty-worktree-gate.sh` | `gates/business-dirty-worktree-gate.sh <repo> [--ledger <ledger.md>]` | 业务仓有脏 diff 时，每个脏文件必须记入台账（含 owner 和 decision），防止静默覆盖用户工作 | 脏仓时先建 `dirty-worktree-ledger.md` |

### 6. 实现阶段（条件触发）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `ui-rule-gate.sh` | `gates/ui-rule-gate.sh <change-dir>` | `ui_rule_status: READY / NOT_APPLICABLE`；`rule_gap_status: NONE / CONFIRMED / NOT_APPLICABLE`；无未确认规范缺口 | PRD UI 编码命中时先建 `ui-rule-checklist.md` |
| `swagger-model-documentation-gate.sh` | `gates/swagger-model-documentation-gate.sh <change-dir> <changed-file>...` | 活动 Swagger profile 下新增对外响应 `*VO.java`：类有 `@ApiModel`、每个非静态字段有 `@ApiModelProperty` | `rules/backends/*/manifest.yml` 配置 + `runtime_local.sh` 仓路径变量 |
| `contract-delta-gate.sh` | `gates/contract-delta-gate.sh <changed-file>...` | 契约文档有改动时，`contract-delta.md` 必须同步改动（前端通知行） | 实现中契约发生增量 |

### 7. 真实 E2E 前（停止点 4）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `environment-readiness-gate.sh` | `gates/environment-readiness-gate.sh <change-dir>` | `environment_status: READY`；环境 / 运行时 / 拓扑 / 账号来源 / 权限 / 数据 / 设备各节齐全；至少一行 READY 的系统运行时。只查材料不探活、不查 CONFIRMED | `environment-readiness.md` 已填 |

### 8. 验收阶段（停止点 7 / 8 / 9）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `test-agent-verification-gate.sh` | `gates/test-agent-verification-gate.sh <change-dir>` | `verification_status: GOAL_ACHIEVED` + `final_decision: GOAL_ACHIEVED`；无未关闭 P0/P1/P2 问题 | Tester 已验收（主 Agent 不得代填） |
| `ai-test-report-gate.sh` | `gates/ai-test-report-gate.sh <change-dir>` | 报告 `confirmation_status: CONFIRMED`；内部级联检查：同目录测试方案已确认 + Tester `GOAL_ACHIEVED` | Tester 已过；用户已确认报告 |
| `reviewer-gate.sh` | `gates/reviewer-gate.sh <change-dir>` | `review.md` 证明 Reviewer 覆盖：方案对齐 / harness 约束 / 架构漂移 / 注释日志质量 / 可读性 / 测试证据；`high_risk_count: 0` | Reviewer 已产出（主 Agent 不得代填） |
| `skill-usage-gate.sh` | `gates/skill-usage-gate.sh changes/<change-id>` | `skill-usage.md` 存在且无 TODO 状态；不裁决 N/A 理由是否成立（交 Reviewer） | 用过 skill 或写 N/A |

### 9. 合并前（检查项，非决策停止点）

| Gate | 命令 | 检查什么 | 前置依赖 |
|---|---|---|---|
| `diff-hygiene-gate.sh` | `gates/diff-hygiene-gate.sh <repo> [--base <ref>] <files>...` | 变更文件无纯空白噪音 diff；缺文件参数时取 `git diff --name-only`；默认 base 为 HEAD | Reviewer 已过 |
| `temp-hardcode-scan.sh` | `gates/temp-hardcode-scan.sh <changed-file-or-dir>...` | 临时硬编码标记扫描：`CODX` / `smoke` / `mock` / `localhost` / `token` / `password` / `TODO` / `FIXME`；只输出行号和标记，不打印整行防泄密 | 同上 |

## 速查：按停止点编号

| 停止点 | Gate |
|---|---|
| 1 Spec | `confidence-gate` |
| 2 方案 | `technical-solution-gate`（含飞书同步级联） |
| 3 测试方案 | `ai-test-plan-gate` + `verification-map-gate` |
| 4 环境 | `environment-readiness-gate` |
| 5 开工 | `business-code-start-gate` + `allowed-paths` + `assumption-leak-gate` + `business-dirty-worktree-gate`（脏仓） |
| 6 UI | `ui-rule-gate`（确认记录无独立 gate，人工核对文件） |
| 7 Tester | `test-agent-verification-gate` |
| 8 报告 | `ai-test-report-gate` |
| 9 Reviewer | `reviewer-gate` |
| — 合并前 | `diff-hygiene-gate` + `temp-hardcode-scan` |
| — 建包后 | `change-artifacts-gate` |
| — 实现中 | `swagger-model-documentation-gate` + `contract-delta-gate` + `skill-usage-gate` |

## 尚未引入（标本有、RZ 未拷）

`requirement-intake-gate`、`local-routing-gate`、`miniapp-local-env-gate`、`temporary-state-ledger-gate`、`ui-confirmation-gate`、`retro-gate`、`change-stage-gate`、`codegraph-evidence-gate`、`architecture-drift-gate`、`canonical-command-gate`、`workstream-dispatch-gate`、`agent-dispatch-plan-gate`、`agent-registry-gate`、`agent-output-contract-gate`、`parallel-worktree-gate`、`knowledge-reference-gate`。命中场景再从标本 `learning_objectives/scripts/` 拷贝并登记进本目录。
