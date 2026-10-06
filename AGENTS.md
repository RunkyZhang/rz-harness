# AGENTS.md (rz-ai-harness)

本仓库是 RZ AI Harness **控制面**：规矩、模版、gate、子 Agent 人设、变更包工作目录。业务代码在各自 git 仓，用磁盘路径引用，**不要拷进本目录**。

---

## 1. 全局硬约束（S/M/L 都要）★

- **不在 `origin/master`（或 `origin/main`） 改业务代码，也不提交到 `origin/master`（或 `origin/main`）**；每仓首次改前从 `origin/master`（或 `origin/main`）切 `harness/<change-id>`，记基线 commit。
- 未经 spec 许可不改：生产配置、密钥、`.env*`、部署清单、DB 迁移、Nacos 生产配置、发布脚本、`allowed_paths` 外的模块。
- 真实 SIT/UAT/生产库**默认只读**；真实写入/DDL/改数据的 API 需：目标环境 + 精确 SQL/API + 预期行数 + 回滚计划 + **用户第二次确认**。
- 高危 SQL 全局禁止：`DROP DATABASE`、`DROP TABLE`、`TRUNCATE`、宽范围 `DELETE`/`UPDATE`、无精确范围的写入。
- **永不**在版本化文件、harness 文档、证据里写明文密码 / token / cookie（只放 `config/runtime_local.sh` 或钥匙串）。
- 给人看的文档用简体中文；代码标识、命令、API 路径、字段名、错误码、YAML key、日志 key 保持原文。
- 合并前对变更的业务文件跑 `gates/diff-hygiene-gate.sh` 和 `gates/temp-hardcode-scan.sh`。
- 单一控制面：只用 `changes/<change-id>/`；不建顶层 `openspec/`；旧产物放 `changes/<id>/legacy-openspec/`。

## 2. 去哪查（文档分工）

| 要什么 | 去哪 |
|---|---|
| 本机配置（仓路径 / DB 连接信息 / 端口 / 凭据**来源** / 工具命令） | `config/runtime_local.sh`（开工前 `source`） |
| 仓清单 | `git-registry.md` |
| 仓说明书：仿写锚点 / 分层 / 保护路径 | `baselines/<repo>.md`。**只读本次涉及的**；写 `allowed_paths` / 选样板 / 首次改代码前、Explorer 下钻前、Backend/Frontend/Mobile 实现前、Reviewer 审查时都要读 |
| 模板 + 字典 | `templates/` + `templates/template_directory.md` |
| 门禁 + 字典 | `gates/` + `gates/gate_directory.md` |
| 工具脚本 + 字典 | `scripts/` + `scripts/script_directory.md` |
| skill + 使用规则 | `skills/` + `skills/skill_directory.md` |
| 技术栈规则（生成代码参考） | `rules/` |
| 任务路线 | `lanes/` |
| 子 Agent 人设 + 派发协议 | `subagents/` + `subagents/dispatch_subagent.md` |
| hook 接线 | `hooks/hook_setup.md` |
| 给人看的详解（机制 / 图 / 目录职责） | `docs/readme.html` |

## 3. 需求理解三标签（写在 `spec.md`）

- `[FACT]`：有出处（PRD / 用户 / 现有代码 / 契约）——**只有这类可进实现**。
- `[ASSUMP]`：模型推断、未确认——**不得作为实现依据**；渗进实现文件 → `gates/assumption-leak-gate.sh` FAIL。
- `[QUESTION]`：必须用户决定——**阻塞未清不得写业务代码**（非阻塞的放 `non_blocking_questions:`）。
- 三种标签都要出现；没有假设写 `[ASSUMP] None.`。拿不准就写 `[QUESTION]`，不要先标 `[FACT]`；吃不准是否阻塞就放正文当阻塞项。
- **谁写**：主 Agent 定义全部三标签并写入 `spec.md`；Explorer（可选、只读）按三标签供料（含证据路径）、不改文件，主 Agent 决定采纳后再落盘；用户答阻塞 `[QUESTION]`、确认或推翻 `[ASSUMP]`。建包时 scaffold 拷的模板里**是占位标签，不代表已经问过用户**。
- 用户答完后，主 Agent **原地**把该行改成带来源的 `[FACT]`（不能留下 `[QUESTION]` 再另写一行）。拿某条 `[ASSUMP]` 去写代码前，必须先确认成 `[FACT]`。
- 其他模板（契约、技术方案）里的 `[QUESTION]` 只是占位，`gates/confidence-gate.sh` 不扫那些文件；它**不会**因 `spec.md` 里留着未确认 `[ASSUMP]` 就不开工。
- 详情与格式见 `templates/spec-tier-s.md` / `spec-tier-m.md` / `spec-tier-l.md`。

## 4. 档位

| 档 | 说明 |
|---|---|
| S | 单仓小修、文档、低风险脚本 → 只要 spec / 状态卡 / 证据 |
| M | 普通全栈或多文件、约 1–2 个 API → 加方案 / 契约 / 测试方案 / Tester / Reviewer |
| L | 跨仓、高风险、强依赖真实环境 → 再加环境就绪 / 测试报告 / 决策记录 |

## 5. 停止点（何时必须停）

> 两类：**用户拍板类**（等用户确认；确认后主 Agent 回写产物 → 改状态卡 → 跑 gate）；**自动关卡 / 独立角色类**（gate / Tester / Reviewer 放行，`BLOCKED` 才升级）。
> 用户节奏：答 QUESTION(1) → 确认方案(2) → 确认测试方案(3) →（条件）确认 UI(6) → 确认报告(8) → 人审。4/5/7/9 平时不用参与。

| # | 停止点 | 类型 | 谁写 | 怎样算过 |
|---|---|---|---|---|
| 1 | Spec 三标签 | 拍板 + gate | 主 Agent | 阻塞 `[QUESTION]` 已清；`lane` 合法且与状态卡一致 → `gates/confidence-gate.sh` |
| 2 | 技术方案（M/L） | 拍板 + gate | 主 Agent | 写 `confirmed_by` / `confirmed_at`，`confirmation_status: CONFIRMED` 且 `allowed_next_stage` ≠ none → `gates/technical-solution-gate.sh` |
| 3 | AI 测试方案（M/L） | 拍板 + gate | Test Strategy | `test_plan_status: CONFIRMED` → `gates/ai-test-plan-gate.sh` |
| 4 | 环境就绪（真 E2E） | 自动关卡 | 主 Agent | `environment_status: READY` → `gates/environment-readiness-gate.sh` |
| 5 | Code start | 自动关卡 | 主 Agent | **S**：confidence + assumption-leak + allowed-paths；**M/L 再加** business-code-start；脏仓先写 `dirty-worktree-ledger.md` 再加 dirty-worktree gate。未过不得改业务文件 |
| 6 | 复杂 UI | 拍板（条件触发） | 主 Agent | 判定表 `Status: CONFIRMED`，且人工确认表有一行 Decision=`CONFIRMED`（PC smoke 不能替代） |
| 7 | Tester（M/L） | 独立角色 | Tester | `GOAL_ACHIEVED`；**`BLOCKED` 是停不是过**；改代码后重跑 |
| 8 | AI 测试报告 | 拍板 + gate（L 强制；M 提测 / 预发时才要） | 主 Agent | 人工 `CONFIRMED`；进预发 + `recommendation: 允许进入预发` |
| 9 | Reviewer（M/L 强制；S 建议） | 独立角色 | Reviewer | `high_risk_count: 0`；代码又变则审查过期 |

（各停止点的完整字段、`BLOCKED` 处理、编号与阶段错位说明见 readme。）

## 6. gate 约定

- 位置 `gates/`；`exit 0` = PASS，非 `0` = FAIL；FAIL 输出 `FAIL / CODE / FIX / SAMPLE`。
- **fail-closed**：判定不了时默认 FAIL，不许“找不到就跳过”。
- 参数见 `gates/gate_directory.md`。gate 只裁决不干活；命令证据记 `evidence.md`。
- gate 是**拉式**的（要人 / agent 跑）；自动跑靠 hook（见 `hooks/hook_setup.md`）。

## 7. 工作流

### 7.1 整体工作流（15 步索引）

定 id（不用 `demo` / `tbd`）→ 选 lane → 建包 → **spec**(停1) → 契约 → **技术方案**(停2) → **测试方案**(停3) → plan+verification-map → **开工门禁**(停5) → 实现+证据(停6) → **Tester**(停7) → **报告**(停8) → **Reviewer**(停9) → 人审/PR/SIT → retro

- 有匹配 lane 时，步骤菜单用该 lane；本索引只核对停止点有没有被跳过。
- **S 档可 `N/A`**：契约 / 技术方案 / 测试方案 / plan+verification-map / Tester / 报告（仍须 spec、`allowed_paths`、evidence）。
- 环境就绪（停4）材料可提前，**真 E2E 前必须 READY**。
- 契约只写 `changes/<change-id>/contract.md`，不用 `docs/contracts/<id>-api.md`。未冻不得实现。
- 实现后、进入 Tester 前：编译、定向测试、窄范围 lint（前端 `scripts/frontend-lint-build.sh <repo> lint-files <files...>`，后端 `scripts/mvn-targeted-test.sh`）。`verification-map.md` 有可执行行时跑 `scripts/verification-run.sh`。跑不了写 `BLOCKED` 和原因。已选 lane 时验证命令以该 lane 为准。S 档 Tester 为 `N/A` 时，验证在 Reviewer 前完成。
- **Optional Pack（命中才跑）**：E2E → `lanes/pc-e2e-smoke.md`（先过停 4 环境 READY）；Impact / Parallel（CodeGraph / GitNexus）→ RZ 未引入 → `N/A`。
- 建包：`changes/change-scaffold.sh --tier S|M|L <change-id>`。每步详细动作见 `docs/readme.html`。

### 7.2 lane 工作流

- `lane = 某类任务的默认步骤清单`，放 `lanes/`；与档位正交：**lane 选步骤菜单，tier 选产物厚度**。lane 只能选路线，**不能豁免已命中的停止点**。建包后把 spec 的 `lane:` 写成唯一合法值：`lanes/bugfix-fast.md` / `lanes/fullstack-crud.md` / `none`。状态卡 `Lane` 只照抄；不一致时先改状态卡。spec 为准。
- 小修 / bugfix → `lanes/bugfix-fast.md`（常配 S）；低风险全栈 CRUD → `lanes/fullstack-crud.md`（常配 M）。
- PC 冒烟是**子 lane / Pack**（`lanes/pc-e2e-smoke.md`），不是开工三选一；命中 E2E Pack 再读。不改 `lane`。
- 无匹配 → `none`，走整体工作流（**不编造新 lane**）。`gates/confidence-gate.sh` 核对 `lane` 与状态卡一致；仍是 `TODO` 不能开工。
- 新会话先读 spec 的 `lane`。是路径就打开该文件，从状态卡「下一步」继续，不从 lane 第 1 步重跑。是 `none` 就用整体工作流。

### 7.3 强制工作流（M/L 等；★ = 全局，S/M/L 都适用）

1. **开场**：第一条回复列出本次会碰到的关卡（用停止点表，不要手写混合名单）。
2. **开工前**：★ `source config/runtime_local.sh`、确认允许路径、优先用目标仓样板；★ 三标签未决不进实现；★ 切 `harness/<change-id>` 分支；跑开工门禁（见停止点 5）。
3. **不可豁免**：口头「ok」不能跳过档位需要或条件命中的关卡（含飞书同步）；状态卡持续更新；代码再变则旧结论作废，重跑 Tester 再重跑 Reviewer；主 Agent 不得代裁 Tester / Reviewer。
4. **M/L 默认必做**：全栈 `technical-solution.md` 需 `CONFIRMED`（必须覆盖模板列出的每一块 PRD 面；**前端 / APP / 导出 / 分析 / 跨仓在范围内时，只写后端无效**）；Test Strategy 写 `ai-test-plan.md`，**主 Agent 不得代写正文**，用户确认后只写 `test_plan_status: CONFIRMED`；按 `skills/skill_directory.md` 记 `skill-usage.md`（未用写 N/A）并跑 `gates/skill-usage-gate.sh`。
5. **命中才做**：行为 / 契约变更（spec + 契约 + evidence）｜Java 行为变更（`backend-test-plan.md` 或 N/A，仅编译不够）｜Swagger 对外 VO（**仅当有活动 `rules/backends/*/manifest.yml` profile**：只扫该 profile 的响应根；新增对外 `*VO.java` 用 `@ApiModel` + 每字段 `@ApiModelProperty`；不追溯既往；不含导出模型与基础设施 DTO；pre-commit 跑 `gates/swagger-model-documentation-gate.sh`）｜前端 / UI（PRD UI 需 `ui-rule-checklist.md` + `gates/ui-rule-gate.sh`，规则缺口停下等用户；复杂 UI 需可运行页面 + `ui-confirmation.md`；`mapSystem` 先读 `baselines/frontend-map-system.md`，用 `scripts/frontend-dev-server.sh frontend-map-system 9527`，Node 14.21.3 / 产品组登录 / 临时路由，`HomeIndex` 重定向即失败）｜DB（带 ER 数据模型 + 可执行 SQL + 规范化检查 + 自包含注释 + 字段来源）｜飞书 PRD（`scripts/technical-solution-feishu-sync.sh` 同步 + 改后重同步 + `gates/technical-solution-feishu-sync-gate.sh`；流程图 / ER / 状态图用白板不用 Mermaid）｜复杂行为（`capability-spec.md` / `behavior-spec.md` + verification-map 映射）。
6. **环境与就绪**：真实 E2E 前填 `environment-readiness.md` + gate；本地后端「可验收」只在 `scripts/local-service-lifecycle.sh` 的 HEALTH=UP + check-web-stack 后声明（Maven / nohup / 端口单独成功不算）。
7. **验收与审查**：业务代码审查前跑 `scripts/code-comment-log-quality.sh`；Tester / AI 测试报告 / Reviewer 见停止点 7 / 8 / 9。

## 8. 变更包

- `changes/<change-id>/` 是这次需求的本机工作目录；**整包不进 git**；`changes/` 根下 `change-scaffold.sh`、`status-card.sh`、`change-whitelist-spec.md` 是控制面，要进 git。
- 建包：`changes/change-scaffold.sh --tier S|M|L <change-id>` —— 建目录 + `artifacts/`、按档拷模板、生成空 `evidence.md`；M/L 另拷 `agent-dispatch-plan.md` 空壳（不调 `agent-dispatch-plan.sh`）。不派实现 Agent 时，该文件写 `N/A`。
- **状态卡** `status-card.md`：给人看的单一入口；**只主 Agent 写**（子 Agent 不得改）；跑 `changes/status-card.sh` 后更新（不覆盖 Roster）。建包后立刻写「阶段（通常 `需求理解`）/ 下一步 / 是否允许进入下一阶段 / 当前阻塞 / 需人工确认」，Roster 从主 Agent 那行起填。**刷新时机**：阶段切换、阻塞出现或解除、人工确认前后、Tester / Reviewer 返回、代码又变致旧结论失效、进预发前、派发 / 完成 / 阻塞子 Agent、用户问进度。阶段枚举 `需求理解 / 方案确认 / 允许开工 / 实现中 / AI测试待确认 / 预发待发布 / 已收口`；脚本推断上限「允许开工」，「实现中」「已收口」由主 Agent 手写。禁止写入 token / cookie / DB password。
- **证据** `evidence.md`：scaffold 当场生成空表，首行是建包记录 `Scaffold … PASS`；每跑一条关键命令追加 `Check | Command / Source | Result | Summary`，`Result` 取 `PASS / FAIL / BLOCKED / N/A`；只记摘要，长输出放 `artifacts/`。**禁止**写入 token / cookie / DB password / 客户资料 / 未脱敏 SQL 结果 / 原始私密 prompt。`review.md` 必须引用 `evidence.md`，否则 `gates/reviewer-gate.sh` FAIL。
- **白名单**：`changes/change-whitelist-spec.md` 定义允许出现的文件，`gates/change-artifacts-gate.sh` 检查根目录有没有名单外文件；大文件（截图 / 录屏 / trace / 长日志）放包内 `artifacts/`，不放包根或仓库根 `artifacts/`。
- **M/L 12 个根文件**：spec / status-card / evidence / plan / contract / technical-solution / verification-map / ai-test-plan / test-agent-verification / agent-dispatch-plan / skill-usage / review；**L 再加** environment-readiness / ai-test-report / decisions。产物全集约 34 项，见 `templates/template_directory.md`；scaffold 只按档预建 S 3 / M 12 / L 15 个，其余（backend-test-plan / ui-* / data-model / local-routing / smoke / dirty-worktree-ledger / pre-pr / handoff 等）条件命中时手建。

## 9. 子 Agent

- 用 runtime 内置工具（如 Cursor `Task`）创建子 Agent；子 Agent 是新会话、默认看不到主对话，必读材料（spec / diff 等）写进派发提示的 `Read inputs`，由它自己读磁盘。
- 默认只读：**Explorer** / **Reviewer**；方案确认后写测试方案派 **Test Strategy**；实现后验收派 **Tester**；**Backend / Frontend / Mobile** 是候选实现角色（需契约 v0.1 + `allowed_paths` + 隔离 worktree + 用户确认后的 `agent-candidate-confirmation.md`）。不派则不建确认文件。
- 主 Agent 可实施 / 修复，但**不得代裁** Tester / Reviewer。
- 派发格式：提示词以 `Agent Label: <change-id> / <role> / <scope>` 开头，声明写入范围 / 禁止路径 / 产出 / 是否只读；回复以 `<role>: DONE|PASS|BLOCKED|NEEDS_CONTEXT` 开头；主 Agent 在状态卡 Agent Roster 记录。细则见 `subagents/dispatch_subagent.md`。

## 10. 完成定义

spec / plan / 契约与 M/L 技术方案一致；无未决假设 / 问题进代码；需要时 `ai-test-plan.md` 已确认；E2E 环境就绪清楚；Tester `GOAL_ACHIEVED`（或记录 `BLOCKED` 并升级）；Reviewer 过 `gates/reviewer-gate.sh`；残余风险与回滚已记录。
