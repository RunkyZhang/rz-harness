# 全栈 CRUD Lane

> 适用于 1 个 Vue2 页面 + 1-2 个 Java 接口 + 不动复杂状态机的低风险后台 CRUD。
>
> **RZ 本地化说明**：契约只写 `changes/<change-id>/contract.md`。`gitnexus-*` / `codegraph-*` / `workstream-dispatch-gate` / `parallel-worktree-gate` RZ 未引入 → 相关步骤记 `N/A`，**不得当 FAIL**。Skill 路由：`skills/skill_directory.md`。前端规则：`rules/frontend-vue2.mdc`、`rules/frontends/legacy-sfa/`。本 lane 常配档位 M，**不能豁免**技术方案、AI 测试方案、Tester、Reviewer。PC 冒烟不是开工主 lane，命中 E2E Pack 再读 `lanes/pc-e2e-smoke.md`。

## 适用条件

- 前端主仓：`$RZ_REPO_MAP_SYSTEM`
- 后端主仓：`$RZ_REPO_SFA_SALES_MANAGEMENT`
- 不修改生产配置、部署脚本、DB migration、复杂权限、复杂状态机。
- 如需要 DB schema、跨服务事务、MQ、定时任务，升级到 Tier L。

## 默认最小流程

适用于满足本 lane 适用条件的低风险 CRUD。M 档停止点 2 / 3 / 7 在默认流程内，不是 Optional Pack。

1. 建包：`changes/change-scaffold.sh --tier M <change-id>`。给用户的第一条回复包含本次停止点。`source config/runtime_local.sh`，路径空不要猜。
2. 把 spec 文首 `lane: TODO` 改成 `lane: lanes/fullstack-crud.md`，并写三标签和 `allowed_paths`。（停止点 1）
3. 状态卡 `Lane` 照抄 spec。spec 为准。
4. 创建 `changes/<change-id>/contract.md`，使用 `templates/api-contract.md`，冻结 endpoint、request、response、错误码、分页和空态。
5. 如涉及复杂状态机、权限矩阵或跨端一致性，创建 `capability-spec.md` 或 `behavior-spec.md`；普通 CRUD 记录 `N/A:` 原因。
6. 填写 `technical-solution.md`，用户确认后写成 `CONFIRMED`，运行 `gates/technical-solution-gate.sh`。（停止点 2）
7. 独立 Test Strategy 填写 `ai-test-plan.md`；用户确认后主 Agent 写成 `test_plan_status: CONFIRMED`，运行 `gates/ai-test-plan-gate.sh`。（停止点 3）主 Agent 不得代写测试方案正文。
8. 填写 `plan.md`、`verification-map.md`。
9. 填写 `skill-usage.md`；按 `skills/skill_directory.md` 读取命中 skill，运行 `gates/skill-usage-gate.sh changes/<change-id>`。
10. 运行 `gates/confidence-gate.sh`、`gates/assumption-leak-gate.sh`、`gates/verification-map-gate.sh changes/<change-id>` 和 `gates/allowed-paths.sh`。
11. 业务仓首次改代码前从远程主干拉 `harness/<change-id>`，运行 `gates/business-code-start-gate.sh`；禁止在 `main`/`master` 改业务代码。脏仓先写 `dirty-worktree-ledger.md` 并过 `business-dirty-worktree-gate.sh`。（停止点 5）
12. 按 `config/git-registry.md` 和目标仓 `config/baselines/` 读规则；`mapSystem` 读 `rules/frontends/legacy-sfa/manifest.yml` 中的 `legacy-sfa-web`。
13. 后端实现前确认是否需要 `backend-test-plan.md`；Maven 命令前先跑 `gates/canonical-command-gate.sh -- <mvn command>`。
14. 实现：只改 `allowed_paths`；前端优先复用样板；窄范围 `scripts/frontend-lint-build.sh <repo> lint-files <files...>`。命令追加 `evidence.md`。
15. 契约对齐：逐字段核对前端入参 / 展示和后端 request / response。
16. 命中下方 Optional Packs 时追加；未命中在 `plan.md` / `evidence.md` 写 `N/A:` 原因。复杂 UI 须 `ui-confirmation.md`。（停止点 6）
17. 注释 / 日志：`scripts/code-comment-log-quality.sh`，warning 写入 evidence 交 Reviewer。
18. 独立 Tester 对照已确认 `ai-test-plan.md` 维护 `test-agent-verification.md`，直到 `GOAL_ACHIEVED` 或 `BLOCKED`。主 Agent 不得自称 `GOAL_ACHIEVED`。（停止点 7）
19. 合并前扫描：`gates/diff-hygiene-gate.sh`、`gates/temp-hardcode-scan.sh`。
20. 刷新状态卡：`changes/status-card.sh changes/<change-id>`，再更新 `status-card.md`。
21. Reviewer 只读审查，输出 `review.md` 后运行 `gates/reviewer-gate.sh`。（停止点 9）
22. 用户人工 review。
23. 写 `pre-pr.md` 和 `retro.md`。大文件放 `changes/<change-id>/artifacts/`，不要摊到仓库根 `artifacts/`。

## Optional Packs

以下 pack 只在触发条件命中时追加；未触发时写 `N/A:` 原因。Test Strategy / Tester 已在默认流程，不放在本表「可选」里。

### UI Pack

触发条件：PRD UI / 交互编码、复杂 PC 页面、用户提供截图 / 页面 URL / 指定参考页，或 Harness UI 规范缺口。

追加动作：

- 创建 `changes/<change-id>/ui-rule-checklist.md`，使用 `templates/ui-rule-checklist.md`。
- 运行 `gates/ui-rule-gate.sh changes/<change-id>`。
- 复杂 UI 先生成可交互 HTML 原型到 `changes/<change-id>/artifacts/ui-prototype/`，人工确认后再进入正式页面实现；确认写入 `ui-confirmation.md`。
- `mapSystem` 使用 `scripts/frontend-dev-server.sh frontend-map-system 9527`，验证产品组登录流和临时路由菜单。

### E2E Pack

触发条件：需要浏览器真实路径、本地前后端联调、PC 管理后台冒烟、小程序本地 smoke，或用户要求 E2E 证据。

追加动作：

- PC 管理后台按 `lanes/pc-e2e-smoke.md` 执行，生成 `pc-e2e-smoke-plan.md` / `pc-e2e-smoke-report.md`。
- 需要本地后端时必须走 harness proxy 和 `local-routing.yml`，并运行 `gates/local-routing-business-config-gate.sh <changed-frontend-files...>`。
- 小程序本地联调记录 `miniapp-local-env.md`，并运行 `gates/miniapp-local-env-gate.sh changes/<change-id>`。
- 真 E2E 前 `environment-readiness.md` 须 `READY`。

### Report Pack

触发条件：提测 / 预发发布前，或档位 L（scaffold 已有空壳）。

追加动作：

- 创建 `ai-test-report.md`（M 提测时拷 `templates/ai-test-report.md`）。
- 前置：测试方案已确认 + Tester `GOAL_ACHIEVED`。
- 用户确认后写 `confirmation_status: CONFIRMED`；进预发还要 `recommendation: 允许进入预发`。
- 运行 `gates/ai-test-report-gate.sh changes/<change-id>`。

### Environment Pack

触发条件：真实 E2E、SIT/UAT/预发依赖、账号 / 数据 / VPN / 设备 / DB 权限、跨系统联调，或任何环境状态会影响验证结论。

追加动作：

- 创建 `changes/<change-id>/environment-readiness.md`（RZ 无 `local-dev-readiness.md` 模板，本地启动标准写进本文件即可）。
- 记录必测系统、运行标准、联调拓扑、角色账号**来源**、数据、DB/write 边界、回滚和阻塞。禁止明文密码。
- 真实 E2E 前运行 `gates/environment-readiness-gate.sh changes/<change-id>`。

### Temporary State Pack

触发条件：产生本地服务、storage、测试二维码、临时数据、debug flag、mock 开关或任何需要交接 / 清理的临时状态。

追加动作：

- 创建 `temporary-state-ledger.md`。
- 结束本地联调 / AI 测试报告前运行 `gates/temporary-state-ledger-gate.sh changes/<change-id>`。
- 未清理项必须标记为用户负责或写明保留原因。

### Impact Pack

触发条件：改公共 API / DTO / VO / RPC contract、Controller / Service / Mapper / shared util、删除 / 重命名 / 改方法签名、跨前后端 / 跨仓 / 跨模块、权限 / 登录 / 支付 / 库存 / 奖励 / 审核等核心流程，或用户明确要求影响分析。

追加动作：

- `scripts/gitnexus-*`、`scripts/codegraph-preflight.sh`、`gates/codegraph-evidence-gate.sh` RZ **未引入** → 用 `rg` / `git diff` / Maven / npm / Reviewer 兜底，在 `evidence.md` 写 `N/A:` 原因。不得因缺少这些脚本而 FAIL。

### Parallel Agent Pack

触发条件：API 契约达到 v0.1、前后端可分工、实现 agent 需要并行推进。

追加动作：

- 先创建后端 / 前端独立 git worktree。`gates/parallel-worktree-gate.sh` RZ 未拷 → 主 Agent 在 evidence 记录两个 worktree 路径、互不嵌套、不在控制面仓内；缺失该 gate **不是**阻断。
- Backend / Frontend 只写各自业务仓 worktree；主 Agent 单写控制面。须用户确认 `agent-candidate-confirmation.md`。
- Backend 只能提出 contract delta，由主 Agent 更新控制面 `contract.md`、plan 和 verification map。

## 有边界自动执行

用户人工确认 `spec.md`、`changes/<change-id>/contract.md`、`technical-solution.md`、`ai-test-plan.md` 和 `plan.md` 后，主 Agent 默认进入自动执行模式：持续按 plan checklist 推进实现、常规测试、证据和 review 包装，直到到达人工验收点、阻塞点或风险决策点。不得在「后端完成」「前端完成」「验证完成一个子项」这类机械阶段停下询问是否继续。Tester 验收仍由独立 Tester 裁决。

### 必须继续执行

- 当前动作已经写在确认后的 `plan.md` 中，且修改路径落在 `allowed_paths` 内。
- `ai-test-plan.md` 已经确认；否则只能继续完善测试方案，不能进入业务代码。
- 没有新的阻塞性 `[QUESTION]`，也没有 `[ASSUMP]` 准备进入实现。
- 只是在已确认范围内补代码、补契约消费、补 evidence、修复本次改动引入的 compile / lint / test 问题。
- 校验失败原因清楚，且修复只影响本次允许路径和本次改动范围。
- 需要补跑 `confidence-gate.sh`、`assumption-leak-gate.sh`、`allowed-paths.sh`、`contract-delta-gate.sh`、Maven / npm 窄范围验证、PC E2E Smoke 或 Reviewer 审查。
- 需要补跑 `code-comment-log-quality.sh`，或修复本次改动引入的注释 / 日志门禁问题。

### 必须停止并报告

- 需要用户确认 AI 测试方案、复杂 UI HTML 原型、UI 规范缺口、人工浏览器 SIT、最终人工验收或是否接受残余风险。
- 出现新的业务口径、字段语义、状态流转、权限、错误码、默认值或回滚策略问题。
- 需要修改 protected paths、生产配置、secrets、DB migration、部署脚本、发布脚本或目标分支 / 发布范围。
- 账号、登录态、测试数据、依赖、服务或外部环境缺失，导致无法继续验证。
- 校验失败涉及历史问题、范围外文件，或无法确定修复是否安全。
- 需要用户决定是否创建 PR、是否推送、是否进入 SIT 或是否扩大 allowed paths。

### 到达停点时的输出

- 人工验收：给出验收 URL、HTML 原型路径、测试方案、Tester 验收报告或 PC E2E Smoke 报告路径，并列出已跑命令、截图 / evidence、未覆盖项和需要用户确认的问题。
- 阻塞：用 `BLOCKED` 标记，写清阻塞条件、已尝试动作、不能继续自动执行的原因和最小用户输入。
- 风险决策：列出可选方案、推荐方案和不推荐继续自动化的具体原因。

## 并行开发模式

当 API 契约已经达到 v0.1 稳定状态时，允许 Backend 与 Frontend 并行开发。`parallel-worktree-gate.sh` 未引入时，隔离由主 Agent 记 evidence，不因缺 gate 阻断。

### 进入条件

- `spec.md` 无阻塞性 `[QUESTION]`。
- `changes/<change-id>/contract.md` 已写清 endpoint、request、response、error、empty state、pagination。
- `allowed_paths` 已分别覆盖后端、前端和控制面契约文件。
- DB 表关系、核心状态口径和权限方式已经确认。
- 计划中已经明确 Backend 与 Frontend 的写入边界。
- Backend 和 Frontend 已使用独立 git worktree；不得直接共写主业务仓工作树。
- 控制面只允许主 Agent 写入；实现 Agent 只读 `changes/<change-id>/contract.md` 和 `contract-delta.md`。

### Agent 分工

| Agent | 可写范围 | 契约权限 | 验证证据 |
| --- | --- | --- | --- |
| Backend | 后端独立 worktree 内的 Java、Mapper、后端测试；读取 change package，不在业务仓新建 OpenSpec | 只允许提出 contract delta；由主 Agent 合并控制面 contract、plan 和 verification map | Maven test/compile、verification evidence |
| Frontend | 前端独立 worktree 内的 Vue 页面、路由、前端 API 调用、前端 mock | 只读契约；不得直接修改 contract | 窄范围 ESLint/build 或阻塞原因 |
| 主 Agent | 控制面 plan/evidence/review、任务协调、最终集成 | 唯一可写控制面；合并 Backend 的契约变更并通知 Frontend | worktree 隔离记录、allowed paths、confidence gate、review |

### Worktree 隔离

- Backend 必须在后端业务仓的独立 worktree 中实现，不得直接写 `$RZ_REPO_SFA_SALES_MANAGEMENT` 主工作树。
- Frontend 必须在前端业务仓的独立 worktree 中实现，不得直接写 `$RZ_REPO_MAP_SYSTEM` 主工作树。
- 两个 implementation worktree 不能相同，不能嵌套在控制面仓库中，不能互相嵌套。
- 主 Agent 在集成前把两个 worktree 绝对路径写入 `evidence.md`（`parallel-worktree-gate.sh` RZ 未拷，本步不跑该脚本）。
- 实现 Agent 返回后，主 Agent 先审查 diff，再合并到目标业务仓或继续在隔离 worktree 中修正。

### 契约变更同步

- Backend 如果必须改契约，只能提交 contract delta 建议；主 Agent 负责更新 `changes/<change-id>/contract.md` 和 `changes/<change-id>/contract-delta.md`。
- Frontend 每次继续开发前必须检查 `contract-delta.md` 是否有新条目。
- 主 Agent 发现契约 diff 后，必须把 delta 摘要发送给 Frontend，前端只做适配，不反向改契约。
- 主 Agent 必须运行 `gates/contract-delta-gate.sh <changed-files...>`；如果输出 `NOTICE`，必须转发给 Frontend。
- Reviewer 必须检查契约 diff 是否已被前端实现消费。

### 前端校验策略

- Frontend 修改 `mapSystem` 前必须读取 `rules/frontend-vue2.mdc`、`rules/frontends/legacy-sfa/manifest.yml` 和 `legacy-sfa-web` 中与本次页面/API/UI 类型相关的 `web/*.mdc`。
- `web/effort-estimation.mdc` 是估时规则，不参与默认实现约束；只有用户要求前端估时时才读取。
- `sign-up` 不得默认套用 `legacy-sfa-web`，除非 spec 明确把该 profile 列为 `[FACT]`。
- 如果触发复杂 UI，Frontend 正式写 Vue 页面前必须先生成 `changes/<change-id>/artifacts/ui-prototype/frontend-ui-prototype.html` 或 plan 中指定的等价 HTML 原型，用 mock 数据覆盖核心交互，并等待人工确认；确认结果写入 `ui-confirmation.md` 和 evidence。未确认时只能继续 contract、mock、样板分析或原型修正，不得进入正式页面实现。
- 新增 `mapSystem` 管理后台页面前，Frontend 必须先抽样 2-3 个同模块或相邻模块页面，并在 plan/evidence 中记录参考路径、页面骨架和复用的全局 class。
- 如果用户在当前需求中提供 URL、截图、页面路径或明确指定参考页面，该参考页面优先级高于 harness 默认样板；Frontend 必须优先复用用户指定页面的骨架和 class，不能自行改用默认样板。
- 列表页按样板复用 `customerlist` 或 `specialAudit-container`、`new-header-wrapper`、`new-search-wrapper`、`el-table`、`all-el-pagination`；详情页按样板复用 `details add-post-details` 或 `specialDetail-container`、`content-container`、`content-header`、`content-body`。
- 临时路由、审核/运营类后台页优先确认是否参考 `src/views/audit/rectification/list.vue` 与 `src/views/audit/rectification/detail.vue`，不得直接套用自定义布局。
- Reviewer 必须检查前端页面是否遵循用户指定 UI 参考页或样板骨架；如果出现大面积自定义布局、scoped CSS 覆盖，或忽略用户指定参考页，应列为人工 review 风险。

- 默认先跑新页面/本次改动文件的窄范围 ESLint：

```bash
scripts/frontend-lint-build.sh "$RZ_REPO_MAP_SYSTEM" lint-files \
  src/views/<feature>/*.vue
```

- 不默认运行 `npm run lint`，因为该脚本包含 `eslint --fix --ext .js,.vue src`，可能自动修改范围外文件。
- 如必须运行全量 `npm run lint`，主 Agent 必须先记录风险；运行后若出现 allowed paths 外 diff，必须清理本次自动修复或暂停等待用户确认。

### 禁止项

- Frontend 不得为了页面方便自行改字段名、状态枚举或分页参数。
- Backend 不得只改 Java DTO 而不回写 contract。
- 两个实现 Agent 不得共写同一个 worktree 或同一个业务仓文件。
- 实现 Agent 不得直接修改控制面文件；控制面由主 Agent 单写。
- Frontend 不得默认运行会全仓 auto-fix 的 `npm run lint`。
- 契约未达到 v0.1 时不得并行实现，只能先补 contract。
- 复杂 UI 的 HTML 原型未经人工确认前，Frontend 不得开始正式 Vue 页面实现。

## 必须产物

默认（本 lane / 档位 M）：

| 文件 | 目的 |
| --- | --- |
| `changes/<change-id>/spec.md` | 事实、假设、问题、范围、`lane` |
| `changes/<change-id>/contract.md` | 前后端契约 |
| `changes/<change-id>/status-card.md` | 用户查看当前阶段、下一步、待确认项；文首 `Lane` |
| `changes/<change-id>/technical-solution.md` | 完整技术方案和人工确认状态 |
| `changes/<change-id>/ai-test-plan.md` | 独立 Test Strategy 生成并经用户确认的测试方案 |
| `changes/<change-id>/plan.md` | 实施顺序、路径、验证、回滚 |
| `changes/<change-id>/verification-map.md` | 约束如何验 |
| `changes/<change-id>/skill-usage.md` | 用过的 skill 或 N/A |
| `changes/<change-id>/evidence.md` | 命令证据 |
| `changes/<change-id>/test-agent-verification.md` | Tester 独立验收 |
| `changes/<change-id>/review.md` | Reviewer 输出 |
| `changes/<change-id>/pre-pr.md` | PR 前自审 |
| `changes/<change-id>/retro.md` | 复盘 |

条件产物（未命中写 `N/A:`）：

| 文件 | 何时 |
| --- | --- |
| `environment-readiness.md` | 真 E2E / Environment Pack |
| `ui-rule-checklist.md` / `ui-confirmation.md` | UI Pack / 复杂 UI |
| `contract-delta.md` | 并行且契约有增量 |
| `pc-e2e-smoke-plan.md` / `pc-e2e-smoke-report.md` | E2E Pack |
| `ai-test-report.md` | Report Pack（提测 / 预发） |
| `backend-test-plan.md` | Java 行为变更 |

## 过程产物保留

- `changes/<change-id>/` 是变更包控制面；整包不进 git。截图、录屏、trace、完整长日志放 `changes/<change-id>/artifacts/`。
- PC E2E Smoke 截图默认放在 `changes/<change-id>/artifacts/pc-e2e-smoke/`，report 只记录路径、用途和结论。
- 完整 Maven / npm / browser 自动化日志默认放在 `changes/<change-id>/artifacts/raw-logs/`，`evidence.md` 只保留命令、结果、关键错误和 artifact 路径。
- 复杂 UI 原型放 `changes/<change-id>/artifacts/ui-prototype/`。
- AI 默认只读取当前 active change；历史 `changes/` 只能按明确线索定向检索，不得全量灌入上下文。

## 阻断条件

- 有未解决的阻塞性 `[QUESTION]`。
- 有 `[ASSUMP]` 准备进入实现。
- 技术方案未通过 `gates/technical-solution-gate.sh changes/<change-id>`。
- 业务仓首次改代码前未通过 `gates/business-code-start-gate.sh changes/<change-id> <changed-files...>`。
- 业务仓存在 dirty diff 但没有通过 `gates/business-dirty-worktree-gate.sh` 记录归属。
- AI 测试方案缺失、未确认，或未通过 `gates/ai-test-plan-gate.sh changes/<change-id>`。
- 真实 E2E / 联调测试需要环境，但 `environment-readiness.md` 未达到 `READY` 或未通过 `gates/environment-readiness-gate.sh`。
- PRD UI / 交互编码前缺少 `ui-rule-checklist.md`，或 `gates/ui-rule-gate.sh` 未通过；规范缺口未经用户确认时不得实现。
- `assumption-leak-gate.sh` 发现 `[ASSUMP]` 标签或假设标识进入实现文件。
- Contract 字段未确认。
- 计划修改路径未写入 `allowed_paths`。
- 复杂 UI 未生成可交互 HTML 原型，或原型未得到人工确认且未记录阻塞原因。
- 自动执行停在机械步骤后未继续推进，且没有记录人工验收、阻塞或风险决策原因。
- 并行模式下缺少 Backend / Frontend 写入边界，或两个 worktree 未在 evidence 记录隔离（缺 `parallel-worktree-gate.sh` 本身不是阻断）。
- Backend 修改了契约但没有写 `contract-delta.md`。
- 前端 lint/build 或后端 compile/test 无法运行且没有记录原因。
- 后端 Maven 验证命令未先通过 `gates/canonical-command-gate.sh -- <mvn command>`。
- PC 本地联调通过修改业务前端 `vue.config.js` / `.env*` 实现代理，而不是走 `local-routing.yml` 和 harness proxy。
- 注释 / 日志门禁未运行，或 warning 未写入 evidence 并交 Reviewer 判断。
- Reviewer 未运行，`review.md` 未通过 `gates/reviewer-gate.sh`，或 `high_risk_count` 不为 0。
- `skill-usage.md` 缺失、仍有 TODO，或命中场景未记录对应 harness skill / N/A reason。
- 临时写死扫描未运行，或命中后没有移除、配置化或记录已审 false positive。
- 命中 E2E Pack 时 PC E2E Smoke 未执行且没有记录阻塞原因，或失败后未修复也未列为人工 SIT 风险。未命中 E2E Pack 时写 `N/A`，不阻断。
- 小程序本地联调使用 `bd_owner_env_override` 但未记录 `miniapp-local-env.md` 或未通过 gate。
- 本地服务、storage、测试二维码、临时数据或 debug flag 有 `OPEN` 项未通过 `temporary-state-ledger-gate.sh`。
- Tester 验收报告缺失、`verification_status` 不是 `GOAL_ACHIEVED`，或存在未关闭 P0/P1/P2 blocking issue。
- 进入测试 / 预发发布前，AI 测试报告未通过 `gates/ai-test-report-gate.sh`（未提测则本项 N/A）。
- 大体积过程产物准备提交到 Git，且没有说明长期保留理由。
- `workstream-dispatch-gate` / GitNexus / CodeGraph 相关脚本 RZ 未引入 → **不得**作为 FAIL。

## 输出口径

给人工 review 的结论使用中文。代码标识、命令、API path、字段名、错误码、YAML key、日志 key 和引用原文保持原样。永不记录明文密码 / token / cookie。
