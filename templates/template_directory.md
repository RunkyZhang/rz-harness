# 模板字典目录（templates/template_directory.md）

> 每个模板拷到变更包后叫什么、谁填、用在哪段流程、谁检查。本文件是字典，**不要**拷进 `changes/<change-id>/`。
> 通用规则：模板只提供空壳；`changes/change-scaffold.sh` 按档位原样 copy，不读 PRD、不让模型写正文。条件文件由主 Agent 命中时再拷。占位符 `<change-id>` 由 scaffold 替换。

拷贝命令示例：

```bash
cp templates/<template> changes/<change-id>/<dest>
# 或建包：
changes/change-scaffold.sh --tier S|M|L <change-id>
```

## 按流程阶段查

### 1. 建包即有（scaffold）

| 模板 | 变更包内文件名 | 档位 | 作用 | 谁填 | 谁检查 |
|---|---|---|---|---|---|
| `spec-tier-s.md` | `spec.md` | S | 目标、范围内外、三标签、`allowed_paths` | 主 Agent；Explorer 只读供料 | `confidence-gate.sh` |
| `spec-tier-m.md` | `spec.md` | M | 同上，M 节更全（全栈盘点、契约路径等） | 同上 | 同上 |
| `spec-tier-l.md` | `spec.md` | L | 同上，L 再加环境/能力边界等 | 同上 | 同上 |
| `harness-status.md` | `harness-status.md` | S/M/L | 给人看的阶段、阻塞、下一步、Agent Roster。scaffold 会在文首加 `artifact_profile` + `artifact_schema_version: 1` | 主 Agent 贯穿更新 | `change-artifacts-gate.sh` 读 marker；无单独状态卡 gate |
| `plan-tier-m.md` | `plan.md` | M/L | 实现步骤、验证、回滚 | 主 Agent | 无单独过门 |
| `api-contract.md` | `contract.md` | M/L | 冻结 endpoint、字段、错误码、分页、空态。RZ **只用**变更包内这一条路径 | 主 Agent；前端只读 | 未冻不得实现；有增量时 `contract-delta-gate.sh` |
| `technical-solution.md` | `technical-solution.md` | M/L | 全栈技术方案 | 主 Agent | `technical-solution-gate.sh`（用户对话确认后写 `CONFIRMED`） |
| `verification-map.md` | `verification-map.md` | M/L | 每条约束怎么验（命令 / 人确认 / N/A） | 主 Agent | `verification-map-gate.sh` |
| `ai-test-plan.md` | `ai-test-plan.md` | M/L | AI 测试方案 | **Test Strategy** 填内容；主 Agent 不得代写。用户确认后主 Agent 写 `test_plan_status: CONFIRMED` | `ai-test-plan-gate.sh` |
| `test-agent-verification.md` | `test-agent-verification.md` | M/L | 对照已确认测试方案的独立验收 | **Tester** 填；主 Agent 不得代裁 | `test-agent-verification-gate.sh` |
| `agent-dispatch-plan.md` | `agent-dispatch-plan.md` | M/L | 准备派哪些子 Agent。RZ 不调标本 registry 脚本 | 主 Agent；对照 `subagents/dispatch_subagent.md` | 标本 `agent-dispatch-plan-gate.sh` **RZ 未拷** |
| `skill-usage.md` | `skill-usage.md` | M/L | 用过哪些 skill 或 N/A | 主 Agent | `skill-usage-gate.sh` |
| `review.md` | `review.md` | M/L | 人审 / PR 前只读审查 | **Reviewer** 填；主 Agent 不得代裁 | `reviewer-gate.sh` |
| `environment-readiness.md` | `environment-readiness.md` | L 建包即有；M 命中再拷 | 环境、拓扑、账号**来源**、写库边界 | 主 Agent | `environment-readiness-gate.sh`（查 `READY`，不探活） |
| `ai-test-report.md` | `ai-test-report.md` | L 建包即有；M 提测再拷 | 测试结论给人确认 | 主 Agent 汇总；用户确认后写 `CONFIRMED` | `ai-test-report-gate.sh` |
| `decisions.md` | `decisions.md` | L 建包即有；S/M 可后补 | 过程决策记录 | 主 Agent | 无单独过门 |

`evidence.md` **无模板**：scaffold 当场生成空表，之后每跑命令追加。

### 2. Spec / 收需求（停止点 1）

| 模板 | 变更包内文件名 | 何时拷 | 作用 | 谁填 | 谁检查 |
|---|---|---|---|---|---|
| `requirement-intake.md` | `requirement-intake.md` | 条件：M/L 要结构化收需求 | 把 PRD 收成结构化入口 | 主 Agent | 标本 `requirement-intake-gate.sh` **RZ 未拷** |

### 3. 方案 / 契约（停止点 2）

见建包表中的 `technical-solution.md`、`api-contract.md`、`plan-tier-m.md`、`verification-map.md`。

| 模板 | 变更包内文件名 | 何时拷 | 作用 | 谁填 | 谁检查 |
|---|---|---|---|---|---|
| `data-model-sql.md` | `data-model-sql.md` | 条件：改 DB | 可执行 SQL、字段来源。`data-model.md` **无模板**，对照方案自建 | 主 Agent | 无单独过门；真实库写要用户二次确认 |
| `contract-delta.md` | `contract-delta.md` | 条件：实现中契约有增量 | 契约变更说明 | 主 Agent | `contract-delta-gate.sh` |

### 4. 测试方案（停止点 3）

见建包表中的 `ai-test-plan.md`。Java 行为变更另加：

| 模板 | 变更包内文件名 | 何时拷 | 作用 | 谁填 | 谁检查 |
|---|---|---|---|---|---|
| `backend-test-plan.md` | `backend-test-plan.md` | 条件：Java 行为变更 | 后端测什么；仅编译不够 | 主 Agent | 实现前必须有此文件或明确 N/A |

### 5. 开工前（停止点 5）

| 模板 | 变更包内文件名 | 何时拷 | 作用 | 谁填 | 谁检查 |
|---|---|---|---|---|---|
| `dirty-worktree-ledger.md` | `dirty-worktree-ledger.md` | 条件：业务仓已有未提交改动 | 脏 diff 归属，避免覆盖用户工作 | 主 Agent | `business-dirty-worktree-gate.sh` |
| `agent-candidate-confirmation.md` | `agent-candidate-confirmation.md` | 条件：派 Backend / Frontend / Mobile | 允许候选实现 Agent | 主 Agent（用户确认后回写） | 派发前检查；不派则不建 |

### 6. UI / 联调（停止点 6 及条件）

| 模板 | 变更包内文件名 | 何时拷 | 作用 | 谁填 | 谁检查 |
|---|---|---|---|---|---|
| `ui-rule-checklist.md` | `ui-rule-checklist.md` | 条件：PRD UI / 交互编码 | UI 规范逐项、缺口 | 主 Agent | `ui-rule-gate.sh` |
| `ui-confirmation.md` | `ui-confirmation.md` | 条件：复杂 UI | 可运行页 / 截图后的确认记录 | 主 Agent；用户看页面后写 `CONFIRMED` | `ui-confirmation-gate.sh` **RZ 未拷** |
| `local-routing.yml` | `local-routing.yml` | 条件：本地前后端联调 | 前端打哪套后端 / 代理。标本生成脚本 **RZ 未拷**，命中时手写 | 主 Agent | `local-routing-gate.sh` **RZ 未拷** |
| `pc-e2e-smoke-plan.md` | `pc-e2e-smoke-plan.md` | 条件：PC 真浏览器冒烟 | 冒烟计划 | 主 Agent | 无专用 RZ gate；真 E2E 须先过 `environment-readiness-gate.sh` |
| `pc-e2e-smoke-report.md` | `pc-e2e-smoke-report.md` | 同上 | 冒烟结果摘要 | 主 Agent | 同上 |
| `miniapp-local-env.md` | `miniapp-local-env.md` | 条件：改小程序本地环境 | 小程序本地运行约定 | 主 Agent | `miniapp-local-env-gate.sh` **RZ 未拷** |
| `temporary-state-ledger.md` | `temporary-state-ledger.md` | 条件：本地服务、测试数据、debug 开关 | 临时状态清理台账 | 主 Agent | `temporary-state-ledger-gate.sh` **RZ 未拷** |

### 7. 环境就绪（停止点 4）

见建包表中的 `environment-readiness.md`。

### 8. 验收（停止点 7 / 8 / 9）

见建包表中的 `test-agent-verification.md`、`ai-test-report.md`、`review.md`。

| 模板 | 变更包内文件名 | 何时拷 | 作用 | 谁填 | 谁检查 |
|---|---|---|---|---|---|
| `codegraph-evidence.md` | `codegraph-evidence.md` | 条件：改公共 API / 权限等；可选 | 结构影响线索 | 主 Agent | 可选，不是关卡 |

### 9. 合并前 / 收口

| 模板 | 变更包内文件名 | 何时拷 | 作用 | 谁填 | 谁检查 |
|---|---|---|---|---|---|
| `pre-pr-review.md` | `pre-pr.md` | 合并前 | 人审包、残余风险 | 主 Agent | `diff-hygiene-gate.sh`、`temp-hardcode-scan.sh`（检查项，不是拍板停止点） |
| `retro.md` | `retro.md` | 收口时，可后补 | 复盘 | 主 Agent | 无单独过门；大文件不进 git |

## 速查：模板文件名 → 变更包文件名

| 模板 | 拷到变更包后 |
|---|---|
| `spec-tier-s.md` / `spec-tier-m.md` / `spec-tier-l.md` | `spec.md` |
| `plan-tier-m.md` | `plan.md` |
| `api-contract.md` | `contract.md` |
| `pre-pr-review.md` | `pre-pr.md` |
| 其余同名 | 同名 |

## 无模板、按约定自建

这些会出现在变更包里，但 `templates/` 没有对应文件：

| 变更包文件 | 怎么来 |
|---|---|
| `evidence.md` | scaffold 当场生成空表 |
| `capability-spec.md` / `behavior-spec.md` | 条件：复杂状态机 / 权限 / 跨端；按 AGENTS 自建 |
| `data-model.md` | 改 DB 时对照方案自建（SQL 用 `data-model-sql.md`） |
| `verification-run-report.md` | 标本 `verification-run.sh` **RZ 未拷**；有可执行验证行时主 Agent 手工写 |
| `handoff.md` | 换线程 / 暂停时按 handoff skill 章节自建；给下一个主 Agent，不是子 Agent 信箱 |

## 标本有、RZ 未拷（需要时再补）

`frontend-style-profile.md`、`business-repo-agents-stub.md`、`codex-agent.toml`、`local-backend-services.yml`、`harness-state.yml`、`implementation-decision-matrix.md`、`local-dev-readiness.md`。
