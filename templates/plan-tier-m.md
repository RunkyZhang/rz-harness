# 实施计划：<change-id>

> 面向人工 review 的计划默认中文；代码标识、命令、API 路径、字段名、错误码、YAML key、日志 key 和引用原文保持原样。

## 输入

| Item | Path |
| --- | --- |
| Spec | `changes/<change-id>/spec.md` |
| Contract | `changes/<change-id>/contract.md` |
| Harness status | `changes/<change-id>/harness-status.md` |
| Technical solution | `changes/<change-id>/technical-solution.md` |
| Verification map | `changes/<change-id>/verification-map.md` |
| Skill usage | `changes/<change-id>/skill-usage.md` |
| Frontend baseline | `baselines/frontend-map-system.md` |
| Backend baseline | `baselines/backend-sales-management.md` |

## Frontend Style References

```yaml
style_sample_references_status: PENDING
style_profile: baselines/<frontend-repo>-style-profile.md
```

> 涉及前端 UI / 页面代码时必填；纯后端或非 UI change 可写 `N/A: reason`。样板引用不是装饰项，后续 Reviewer 的 `style_conformance` 必须对照这里检查。

| Surface | Repo sample path | Reused skeleton / class / pattern | Difference from PRD | Decision |
| --- | --- | --- | --- | --- |
| `<list/detail/form/export>` | `<repo/path.vue>` | `<class/component/api pattern>` | `<PRD 特有差异>` | `reuse / user-confirmed deviation / N/A: reason` |

## Global Constraints

> 每个实施任务、实现 Agent、Tester 和 Reviewer 都默认继承本节。只写已确认事实；
> 不得把 `[ASSUMP]`、未决 `[QUESTION]`、临时环境口径或未获准路径放入本节。

| Constraint | Source | Verification |
| --- | --- | --- |
| `<不可修改生产配置 / secrets / DB migration / 部署脚本等>` | `AGENTS.md` / `spec.md` / `contract.md` | `allowed-paths.sh` / `business-code-start-gate.sh` / Reviewer |
| `<本次允许修改的 repo / module / path>` | `contract.md allowed_paths` | `gates/business-code-start-gate.sh changes/<change-id> <files...>` |
| `<字段、状态、权限、错误码、默认值等已确认事实>` | `spec.md` / PRD / 用户确认 | `verification-map.md` / targeted test / PC smoke |
| `<版本、运行环境、Node/Maven/profile 限制>` | `baselines/*` / `environment-readiness.md` | `canonical-command-gate.sh` / repo-specific command |

## Task Handoff Contract

> 多 Agent 或长上下文执行时，主 Agent 应把任务正文、报告和 review diff 写入
> `.harness/agent-work/<change-id>/`，避免在对话里反复粘贴长任务和 diff。

每个 Task 必须包含：

- `Files`：明确 create / modify / test 文件，路径精确到文件或目录。
- `Interfaces`：写清本任务 consumes / produces 的 DTO、API、函数、字段、事件或文档产物。
- `独立验证`：写清本任务自己的最小验证命令、预期结果和 evidence 路径。
- `Handoff`：需要派发 Agent 时，先运行 `scripts/agent-task-brief.sh <plan-file> <task-number> <change-id>`；Reviewer 输入优先使用 `scripts/agent-review-package.sh <base> <head> <change-id>` 生成的文件。

## 进入实现前门禁

- [ ] `confidence-gate.sh` 已通过；非阻塞问题已放在 `non_blocking_questions:`。
- [ ] `assumption-leak-gate.sh` 已通过，确保 `[ASSUMP]` 没有进入实现文件。
- [ ] 已按 `templates/technical-solution.md` 生成全栈技术方案文档，并完成人工确认；方案已按 PRD 逐项覆盖后端、PC Web、H5、小程序、APP、导出、埋点/分析、DB、job/MQ 中所有适用端；如写入飞书，主流程图、ER 图和状态/关系图必须是 `whiteboard`，不得残留 `lang="mermaid"` 代码块。
- [ ] 已运行 `gates/technical-solution-gate.sh changes/<change-id>`；技术方案 `confirmation_status: CONFIRMED` 且 `allowed_next_stage` 允许进入当前阶段。
- [ ] 已复制 `templates/verification-map.md` 到 `changes/<change-id>/verification-map.md`，将关键约束映射到验证命令、人工确认或 `N/A:` 原因，并运行 `gates/verification-map-gate.sh changes/<change-id>`。
- [ ] 已复制 `templates/harness-status.md` 到 `changes/<change-id>/harness-status.md`，并在每次阶段切换、阻塞、人工确认、进入预发前更新。
- [ ] 多仓 / 全栈需求已在 `harness-status.md` 填写 `Workstream Dispatch`，拆分后端、PC、小程序等工作线；已运行 `scripts/workstream-dispatch-gate.sh changes/<change-id>`。
- [ ] 需要派发子 Agent 时，已填写 `changes/<change-id>/agent-dispatch-plan.md`（scaffold 空壳来自 `templates/agent-dispatch-plan.md`），并对照 `subagents/dispatch_subagent.md`。标本 `agent-dispatch-plan-gate.sh` RZ 未拷。candidate implementation 只有在 contract、allowed paths、隔离分支和 code-start gate 满足后，复制并确认 `templates/agent-candidate-confirmation.md`。
- [ ] 业务仓首次改代码前已运行 `gates/business-code-start-gate.sh changes/<change-id> <changed-files...>`；业务仓不在 `main/master`，且文件在 `contract.md` 的 `allowed_paths` 内。
- [ ] 如业务仓已有 dirty diff，已复制 `templates/dirty-worktree-ledger.md` 到 `changes/<change-id>/dirty-worktree-ledger.md`，并运行 `gates/business-dirty-worktree-gate.sh <repo> --ledger changes/<change-id>/dirty-worktree-ledger.md`。
- [ ] 已按 `docs/skills-routing.md` 读取命中的 harness skill，并复制 `templates/skill-usage.md` 到 `changes/<change-id>/skill-usage.md`。
- [ ] `gates/skill-usage-gate.sh changes/<change-id>` 已通过；命中场景未使用 skill 时已写 N/A reason。
- [ ] 所有 `[ASSUMP]` 已确认、删除或降级为非实现项。
- [ ] 需求理解流程图已写入 spec 或 plan；涉及异步、审批、待办、通知、定时任务/MQ 或跨仓流程时必须覆盖主路径和异常分支。
- [ ] 已判断是否需要 `changes/<change-id>/capability-spec.md` 或 `behavior-spec.md`；如需要，已写入复杂状态机、权限、跨端一致性或能力边界，并在 `verification-map.md` 映射验证方式。
- [ ] 如涉及 DB schema 或持久化状态，已按 `templates/data-model-sql.md` 写 data model 文档，包含可复制执行 SQL、ER 图、字段来源/用途和范式检查。
- [ ] 已填写 Implementation Decision Matrix；所有准备进入代码/SQL/接口/权限/状态/错误码/默认值/adapter/回滚的决定均为可追溯事实。
- [ ] `allowed_paths` 已覆盖本次所有计划修改文件，且后端路径已收窄到目标模块；如触碰 protected paths，spec 已写入 `approved_protected_paths` 和用户确认来源。
- [ ] Contract 已写清 request、response、error、empty state、pagination。
- [ ] 如涉及 Java 后端，Backend Agent 已读取 `docs/standards/java/README.md` 和 `alibaba-java-review-checklist.md`。
- [ ] 如涉及 Java 后端，已计划对本次 Java/XML 改动运行 `java-mechanical-quality.sh`。
- [ ] 如涉及 Java 后端行为变更，已复制 `templates/backend-test-plan.md` 到 `changes/<change-id>/backend-test-plan.md`，并列出 validation、permission、state transition、idempotency、async/job、adapter failure、rollback/error 的适用测试矩阵；缺失项必须标记 `BLOCKED` 或写明不适用原因。
- [ ] 如启用并行开发，已明确 Backend Agent / Frontend Agent 写入边界和契约变更通知方式。
- [ ] 如启用并行开发，后端/前端 Agent 已使用独立 git worktree，并通过 `parallel-worktree-gate.sh`。
- [ ] 如启用并行开发，控制面文件只允许主 Agent 写入。
- [ ] 如触发复杂 UI，已复制 `templates/ui-confirmation.md` 到 `changes/<change-id>/ui-confirmation.md`，先生成可交互 HTML 原型或首个可运行页面，记录打开方式、覆盖交互点和人工 / 工人确认结论；确认前不得进入正式 Vue 页面实现或最终 review。
- [ ] 用户确认本计划后，主 Agent 默认自动执行到人工验收点、阻塞点或风险决策点；不得在机械步骤完成后停下询问是否继续。
- [ ] 已计划 PC E2E Smoke 的目标 URL、登录态、测试数据和截图证据；如无法执行，阻塞原因必须写入 evidence。
- [ ] 如 PC E2E Smoke 需要访问本地后端，已声明 active backend 项目并生成 `changes/<change-id>/local-routing.yml`，且 route 只覆盖本次真实启动的后端项目。
- [ ] 如 PC E2E Smoke 需要访问本地后端，已运行 `scripts/local-routing-business-config-gate.sh <changed-frontend-files...>`，没有为了本地代理修改业务前端 `vue.config.js` 或 `.env*`。
- [ ] 如小程序本地联调需要环境 override，已复制 `templates/miniapp-local-env.md` 到 `changes/<change-id>/miniapp-local-env.md`，记录 `bd_owner_env_override` 当前值、实际请求 host、重新进入小程序和清理命令，并运行 `scripts/miniapp-local-env-gate.sh changes/<change-id>`。
- [ ] 本地联调 / SIT 自测产生临时服务、storage、qrToken、测试数据、vConsole 或 proxy 状态时，已复制 `templates/temporary-state-ledger.md` 到 `changes/<change-id>/temporary-state-ledger.md`，结束前运行 `scripts/temporary-state-ledger-gate.sh changes/<change-id>`。
- [ ] 验证命令执行前已运行 `scripts/canonical-command-gate.sh -- <command>`；后端 Maven reactor 命令没有遗漏 `-am`。
- [ ] 已计划合并前临时写死扫描：`gates/temp-hardcode-scan.sh <changed-files...>`。
- [ ] 已按 `docs/architecture/changes-retention-policy.md` 规划过程产物位置：Git 只保留轻量 Markdown 摘要，大文件放 `artifacts/<change-id>/` 或外部存储。

## 自动执行边界

用户确认 `spec.md`、`changes/<change-id>/contract.md`、`technical-solution.md` 和本计划后，主 Agent 持续执行下面的 checklist，直到到达人工验收点、阻塞点或风险决策点。

继续执行条件：

- 当前动作已在本计划中，且文件落在 `allowed_paths` 内。
- 没有新的阻塞性 `[QUESTION]`，也没有 `[ASSUMP]` 准备进入实现。
- 只是在已确认范围内实现、补 evidence、修复本次改动引入的验证失败、补跑门禁或整理 review 包。
- 校验失败可在本次改动范围内安全修复，不需要扩大 scope。

停止并报告条件：

- 需要用户确认复杂 UI HTML 原型、人工浏览器 SIT、最终验收或残余风险接受。
- 出现新的业务口径、字段语义、状态流转、权限、错误码、默认值或回滚策略问题。
- 需要修改 protected paths、生产配置、secrets、DB migration、部署脚本、发布脚本、目标分支或发布范围。
- 账号、登录态、测试数据、依赖、服务或外部环境缺失，导致无法继续验证。
- 校验失败涉及历史问题、范围外文件，或无法确定修复是否安全。

到达停点时，输出验收 URL / 原型文件 / 报告路径、已跑命令、evidence、未覆盖项和需要用户判断的问题；阻塞项必须标记为 `BLOCKED`。

## 实施步骤

1. 后端样板确认：列出 controller、service、DTO、test 参考路径。
2. Skill 路由：按 `docs/skills-routing.md` 记录 `grill` / `explorer` / `diagnose` / `tdd` / `reviewer` / `handoff` 的 USED 或 N/A。
3. 前端样板确认：先记录用户是否指定 UI 参考页；如用户指定 URL、截图或页面路径，该参考页优先级高于 harness 默认样板，必须写明实际复用的页面骨架和全局 class；如用户未指定，再列出 2-3 个同模块页面样板。临时路由、审核/运营类后台页优先确认是否应参考 `src/views/audit/rectification/list.vue` 与 `src/views/audit/rectification/detail.vue`。
4. 复杂 UI 判定：如触发复杂 UI，先复制 `templates/ui-confirmation.md` 到 `changes/<change-id>/ui-confirmation.md`，再生成 `artifacts/<change-id>/ui-prototype/frontend-ui-prototype.html` 或 plan 指定的等价可运行页面，用 mock 数据覆盖核心布局、主路径交互、空态 / 错误态和关键状态反馈；人工 / 工人确认结论写入 `ui-confirmation.md` 和 evidence 后，才能进入正式 Vue 页面实现。
5. 全栈技术方案确认：按 `templates/technical-solution.md` 先做 PRD 端到端覆盖矩阵，再汇总范围分工、关键业务结论、跨端主流程、后端设计、PC Web/H5/小程序/APP 页面方案、数据模型、API、导出、埋点/分析、测试、发布、回滚和风险；给人工确认。飞书文档中的主流程图、ER 图和状态/关系图必须用 `whiteboard`，不能用 Mermaid 代码块。
6. Verification Map：复制 `templates/verification-map.md` 到 `changes/<change-id>/verification-map.md`，把“什么叫做对”的关键约束逐条映射到命令、PC smoke、SQL 只读查询、人工确认或 `N/A:` 原因；运行 `gates/verification-map-gate.sh changes/<change-id>`。
7. Contract v0.1 冻结：确认 endpoint、request、response、分页、空态、错误处理；如涉及 DB，确认 data model SQL、ER 图和字段理由；如需要独立能力/行为规格，确认 `capability-spec.md` 或 `behavior-spec.md`。
8. Workstream Dispatch：多仓 / 全栈需求先在 `harness-status.md` 拆后端、PC、小程序等工作线，运行 `scripts/workstream-dispatch-gate.sh changes/<change-id>`；无法并行时写 `DEGRADED:` 原因。
9. Agent Dispatch Plan：需要派发 Explorer / Reviewer / Tester / Test Strategy / Backend / Frontend / Mobile 时，填写 `changes/<change-id>/agent-dispatch-plan.md`，对照 `subagents/dispatch_subagent.md`。启用 Backend / Frontend / Mobile 前，先复制 `templates/agent-candidate-confirmation.md`，确认 `candidate_dispatch_confirmation: CONFIRMED`、`business_code_start_gate: PASS`、`allowed_paths_confirmed: yes`，并保持 `protected_actions_allowed: no`、`global_config_write_allowed: no`、`db_or_release_actions_allowed: no`。标本 `agent-output-contract-gate.sh` RZ 未拷。
10. Business code-start：业务仓第一次改代码前运行 `gates/business-code-start-gate.sh changes/<change-id> <changed-files...>`，确认分支不是 `main/master` 且路径已获准。
11. 后端测试计划：如涉及 Java 后端行为变更，先填写 `backend-test-plan.md`；测试矩阵至少覆盖本次适用的参数校验、权限、状态流转、幂等、异步/job、外部 adapter/RPC 失败、回滚/错误落库和自定义 mapper/update count。
12. 后端实现：先测试/DTO/contract，再 application/service，再 controller。
13. 前端实现：基于 contract v0.1 和 mock 数据并行开发页面状态、表单、列表、详情。
14. 后端 Java 规范门禁：运行 `java-mechanical-quality.sh` 检查本次 Java/XML 改动，warning 写入 evidence。
15. 后端验证：先运行 `scripts/canonical-command-gate.sh -- <mvn command>`，再运行最窄 Maven compile 和 `backend-test-plan.md` 中的 targeted test；测试缺失或失败不得进入最终 review，除非用户明确接受残余风险。
16. 前端验证：优先运行本次改动文件的窄范围 ESLint；只有确认不会污染范围外 diff 时再运行全量 lint / build。
17. Contract 对齐：逐字段核对前端映射与后端响应。
18. CodeGraph preflight：对相关业务仓运行 `scripts/codegraph-preflight.sh <repo-id-or-path>`，把输出写入 `codegraph-evidence.md`；MCP 查询必须显式使用 preflight 输出的 `CODEGRAPH_PROJECT_PATH` 作为 `projectPath`。优先用 `codegraph_explore` 回答结构 / route / flow 问题；再用 `codegraph_node`、`codegraph_search`、`codegraph_callers` / `codegraph_trace` 做精确跟进。只有 stale / PARTIAL / MISS / UNAVAILABLE 时才用 `--sync`、`rg`、直接读文件或测试证据降级；不能当作阻断或无影响证明；运行 `scripts/codegraph-evidence-gate.sh changes/<change-id>`。
19. 临时写死扫描：运行 `gates/temp-hardcode-scan.sh <changed-files...>`；命中 `CODX` / `smoke` / `mock` / `localhost` / `token` / `password` / `TODO` / `FIXME` 时先移除、配置化或记录已审 false positive。
20. PC E2E Smoke：复制 `templates/pc-e2e-smoke-plan.md` 到 `changes/<change-id>/pc-e2e-smoke-plan.md`；如需本地后端，声明 active backend 项目并运行 `scripts/generate-local-routing.sh` 生成 `changes/<change-id>/local-routing.yml`，再运行 `scripts/local-routing-gate.sh` 和 `scripts/local-routing-business-config-gate.sh <changed-frontend-files...>`；使用真实浏览器验证页面打开、默认查询、核心筛选、分页或列表刷新、详情、返回、空态或错误态；结果写入 `pc-e2e-smoke-report.md` 和 `evidence.md`。
21. AI 测试报告：复制 `templates/ai-test-report.md` 到 `changes/<change-id>/ai-test-report.md`，汇总后端 targeted tests、接口、PC E2E、截图、SQL/API 观察、未覆盖项和残余风险；人工确认前不得进入测试 / 预发发布。
22. 预发前确认：运行 `gates/ai-test-report-gate.sh changes/<change-id>`；只有 `confirmation_status: CONFIRMED` 且 `recommendation: 允许进入预发` 才允许进入测试 / 预发发布。
23. 状态卡更新：运行 `scripts/harness-status.sh changes/<change-id>`，把输出同步或整理进 `harness-status.md`，作为用户查看“当前走到哪一步”的入口。
24. 产物整理：保留轻量 Markdown 摘要；将截图、录屏、trace、完整长日志、临时原型草稿和数据快照移动到 `artifacts/<change-id>/` 或外部存储，并在 evidence / report 中记录路径。
25. Reviewer：只读审查 spec、plan、contract、contract-delta、technical-solution、diff、evidence、backend-test-plan、pc-e2e-smoke-plan、pc-e2e-smoke-report、test-agent-verification、ai-test-report 和 harness-status，并按 Java checklist 复核后端改动；输出 `review.md` 后运行 `scripts/agent-output-contract-gate.sh changes/<change-id> Reviewer` 和 `gates/reviewer-gate.sh changes/<change-id>`。
26. 人工 review：用户确认 HIGH/MEDIUM 风险处理。

## Task 模板

```markdown
### Task N: <任务名称>

**Files:**
- Create: `<path>`
- Modify: `<path>`
- Test: `<path or N/A: reason>`

**Interfaces:**
- Consumes: `<上游 contract / DTO / API / state / document artifact>`
- Produces: `<下游依赖的字段 / 方法 / endpoint / evidence / report>`

**Handoff:**
- Task brief: `scripts/agent-task-brief.sh changes/<change-id>/plan.md N <change-id>`
- Progress ledger: `.harness/agent-work/<change-id>/progress-ledger.md`

- [ ] **Step 1: 写失败测试或等价门禁 fixture**

Run: `<command>`
Expected: `<expected failure proving the missing behavior>`

- [ ] **Step 2: 实现最小变更**

Scope: `<只改本任务 Files 中列出的文件>`

- [ ] **Step 3: 独立验证**

Run: `<narrowest useful command>`
Expected: `<PASS / expected output>`
Evidence: `<changes/<change-id>/evidence.md or artifact path>`

- [ ] **Step 4: Review package**

Run: `scripts/agent-review-package.sh <base> <head> <change-id>`
Expected: `.harness/agent-work/<change-id>/review-<base>..<head>.diff`
```

## 并行 Agent 规则

| Agent | 可写范围 | 契约权限 | 必须输出 |
| --- | --- | --- | --- |
| Backend Agent | 后端独立 worktree 内的 Java、Mapper、后端测试；读取 change package，不在业务仓新建 OpenSpec | 只允许提出 contract delta；由主 Agent 合并控制面 contract、plan 和 verification map | Maven/targeted test 证据；如需改契约或任务，输出 delta 建议 |
| Frontend Agent | 前端独立 worktree 内的 Vue 页面、路由、前端 API 调用、前端 mock | 只读 contract；只按 delta 适配 | 窄范围 ESLint/build 证据；前端字段映射说明 |
| 主 Agent | 控制面 plan/evidence/review 协调、最终集成 | 唯一可写控制面；合并契约变更并通知前端 Agent | worktree gate、allowed paths、confidence gate、review |

Worktree 隔离规则：

1. Backend Agent 不直接写主业务仓，必须写后端独立 worktree。
2. Frontend Agent 不直接写主业务仓，必须写前端独立 worktree。
3. 实现 Agent 不得修改控制面文件；控制面只由主 Agent 更新。
4. Backend Agent 必须读取 Java 规范门禁文档并运行 `java-mechanical-quality.sh`。
5. 主 Agent 集成后必须重新运行 `java-mechanical-quality.sh`。
6. 即使后端、H5、iOS、Android 是不同 Git 仓，也默认给实现 Agent 使用独立 worktree；原因是保护主业务工作树、保留独立分支和 diff，方便主 Agent 独立集成或回退。
7. 主 Agent 在派发实现前运行：

```bash
scripts/parallel-worktree-gate.sh /path/to/backend-worktree /path/to/frontend-worktree
```

多 Agent 等待与集成规则：

1. 主 Agent 派发实现 Agent 后必须保持执行，不得只输出“Agent 已派发/等待返回”后停止。
2. 主 Agent 必须持续等待，直到所有 Agent 返回 `completed`、返回 blocker/risk，或用户明确要求暂停。
3. Agent 返回后，主 Agent 负责读取各 worktree diff、同步 contract delta、更新 evidence/status、运行集成验证，再进入下一 gate。
4. 只有遇到跨 Agent 契约冲突、环境阻塞、真实环境写入、UI 人工确认或高风险决策时，才停止等待用户。

契约变更同步规则：

1. Backend Agent 需要改 contract 时，先停止实现并输出 delta 建议，不直接改控制面 contract。
2. 主 Agent 合并 contract 后，必须追加 `changes/<change-id>/contract-delta.md`。
3. 主 Agent 必须把 delta 摘要发给 Frontend Agent。
4. Frontend Agent 继续开发前必须读取最新 contract 和 contract-delta。
5. Reviewer 必须检查“后端契约变更是否已被前端消费”。
6. 主 Agent 必须运行 `gates/contract-delta-gate.sh <changed-files...>`，并把 `NOTICE` 输出作为前端通知内容。

## 计划修改路径

```yaml
frontend:
  - $RZ_REPO_MAP_SYSTEM/src/**
backend:
  - $RZ_REPO_SFA_SALES_MANAGEMENT/**
control_plane:
  - rz-harness/changes/<change-id>/**
  - rz-harness/changes/<change-id>/contract.md
```

## 验证命令

```bash
gates/confidence-gate.sh changes/<change-id>/spec.md
gates/technical-solution-gate.sh changes/<change-id>
gates/verification-map-gate.sh changes/<change-id>
gates/assumption-leak-gate.sh changes/<change-id>/spec.md <changed-files...>
scripts/workstream-dispatch-gate.sh changes/<change-id>
gates/business-code-start-gate.sh changes/<change-id> <changed-files...>
scripts/parallel-worktree-gate.sh /path/to/backend-worktree /path/to/frontend-worktree
gates/contract-delta-gate.sh <changed-files...>
gates/allowed-paths.sh changes/<change-id>/spec.md <changed-files...>
scripts/java-mechanical-quality.sh "$RZ_REPO_SFA_SALES_MANAGEMENT" <changed-java-or-xml-files...>
scripts/canonical-command-gate.sh -- mvn -pl sfa-sales-management-interfaces -am -DskipTests compile
scripts/mvn-targeted-test.sh "$RZ_REPO_SFA_SALES_MANAGEMENT" <module> compile
scripts/frontend-lint-build.sh "$RZ_REPO_MAP_SYSTEM" lint-files src/views/<feature>/*.vue
scripts/generate-local-routing.sh --change-id <change-id> --frontend-repo frontend-map-system --active-backends backend-sales-management,backend-sfa-backend --services templates/local-backend-services.yml --output changes/<change-id>/local-routing.yml --env-output artifacts/<change-id>/pc-e2e-smoke/frontend.env
scripts/local-routing-gate.sh changes/<change-id>/local-routing.yml
scripts/local-routing-business-config-gate.sh <changed-frontend-files...>
RZ_HARNESS_SMOKE=1 RZ_HARNESS_PROXY_LOG=artifacts/<change-id>/pc-e2e-smoke/local-proxy.ndjson node scripts/harness-local-proxy.mjs changes/<change-id>/local-routing.yml
VUE_APP_BASE_API=http://127.0.0.1:19080/ npm run dev
# PC E2E Smoke 使用真实浏览器执行；把 URL、步骤、截图路径和接口观察写入 changes/<change-id>/pc-e2e-smoke-report.md
gates/ai-test-report-gate.sh changes/<change-id>
scripts/harness-status.sh changes/<change-id>
# 大体积产物放 artifacts/<change-id>/，Git 中只保留摘要和路径
```

## 回滚

- 后端：revert 对应分支提交；如新增 API 未被调用，可先停止前端入口。
- 前端：隐藏入口或 revert 页面/API 调用。
- 数据：Tier M 默认不改 DB schema；如实际需要，必须升级为 Tier L。

## 风险

| 风险 | 处理 |
| --- | --- |
| 前端依赖未安装导致 lint/build 不可跑 | 记录为阻塞验证缺口，不得声称前端验证通过 |
| 后端根编译耗时过长 | 优先使用模块级 `-pl <module> -am` |
| 字段语义不清 | 回到 contract，不在代码里猜 |
| `[ASSUMP]` 中的标识进入实现文件 | 先把假设升级为 `[FACT]` 或移出实现，再重跑 `assumption-leak-gate.sh` |
| 两个 Agent 并行导致字段漂移 | Backend Agent 只提 delta，主 Agent 合并 contract，Frontend Agent 通过 contract-delta 适配 |
| 多 Agent 共写工作树导致冲突 | 并行实现必须用独立 worktree；主 Agent 最终集成 |
| `npm run lint` 自动修改范围外文件 | 默认跑 `lint-files`；全量 auto-fix 后必须检查 diff 并清理或暂停 |
| 复杂 UI 直接进入 Vue 实现后返工 | 先用可交互 HTML 原型让人工 / 工人确认布局和关键交互；未确认则记录 `BLOCKED` |
| AI 在机械步骤后反复停下询问 | 用户确认 plan 后默认自动执行到人工验收、阻塞或风险决策点；停下必须说明停点类型 |
| `changes/` 被过程数据撑大 | Git 只提交轻量摘要；截图、录屏、trace、完整长日志和临时草稿放 `artifacts/<change-id>/` 或外部存储 |
| Agent 声称遵守 Java 规范但实际遗漏 | 机械门禁硬阻断可判断项；Reviewer 按 checklist 复核不可机器判断项 |
| PC E2E Smoke 缺少账号、登录态、测试数据或浏览器环境 | 记录为 `BLOCKED`，不得声称 E2E 通过；进入人工 SIT 前补齐条件或明确风险 |
| 本地前端默认访问测试环境，无法命中本地后端 | 使用 active backend 生成的 harness-only `local-routing.yml` 和本地 proxy；只声明本次真实启动的后端项目，其他请求 fallback |
| AI 测试报告未人工确认却进入预发 | `ai-test-report-gate.sh` fail-closed；状态卡必须显示 `AI测试待确认` |
