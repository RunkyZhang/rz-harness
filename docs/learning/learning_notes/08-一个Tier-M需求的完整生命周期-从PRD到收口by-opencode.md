# 08 - 一个 Tier M 中型需求的完整生命周期（从需求文档到收口）

> 目的：还原示例（`learning_objectives/sfa-ai-harness`）中一个 Tier M 中型需求从 PRD 进入到最终收口的**全部步骤、使用的文档、跑的脚本**。
> 用途：作为查阅手册，判断哪些文件保留、哪些舍弃；后续逐阶段深入提问用。
> 来源：`lanes/fullstack-crud.md`（Tier M 默认 lane）+ `docs/architecture/harness-workflow-and-design-principles.md` 完整工作流图 + `templates/` + `AGENTS.md` 交叉还原。示例的 `changes/` 无历史案例。

**场景设定**：用户给一份飞书 PRD（例如"业务员客户列表增加标签筛选+导出"），1 个前端仓 + 1 个后端仓，1-2 个 API。

---

## 总览：流程主链

```
需求进入 → spec → contract → 状态卡 → technical-solution → ai-test-plan
→ change package 补全 → environment readiness → code-start gates
→ 实现(业务仓 codex/<id> 分支) → evidence 收口
→ Test Agent 独立验收 → ai-test-report → Reviewer 只读审查
→ pre-merge 门禁 → 人工 review/PR/SIT → retro 收口
```

贯穿全程的三个机制：
- `[FACT] / [ASSUMP] / [QUESTION]` 置信度关卡（未解决的不得进入实现）
- `harness-status.md` 状态卡（每次阶段变化/阻塞/确认都更新，不是最后才写）
- skill 使用记录 `skill-usage.md`（命中场景先读 SKILL.md 再动手）

---

## 阶段 0：需求进入

| 动作 | 读 | 写 | 跑 |
|---|---|---|---|
| 定 change-id、选 lane、声明"本次流程和停止点" | `AGENTS.md`、`docs/skills-routing.md`、`lanes/fullstack-crud.md` | 无（或 `requirement-intake.md`） | — |

⚠️ AGENTS.md 硬性要求：**第一条用户可见回复必须列出全部停止点**：spec / contract / solution / test-plan / env / code-start / UI / DB / Tester / report / pre-merge 关卡。

---

## 阶段 1：Spec（需求理解）

| 动作 | 读 | 写 | 跑 |
|---|---|---|---|
| 拆 PRD：能查证的自己查（grill → explorer skill），查不到的问用户 | `templates/spec-tier-m.md`、`docs/domain-glossary.md`、`docs/architecture/repo-registry.md`、业务仓代码（只读） | `changes/<id>/spec.md` | `scripts/knowledge-reference-gate.sh` |

spec.md 必含内容：
- FACTS / ASSUMPTIONS / OPEN QUESTIONS 三清单
- PRD 全栈覆盖盘点表（每个 PRD 项 → 影响端 → 仓库 → 是否进入技术方案，`No/N/A` 必须写理由）
- allowed_paths / forbidden_paths / approved_protected_paths
- Implementation Decision Matrix（所有进代码的决定必须有来源）
- API 草案 + 请求/响应字段表
- 数据模型节（涉及 DB 时）
- 回滚路径

**停止点 1**：阻塞 `[QUESTION]` 未解决 / `[ASSUMP]` 未确认 → 不得进入下一阶段。

---

## 阶段 2：Contract（API 契约冻结）

| 动作 | 读 | 写 | 跑 |
|---|---|---|---|
| 冻结 endpoint、请求/响应字段、错误码、分页、空态 | `templates/api-contract.md` | `docs/contracts/<id>-api.md` | `scripts/contract-delta-gate.sh` |

---

## 阶段 3：状态卡（贯穿全程）

| 动作 | 读 | 写 | 跑 |
|---|---|---|---|
| 建用户可见的单一流程入口 | `templates/harness-status.md` | `changes/<id>/harness-status.md` | `scripts/harness-status.sh` |

状态卡内容：16 行 Gate 状态表、Agent Roster（子 Agent 职责表）、Workstream Dispatch、关键产物表、人工确认待办、残余风险。之后**每次阶段变化、阻塞出现/解除、Agent 返回都要更新重跑**。

---

## 阶段 4：Technical Solution（全栈技术方案，Tier M/L 必须）

| 动作 | 读 | 写 | 跑 |
|---|---|---|---|
| 按模板覆盖 PRD 全部端（后端/PC/H5/小程序/APP/导出/埋点/DB/Job），不能只写后端 | `templates/technical-solution.md`、对应仓 baseline（`docs/baseline/`） | `changes/<id>/technical-solution.md` | `scripts/technical-solution-gate.sh`；PRD 来自飞书时 `scripts/technical-solution-feishu-sync.sh`（同步到飞书子文档，后续本地修改必须重新同步） |

**停止点 2**：用户未确认 `CONFIRMED` → 不得写业务代码。

---

## 阶段 5：AI Test Plan（独立测试策略，方案确认后）

| 动作 | 读 | 写 | 跑 |
|---|---|---|---|
| 派独立 **Test Strategy Agent**（不是主 Agent 自己写） | `templates/ai-test-plan.md`、已确认的技术方案 | `changes/<id>/ai-test-plan.md` | `scripts/ai-test-plan-gate.sh` |

**停止点 3**：用户未确认测试方案 → 不得进入实现。

---

## 阶段 6：Change Package 补全（plan / 映射 / skill 记录）

| 动作 | 读 | 写 | 跑 |
|---|---|---|---|
| 写实施计划、约束→验证映射、skill 使用记录 | `templates/plan-tier-m.md`、`templates/verification-map.md`、`templates/skill-usage.md` | `changes/<id>/plan.md`、`verification-map.md`、`skill-usage.md` | `verification-map-gate.sh`、`skill-usage-gate.sh` |

---

## 阶段 7：Environment Readiness（需要真实 E2E 时）

| 动作 | 读 | 写 | 跑 |
|---|---|---|---|
| 记录环境、账号来源、联调拓扑、DB 写入边界、回滚、无明文凭据 | `templates/environment-readiness.md`、`local-dev-readiness.md` | `changes/<id>/environment-readiness.md` | `environment-readiness-gate.sh` |

**停止点 4**：真实 E2E 前必须 READY。

---

## 阶段 8：Code Start Gates（开工门禁，一次性）

| 动作 | 跑 |
|---|---|
| 置信度 / 假设泄漏 / 路径 / 分支四重检查 | `confidence-gate.sh`、`assumption-leak-gate.sh`、`allowed-paths.sh`、`business-code-start-gate.sh`（强制业务仓从 main/master 切 `codex/<change-id>` 分支，记录基线 commit） |
| 业务仓有脏 diff 时 | `business-dirty-worktree-gate.sh` + `templates/dirty-worktree-ledger.md`（先记录归属，避免覆盖用户工作） |
| 要派子 Agent 并行时 | `workstream-dispatch-gate.sh`、`agent-dispatch-plan-gate.sh`（+ `templates/agent-candidate-confirmation.md`、`business-repo-bootstrap.sh`） |

**停止点 5**：任一 gate 不过 → 停。

---

## 阶段 9：实现（业务仓内，`codex/<id>` 分支上）

| 谁 | 读 | 跑 |
|---|---|---|
| 后端 | `rules/backend-java.mdc`、仓 baseline、样板代码（explorer 产出） | 先写 `backend-test-plan.md`（tdd skill，行为变更必须有，否则 N/A 证据；仅编译不够）→ `canonical-command-gate.sh`（拦截非法 mvn reactor 命令）→ `mvn-targeted-test.sh` → `java-mechanical-quality.sh` → 启动走 `local-service-lifecycle.sh`（**HEALTH=UP + check-web-stack 才算可用**，mvn/nohup/端口成功都不够） |
| 前端 | `rules/frontend-vue2.mdc`、样板页面 | `frontend-lint-build.sh <repo> lint-files <files>`（窄范围优先）→ 复杂页面 `frontend-dev-server.sh frontend-map-system 9527`（验证登录流和临时路由） |
| 新增 VO | Swagger 规则 | `swagger-model-documentation-gate.sh`（新增响应 `*VO.java` 必须 `@ApiModel` + `@ApiModelProperty`） |

**Optional Packs**（按触发条件追加，未触发在 plan/evidence 写 `N/A:` 原因）：

| Pack | 触发条件 | 追加动作 |
|---|---|---|
| UI Pack | PRD UI/交互编码、复杂 PC 页面、用户给截图/URL | `ui-rule-checklist.md` + `ui-rule-gate.sh`；复杂 UI 还要 `ui-confirmation.md` + 可运行原型。**停止点 6**：UI 未 CONFIRMED 不得声明通过 |
| E2E Pack | 浏览器真实路径、本地前后端联调、PC smoke | `generate-local-routing.sh` → `local-routing.yml` → `local-routing-gate.sh` → `harness-local-proxy.mjs`；按 `lanes/pc-e2e-smoke.md` 产出 `pc-e2e-smoke-plan.md` / `report.md` |
| Impact Pack | 改公共 API/DTO/Service/Mapper/权限/登录等核心流程 | `codegraph-preflight.sh` + CodeGraph，或 GitNexus / rg 降级证据 |
| Temporary State Pack | 本地服务、临时数据、debug flag、mock 开关 | `temporary-state-ledger.md` + gate（避免临时状态遗留） |
| Test Agent Pack | Tier M/L、行为风险高、测试/预发前 | 见阶段 11 |
| Environment Pack | 环境/账号/数据/VPN/DB 权限影响验证 | 见阶段 7 |

---

## 阶段 10：证据与常规验证收口

| 动作 | 写 | 跑 |
|---|---|---|
| 记录命令 + 输出摘要到证据文件；跑 verification-map 里可执行行 | `changes/<id>/evidence.md`、`verification-run-report.md` | `verification-run.sh`、`code-comment-log-quality.sh`（注释/日志质量，warning 交 Reviewer 判断） |

---

## 阶段 11：Test Agent 独立验收（Tier M 默认触发）

| 动作 | 读 | 写 | 跑 |
|---|---|---|---|
| 独立 **Tester Agent** 对照已确认 ai-test-plan 验收；发现问题 → 主 Agent 修 → 复测循环 | `templates/test-agent-verification.md`、`ai-test-plan.md` | `changes/<id>/test-agent-verification.md`（只有 Tester 能写） | `test-agent-verification-gate.sh` |

**停止点 7**：非 `GOAL_ACHIEVED` 主 Agent 不得宣称目标达成（主 Agent 可以实现/修复/记录证据，但不能替代 Tester 裁决）。

⚠️ **若此后业务代码又变 → 验证作废，必须重跑或刷新。**

---

## 阶段 12：AI Test Report（进测试/预发前）

| 动作 | 写 | 跑 |
|---|---|---|
| 汇总测试结论、建议下一阶段 | `changes/<id>/ai-test-report.md` | `ai-test-report-gate.sh`（同时检查测试方案已确认 + Tester `GOAL_ACHIEVED`） |

**停止点 8**：报告未经人工确认 → 不得进测试/预发发布。

---

## 阶段 13：Reviewer 只读审查

| 动作 | 读 | 写 | 跑 |
|---|---|---|---|
| 独立只读 Reviewer 按固定顺序审查 | reviewer skill、`docs/standards/java/alibaba-java-review-checklist.md` | `changes/<id>/review.md`（HIGH/MEDIUM/LOW 风险） | `reviewer-gate.sh`（要求 `high_risk_count: 0`） |

Reviewer 审查顺序：spec → contract → technical-solution → plan → ai-test-plan → test-agent-verification → ai-test-report → 实际 diff → evidence。
必查项：未解决 QUESTION 是否进入实现 / ASSUMP 是否被当事实 / 是否越过 allowed_paths / 方案对齐 / 架构漂移 / 注释日志质量 / 测试证据。

**停止点 9**：HIGH 风险 > 0 → 回阶段 9 修。⚠️ **代码又变 → review 标 STALE，按需重跑 Tester，再重跑 Reviewer。**

---

## 阶段 14：Pre-merge 卫生门禁

| 动作 | 跑 |
|---|---|
| diff 卫生 + 临时写死扫描 | `diff-hygiene-gate.sh <repo> [--base <ref>] <files>`、`temp-hardcode-scan.sh <files>`；写 `changes/<id>/pre-pr.md`（模板 `pre-pr-review.md`） |

---

## 阶段 15：人工 Review / PR / SIT

交给用户人工 review、提 PR、走 SIT。harness 阶段到此结束。

---

## 阶段 16：Retro 收口

| 动作 | 写 | 跑 |
|---|---|---|
| 复盘 + 知识沉淀（更新 pitfall/sample/decision-log 的 `last_referenced` / `referenced_by`） | `changes/<id>/retro.md` | `retro-gate.sh`、`change-stage-gate.sh`；按 `docs/architecture/changes-retention-policy.md` 清理：Git 长期只保留可 review 的 Markdown 摘要，大文件放 `artifacts/<id>/` 或外部存储 |

---

## 随时插入：Handoff

上下文要压缩 / 暂停 / 切线程 / 阶段移交时：handoff skill → 写 `changes/<id>/handoff.md`（无 change-id 时写 `docs/decision-log/YYYY-MM-DD-handoff-<topic>.md`）。

---

## 9 个停止点汇总

| # | 停止点 | 条件 |
|---|---|---|
| 1 | Spec | 阻塞 QUESTION 未解决 / ASSUMP 未确认 |
| 2 | 技术方案 | 用户未确认 CONFIRMED |
| 3 | AI 测试方案 | 用户未确认 |
| 4 | 环境就绪 | 真实 E2E 前必须 READY |
| 5 | Code start | 任一开工 gate 不过（含分支保护） |
| 6 | UI 确认 | 复杂 UI 未 CONFIRMED 不得声明通过 |
| 7 | Test Agent | 非 GOAL_ACHIEVED 不得宣称达成 |
| 8 | AI 测试报告 | 未人工确认不得进测试/预发 |
| 9 | Reviewer | high_risk_count > 0 不得进人审 |

外加两条失效规则：**Tester 验证后代码再变 → 验证作废重跑；Reviewer 产出后代码再变 → 审查标 STALE 重跑**。

---

# 文件分类汇总（判断保留/舍弃用）

## A. 核心主链路（Tier M 每次都走，必留）

| 文件 | 角色 |
|---|---|
| `AGENTS.md` | 总契约 |
| `templates/spec-tier-s/m/l.md` | spec 三档 |
| `templates/api-contract.md` | 契约 |
| `templates/technical-solution.md` | 技术方案 |
| `templates/ai-test-plan.md` / `ai-test-report.md` | 测试方案/报告 |
| `templates/harness-status.md` | 状态卡（流程仪表盘） |
| `templates/plan-tier-m.md` | 实施计划 |
| `templates/verification-map.md` | 约束→验证映射 |
| `templates/skill-usage.md` | skill 使用记录 |
| `templates/test-agent-verification.md` | Tester 验收 |
| `templates/review.md` | Reviewer 产出 |
| `templates/pre-pr-review.md` / `retro.md` | 合并前/复盘 |
| evidence（自记，无模板） | 证据 |
| 6 个 skills（grill / explorer / diagnose / tdd / reviewer / handoff）+ `docs/skills-routing.md` | 方法论 |
| 13 个核心 gate：`confidence` / `assumption-leak` / `allowed-paths` / `business-code-start` / `technical-solution` / `ai-test-plan` / `ai-test-report` / `test-agent-verification` / `reviewer` / `skill-usage` / `verification-map` / `environment-readiness` / `diff-hygiene` + `temp-hardcode-scan` | 确定性门禁 |
| `lanes/fullstack-crud.md`、`bugfix-fast.md` | lane |
| `rules/*.mdc`（按自己技术栈留）+ `docs/architecture/repo-registry.md` | 分仓规则 |

## B. 条件触发（Optional Pack，建议留但可简化）

| 文件 | 触发场景 |
|---|---|
| `ui-rule-checklist.md` + `ui-confirmation.md` + 两个 gate | PRD UI / 复杂 UI |
| `data-model-sql.md` | DB 变更（ER + SQL + 范式检查 + 回滚） |
| `local-routing.yml` / `generate-local-routing` / `local-routing-gate` / `harness-local-proxy` | 本地前后端联调 |
| `backend-test-plan.md` | 后端行为变更 |
| `dirty-worktree-ledger.md` + gate | 业务仓有脏 diff |
| `contract-delta.md` + gate | 契约变更 |
| `capability-spec.md` / `behavior-spec.md` | 复杂状态机/权限/跨端一致性 |
| `verification-run*` | verification-map 有可执行行 |
| `code-comment-log-quality` | 注释/日志质量 |
| `canonical-command-gate` | mvn 命令拦截 |
| `mvn-targeted-test` | 窄范围测试 |
| `local-service-lifecycle` | 本地后端启动就绪判定 |
| `frontend-lint-build` / `frontend-dev-server` | 前端验证 |
| `swagger-model-documentation-gate` | 新增 VO |
| `temporary-state-ledger.md` + gate | 临时状态清理 |
| `pc-e2e-smoke lane` + plan/report 模板 | PC 冒烟 |

## C. 团队规模化/自演化设施（个人版可舍弃或后置）

| 类别 | 文件 | 判断 |
|---|---|---|
| 遥测 | `harness-telemetry-*`（8 个）、`harness-observability-ready`、`harness-weekly-audit-summary` | 舍 |
| Eval/金样 | `eval-*`、`harness-behavior-*`、`harness-*-golden-*`、`evals/`、`harness-replay-fixture-*`、`harness-live-*` | 舍（后置） |
| 多 Agent 编排 | `agent-dispatch-plan*`、`agent-registry-gate`、`agent-output-contract-gate`、`agent-review-package`、`agent-task-brief`、`agent-workspace`、`workstream-dispatch-gate`、`parallel-worktree-gate`、`codex-agent-generator`、`business-repo-bootstrap` | "without agent 执行核心"→ 大部分可舍 |
| 团队推广 | `team-rollout-preflight`、`harness-self-audit`、`harness-control-audit`、`no-personal-paths`、`knowledge-lint` | 后置 |
| ECC/third-party | `scripts/ecc/`、`skills/third-party/*` | 舍 |
| CodeGraph/GitNexus | `codegraph-*`、`gitnexus-*` | 可选，非 gate |
| 文档治理 | `superseded-docs-gate`、`decision-gate`、`adapter-compliance-gate`、`harness-gc`、`change-artifacts-gate`、`change-stage-gate` | 简化保留 |

**一句话结论**：示例约 130 个脚本，但 Tier M 单次需求真正触发的 gate 只有 **13 个核心 + 约 10 个条件触发**；遥测 / eval / 多 Agent 编排 / 团队推广是"平台化第二阶段"产物，个人建 harness 可以整块舍弃。
