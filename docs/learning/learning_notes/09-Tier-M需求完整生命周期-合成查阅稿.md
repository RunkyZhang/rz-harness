# 09 - Tier M 需求完整生命周期（合成查阅稿）

> 日期：2026-09-05  
> 用途：查阅。一条中型需求从你把 PRD 交给主 Agent，到人审 / PR / 收口。用来判断 RZ Harness 留什么、扔什么。  
> 合成来源：[08 by Cursor](08-标本中型需求从PRD到结束-步骤与文件全表by-cursor.md) + [08 by OpenCode](08-一个Tier-M需求的完整生命周期-从PRD到收口by-opencode.md)，对照标本 `AGENTS.md`、`lanes/fullstack-crud.md`、`change-artifacts-spec.md`。  
> 这是标本**设计**流程。RZ 根上尚未备齐全部脚本；路径按标本原文写，RZ 对照见文末。

**场景：** 一份飞书或 Markdown PRD；1 个 Web 仓 + 1 个后端仓；1～2 个 API；列表/表单；不改生产配置。标本默认 lane：`lanes/fullstack-crud.md`。

**标本内部不一致（读的时候别混）：**  
`AGENTS.md` + `change-artifacts-spec` 的 **tier-m** 要求技术方案、AI 测试方案、Tester、契约等。`fullstack-crud.md` 的「默认最小 18 步」更短，没单独列出技术方案/测试方案。本文以 **AGENTS.md 为准**（更完整）；lane 的 Optional Pack 用来说明「命中才加」。

---

## 怎么读

- 每阶段一张表：**读 / 写 / 跑 / 停**。  
- **贯穿**不是阶段：三标签、状态卡、（标本）skill 记录。状态卡从开变更包就开始写，不是契约之后才出现的单独阶段。  
- **停止点**全文共 9 个，文末有总表。  
- 你说「ok / 开始开发 / 进行下一步 / 确认」只走到下一个**已满足前置**的关卡，口头确认不豁免任何 gate。

---

## 先记住三件事

1. **第一件事不是写业务代码。** 开工关卡过了才能改业务仓。  
2. **常驻文件 vs 每次变更文件**——仓库里长期放着的（AGENTS、registry、baseline、人设）和每次在 `changes/<id>/` 里长出来的（spec、evidence…）是两类东西，别混。  
3. **停止工作的定义：** 状态卡收口，或状态是 `BLOCKED` 且最小缺口已写清、等你决策。不是模型说「我写完了」就算停。

### 档位对照

| 档 | 定义 | 相对 S 多什么 |
|---|---|---|
| S | 单仓小修 | — |
| M | 普通全栈/多文件、1～2 API | 方案、契约、测试方案、独立验收、审查 |
| L | 跨仓、高风险、强依赖真实环境 | 再加 environment-readiness、ai-test-report、decisions 强制 |

---

## 总览（必经 vs 条件触发）

```text
需求进入（第一条回复列出停止点）
  → spec（三标签 + allowed_paths + 全栈盘点）     【必经】
  → 契约冻结                                        【M 必经】
  → 技术方案（你确认；飞书 PRD 还要同步子文档）     【M 必经】
  → AI 测试方案（独立角色写，你确认）               【M 必经】
  → plan / verification-map /（标本）skill-usage
  → 【仅真 E2E】environment-readiness               【场景触发，不是每次 M 主链】
  → 开工门禁（分支 + 路径 + 置信度）                 【必经】
  → 实现 + evidence + 场景 Pack                     【Pack 仅命中才加】
  → Tester 独立验收                                 【要宣称完成则必经】
  →（提测/预发）ai-test-report 你确认               【L 强制；M 提测时常要】
  → Reviewer 只读过门                               【M 建议必经】
  → pre-merge 卫生 → 人审 / PR / SIT
  → retro 收口（可后补）
```

贯穿全程：

1. `[FACT]` / `[ASSUMP]` / `[QUESTION]`：未解决不得进实现。无来源的业务规则、字段、状态、权限、错误码、默认值或回滚不是事实。  
2. `harness-status.md`：阶段变化、阻塞出现/解除、子 Agent 返回、审查之后代码变更使先前验证失效时，都要更新。不是最后才写。  
3. 标本还要求 `skill-usage.md`（命中 skill 先读 `SKILL.md`）。RZ v1 可后补。  
4. **失效规则：** Tester 验证后代码再变 → 验证作废重跑；Reviewer 产出后代码再变 → 审查标 STALE，按需重跑 Tester，再重跑 Reviewer。

主 Agent 可以实施、集成和修复，但不得替代独立 Tester 或只读 Reviewer 的裁决。

---

## 阶段 0：需求进入（还不改代码）

| | 内容 |
|---|---|
| **读** | `AGENTS.md`；仓登记（标本 `docs/architecture/repo-registry.md` / RZ `git-registry.md`）；`docs/skills-routing.md`；`lanes/fullstack-crud.md` 或 `bugfix-fast.md`；本机 `config/runtime_local.sh`（标本 `repos.local.sh`）；目标仓 baseline；必要时 `skills/grill`；你的 PRD |
| **写** | 定 `change-id`（业务含义，如 `promo-sku-unit`）；建 `changes/<id>/`；开始 `harness-status.md`；可选 `requirement-intake.md` |
| **跑** | — |
| **停** | — （但第一条回复必须列出停止点） |

中/重、跨仓、后端行为、DB、复杂 UI：给用户的**第一条回复**必须列出：spec / contract / solution / test-plan / env / code-start / UI / DB / Tester / report / pre-merge。

---

## 阶段 1：Spec

| | 内容 |
|---|---|
| **读** | `templates/spec-tier-m.md`；仓登记；baseline；必要时 grill、只读 Explorer（RZ `subagents/explorer_agent.md`）；业务仓只读 |
| **写** | `changes/<id>/spec.md`（状态卡同步更新） |
| **跑** | `confidence-gate.sh`。标本还有 `knowledge-reference-gate.sh`（引用知识库 ID 时；RZ v1 可后补） |
| **停 1** | 阻塞 `[QUESTION]` 未解决或 `[ASSUMP]` 未确认 |

spec 建议有（标本模板）：三清单；PRD 全栈覆盖盘点（每项 → 影响端 → 仓库 → 是否进方案，`No/N/A` 要理由）；`allowed_paths` / 禁止路径 / 已批准的保护路径；进代码的决定要有来源（Implementation Decision Matrix）；API 草案 + 请求/响应字段表；涉及 DB 时数据模型；回滚。字段/权限/默认值找不到出处就问你，不写业务代码。

复杂状态机/权限/跨端一致性才加 `capability-spec.md` / `behavior-spec.md`；普通 CRUD 写 `N/A` 即可。

---

## 阶段 2：契约冻结

| | 内容 |
|---|---|
| **读** | `templates/api-contract.md` |
| **写** | `docs/contracts/<id>-api.md` 或变更包 `contract.md`（前端只读契约，不反向改） |
| **跑** | 契约有变更时 `contract-delta-gate.sh` |
| **停** | 契约未冻、前后端字段对不上 → 不实现 |

冻结：endpoint、请求/响应、错误码、分页、空态。

---

## 阶段 3：全栈技术方案（M/L 必须）

| | 内容 |
|---|---|
| **读** | `templates/technical-solution.md`；对应仓 baseline；已确认 spec/契约 |
| **写** | `changes/<id>/technical-solution.md`（覆盖 PRD 涉及的每一端：后端/PC/H5/小程序/APP/导出/埋点/DB/Job，不能只写后端） |
| **跑** | `technical-solution-gate.sh`；PRD 来自飞书：`technical-solution-feishu-sync.sh`（以后本地改方案必须再同步） |
| **停 2** | 你未标 `CONFIRMED`；或飞书 PRD 改了方案却没再同步 → 不得写业务代码 |

---

## 阶段 4：AI 测试方案（独立角色，实现前）

| | 内容 |
|---|---|
| **读** | `templates/ai-test-plan.md`；已确认技术方案 |
| **写** | `changes/<id>/ai-test-plan.md`（Test Strategy / RZ：`subagents/test_strategy_agent.md`，不是主 Agent 自评） |
| **跑** | `ai-test-plan-gate.sh` |
| **停 3** | 你未确认测试方案 → 不得实现 |

---

## 阶段 5：计划、验证映射、skill 记录

| | 内容 |
|---|---|
| **读** | `templates/plan-tier-m.md`、`verification-map.md`、`skill-usage.md` |
| **写** | `plan.md`、`verification-map.md`、`skill-usage.md`（标本 M 档根文件强制 skill-usage；RZ v1 可后补） |
| **跑** | `verification-map-gate.sh`、`skill-usage-gate.sh` |

`plan` 与状态卡不要两套打架；v1 可把步骤写进状态卡。`verification-map` 可与测试方案合并（标本是分开的）。Java 行为变更还要 `backend-test-plan.md` 或明确 N/A（仅编译不够）。

---

## 阶段 6：环境就绪（仅真 E2E / 依赖真实环境时）

总览里不要把它当成每次 M 都必走。纯编译、窄范围单测可以没有。`change-artifacts-spec` 把该文件标在 **tier-l** 必有；M 若要提测/预发或真要点页面，仍应按本阶段做。

| | 内容 |
|---|---|
| **读** | `templates/environment-readiness.md`（标本还有 `local-dev-readiness.md`） |
| **写** | `environment-readiness.md`（账号只写**来源**，不写明文） |
| **跑** | `environment-readiness-gate.sh` |
| **停 4** | 真 E2E 前必须 READY |

---

## 阶段 7：开工门禁（第一次改业务文件前）

| | 跑 / 写 |
|---|---|
| 四重检查 | `confidence-gate`、`assumption-leak-gate`、`allowed-paths`、`business-code-start-gate` |
| 分支 | 业务仓从 `main`/`master` 拉 `codex/<change-id>`，记录基线 commit，禁止在主干改 |
| 脏工作区 | `business-dirty-worktree-gate` + `dirty-worktree-ledger.md`（先记归属，避免覆盖你未提交的改动） |
| 派实现子 Agent | `parallel-worktree-gate`、`workstream-dispatch-gate`、`agent-dispatch-plan`、`agent-candidate-confirmation`（标本还有 bootstrap） |

**停 5：** 任一开工 gate 不过（还在 main、路径越界、方案/测试方案未确认、QUESTION 未清、脏仓未记账）。

**读（按栈，不要灌全部 rules）：** `rules/backend-java.mdc` 和/或 `rules/frontend-vue2.mdc`；`mapSystem` 再读 `rules/frontends/legacy-sfa/web/` 里和本次相关的几份。

控制面默认只允许主 Agent 写。实现 Agent 只改隔离 worktree 白名单。派发协议：RZ `subagents/dispatch_subagent.md`。

---

## 阶段 8：实现（业务仓 `codex/<id>`）

| 谁 | 读 | 跑（标本） |
|---|---|---|
| 后端 | baseline、样板、`backend-java.mdc` | 行为变更先有 `backend-test-plan.md` 或 N/A → `canonical-command-gate`（拦非法 mvn reactor）→ `mvn-targeted-test`（最窄优先）→ `java-mechanical-quality`；本地「可验收」走 `local-service-lifecycle`（**HEALTH=UP + web-stack**，端口/nohup/Maven 单独成功都不够） |
| 前端 | baseline、样板、`frontend-vue2.mdc` | 窄范围 `frontend-lint-build.sh <repo> lint-files <files>`；复杂页 `frontend-dev-server.sh frontend-map-system 9527`，验证登录和临时路由；`HomeIndex` 重定向当路由失败 |
| 新增对外 `*VO.java` | Swagger profile | `swagger-model-documentation-gate`（`@ApiModel` + 字段 `@ApiModelProperty`） |

契约字段前后端逐项对齐。注释/日志：`code-comment-log-quality.sh`，warning 进 evidence 交 Reviewer。实现中契约有增量：`contract-delta.md` + gate。

### 场景 Pack（未命中在 plan/evidence 写 `N/A`）

| Pack | 何时 | 追加 |
|---|---|---|
| UI | PRD UI/交互、复杂 PC、你给了截图/URL | `ui-rule-checklist` + `ui-rule-gate`；复杂 UI 再加 `ui-confirmation` + 可运行原型。**停 6：** 未确认不得声称 UI 通过（PC smoke 不能替代） |
| E2E | 真浏览器路径、本地前后端联调 | `generate-local-routing` → `local-routing.yml` → gate / proxy；`pc-e2e-smoke-plan/report`；先过环境就绪 |
| DB | 改 schema | 数据模型 + 可执行 SQL；ER、字段来源、范式、SQL COMMENT；真实库写要二次确认；高危 SQL 禁止 |
| Impact | 改公共 API/权限/登录等 | CodeGraph 可选（先 preflight）；未命中不是无影响证明 |
| 临时状态 | 本地服务、测试数据、debug 开关 | `temporary-state-ledger` + gate |

保护行为：`.env*`、生产配置、migration、宽 DELETE 默认不许；高危 SQL 全局禁止（`DROP DATABASE` / `DROP TABLE` / `TRUNCATE` / 宽范围 DELETE/UPDATE）。明文密码、token、cookie 只允许出现在已忽略的 `runtime_local.sh` 或钥匙串。

---

## 阶段 9：证据收口

| | 内容 |
|---|---|
| **写** | `evidence.md`（命令+摘要，无密码）；标本还可有 `verification-run-report.md` |
| **跑** | 按 verification-map 可执行行；标本 `verification-run.sh` |

---

## 阶段 10：Tester 独立验收（M 默认要走）

| | 内容 |
|---|---|
| **读** | 已确认 `ai-test-plan.md`、`templates/test-agent-verification.md` |
| **写** | `test-agent-verification.md`（只有 Tester 写；主 Agent 修代码、补证据） |
| **跑** | `test-agent-verification-gate.sh` |
| **停 7** | 非 `GOAL_ACHIEVED` 主 Agent 不得宣称目标达成（`BLOCKED` 且缺口写清也算合法停止） |

人设：RZ `subagents/tester_agent.md`。之后业务代码再变 → 验证作废，必须重跑。

---

## 阶段 11：AI 测试报告（进测试 / 预发前）

| | 内容 |
|---|---|
| **写** | `ai-test-report.md` |
| **跑** | `ai-test-report-gate.sh`（要求测试方案已确认 + Tester `GOAL_ACHIEVED`） |
| **停 8** | 你未确认报告 → 不得进测试/预发 |

artifacts 规格把该文件放在 **L 必有**；M 若要提测/发布，按本阶段做。只合到功能分支、不进预发，可没有报告，但 Tester + Reviewer 仍建议有。

---

## 阶段 12：Reviewer 只读审查

| | 内容 |
|---|---|
| **读** | 人设/skill；实际 diff；Java 时标本还有阿里 checklist |
| **写** | `review.md`（HIGH / MEDIUM / LOW） |
| **跑** | `reviewer-gate.sh`（`high_risk_count: 0`） |
| **停 9** | HIGH > 0 → 回实现修，不得进人审 |

人设：RZ `subagents/reviewer_agent.md`。

审查顺序（标本）：spec → contract → 技术方案 → plan → ai-test-plan → Tester 验收 →（若有）ai-test-report → diff → evidence。

必查：QUESTION 是否进代码、ASSUMP 当事实、是否越 `allowed_paths`、是否对齐方案、架构漂移、注释日志、测试证据。

代码又变 → review 标 STALE；按需重跑 Tester，再重跑 Reviewer。

---

## 阶段 13：Pre-merge

`diff-hygiene-gate.sh <repo> [--base <ref>] <files...>`、`temp-hardcode-scan.sh <files...>`；可写 `pre-pr.md`（模板 `pre-pr-review.md`）。

---

## 阶段 14：人审 / PR / SIT

交给你。Harness 实现阶段到此结束。

---

## 阶段 15：Retro 收口

`retro.md`；标本 `retro-gate.sh`。大文件按保留策略：Git 长期只留可 review 的 Markdown 摘要；截图、录屏、trace、长日志放 `artifacts/<id>/` 或外部存储，evidence 里只记路径和结论。知识库若有 pitfalls/samples，更新引用记录。

---

## 随时：Handoff

长会话压缩、暂停、切线程：写 `changes/<id>/handoff.md`（标本 `skills/handoff`）。无 change-id 时标本写 `docs/decision-log/YYYY-MM-DD-handoff-<topic>.md`。

---

## 9 个停止点

| # | 何时 | 条件 |
|---|---|---|
| 1 | Spec | 阻塞 QUESTION / 未确认 ASSUMP |
| 2 | 技术方案 | 未 CONFIRMED（含飞书同步未刷新） |
| 3 | AI 测试方案 | 你未确认 |
| 4 | 环境 | 真 E2E 前未 READY |
| 5 | 开工 | 分支/路径/置信度等 gate 不过 |
| 6 | UI | 复杂 UI 未确认却声称通过 |
| 7 | Tester | 非 GOAL_ACHIEVED 却宣称完成 |
| 8 | 测试报告 | 未确认就进预发 |
| 9 | Reviewer | `high_risk_count > 0` |

外加：Tester 后改代码 → 重验；Reviewer 后改代码 → STALE 再审。

---

## 标本 M 档变更包强制根文件

来源：`change-artifacts-spec.md` 的 tier-m。

`spec.md`、`harness-status.md`、`evidence.md`、`plan.md`、`contract.md`、`technical-solution.md`、`verification-map.md`、`ai-test-plan.md`、`test-agent-verification.md`、`agent-dispatch-plan.md`、`skill-usage.md`、`review.md`。

仅派候选实现 Agent 时再加 `agent-candidate-confirmation.md`。  
L 再加：`environment-readiness.md`、`ai-test-report.md`、`decisions.md`。

---

## 裁剪（给 RZ 判断留/扔）

同一份表三个口径：最小 v1 → 标准 M → 场景再加。建仓从 v1 起步，档位升了再加。

### 口径一：最小 v1（没有就不成控制面）

| 常驻 | 每次变更 |
|---|---|
| `AGENTS.md` | `spec.md` |
| `git-registry.md` | `harness-status.md` |
| `config/runtime_local.example.sh` | `evidence.md` |
| `baselines/`（按仓） | 三标签纪律卡住开工 |
| `subagents/dispatch` + explorer / reviewer 人设 | |

开工至少还要：**路径白名单 +「QUESTION 未清不能写代码」**——脚本可以后补，纪律要先有。gate 先只留 `confidence` / `business-code-start` / `reviewer` 三个。

### 口径二：标准 M 档（对齐完成定义）

| 常驻 | 每次变更 |
|---|---|
| `templates/`：spec、技术方案、测试方案、review、验收 | `technical-solution.md`（你确认） |
| `rules/`：按栈入口 `.mdc`，不要 27 份 always-on | `contract.md`（有 API 时） |
| 约 13 个核心 gate（见下） | `ai-test-plan.md`（你确认） |
| | `plan.md` 或并入状态卡（不要两份打架） |
| | `verification-map.md`（v1 可与测试方案合并） |
| | `review.md`、`test-agent-verification.md` |

13 个核心 gate：`confidence` / `assumption-leak` / `allowed-paths` / `business-code-start` / `technical-solution` / `ai-test-plan` / `ai-test-report` / `test-agent-verification` / `reviewer` / `skill-usage` / `verification-map` / `environment-readiness` / `diff-hygiene` + `temp-hardcode-scan`。其中 skill-usage、environment-readiness、ai-test-report 在标本是强制或 L 强制；RZ v1 可按场景后补。

### 口径三：场景触发（无场景不建）

| 场景 | 文件 |
|---|---|
| 飞书 PRD | 同步脚本 + 方案子文档 |
| 复杂 UI | `ui-rule-checklist`、`ui-confirmation`、web 细则 |
| 改 DB | 数据模型 + SQL + 二次确认 |
| 真 E2E | `environment-readiness`、smoke plan/report、local-routing 全家 |
| 派 Backend/Frontend 子 Agent | `agent-dispatch-plan`、candidate 确认、worktree |
| Swagger 对外 VO | swagger 规则 + gate |
| 后端行为变更 | `backend-test-plan`；lifecycle HEALTH；窄范围 mvn |
| 前端改动 | 窄范围 lint；复杂页 9527 + 临时路由 |
| 脏工作区 | dirty-worktree 台账 |
| 契约增量 | `contract-delta` |
| CodeGraph | 可选，不是关卡 |

### 明确舍弃 / 后补

- `agent-registry.yml` 全家桶（Cursor Task 不靠 YAML 创建 Agent）  
- 38 个 gate 一次上齐；遥测、eval/golden、ECC、团队 preflight/self-audit  
- `skill-usage.md` 强制记账（v1 可舍，标准档再上）  
- 多条 `lanes/`、飞书白板强制、OpenSpec  
- intake / decisions / retro / pre-pr 包（M 档可后补）  
- iOS/Android archive 规则、某次需求专属仓表  

**口诀：** 常驻要薄（入口 + 登记 + baseline + 人设）；每次变更强制 spec / 状态 / 证据 /（M）方案与测试方案 / 审查；其余场景触发。标本约 130 个脚本，单次 M 真正常跑的是约十几个核心 gate + 若干条件 gate。

---

## RZ 路径对照

| 标本 | RZ 现用 | 状态 |
|---|---|---|
| `AGENTS.md` | `AGENTS.md` | 已有 |
| `docs/architecture/repo-registry.md` | `git-registry.md` | 已有 |
| `config/repos.local.sh` | `config/runtime_local.sh` | 样例已有，本机真文件需自拷 |
| `docs/baseline/` | `baselines/` | 已有 |
| Test Agent / Test Strategy Agent | Tester / Test Strategy | 人设已有 |
| Orchestrator | 主 Agent | 已改名 |
| `skills/explorer` 等 | `subagents/*_agent.md` | 已有（形态不同：skill=方法论，人设=派发协议） |
| `templates/`、`scripts/`、`rules/*.mdc`、`lanes/` | — | 待建（按本文裁剪） |

---

## 完成定义（M 档收口标准）

spec/plan/契约与 M 档技术方案对齐；没有未决 QUESTION 进代码；需要时 `ai-test-plan` 已确认；该跑的 E2E 环境清楚；Tester 有结论（`GOAL_ACHIEVED` 或 `BLOCKED`）；Reviewer 过门（`high_risk_count: 0`）；残余风险与回滚写清。

---

## 和两份 08 的取舍（为何还要 09）

从 OpenCode 08 收进来：读/写/跑表；编号停止点；实现期 Optional Pack；后端 HEALTH / 窄测 / Swagger；前端 9527 临时路由；Reviewer 审查顺序；Handoff；「13 核心 gate vs 平台化可扔」。

从 Cursor 08 收进来：RZ 命名（`runtime_local.sh`、`git-registry`、`baselines/`、Tester、主 Agent、`subagents/`）；状态卡贯穿而非独立阶段；环境就绪不是 M 每次必走；规则按栈点名；档位对照与口头豁免；三口径裁剪口诀；完成定义。

不采用：把环境就绪画进主链「每次都有」；把状态卡当成契约之后才建的阶段；把 `agent-registry` 当成创建子 Agent 的 API；lane 18 步与 AGENTS.md 打架时跟短的那份；把 knowledge-reference / skill-usage 写成 RZ v1 已经强制。

---

## 相邻笔记

- 工作区与停止点：07  
- 名词：06  
- 从 0 写 harness：04  
- 两份上游原文：08 by Cursor、08 by OpenCode  
