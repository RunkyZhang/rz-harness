# Pre-PR 自审：<change-id>

> 面向人工 review 的说明、风险、结论默认使用中文；代码标识、命令、API 路径、字段名、错误码、YAML key、日志 key 和引用原文保持原样。

## Spec 一致性

- [ ] 业务目标与 `changes/<change-id>/spec.md` 一致。
- [ ] `changes/<change-id>/harness-status.md` 已更新当前阶段、下一步、待确认项和是否允许进入下一阶段。
- [ ] `changes/<change-id>/technical-solution.md` 已人工确认，并通过 `gates/technical-solution-gate.sh changes/<change-id>`。
- [ ] 多仓 / 全栈需求已通过 `scripts/workstream-dispatch-gate.sh changes/<change-id>`；如降级为单 Agent 串行，`harness-status.md` 已记录 `DEGRADED:` 原因。
- [ ] 业务仓首次改代码前已通过 `gates/business-code-start-gate.sh changes/<change-id> <changed-files...>`；没有在 `main/master` 直接修改业务代码。
- [ ] 若业务仓存在接手前 dirty diff，已通过 `gates/business-dirty-worktree-gate.sh <repo> --ledger changes/<change-id>/dirty-worktree-ledger.md`，每个 dirty path 有 owner 和 decision。
- [ ] 所有阻塞性 `[QUESTION]` 已解决。
- [ ] 没有把 `[ASSUMP]` 内容实现进代码。
- [ ] 范围没有超出已批准的仓库和路径。

## Diff 边界

- [ ] 前端改动都在 allowed paths 内。
- [ ] 后端改动都在 allowed paths 内。
- [ ] 未修改生产配置。
- [ ] 未修改 secrets 或 `.env*` 文件。
- [ ] 未修改 DB migration、prod k8s 或生产配置，除非 spec 的 `approved_protected_paths` 逐条记录了用户确认。
- [ ] 本地联调未通过修改业务前端 `vue.config.js` / `.env*` 实现代理；如涉及 PC 本地代理，已执行 `scripts/local-routing-business-config-gate.sh <changed-frontend-files...>`。

## 契约

- [ ] 变更包内已有 `contract.md`。RZ 不用 `docs/contracts/<id>-api.md`。
- [ ] 前端请求字段与契约一致。
- [ ] 前端响应映射与契约一致。
- [ ] 后端响应字段与契约一致。
- [ ] 错误码 / 空态 / 分页行为已记录。

## 验证证据

在 `changes/<change-id>/evidence.md` 记录精确命令和结果。

- [ ] 已创建 `changes/<change-id>/skill-usage.md`，并按 `docs/skills-routing.md` 记录命中的 harness skill。
- [ ] 已执行 `gates/skill-usage-gate.sh changes/<change-id>`；没有遗留 TODO，N/A 行均有原因。
- [ ] 如使用外部 Codex skill / Brooks lens，已按 `skills/third-party/external-codex-skills.md` 记录 USED / N/A；没有用外部 lens 替代 harness-local skill。
- [ ] 未启用 `brooks-sweep`、PR/CI auto-fix loop 或外部 app real action 自动化。
- [ ] 如涉及 Java 后端行为变更，已创建 `changes/<change-id>/backend-test-plan.md`，或记录 `NOT_APPLICABLE` 原因。
- [ ] 后端测试矩阵已覆盖本次适用的 validation、permission、state transition、idempotency、async/job、adapter failure、rollback/error、mapper/update count。
- [ ] 已执行后端 compile 或 targeted test。
- [ ] 后端 Maven 命令执行前已通过 `scripts/canonical-command-gate.sh -- <mvn command>`；`sfa-sales-management-interfaces` reactor 命令未遗漏 `-am`。
- [ ] 如只执行 compile 未执行 targeted test，已说明后端没有行为分支，或用户已接受残余风险。
- [ ] 已执行前端 lint。
- [ ] 已执行前端 build 或 unit smoke。
- [ ] 已执行 `gates/diff-hygiene-gate.sh <repo-root> [--base <ref>] <changed-files...>`，确认没有无关空白 / 格式噪音进入 review。
- [ ] 如涉及 iOS / Android 改动，已执行 `scripts/mobile-mechanical-quality.sh <repo-root> <changed-files...>`。
- [ ] 如涉及 iOS / Android 改动，已执行 Xcode / Android Studio / Gradle 的最窄可用编译或记录 `BLOCKED` 原因。
- [ ] 已创建 `changes/<change-id>/ai-test-report.md`，汇总 AI 测试用例、角色、步骤、截图/API/SQL 证据、结果、未覆盖项和残余风险。
- [ ] 如进入测试 / 预发发布，已执行 `gates/ai-test-report-gate.sh changes/<change-id>`；报告为 `CONFIRMED` 且 `recommendation: 允许进入预发`。
- [ ] 如改动 `mapSystem` 并启动本地页面，已优先使用 `scripts/frontend-dev-server.sh frontend-map-system 9527`，或在 evidence 中记录等价 Node `14.21.3` 启动命令。
- [ ] 如新增 `mapSystem` 页面，已挂入临时路由菜单，并在 evidence / PC smoke report 证明目标 route 没有跳到 `HomeIndex`。
- [ ] 已执行 allowed-paths 检查。
- [ ] 已执行 confidence gate 检查。
- [ ] 已执行 assumption leak gate 检查。
- [ ] 已执行 `scripts/code-comment-log-quality.sh <repo-root> <changed-files...>`，或说明本次不涉及 Java / Vue / JS。
- [ ] 如本次新增 active Swagger 2 profile 覆盖范围内的 public REST response `*VO.java`，已执行 `gates/swagger-model-documentation-gate.sh changes/<change-id> <changed-files...>`；模型和字段说明均通过。
- [ ] 注释 / 日志 warning 已写入 `evidence.md`，Reviewer 已判断是否必须修复。
- [ ] 已执行 `scripts/architecture-drift-gate.sh <repo-root> <changed-files...>`；如命中架构例外，技术方案和 Reviewer 结论已明确确认。
- [ ] 已执行 `gates/temp-hardcode-scan.sh <changed-files...>` 扫描 `CODX` / `smoke` / `mock` / `localhost` / `token` / `password` / `TODO` / `FIXME`。
- [ ] 临时写死扫描命中项已删除、配置化，或在 `evidence.md` 逐条记录为已审 false positive；没有把明文 token/password 写入 evidence。
- [ ] 若本次有 `decisions.md`，已执行 `scripts/decision-gate.sh changes/<change-id>/`，无遗留 `pending`。

## 注释与日志

- [ ] public/complex 后端方法、前端导出 API 方法、复杂页面方法已有 Javadoc / JSDoc 或等价注释。
- [ ] 状态流转、权限 / 数据范围、事务 / 锁、幂等、异步 / job、回滚 / 补偿、外部服务失败、枚举映射、兼容旧字段等关键逻辑点有注释说明。
- [ ] 注释解释业务原因和边界，没有大量重复代码语句或过期 TODO。
- [ ] 前端无 `console.*`、`debugger`、临时 `[DEBUG-...]` 标记；后端无 `System.out` / `System.err` / `printStackTrace()`。
- [ ] 日志使用占位符、位置不重复、能定位失败原因，且没有手机号、token、Cookie、明文密码等敏感信息。
- [ ] 没有绕过既有架构边界：后端 Controller 不直连 Mapper / DAO，Vue 页面不直连网络请求，小程序页面不直接 `wx.request`，移动端页面 / Adapter 不直连网络 client。

## GitNexus 影响分析

- [ ] 如本次改公共 API / DTO / VO / RPC contract、Controller / Service / Mapper / shared util、删除 / 重命名 / 改方法签名、跨前后端 / 跨仓 / 跨模块、权限 / 登录 / 支付 / 库存 / 奖励 / 审核等核心流程，已执行 `scripts/gitnexus-impact.sh <repo> <symbol>` 并把结果写入 `evidence.md`。
- [ ] 如本次是文档、模板、rules、harness 脚本小改、单页面样式 / 文案调整或新增孤立测试，已记录 GitNexus N/A 原因。
- [ ] 如 GitNexus 输出 `GITNEXUS_STATUS=UNAVAILABLE`，已记录降级原因，并补充 `rg` / `git diff` / Maven / npm / Reviewer 兜底证据。
- [ ] Pre-PR 前已按风险执行 `scripts/gitnexus-detect-changes.sh <repo> --scope all` 或 `--scope compare --base-ref <branch>`，或记录不适用原因。
- [ ] 如 GitNexus detect_changes 输出 `HIGH` / `CRITICAL`，已暂停并取得用户确认；未把本地测试通过包装成最终安全结论。

## CodeGraph 索引刷新

- [ ] 如使用 CodeGraph 做结构、route 或影响面证据，已先执行 `scripts/codegraph-preflight.sh <repo-id-or-path>` 并记录结果；只有 stale / pending / watcher 不可用 / 批量变更后才使用 `--sync`。
- [ ] CodeGraph MCP 查询业务符号时，已显式使用 preflight 输出的 `CODEGRAPH_PROJECT_PATH` 作为 `projectPath`，没有默认查 harness 仓。
- [ ] 如查询 API route / URL，已优先用 `codegraph_explore`，query 同时包含业务模块词、route 片段和目标；再按需要用 `codegraph_node` / `codegraph_search` / `codegraph_callers` / `codegraph_trace` 精确跟进。
- [ ] 如使用 CodeGraph 给出影响面或 route 结论，已创建 `changes/<change-id>/codegraph-evidence.md` 并通过 `scripts/codegraph-evidence-gate.sh changes/<change-id>`。
- [ ] CodeGraph 响应如有 staleness banner / pending sync，已直接读取被点名文件或运行 preflight `--sync` 后重查。
- [ ] CodeGraph 未命中或命中无关符号时，已先确认 repo/path、状态和查询词，再降级到 `rg` / 直接读文件 / 编译测试。
- [ ] 如 CodeGraph 未初始化、sync 失败、MCP 不可用或查不到新增符号，已在 `evidence.md` 记录降级原因，并使用 `rg`、直接读文件、编译 / 测试和 Reviewer 证据兜底。
- [ ] 未把 CodeGraph 无输出解释为“无影响面”或“无需测试”；也未在 HIT 后把 `rg` 当成固定必选复验。

## DB 操作安全

- [ ] 真实 SIT/UAT/生产数据库查询默认只读。
- [ ] 如执行过真实数据写操作，已记录目标环境、完整 SQL/API、预计影响行数、回滚/清理方案和用户二次确认。
- [ ] 未执行 `DROP DATABASE`、`DROP TABLE`、`TRUNCATE`、无精确范围的 `DELETE` / `UPDATE` 或没有明确范围的真实数据写入。
- [ ] 未把数据库密码、token、cookie 写入 versioned 文件、evidence、截图说明或长期记忆。

## 产物保留

- [ ] `changes/<change-id>/` 只包含轻量 Markdown 事实源、审计摘要和必要确认版原型。
- [ ] 截图、录屏、trace、coverage、完整长日志、临时原型草稿和数据快照未提交到 Git。
- [ ] 大体积或原始过程产物已放到 `artifacts/<change-id>/`、CI artifact、对象存储或飞书附件。
- [ ] `evidence.md` / report 只记录 artifact 路径、关键摘要、结果和影响。
- [ ] 没有默认全量引用历史 `changes/` 作为本次上下文；如引用历史 change，已说明检索线索。

## 自动执行停点

- [ ] 用户确认方案后，AI 已按 plan 自动推进到人工验收点、阻塞点或风险决策点。
- [ ] 每次到达人工验收点、阻塞点或风险决策点时，`harness-status.md` 已同步当前阶段和下一步。
- [ ] 没有在机械步骤完成后无理由暂停；如暂停，已在 evidence 中说明停点类型。
- [ ] 如标记 `BLOCKED`，已记录阻塞条件、已尝试动作、不能继续自动执行的原因和最小用户输入。
- [ ] 如进入人工验收，已提供验收 URL / 原型文件 / 报告路径、已跑命令、未覆盖项和需要用户判断的问题。

## 复杂 UI 确认

- [ ] 已判定本次是否涉及复杂 UI；判定结论写入 spec / plan / `ui-confirmation.md`。
- [ ] 如涉及复杂 UI，已创建 `changes/<change-id>/ui-confirmation.md`。
- [ ] 如涉及复杂 UI，已执行 `scripts/ui-confirmation-gate.sh changes/<change-id>`；未确认时未宣称 UI 通过。
- [ ] 如涉及复杂 UI，正式 Vue/H5 页面实现或最终 review 前已有人工 / 工人确认记录。
- [ ] 如复杂 UI 未确认，已标记为 `BLOCKED`，未用实现后的 PC E2E smoke 替代确认门禁。
- [ ] 如复杂 PC 页面未跑起来给人工确认，未在 final、review 或 evidence 中写“UI 通过”。

## PC E2E Smoke

- [ ] 已创建 `changes/<change-id>/pc-e2e-smoke-plan.md`，或说明本需求不适用 PC 端浏览器冒烟。
- [ ] 已创建 `changes/<change-id>/pc-e2e-smoke-report.md`，记录执行结论、截图、接口观察和失败点。
- [ ] 登录态来源已记录，但 report / evidence / 截图说明没有明文密码、token 或 cookie。
- [ ] 已使用真实浏览器覆盖页面打开、默认查询、核心筛选、分页或列表刷新、详情、返回、空态或错误态中的适用步骤。
- [ ] E2E 失败或阻塞项已修复、重跑，或列为人工 SIT 风险。
- [ ] 没有把未覆盖的权限矩阵、复杂数据边界、APP / H5 路径写成已通过。

## 本地临时状态

- [ ] 如小程序本地联调使用 `bd_owner_env_override`，已创建 `changes/<change-id>/miniapp-local-env.md` 并通过 `scripts/miniapp-local-env-gate.sh changes/<change-id>`。
- [ ] 如本地联调 / SIT 自测产生临时服务、storage override、测试二维码 / taskId、临时 DB/API 状态、vConsole/debug flag 或 proxy 状态，已创建 `changes/<change-id>/temporary-state-ledger.md` 并通过 `scripts/temporary-state-ledger-gate.sh changes/<change-id>`。

## AI 测试报告确认

- [ ] `ai-test-report.md` 写清测试范围、测试用例、角色、前置条件、执行步骤、期望、实际、证据和结果。
- [ ] 报告中的截图、trace、完整日志和数据快照仅记录路径，不提交大体积原始产物。
- [ ] 报告没有记录明文密码、token、cookie、生产凭据或个人敏感信息。
- [ ] `FAIL` / `BLOCKED` / `NOT_COVERED` 项已修复、重跑，或明确列为人工接受的残余风险。
- [ ] 未经人工 `CONFIRMED`，未进入测试 / 预发发布。

## Reviewer

- [ ] 独立 Reviewer 已按 `skills/reviewer/SKILL.md` 审查 spec、contract、technical-solution、diff、evidence、skill usage、Tester、AI test report 和 PC E2E Smoke 证据。
- [ ] `changes/<change-id>/review.md` 已记录 `technical_solution_alignment`、`harness_constraints`、`architecture_drift`、`comment_log_quality`、`maintainability_readability`、`test_evidence`、`high_risk_count` 和 `medium_risk_status`。
- [ ] 已执行 `gates/reviewer-gate.sh changes/<change-id>`；`high_risk_count: 0`，所有必查面均为 `PASS`。
- [ ] 如涉及 Pre-PR、架构债、技术债或测试质量审查，Reviewer 已读取 `skills/third-party/external-codex-skills.md`，并将 Brooks findings 归并到 HIGH / MEDIUM / LOW。
- [ ] Reviewer HIGH 风险为 0；如存在 HIGH，当前 change 必须保持 `BLOCKED`，不得进入人工 review / PR。
- [ ] Reviewer MEDIUM 风险已修复或记录。
- [ ] Reviewer 之后，用户已做最终人工 review。

## 隐性行为检查

- [ ] No undocumented default sorting.
- [ ] No undocumented status transition.
- [ ] No undocumented permission behavior.
- [ ] No undocumented data cleanup.
- [ ] No unrelated refactor.

## 回滚

- [ ] 已记录回滚路径。
- [ ] 已记录用户侧风险。
- [ ] 如涉及 SIT，已记录 smoke 路径。

## ARCHIVE：知识沉淀（合并前提炼）

> 闭环：本次 change 产生的知识必须沉淀回团队知识库，否则经验死在 change 文件夹里。元数据约定见 `docs/decision-log/2026-05-29-knowledge-lifecycle.md`。

- [ ] 本次有无 **pitfall**（踩过的坑 / 故障模式）？有则新增 `docs/pitfalls/SFA-PIT-*.md`（按 `docs/pitfalls/TEMPLATE.md`），无则勾选并说明 N/A。
- [ ] 本次有无可复用 **sample**（值得模仿的样板）？有则新增 `docs/samples/SFA-SMP-*.md`（按 `docs/samples/TEMPLATE.md`）。
- [ ] 本次有无 **decision**（技术选型 / 架构决策）？有则新增 `docs/decision-log/YYYY-MM-DD-<topic>.md`。
- [ ] 本次有无 **guideline**（应当固化的推荐 / 禁止做法）？有则更新对应 `rules/*.mdc` 或 `docs/standards/`。
- [ ] 已更新本次**引用过**的既有知识条目的 `last_referenced` 与 `referenced_by`（必要时提升 `maturity`）。
- [ ] 新增 / 修改的知识条目已带 front matter 元数据（`maturity` / `sources` / `last_referenced`）。

## 最终 PR 说明

PR 描述必须包含：

- spec path
- contract path
- changed repos
- verification commands
- Reviewer summary
- residual risks
- rollback path
