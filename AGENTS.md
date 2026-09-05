# AGENTS.md (rz-ai-harness)

本仓库是 RZ AI Harness **控制面**：规矩、变更包、gate、子 Agent 人设。业务代码在各自 git 仓里，用磁盘路径引用，不要把业务仓 clone 或拷进本目录。

## 运行时参数
- 本机配置：路径 `config/runtime_local.sh`，按当前开发环境填写。参数至少包括：业务仓绝对路径、账号/凭据**来源**、数据库连接信息、本地服务地址/代理/端口、本机工具命令等
- 明文密码、token、cookie 等只放在 `config/runtime_local.sh` 或系统钥匙串。以上禁止写入 spec、evidence、状态卡或任何会进 git 仓库的文件

## 语言政策
- 给人工 review / 用户确认的文档默认使用简体中文
- 代码标识、命令、API 路径、字段名、错误码、YAML key、日志 key 和引用这些原文保持原样不要翻译为英文

## Git仓库
先读 `git-registry.md`。当前仓库：
- 后端代码：`sfa-sales-management`、`sfa-backend`、`sfa-root`、`sfa-base`、`arch-open`、`arch-event`、`sfa-common-sdk`
- Web端代码：`mapSystem`
- App端代码：`sign-up`、`sfa-ios`、`sfa-android`

## Baseline

仓说明书在 `baselines/`。**不要一次读完全部。** 只读本次变更涉及的仓。

主 Agent 在写该仓 `allowed_paths`、选样板、第一次改业务代码之前读取对应文件。Explorer 下钻业务仓前先读。Backend / Frontend / Mobile 实现前必读。Reviewer 审查该仓 diff 时对照其中的分层、样板和受保护路径。

`mapSystem` 额外遵守 `baselines/frontend-map-system.md` 的 Node 版本、登录和临时路由约定。

## 领域名词

### 档位

这次需求使用哪个档位分级，使用不同档位流程上会有不同的步骤。不一定代表需求大小，而是改动范围、风险和环境依赖。功能点少也可能是 L（例如改权限、动真实库）；页面很多也可能是 S（单仓低风险小修）。

| 档 | 典型长什么样 | 流程上多什么 |
|---|---|---|
| S | 单仓小修、文档、低风险脚本 | 只要 spec / 状态卡 / 证据 |
| M | 普通全栈或多文件业务，大约 1～2 个 API | 再加强制方案、契约、测试方案、Tester、Reviewer |
| L | 跨仓、高风险、强依赖真实环境、发布前风险高 | 再加环境就绪、测试报告、决策记录 |

### gate（门禁）

检查变更包产出物或流程状态、输出 PASS/FAIL 的可执行脚本。主 Agent / hook 根据 exit code 判断流程继续或阻断。gate 只裁决不干活。

- 位置：`gates/` 目录；`gates/gate_directory.md` 为字典目录（每个 gate 检查什么、何时跑、前置依赖）
- 实现：bash 脚本，当前均为 `*.sh`
- exit code 约定：`0` = PASS 可继续；非 `0` = FAIL 阻断
- FAIL 诊断输出 `FAIL / CODE / FIX / SAMPLE` 四要素（问题、错误码、怎么修、参考模板）
- gate 检查的对象是 `changes/<change-id>/` 下的产物（spec、evidence、状态卡等）；命令证据记录在 evidence.md，不由 gate 承载

### 停止点

停止点分两类：
- **用户拍板类**：必须等用户在对话里确认才能进入下一阶段。口头确认后由**主 Agent**把确认状态写入对应文件，再跑 gate；用户不用自己改 YAML。
- **自动关卡 / 独立角色类**：gate 或 Tester / Reviewer 放行。用户不逐项参与；`BLOCKED` 或 HIGH 才升级给用户。

`harness-status.md` 只镜像进度，不是拍板原文。`BLOCKED` 是合法停、升级给用户，不是放行。脚本均在 `gates/`。

用户平时节奏：**答 QUESTION（1）→ 确认方案（2）→ 确认测试方案（3）→（条件）确认 UI（6）→ 确认测试报告（8）→ 人工 review**。4 / 5 / 7 / 9 平时无需介入。

编号与阶段顺序不一一对应：环境材料（4）可提前准备，强制时点在真实 E2E 前；code-start（5）先于 E2E；验收阶段可同时挂 7 / 8 / 9。契约冻结不是这 9 个里的编号项，未冻不得实现。DB 真实写入二次确认挂在实现阶段内，仍由用户拍板。pre-merge 卫生扫描是检查项，不是决策停止点。

| # | 停止点 | 类型 | 谁写产物                                                                                               | 用户要干嘛 | 谁检查 | 怎样算过 |
|---|---|---|----------------------------------------------------------------------------------------------------|---|---|---|
| 1 | Spec 三标签 | 拍板 + gate | 主 Agent 写 `spec.md`；Explorer 只读供料。用户答完后，主 Agent 把该项改成带来源的 `[FACT]` | 答阻塞 `[QUESTION]`、确认 `[ASSUMP]` | `confidence-gate.sh` | 阻塞项已清；未清不得进实现 |
| 2 | 技术方案 | 拍板 + gate | 主 Agent 写 `technical-solution.md`（全栈）。用户拍板后，主 Agent 改文首 YAML：`confirmation_status: CONFIRMED`、`confirmed_by` / `confirmed_at`、`allowed_next_stage` 非 `none` | 审方案，在对话里确认或要求改 | `technical-solution-gate.sh` | 文件已 `CONFIRMED`；未过不得写业务代码 |
| 3 | AI 测试方案 | 拍板 + gate | Test Strategy 写 `ai-test-plan.md`。用户拍板后，主 Agent 写成 `test_plan_status: CONFIRMED` | 审测试方案，在对话里确认或要求改 | `ai-test-plan-gate.sh` | 已 `CONFIRMED`；未过不得实现 |
| 4 | 环境就绪 | 自动关卡（仅真 E2E） | 主 Agent 写 `environment-readiness.md`；账号只写来源                                                        | 自动点，无需用户参与 | `environment-readiness-gate.sh` | `environment_status: READY`；真 E2E 前必须 READY |
| 5 | Code start | 自动关卡 | 主 Agent 从 remote/master 分支拉 `harness/<id>`；`allowed_paths` 写在 spec；脏仓先写 `dirty-worktree-ledger.md` | 自动点，无需用户参与 | `confidence-gate.sh`、`assumption-leak-gate.sh`、`allowed-paths.sh`、`business-code-start-gate.sh`；脏仓再加 `business-dirty-worktree-gate.sh` | 四重开工门禁通过；未过不得改业务文件 |
| 6 | 复杂 UI 确认 | 拍板（条件触发） | 主 Agent 写 `ui-confirmation.md`。用户拍板后，主 Agent 把判定表写成 `Status: CONFIRMED`，并在人工确认表加一行 Decision=`CONFIRMED` | 看可运行页面，在对话里确认。PC smoke 不能替代 | `ui-confirmation-gate.sh`；规则缺口走 `ui-rule-gate.sh` | 已 `CONFIRMED`；未确认不得声称 UI 通过 |
| 7 | Tester 验收 | 独立角色 | Tester 写 `test-agent-verification.md`。主 Agent 只修代码、补证据，不得代裁、不得自称 `GOAL_ACHIEVED`                   | 自动点，无需用户参与 | `test-agent-verification-gate.sh` | 仅 `GOAL_ACHIEVED` 才放行。`BLOCKED` 是停不是过。此后改代码必须重跑 |
| 8 | AI 测试报告 | 拍板 + gate（L 强制；M 提测/预发时要） | 主 Agent 写 `ai-test-report.md`。用户拍板后，主 Agent 改「人工确认」YAML：`confirmation_status: CONFIRMED`；进预发还要 `recommendation: 允许进入预发` | 审报告、残余风险、是否进预发，在对话里确认 | `ai-test-report-gate.sh` | 已人工 `CONFIRMED`；未确认不得进测试/预发 |
| 9 | Reviewer 过门 | 独立角色 | Reviewer 写 `review.md`。主 Agent 不得代裁                                                                | 自动点，无需用户参与 | `reviewer-gate.sh` | `high_risk_count: 0`。代码又变则审查过期，按需重跑 Tester 再重跑 Reviewer |

## 变更包（change）

一次需求开始会创建目录 `changes/<change-id>/` ，相当于这次需求的工作目录。

执行 `changes/change-scaffold.sh --tier S|M|L <change-id>` 。脚本会：
- 新建目录 `changes/<change-id>/`
- 按档位（S/M/L）把所需 md 从 `templates/` 原样 copy 到变更包目录
- 当场拼一个空表 `evidence.md`
- M/L 同时拷 `templates/agent-dispatch-plan.md` 空壳（不调标本 `agent-dispatch-plan.sh`）

白名单策略会判断 `changes/<change-id>/` 目录中会不会产生不应该出现的文件
- 通过 `changes/change-whitelist-spec.md` 定义可以出现哪些文件
- 通过 `gates/change-artifacts-gate.sh` 检查是否出现没在白名单中的文件

| # | 文件                                                | 从哪创建                                                                                                 | 何时出现 | 作用 | 谁写 | 谁检查 | 怎样算过 / 备注 |
|---|---------------------------------------------------|------------------------------------------------------------------------------------------------------|---|---|---|---|---|
| 1 | `spec.md`                                         | 拷 `templates/spec-tier-s.md` / `spec-tier-m.md` / `spec-tier-l.md`（scaffold）                         | 建包即有；需求理解时填。S/M/L 都要 | 目标、范围内外、三标签、`allowed_paths` | 主 Agent；Explorer 只读供料 | `confidence-gate.sh` | 阻塞 `[QUESTION]` 已清、`[ASSUMP]` 已确认并写成带来源的 `[FACT]` |
| 2 | `harness-status.md`                               | 拷 `templates/harness-status.md`；文首加 `artifact_profile` + `artifact_schema_version: 1`（scaffold 会写；手工建包也要写） | 建包即有；此后贯穿更新。S/M/L 都要 | 给人看的阶段、阻塞、下一步、Agent Roster | 主 Agent | 无单独「状态卡 gate」。marker 由 `gates/change-artifacts-gate.sh` 读 | 摘要不是拍板原文 |
| 3 | `evidence.md`                                     | scaffold **当场生成空表**，无模板 md                                                                           | 建包即有；每跑命令就追加。S/M/L 都要 | 命令、结果摘要、阻塞。禁止密码/token | 主 Agent | 无单独过门；Reviewer 会看 | 只记摘要 |
| 4 | `requirement-intake.md`                           | 条件命中时主 Agent 拷 `templates/requirement-intake.md`；scaffold / gate 都不创建                                | 条件：M/L 要结构化收需求时 | 把 PRD 收成结构化入口 | 主 Agent | 标本 `requirement-intake-gate.sh`，**RZ 未拷**；未拷前人工核对 | 可无 |
| 5 | `contract.md`                                     | 拷 `templates/api-contract.md` → 变更包内 `contract.md`（M/L scaffold 或手工拷）。RZ **只用这一条路径** | **空壳：** M/L 建包即有。**填写：** 契约冻结时 | 冻结 endpoint、字段、错误码、分页、空态 | 主 Agent；前端只读这份 | `contract-delta-gate.sh`（有增量时） | 未冻不得实现。不用 `docs/contracts/<id>-api.md` |
| 6 | `technical-solution.md`                           | 拷 `templates/technical-solution.md`（M/L scaffold）                                                    | **空壳：** M/L 建包即有。**填写 / 确认：** 方案阶段 | 全栈技术方案 | 主 Agent | `technical-solution-gate.sh` | 用户对话确认后，主 Agent 写 `confirmation_status: CONFIRMED`（含 `confirmed_by` / `confirmed_at`，`allowed_next_stage` 非 `none`） |
| 7 | `plan.md`                                         | 拷 `templates/plan-tier-m.md`（M/L scaffold）                                                           | **空壳：** M/L 建包即有。**填写：** 方案后、开工前 | 实现步骤、验证、回滚 | 主 Agent | 无单独过门；勿与状态卡两套打架 | v1 可把步骤写进状态卡 |
| 8 | `verification-map.md`                             | 拷 `templates/verification-map.md`（M/L scaffold）                                                      | **空壳：** M/L 建包即有。**填写：** 同 plan | 每条约束怎么验（命令 / 人确认 / N/A） | 主 Agent | `verification-map-gate.sh` | 可与测试方案合并，标本是分开的 |
| 9 | `skill-usage.md`                                  | 拷 `templates/skill-usage.md`（M/L scaffold）                                                           | **空壳：** M/L 建包即有。**填写：** 用到 skill 时；标本 M 强制 | 用过哪些 skill 或 N/A | 主 Agent | `skill-usage-gate.sh` | 未用写 N/A |
| 10 | `agent-dispatch-plan.md`                          | 拷 `templates/agent-dispatch-plan.md`（M/L scaffold）。RZ 不调标本 `agent-dispatch-plan.sh` / registry | **空壳：** M/L 建包即有。**填写：** 派子 Agent 前 | 准备派哪些子 Agent | 主 Agent | 标本另有 `agent-dispatch-plan-gate.sh`，**RZ 未拷**；派前对照 `subagents/dispatch_subagent.md` | 不派实现 Agent 也可写 N/A |
| 11 | `capability-spec.md` / `behavior-spec.md`         | **无模板**，按 AGENTS 自建                                                                                  | 条件：复杂状态机 / 权限 / 跨端 | 行为或能力边界 | 主 Agent | 在 `verification-map.md` 映射 | 普通 CRUD 写 N/A |
| 12 | `ai-test-plan.md`                                 | 拷 `templates/ai-test-plan.md`（M/L scaffold 空壳）                                                       | **空壳：** M/L 建包即有。**填写 / 确认：** 方案确认后、实现前 | AI 测试方案 | **Test Strategy** 填内容；主 Agent 不得代写。用户确认后主 Agent 写 `test_plan_status: CONFIRMED` | `ai-test-plan-gate.sh` | 未确认不得实现 |
| 13 | `backend-test-plan.md`                            | 条件命中时主 Agent 拷 `templates/backend-test-plan.md`；scaffold / gate 都不创建                                 | 条件：Java 行为变更 | 后端测什么；仅编译不够 | 主 Agent | 实现前必须有此文件或明确 N/A | 无行为变更则 N/A |
| 14 | `environment-readiness.md`                        | 拷 `templates/environment-readiness.md`（L scaffold；M 命中再拷）                                            | **空壳：** L 建包即有。**填写：** 真 E2E 前（可提前）。M 非 E2E 可不建 | 环境、拓扑、账号**来源**、写库边界 | 主 Agent | `environment-readiness-gate.sh` | `environment_status: READY`。不查 CONFIRMED，不探活 |
| 15 | `dirty-worktree-ledger.md`                        | 条件命中时主 Agent 拷 `templates/dirty-worktree-ledger.md`；scaffold / gate 都不创建                             | 条件：业务仓已有未提交改动 | 脏 diff 归属，避免覆盖用户工作 | 主 Agent | `business-dirty-worktree-gate.sh` | 无脏仓则不建 |
| 16 | `agent-candidate-confirmation.md`                 | 条件命中时主 Agent 拷 `templates/agent-candidate-confirmation.md`；scaffold / gate 都不创建                      | 条件：派 Backend / Frontend / Mobile | 允许候选实现 Agent | 主 Agent（用户确认后回写） | 派发前检查 | 不派则不建 |
| 17 | 业务仓分支 `harness/<change-id>`                       | **git**：从 `remote`/`master` 拉分支，不是 md                                                                | 第一次改该仓业务文件前 | 实现落点，不是变更包内文件 | 主 Agent | `business-code-start-gate.sh`（与 confidence / assumption-leak / allowed-paths 一起） | 停在主干则不得改业务文件 |
| 18 | `ui-rule-checklist.md`                            | 条件命中时主 Agent 拷 `templates/ui-rule-checklist.md`；scaffold / gate 都不创建                                 | 条件：PRD UI / 交互编码 | UI 规范逐项、缺口 | 主 Agent | `ui-rule-gate.sh` | 规则缺口未确认不得实现 |
| 19 | `ui-confirmation.md`                              | 条件命中时主 Agent 拷 `templates/ui-confirmation.md`；scaffold / gate 都不创建                                   | 条件：复杂 UI | 可运行页 / 截图后的确认记录 | 主 Agent；用户看页面后主 Agent 写 `Status: CONFIRMED` | `ui-confirmation-gate.sh` **RZ 未拷**；未拷前人工核对文件字段 | PC smoke 不能替代 |
| 20 | `data-model.md` / `data-model-sql.md`             | SQL：条件命中时主 Agent 拷 `templates/data-model-sql.md`。**`data-model.md` 无模板**，对照方案自建。scaffold / gate 都不创建 | 条件：改 DB | ER、字段来源、可执行 SQL | 主 Agent | 无单独过门；真实库写要用户二次确认 | 高危 SQL 禁止 |
| 21 | `contract-delta.md`                               | 条件命中时主 Agent 拷 `templates/contract-delta.md`；scaffold / gate 都不创建                                    | 条件：实现中契约有增量 | 契约变更说明 | 主 Agent | `contract-delta-gate.sh` | 无增量不建 |
| 22 | `local-routing.yml`                               | 标本：`generate-local-routing.sh` 生成。**RZ 未拷**：命中时主 Agent 可参考 `templates/local-routing.yml` 手写 | 条件：本地前后端联调 | 前端打哪套后端 / 代理 | 主 Agent | `local-routing-gate.sh` **RZ 未拷** | 不要长期手写堆积 route |
| 23 | `pc-e2e-smoke-plan.md` / `pc-e2e-smoke-report.md` | 条件命中时主 Agent 拷 `templates/pc-e2e-smoke-plan.md`、`pc-e2e-smoke-report.md`；scaffold / gate 都不创建        | 条件：PC 真浏览器冒烟 | 冒烟计划与结果 | 主 Agent | 无专用 RZ gate；真 E2E 须先过已有的 `environment-readiness-gate.sh` | 报告只留摘要 |
| 24 | `miniapp-local-env.md`                            | 条件命中时主 Agent 拷 `templates/miniapp-local-env.md`；scaffold / gate 都不创建                                 | 条件：改小程序本地环境 | 小程序本地运行约定 | 主 Agent | `miniapp-local-env-gate.sh` **RZ 未拷** | 未改小程序不建 |
| 25 | `temporary-state-ledger.md`                       | 条件命中时主 Agent 拷 `templates/temporary-state-ledger.md`；scaffold / gate 都不创建                            | 条件：本地服务、测试数据、debug 开关 | 临时状态清理台账 | 主 Agent | `temporary-state-ledger-gate.sh` **RZ 未拷** | 避免遗留 |
| 26 | `codegraph-evidence.md`                           | 条件命中时主 Agent 拷 `templates/codegraph-evidence.md`；scaffold / gate 都不创建                                | 条件：改公共 API / 权限等；可选 | 结构影响线索 | 主 Agent | 可选，不是关卡 | 未命中不是无影响证明 |
| 27 | `verification-run-report.md`                      | 标本：`verification-run.sh` 生成。**RZ 未拷**：有可执行行时主 Agent 手工跑命令并写报告 | 进入 Tester / Reviewer 前（map 有可执行行时） | verification-map 跑完的报告 | 主 Agent | 无 RZ 脚本；有可执行行则必须有报告文件 | 无可执行行则 N/A |
| 28 | `test-agent-verification.md`                      | 拷 `templates/test-agent-verification.md`（M/L scaffold 空壳）                                            | **空壳：** M/L 建包即有。**填写：** 实现后验收，**只能 Tester 填** | 对照已确认测试方案的独立验收 | **Tester**。主 Agent 修代码、补 evidence，不得代裁 | `test-agent-verification-gate.sh` | 仅 `GOAL_ACHIEVED` 放行；`BLOCKED` 是停。改代码后必须重跑 |
| 29 | `ai-test-report.md`                               | 拷 `templates/ai-test-report.md`（L scaffold；M 提测再拷）                                                   | **空壳：** L 建包即有。**填写 / 确认：** 提测 / 预发前。M 非提测可不建 | 测试结论给人确认 | 主 Agent 汇总；用户确认后写 `confirmation_status: CONFIRMED` | `ai-test-report-gate.sh` | 前置：测试方案已确认 + Tester `GOAL_ACHIEVED`。进预发还要 `recommendation: 允许进入预发` |
| 30 | `review.md`                                       | 拷 `templates/review.md`（M/L scaffold 空壳）                                                             | **空壳：** M/L 建包即有。**填写：** 人审 / PR 前，**只能 Reviewer 填** | 只读审查 | **Reviewer**。主 Agent 不得代裁 | `reviewer-gate.sh` | `high_risk_count: 0`。代码又变则过期，按需重跑 Tester 再重跑 Reviewer |
| 31 | `pre-pr.md`                                       | 合并前主 Agent 拷 `templates/pre-pr-review.md` 存成 `pre-pr.md`；scaffold / gate 都不创建                        | 合并前 | 人审包、残余风险 | 主 Agent | `diff-hygiene-gate.sh`、`temp-hardcode-scan.sh` | 卫生扫描是检查项，不是拍板停止点 |
| 32 | `decisions.md`                                    | 拷 `templates/decisions.md`（L scaffold）                                                               | **空壳：** L 建包即有。**填写：** 过程中有拍板时。S/M 可后补 | 过程决策记录 | 主 Agent | 无单独过门 | L 强制 |
| 33 | `retro.md`                                        | 收口时主 Agent 拷 `templates/retro.md`；scaffold / gate 都不创建                                               | 收口时，可后补 | 复盘 | 主 Agent | 无单独过门 | 大文件不进 git |
| 34 | `handoff.md`                                      | **无 `templates/handoff.md`**；按 handoff skill 里的章节自建                                                  | **随时**：换线程、暂停、上下文压缩 | 留给**下一个主 Agent**的交接单 | 主 Agent | 无 gate | 不是 Explorer / Reviewer 之间的信箱 |

## 模版文件

全部模板文件保存在目录 `templates/`，用来生成 change 变更包所需文件。`templates/template_directory.md` 为字典目录（每个 template 作用是什么、用在哪段流程、拷到变更包后叫什么）。

## 强制工作流
对档位 M/L、跨仓、后端行为、DB 或复杂 UI 工作，给用户的第一条回复必须包含「本次 harness 流程和停止点」：spec/contract/solution/test-plan/env/code-start/UI/DB/Tester/report/pre-merge 关卡。以 `changes/<change-id>/harness-status.md` 作为用户可见的状态卡。

写代码之前：阅读当前变更，业务工作加载 `config/runtime_local.sh`，确认允许的仓库/路径，区分 `[FACT]` / `[ASSUMP]` / `[QUESTION]`，未解决的假设/问题不得进入实现，并优先使用目标仓样板。
每个目标仓第一次修改业务代码之前，从 `main`/`master` 创建/切换到 `harness/<change-id>`，除非用户另有要求；记录基线分支+commit，永不在 `main`/`master` 上修改，并对计划文件通过 `gates/business-code-start-gate.sh`。

严格执行说明：
- 用户说「开始开发」、「进行下一步」、「确认」或「ok」时，只推进到下一个已满足的 harness 关卡。它们不能豁免技术方案确认、飞书同步、AI 测试方案确认、code-start、allowed-path、环境、Tester 或 Reviewer 关卡。
- `harness-status.md` 不是最后才写的总结。阶段变化、阻塞出现或解除、Tester / Reviewer 返回、以及审查之后的代码变更使先前验证失效时，都要更新。
- 若 Tester 验证之后又发生任何业务代码变更，在采信该结果之前必须重跑或刷新 Tester 验证。
- 若 Reviewer 产出之后又发生任何业务代码变更，将先前审查标为过期，按需重跑 Tester，然后重跑 Reviewer 和 `gates/reviewer-gate.sh`。
- 主 Agent 可以实施、集成和修复问题，但不得替代独立 Tester 或只读 Reviewer 的裁决。
- 使用子 Agent 时，在派发提示词和 `harness-status.md` 的 Agent Roster 中记录可读的角色标签，以便即使用户面对 runtime 分配的不透明昵称，也能识别每个 Agent 的用途。

行为/契约变更在实现前需要 spec、契约文档，
以及 `changes/<change-id>/evidence.md` 中的证据。业务代码审查前应用
`docs/standards/comment-logging.md`。
通过 `docs/skills-routing.md` 使用本地 harness skills；记录
`changes/<change-id>/skill-usage.md` 并运行 `gates/skill-usage-gate.sh`。

Java 后端行为变更在实现前需要 `backend-test-plan.md`，
或明确的 N/A 证据。仅编译是不够的。

对于带有活动 `rules/backends/*/manifest.yml` Swagger 配置的后端仓库，
在所配置的响应根目录中，每一个新增加的对外 REST 响应 `*VO.java` 必须使用
`@ApiModel`，并为每个已声明的可序列化字段标注 `@ApiModelProperty`。在 pre-commit 运行
`gates/swagger-model-documentation-gate.sh <change-dir> <changed-files...>`；
该配置不追溯既往，不适用于仅用于导出的模型或基础设施 DTO。

前端/UI 变更：先判断复杂度。PRD UI / 交互编码需要 `ui-rule-checklist.md`、PRD UI 来源、匹配的规则，以及 `gates/ui-rule-gate.sh changes/<change-id>`。
若规则缺少布局/间距/按钮/组件状态，停下来等待用户确认。复杂 UI 需要 `ui-confirmation.md` 以及可运行的原型/页面，UI 才能通过。
对于 `mapSystem`，阅读 `baselines/frontend-map-system.md`，使用 `scripts/frontend-dev-server.sh frontend-map-system 9527`，验证产品组登录和临时路由菜单；`HomeIndex` 重定向是路由失败。
永不记录明文密码/token/cookie。

在真实 E2E 或依赖环境的测试之前，填写 `environment-readiness.md` 并运行 `gates/environment-readiness-gate.sh changes/<change-id>`；记录环境、所需系统、本地运行标准、集成拓扑、角色/账号来源、数据、DB/写入边界、回滚、设备/工具、阻塞项，以及无可复用凭据。

本地后端“已重启/可验收”只能在 local-service-lifecycle 的 HEALTH=UP 和 check-web-stack 成功后声明；Maven、nohup 或端口单独成功均不足以证明可用。
仅成功的 `restart` 或启动命令返回不足以确立就绪。
对应操作命令为 `scripts/local-service-lifecycle.sh`。

档位 M/L 的方案文档在业务代码之前需要已确认的 `templates/technical-solution.md` 和 `gates/technical-solution-gate.sh changes/<change-id>`。
技术方案文档必须是全栈技术方案；覆盖模板中列出的每一块 PRD 面。当前端、APP、导出、分析或跨仓行为在范围内时，仅后端方案无效。
若 PRD 来源是飞书/Lark 链接，已确认的技术方案文档必须用 `gates/technical-solution-feishu-sync-gate.sh` 同步到飞书子文档，并且此后本地方案变更必须重新同步，技术方案关卡才能通过。
方案确认之后，独立的 Test Strategy 创建 `ai-test-plan.md`；在实现之前需要用户确认以及 `gates/ai-test-plan-gate.sh changes/<change-id>`。
飞书流程图/ER/状态图必须是白板，不是 Mermaid 代码块。

`changes/<change-id>/` 是新工作唯一的 harness 变更控制面。不要创建顶层 `openspec/` 产物或要求本地 OpenSpec CLI。历史 OpenSpec 产物若保留，仅放在 `changes/<change-id>/legacy-openspec/` 供审计。
若需要复杂的行为/能力 spec，将其写在变更包中作为 `capability-spec.md` 或 `behavior-spec.md`，并在 `verification-map.md` 中映射。
DB 变更需要带 ER 图的数据模型文档、可执行 SQL、规范化检查、自包含 SQL 注释，以及字段来源/理由。

主 Agent 实施、修复、重跑常规测试并记录证据，但不能宣称最终目标达成。
独立的 Tester 维护 `test-agent-verification.md`，对照已确认的 `ai-test-plan.md` 进行验证，返回问题并复测，直到 `GOAL_ACHIEVED` 或 `BLOCKED`。
在测试/预发发布之前，需要 `ai-test-report.md` 以及 `gates/ai-test-report-gate.sh changes/<change-id>`；该关卡还要求已确认的测试方案和 Tester `GOAL_ACHIEVED`。

实现和验证之后，只读 Reviewer 必须在人工 review 或 PR 之前撰写 `changes/<change-id>/review.md` 并运行 `gates/reviewer-gate.sh changes/<change-id>`。
Reviewer 关卡要求技术方案对齐、harness 约束、架构漂移、注释/日志质量、可维护性/可读性、测试证据，以及 `high_risk_count: 0`。

CodeGraph 是可选的，不是关卡。在业务 CodeGraph review 之前，运行 `scripts/codegraph-preflight.sh <repo-id-or-path>` 并将该仓库作为 MCP `projectPath`。
宽结构/路由问题优先 `codegraph_explore`；精确符号跟进使用 node/search/callers/trace。记录过期/降级；未命中不是无影响的证明。

## 置信度关卡

`[FACT]` = 由 PRD/用户/代码/契约提供来源；`[ASSUMP]` = 未确认且不得进入实现；`[QUESTION]` = 需要用户决定。
无来源的业务规则、字段、状态、权限、错误码、默认值或回滚规则不是事实。

## 受保护行为

未经 spec 明确许可不要修改：生产配置、密钥、`.env*`、部署清单、DB 迁移、Nacos 生产配置、发布脚本，或 allowed paths 之外的无关模块。
真实 SIT/UAT/生产 DB 访问默认只读。真实数据写入、DDL、任务触发的数据变更或会修改的 API 需要目标环境、精确 SQL/API、预期行数、回滚/清理计划，以及明确的第二次用户确认。
高危 SQL 全局禁止：`DROP DATABASE`、`DROP TABLE`、`TRUNCATE`、宽范围 `DELETE`、宽范围 `UPDATE`，或没有精确范围的写入。
永不在版本化文件、harness 文档、证据或记忆中持久化明文 DB 密码、token 或 cookie。此类机密只放在已忽略的 `config/runtime_local.sh` 或系统钥匙串。
合并前，对变更的业务文件运行 `gates/diff-hygiene-gate.sh <repo> [--base <ref>] <files...>` 和 `gates/temp-hardcode-scan.sh <files...>`。

## 子 Agent

主 Agent 负责派发和管理子 Agent。创建靠 **runtime 内置工具**（例如：Cursor 为 `Task`）。子 Agent 使用新 session，默认看不到主对话；spec / diff 等必读材料写进派发 prompt 的 `Read inputs`，由子 Agent 读磁盘。

- 目录：`subagents/`
- 派发协议（只给主 Agent）：`subagents/dispatch_subagent.md`
- 角色人设（派发时列入 `Read inputs`）：`subagents/<role>_agent.md`
- 默认只读：**Explorer** / **Reviewer**。方案确认后、写代码前派 **Test Strategy**。实现后、发布前派 **Tester**。**Backend** / **Frontend** / **Mobile** 为候选实现角色，须契约 v0.1、allowed paths 与隔离 worktree 才派发。
- 控制面默认只允许主 Agent 写。主 Agent 可以实施、集成和修复，但不得代替 Reviewer / Tester 的裁决。

当前角色：

- **Explorer**（`subagents/explorer_agent.md`）：方案或实现前只读查证。输出 `[FACT]` / `[ASSUMP]` / `[QUESTION]` 和可仿写样板路径；不改文件。
- **Reviewer**（`subagents/reviewer_agent.md`）：实现之后、人工 review / PR 之前只读审查。只写 `changes/<change-id>/review.md`；`high_risk_count` 为 0 才建议进人审。
- **Test Strategy**（`subagents/test_strategy_agent.md`）：技术方案确认后、实现前编写 `ai-test-plan.md`，须用户确认；不写业务代码。
- **Tester**（`subagents/tester_agent.md`）：实现后对照已确认测试方案独立验收，维护 `test-agent-verification.md`；不得修业务代码；不得由主 Agent 自称 `GOAL_ACHIEVED`。
- **Backend**（`subagents/backend_agent.md`）：候选。契约与后端测试计划之后，在隔离 worktree 内改后端。
- **Frontend**（`subagents/frontend_agent.md`）：候选。UI 规则与契约之后，在隔离 worktree 内改前端；契约只读。
- **Mobile**（`subagents/mobile_agent.md`）：候选。移动端契约与允许路径之后，在隔离 worktree 内改 iOS/Android。

每个子 Agent 提示词必须以 `Agent Label: <change-id> / <role> / <scope>` 开头，并且必须声明写入范围、禁止路径、要求产出，以及该 Agent 是否只读。子 Agent 最终回复应以 `<role>: <DONE|PASS|BLOCKED|NEEDS_CONTEXT>` 开头；主 Agent 在 `changes/<change-id>/harness-status.md` 的 Agent Roster 中记录相同的标签和状态。详细约定见 `subagents/dispatch_subagent.md`。

## 命令

使用仓库特定的基线文件。初始候选：`mvn -DskipTests compile`、`scripts/frontend-lint-build.sh <repo> lint-files <files...>`、`scripts/frontend-dev-server.sh frontend-map-system 9527`、`npm run build:test`。
先运行范围最窄的有用检查。

## 完成定义

仅当 spec/plan/契约与档位 M/L 技术方案一致；没有未解决的假设/问题进入代码；需要时 `ai-test-plan.md` 已确认。
对已执行的 E2E，环境就绪是清楚的；Tester 已确认 `GOAL_ACHIEVED` 或记录了 `BLOCKED`；Reviewer 产出已通过 `gates/reviewer-gate.sh changes/<change-id>`。
残余风险和回滚已记录。
