# SFA AI Harness Docs Index

> 这个目录是控制面的知识库入口。AGENTS 只写规则和索引，具体事实放在这里。

## 必读文档

| 文档 | 用途 | 读取时机 |
| --- | --- | --- |
| `architecture/harness-workflow-and-design-principles.md` | 当前 Harness 完整工作流、设计理念、行业借鉴和 Mermaid 可视化流程图 | 新人 onboarding、解释 Harness 机制、复盘或推广前 |
| `architecture/sfa-harness-engineering-architecture.md` | SFA Harness 控制面的文章式整体架构说明，包含知识控制面、交付闭环、Agent 权限和评测反馈图 | 对外说明、团队评审、架构推广或需要一页式理解当前 harness 时 |
| `architecture/repo-registry.md` | 当前业务仓的路径、类型、技术栈、试点角色 | 每次跨仓工作开始前 |
| `onboarding/local-dev-environment.md` | 本地工具链、服务生命周期命令、联调拓扑和健康检查标准 | 本地启动、重启或验收前 |
| `architecture/agent-registry.md` | Agent registry 的 source of truth、Codex 生成策略、OpenCode marker 和 ECC 借鉴边界 | 新增 / 修改 agent、生成 Codex agent 配置或声明 agent 能力前 |
| `architecture/changes-retention-policy.md` | `changes/` 与 `artifacts/` 的保留、归档和 AI 检索策略 | 创建 change、写 evidence、提交 PR 前 |
| `architecture/change-artifacts-spec.md` | Tier S/M/L change 产物矩阵、根目录文件名约束和 scaffold/gate 使用方式 | 新建 change、减少产物过载或迁移历史 change 前 |
| `architecture/adapter-compliance.md` | Codex / Cursor / OpenCode / CodeGraph / GitNexus / ECC sidecar 的真实支持矩阵 | 启用或声明 adapter 能力前 |
| `architecture/hook-lifecycle-contract.md` | Codex / Cursor / OpenCode 的 hook lifecycle 支持状态、SessionStart 预算和 runtime 停止点 | 声明或修改 hook lifecycle 能力前 |
| `architecture/harness-eval-reliability.md` | `pass@k` / `pass^k` 评分语义、safety / exploratory 模式和 reliability runner 边界 | 扩展 behavior eval、声明高风险规则可靠性或接入 live runner 前 |
| `architecture/harness-replay-fixture-eval.md` | Replay / Fixture Eval 契约、fixture 目录结构、deterministic grader 和 live agent 边界 | 建设 behavior eval fixture、校准 grader 或接入 live agent runner 前 |
| `architecture/harness-business-golden-eval.md` | Business Golden Eval 契约、脱敏业务 case 目录结构和 `eval-golden.sh` 委托边界 | 建设业务 golden suite、校准业务 change artifact grader 前 |
| `architecture/harness-eval-suite.md` | Harness Eval Suite 总入口、默认检查集合、汇总指标和边界 | 运行完整评测回归、查看整体稳定性或接入周报前 |
| `architecture/harness-memory-profile.md` | repo / project / global memory 隔离、`instinct_candidate` 字段、晋升门槛和自动晋升停止点 | 记录学习候选、设计 memory/profile 或讨论 global instinct 前 |
| `architecture/harness-telemetry-readiness.md` | telemetry 数据窗口 readiness，判断 `skill-usage-gate.sh` 迁移和 model routing 成本控制是否具备真实数据 | 讨论 `skill-usage` 迁移、model routing 或 telemetry 数据窗口是否足够前 |
| `architecture/ecc-integration.md` | ECC optional sidecar 的安装、调用、禁用和回退边界 | 试用 ECC 参考能力前 |
| `decision-log/2026-05-19-language-policy.md` | 人工 review 文档默认中文的语言策略 | 创建 spec / plan / review / evidence 前 |
| `decision-log/2026-05-19-pilot-selection.md` | 首个试点范围、选择理由、待确认项 | Phase 0 / 试点启动前 |
| `decision-log/2026-05-19-opencode-adapter.md` | OpenCode 适配层设计与限制 | 使用 OpenCode 跑 harness 前 |
| `onboarding.md` | 团队首次使用手册、本地配置项、自检命令和 CodeGraph MCP 配置 | 新成员首次使用前 |
| `ios-packaging.md` | SFA iOS pak/package 工具、产物策略和开发签名协作边界 | 需要生成 iOS `.ipa` 或确认签名前 |
| `android-packaging.md` | SFA Android 阿里云 EMAS 打包入口、权限前置和产物策略 | 需要生成 Android `.apk` / `.aab` 或确认云打包权限前 |
| `skills-routing.md` | 本仓 `skills/*/SKILL.md` 的触发路由和使用记录要求 | 复杂需求、查证、调试、测试、review、handoff 前 |

## 当前变更

| Change | 状态 | 用途 |
| --- | --- | --- |
| `../changes/harness-self-test-20260519/` | 自测完成 | 控制面骨架和 sensor 自测记录 |
| `../changes/pilot-crud-tbd/` | 试点收口 / PR 准备 | 第一个真实 CRUD 试点证据包，后续新需求不得默认加载 |
| `../changes/legacy-sfa-frontend-rules/` | 已接入 | 旧 SFA 大前端 Web rules 独立 rule pack |
| `../changes/special-display-department-photo-list/` | 控制面包 | 特陈线下审核照片多图上传全栈契约与计划 |

## Baseline

| 文件 | 状态 |
| --- | --- |
| `baseline/frontend-map-system.md` | 已完成首版；前端依赖安装命令待确认 |
| `baseline/backend-sales-management.md` | 已完成首版；模块级验证命令待实测 |
| `baseline/frontend-sign-up.md` | 已完成首版；前端依赖安装命令待确认 |
| `baseline/frontend-merchant-wechatapp.md` | 已完成首版；微信开发者工具 smoke 待人工确认 |
| `baseline/backend-sfa-backend.md` | 已完成首版；模块级验证命令待实测 |
| `baseline/backend-sfa-root.md` | 特陈 root API 转发层 baseline |
| `baseline/backend-ceo-member.md` | CEO member 后端 baseline |
| `baseline/mobile-sfa-ios.md` | 特陈 iOS 上传/审核详情 baseline |
| `baseline/mobile-sfa-android.md` | 特陈 Android 同业务域待验真 baseline |
| `baseline/frontend-sfaintl.md` | PC 特陈审核详情候选仓 baseline |

## Domain

| 文件 | 用途 |
| --- | --- |
| `domain-glossary.md` | SFA 业务术语表，避免 AI 在需求、契约和 review 中混用概念 |

## Pitfalls

| 文件 | 用途 | 读取时机 |
| --- | --- | --- |
| `pitfalls/README.md` | SFA 已知坑 / 故障模式（pitfall 类知识）catalog 入口 | ANALYSE / ARCHITECT / BUILD_VERIFY 查"有没有已知坑"时 |
| `pitfalls/TEMPLATE.md` | pitfall 条目模板（含成熟度元数据） | 新增 pitfall 时 |
| `pitfalls/SFA-PIT-001-map-system-node-sass-runtime.md` | `mapSystem` 高版本 Node / node-sass 启动失败规避 | 启动 `mapSystem` 或执行 PC E2E Smoke 前 |
| `pitfalls/SFA-PIT-002-map-system-login-product-group.md` | `mapSystem` 登录时账号 blur 后加载产品组 / 选择第一项 | 登录 `mapSystem` 或执行 PC E2E Smoke 前 |
| `pitfalls/SFA-PIT-003-map-system-temporary-route.md` | `mapSystem` 新页面必须挂临时路由，否则访问会跳首页 | 新增 `mapSystem` 页面或执行 PC E2E Smoke 前 |
| `pitfalls/SFA-PIT-004-codegraph-route-query.md` | CodeGraph route 查询需用 explore-first + projectPath；stale/miss 时再降级 | 用 CodeGraph 查后端 API route / URL 前 |

## Knowledge Lifecycle

| 文件 | 用途 |
| --- | --- |
| `decision-log/2026-05-29-knowledge-lifecycle.md` | 知识成熟度（draft/verified/proven）+ 衰减阈值 + ARCHIVE 闭环的元数据约定 |
| `samples/README.md` | 可模仿样板 catalog 入口 |
| `samples/TEMPLATE.md` | sample 条目模板（含成熟度元数据） |

## Standards

| 文件 | 用途 |
| --- | --- |
| `standards/java/README.md` | 阿里 Java 规范接入 harness 的门禁模型 |
| `standards/java/alibaba-java-review-checklist.md` | Backend Agent / Reviewer Agent 使用的 Java 规范审查清单 |
| `standards/java/alibaba-java-songshan-fulltext.txt` | 用户提供 PDF 抽取后的带页码全文 |
| `standards/comment-logging.md` | 前后端注释与日志标准，约束公共/复杂方法注释、关键逻辑注释、调试日志清理和敏感信息 |

## Rules

| 文件 | 用途 | 读取时机 |
| --- | --- | --- |
| `../rules/backend-java.mdc` | Java / Spring Boot / Maven 后端仓通用规则 | 修改 `sfa-sales-management`、`sfa-backend`、`sfa-root` 或 `backend-ceo-member` 前 |
| `../rules/backends/swagger2/manifest.yml` | `backend-sales-management` 新增 public REST response VO 的 Swagger 2 模型文档 profile | 修改该仓 controller 对外返回模型前 |
| `../rules/frontend-vue2.mdc` | Vue2 前端仓通用规则 | 修改 `mapSystem` 或 `sign-up` 前 |
| `../rules/frontend-wechat-miniprogram.mdc` | 原生微信小程序 TypeScript 规则 | 修改 `merchant-wechatapp` 前 |
| `../rules/mobile-ios-objc.mdc` | iOS Objective-C 端规则 | 修改 `sfa-ios` 前 |
| `../rules/mobile-android-java.mdc` | Android Java / XML 端规则 | 修改 `sfa-android` 前 |
| `../rules/frontends/legacy-sfa/README.md` | 旧 SFA 大前端规则包入口 | 修改 `mapSystem` 管理后台前 |
| `../rules/frontends/legacy-sfa/manifest.yml` | 前端 rule profile 显式启用清单 | 按 repo registry 解析前端规则时 |

规则文件用于 Codex / Cursor / Reviewer Agent 读取，不替代 `changes/<change-id>/spec.md`。真实需求仍以 spec、contract、plan、evidence 为准。历史 `changes/` 不默认全量进入上下文；除当前 active change 外，只按 change-id、接口、模块、字段或明确问题定向检索。

### Frontend Rule Packs

| Profile | 状态 | 默认适用 repo | 说明 |
| --- | --- | --- | --- |
| `legacy-sfa-web` | active | `frontend-map-system` | 用户提供的大前端 Web rules，约束旧 SFA Vue2 + Element UI 管理后台 |
| `legacy-sfa-ios-archive` | archived | 无 | 仅归档；未接入当前 Web lane |
| `legacy-sfa-android-archive` | archived | 无 | 仅归档；未接入当前 Web lane |

`frontend-sign-up` 当前使用轻量 Vue2/H5 规则，不默认继承 `legacy-sfa-web`。未来新系统应新增自己的 rule pack / profile，不应复用旧 SFA profile 作为默认规则。
`frontend-merchant-wechatapp` 当前使用独立原生微信小程序规则，不继承 Vue2/H5 或旧 SFA Web profile。
`mobile-sfa-ios` 当前使用独立 iOS Objective-C 规则，不默认使用归档的旧 Web/iOS rule pack。
`mobile-sfa-android` 当前使用独立 Android Java/XML 规则，不默认使用归档的旧 Web/Android rule pack。

## Sensors

| 脚本 | layer | trigger | required_by | owner | last_validated | 用途 | 当前状态 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `../scripts/confidence-gate.sh` | sensor/computational | spec / plan 更新后 | Tier M/L 开工门禁 | Orchestrator | self-audit | 检查 spec / plan 中的 `[FACT]`、`[ASSUMP]`、`[QUESTION]` 标记，默认阻断未处理问题；失败输出包含 `CODE` / `FIX` / `SAMPLE` | 已自测通过 |
| `../scripts/requirement-intake-gate.sh` | sensor/computational | Tier M/L intake 完成后 | requirement intake | Orchestrator | self-audit | 校验 `requirement-intake.md` 状态、PRD 条目数、六类关键问题和阻塞问题状态，防止需求遗漏或 AI 自行猜测进入 spec/solution | Tier M/L 需求拆解后 |
| `../scripts/requirement-intake-gate-test.sh` | sensor/computational | requirement intake 模板或 gate 变更后 | requirement intake | Orchestrator | self-audit | 回归验证缺文件、非 READY、完整 intake、缺关键类别和开放问题的 gate 行为 | 修改 requirement-intake 机制后 |
| `../scripts/frontend-style-profile-gate-test.sh` | sensor/computational | 前端 style profile / plan 样板引用 / Reviewer 裁决变更后 | style conformance | Orchestrator | self-audit | 回归验证前端 style profile 模板、plan `style_sample_references_status`、Reviewer `style_conformance` 字段和 reviewer gate 校验 | 修改前端风格闭环机制后 |
| `../scripts/technical-solution-gate.sh` | sensor/computational | 技术方案确认后 | 业务代码开工 | Orchestrator | self-audit | 校验完整技术方案已人工确认，且 `allowed_next_stage` 明确允许进入当前阶段；如 `data-model.md` 声明 `schema_change_required: yes`，强制技术方案主文档内嵌 DB/DDL 设计；确认版禁止 `READY_FOR_SQL`、`OPEN_SQL_DETAIL`、`TODO/TBD/FIXME`、`[QUESTION]`、`[ASSUMP]` 和尖括号占位；要求接口字段来源/处理逻辑和前端 UI 细节 | 业务代码开工前 |
| `../scripts/technical-solution-feishu-sync.sh` | orchestration/computational | 飞书 PRD 技术方案确认后 / 方案修改后 | 技术方案飞书留痕 | Orchestrator | self-audit | 在 PRD Wiki 节点下创建或更新技术方案子文档，并回写 `feishu_solution_*` 同步元数据；dry-run 可预览实际 `lark-cli` 命令 | 飞书 PRD 的技术方案确认后、每次方案变更后 |
| `../scripts/technical-solution-feishu-sync-gate.sh` | sensor/computational | `technical-solution-gate.sh` 内部调用 | 业务代码开工 | Orchestrator | self-audit | 当 PRD 来源是飞书 / Lark 链接时，要求技术方案子文档已同步，且 `feishu_solution_source_sha256` 匹配当前本地方案 | 业务代码开工前 |
| `../scripts/technical-solution-feishu-sync-test.sh` | sensor/computational | Feishu 技术方案同步流程变更后 | self-audit | Orchestrator | self-audit | 回归验证非飞书 PRD 不受影响、飞书 PRD 缺子文档阻断、同步 hash 过期阻断、同步助手 dry-run 输出创建和更新命令 | 修改技术方案确认 / 飞书留痕机制后 |
| `../scripts/verification-map-gate.sh` | sensor/computational | verification map 更新后 | 业务代码开工 | Orchestrator | self-audit | 校验 `verification-map.md` 已把关键约束映射到验证命令、人工确认或 `N/A:` 原因；阻断 TODO/TBD/BLOCKED 和无理由 N/A | 业务代码开工前 |
| `../scripts/verification-run.sh` | sensor/computational | verification map READY 后 / 完成实现后 | closeout evidence | Orchestrator | self-audit | 执行 `verification-map.md` 中显式 `shell:` 行，检查 `manual:` 行已 PASS，并生成 `verification-run-report.md` | 实现完成、Test Agent / Reviewer 前 |
| `../scripts/verification-run-test.sh` | sensor/computational | verification-run 变更后 | closeout evidence | Orchestrator | self-audit | 回归验证 shell 行执行、失败命令阻断、manual pending 阻断、unsupported runner 阻断和 dry-run 报告 | 修改 verification-run 闭环后 |
| `../scripts/business-code-start-gate.sh` | sensor/computational | 首次业务代码编辑前 | 业务代码开工 | Orchestrator | self-audit | 业务仓首次改代码前的硬门禁：技术方案、verification map、contract allowed paths 和业务仓分支必须同时通过；阻断 `main/master` 直接修改 | 业务代码开工前 |
| `../scripts/business-dirty-worktree-gate.sh` | sensor/computational | 目标业务仓已有 dirty diff | 业务代码开工 | Orchestrator | self-audit | 业务仓有 dirty diff 时要求用台账记录每个文件归属和处理决定，防止覆盖用户已有工作 | 业务代码开工前 / 接手已有改动时 |
| `../scripts/workstream-dispatch-gate.sh` | sensor/computational | 多仓 / 全栈拆分后 | Tier M/L 开工门禁 | Orchestrator | self-audit | 多仓 / 全栈需求进入实现前检查 `harness-status.md` 的 Workstream Dispatch 表，确保后端、PC、小程序等工作线已拆分并有验证命令 | 业务代码开工前 |
| `../scripts/ai-test-report-gate.sh` | sensor/computational | 测试 / 预发发布前 | Test Agent Pack | Orchestrator | self-audit | 校验 AI 测试报告已人工确认，且建议 `允许进入预发`；未确认时阻断测试 / 预发发布 | 测试 / 预发发布前 |
| `../scripts/retro-gate.sh` | sensor/computational | closeout / pre-pr 后 | change learning loop | Orchestrator | self-audit | 分层校验 `retro.md`：Tier M/L 必须完整复盘，小修可只保留轻量 closeout metrics；阻断未收口指标、用户纠正、gate 误报和知识沉淀决策 | closeout |
| `../scripts/retro-gate-test.sh` | sensor/computational | retro 模板或 gate 变更后 | change learning loop | Orchestrator | self-audit | 回归验证 Tier S 可省略、Tier M/L 缺失阻断、完整 retro 通过、placeholder/instinct 候选缺失阻断和 closeout 接线 | 修改 retro 闭环后 |
| `../scripts/harness-status.sh` | orchestration/computational | 阶段切换 / 阻塞 / 确认前后 | 用户状态卡 | Orchestrator | self-audit | 从 active change 产物生成用户可见 Harness 状态卡，展示当前阶段、下一步和待确认项 | 阶段切换、阻塞、人工确认前后 |
| `../scripts/change-scaffold.sh` | orchestration/computational | 新建 change 前 | artifact matrix | Orchestrator | self-audit | 按 Tier S/M/L 创建最小产物骨架，并写入 `artifact_profile`，减少手工漏文件和小需求过载 | 新建 change 时 |
| `../scripts/change-artifacts-gate.sh` | sensor/computational | 新建 change 后 / 历史迁移审计 | artifact matrix | Orchestrator | self-audit | 校验新 change 的 `artifact_profile`、必需产物和根目录文件名；`--historical` 对旧 change 只 warning 不阻断 | 新 change 进入方案或 code-start 前 |
| `../scripts/change-artifacts-gate-test.sh` | sensor/computational | artifact matrix / scaffold 变更后 | artifact matrix | Orchestrator | self-audit | 回归验证 Tier S/M/L scaffold、缺 profile fail、未知根文件 fail 和历史 change warning | 修改 scaffold 或 artifact gate 后 |
| `../scripts/superseded-docs-gate.sh` | sensor/computational | SSOT / legacy 文档收敛后 | docs governance | Orchestrator | self-audit | 校验旧根目录长文档带 `SUPERSEDED` banner，并指向当前 `harness-workflow-and-design-principles.md` | 修改旧目标方案、实施计划或 SSOT 索引后 |
| `../scripts/superseded-docs-gate-test.sh` | sensor/computational | superseded docs gate 变更后 | docs governance | Orchestrator | self-audit | 回归验证旧文档 banner、archive index 和缺 banner fixture 阻断 | 修改 superseded docs gate 后 |
| `../scripts/agent-workspace.sh` | orchestration/computational | 多 Agent / 长上下文任务派发前 | Agent handoff | Orchestrator | self-audit | 创建 `.harness/agent-work/<change-id>/` 自忽略工作区和 `progress-ledger.md`，保存 task brief、report、review package 等短期交接文件 | 任务派发、上下文压缩恢复、Reviewer 输入准备 |
| `../scripts/agent-task-brief.sh` | orchestration/computational | 派发单个任务前 | Agent handoff | Orchestrator | self-audit | 从 plan 中抽取单个 Task 到交接文件，避免在对话中粘贴长任务正文 | 多 Agent / 长上下文任务派发前 |
| `../scripts/agent-review-package.sh` | orchestration/computational | Reviewer Agent 输入准备 | Agent handoff / Reviewer | Orchestrator | self-audit | 生成 commit list、diff stat 和 full diff 的 review package 文件，Reviewer 读取文件而不是让 Orchestrator 粘贴 diff | 每任务 review 或最终 review 前 |
| `../scripts/harness-bootstrap-smoke.sh` | sensor/computational | 控制面启动面变更 / 团队推广前 | team rollout | Orchestrator | self-audit | 只读验证 `AGENTS.md`、Codex hooks 和 `docs/skills-routing.md` 的当前 runtime 可发现性 | 控制面 hook / skill routing / startup 指令变更后 |
| `../scripts/harness-observability-ready.sh` | sensor/computational | 控制面变更自审 / 团队推广前 | team rollout | Orchestrator | self-audit | 检查状态 JSON、adapter matrix、个人路径扫描、ECC optional status 和 harness config eval fixture | 控制面变更自审 / 团队推广前 |
| `../scripts/adapter-compliance-gate.sh` | sensor/computational | adapter 能力声明变更 | adapter matrix | Orchestrator | self-audit | 校验 adapter matrix 每行有状态、onramp、验证命令、风险、owner、日期和来源 | 新增 / 修改 adapter 能力声明前 |
| `../scripts/agent-registry-gate.sh` | sensor/computational | Agent registry 或 adapter agent 文件变更后 | Agent registry | Orchestrator | self-audit | 校验 `config/agent-registry.yml` 必填字段、唯一 agent_id、source files、OpenCode marker、Codex output contract 和 gate 引用 | 新增 / 修改 agent 定义前 |
| `../scripts/agent-registry-gate-test.sh` | sensor/computational | Agent registry gate 变更后 | Agent registry | Orchestrator | self-audit | 回归验证默认 registry、缺必填字段、重复 agent_id 和缺 source file 的阻断行为 | 修改 agent registry 校验器后 |
| `../scripts/codex-agent-generator.sh` | orchestration/computational | 需要给 Codex 生成子 Agent 配置时 | Codex agent adapter | Orchestrator | self-audit | 从 `config/agent-registry.yml` 生成 Codex agent TOML；默认 dry-run，写入 `$HOME/.codex/agents` 需要 `--allow-global` | Codex agent 配置生成前 |
| `../scripts/codex-agent-generator-test.sh` | sensor/computational | Codex agent generator 变更后 | Codex agent adapter | Orchestrator | self-audit | 回归验证 dry-run 不写文件、apply 写本地输出、全局写入保护和项目 `.codex` hooks 不被修改 | 修改 Codex agent 生成器后 |
| `../scripts/agent-dispatch-plan.sh` | orchestration/computational | Agent 派发前 | Agent registry | Orchestrator | self-audit | 按 registry、stage、runtime、agent_id 生成派发计划；candidate implementation agent 默认 fail-closed，需显式 `--allow-candidate` 和 `--candidate-confirmation` | 派发 Codex/OpenCode 子 Agent 前 |
| `../scripts/agent-dispatch-plan-test.sh` | sensor/computational | dispatch planner 变更后 | Agent registry | Orchestrator | self-audit | 回归验证 review 阶段选中 Reviewer、candidate 默认阻断、确认文件要求和 handoff plan 输出 | 修改 Agent 派发计划逻辑后 |
| `../scripts/agent-dispatch-plan-gate.sh` | sensor/computational | Agent 派发计划生成后 | Agent registry | Orchestrator | self-audit | 校验 `changes/<change-id>/agent-dispatch-plan.md` 中 agent、权限、output contract、gate 引用、candidate opt-in 和 confirmation 仍匹配 registry | Agent 派发计划进入执行前 |
| `../scripts/agent-dispatch-plan-gate-test.sh` | sensor/computational | dispatch plan gate 变更后 | Agent registry | Orchestrator | self-audit | 回归验证 registry 生成计划、缺计划、未注册 agent、candidate opt-in 和 candidate confirmation 阻断 | 修改 Agent 派发计划 gate 后 |
| `../scripts/agent-output-contract-gate.sh` | sensor/computational | Agent 输出产物进入下游 gate 前 | Agent registry | Orchestrator | self-audit | 按 registry 校验声明输出文件，并把 Reviewer / Test Agent 输出委托给对应 gate；Test Agent 支持 `GOAL_ACHIEVED` 或明确 `BLOCKED` | Agent 输出进入 review / release gate 前 |
| `../scripts/agent-output-contract-gate-test.sh` | sensor/computational | output contract gate 变更后 | Agent registry | Orchestrator | self-audit | 回归验证 Reviewer gate 委托、缺 artifact 阻断、Test Agent 成功/阻塞输出和 pending 阻断 | 修改 Agent 输出契约校验后 |
| `../scripts/hook-lifecycle-contract-test.sh` | sensor/computational | hook lifecycle contract 变更后 | hook lifecycle | Orchestrator | self-audit | 校验 docs-only lifecycle contract 覆盖 SessionStart、PreToolUse、PostToolUse、Stop、PreCompact、Codex、Cursor、OpenCode、状态标签和 runtime 停止点 | 修改 hook lifecycle 文档或准备 runtime pilot 前 |
| `../scripts/harness-behavior-reliability.sh` | sensor/computational | behavior eval 可靠性评分 | eval reliability | Orchestrator | self-audit | 重复运行 eval command 并输出 `pass@k` / `pass^k`、success/failure counts 和 safety/exploratory 决策 | 声明 eval 稳定性、扩展 behavior eval 或接 live runner 前 |
| `../scripts/harness-behavior-reliability-test.sh` | sensor/computational | eval reliability runner 变更后 | eval reliability | Orchestrator | self-audit | 验证 `pass@k` / `pass^k` 文档、safety mode、exploratory mode、all-fail 和当前 behavior eval wrapper | 修改 reliability runner 或评分契约后 |
| `../scripts/harness-replay-fixture-eval.sh` | sensor/computational | Replay / Fixture Eval fixture 或 grader 变更后 | behavior eval | Orchestrator | self-audit | 读取脱敏 transcript、diff.stat 和 artifacts fixture，对比 expected 与 deterministic grader 结果；不运行 live agent | 修改 behavior replay fixture、grader 或接入 live runner 前 |
| `../scripts/harness-replay-fixture-eval-test.sh` | sensor/computational | Replay / Fixture Eval runner 或 fixture 契约变更后 | behavior eval | Orchestrator | self-audit | 回归验证 technical-solution-stop 的正反例 fixture、unexpected result fail-closed、缺 metadata fail-closed 和 docs index | 修改 replay fixture eval 基座后 |
| `../scripts/harness-live-sandbox-eval.sh` | sensor/computational | Live Sandbox Eval 场景或 agent command 变更后 | behavior eval | Orchestrator | self-audit | 创建临时 git 沙箱，运行可信本地 agent command，并根据 transcript、退出码和 dirty diff 判定是否遵守 harness 停止点 | 接入 live agent runner 或校验真实 agent 行为前 |
| `../scripts/harness-live-sandbox-eval-test.sh` | sensor/computational | Live Sandbox Eval runner 或契约变更后 | behavior eval | Orchestrator | self-audit | 回归验证缺 agent fail-closed、正例 fake agent 通过、改文件 fake agent 阻断和 unknown scenario 阻断 | 修改 live sandbox eval 基座后 |
| `../scripts/harness-live-codex-trial.sh` | orchestration/computational | 需要用真实 Codex CLI 跑 live sandbox trial 时 | behavior eval | Orchestrator | self-audit | 通过临时 shim 调用 `codex exec --ephemeral`，复用 Live Sandbox Eval 和 reliability wrapper 输出 pass@k / pass^k | 真实 Codex agent trial 前 |
| `../scripts/harness-live-codex-trial-test.sh` | sensor/computational | Live Codex Trial wrapper 变更后 | behavior eval | Orchestrator | self-audit | 使用 fake Codex CLI 验证缺二进制 fail-closed、Codex exec 参数、reliability 输出和 unknown scenario 阻断 | 修改 live Codex trial wrapper 后 |
| `../scripts/harness-business-golden-eval.sh` | sensor/computational | Business Golden Eval case 或 grader 变更后 | business golden eval | Orchestrator | self-audit | 批量读取 `evals/business-golden/*` 脱敏 case，并委托 `eval-golden.sh` 校验单个业务 change artifact 包 | 建设业务 golden suite 或校准业务 grader 前 |
| `../scripts/harness-business-golden-eval-test.sh` | sensor/computational | Business Golden Eval runner 或 case 契约变更后 | business golden eval | Orchestrator | self-audit | 回归验证通过 case、缺 smoke report、allowed path 越界、unexpected result 和缺 metadata fail-closed | 修改业务 golden suite 基座后 |
| `../scripts/harness-business-golden-candidate-gate.sh` | sensor/computational | 真实历史 SFA change 准备进入 business golden 前 | business golden eval | Orchestrator | self-audit | 校验 `evals/business-golden/candidates/*.env` 的来源、脱敏状态、晋升状态和 promoted case 关系；不读写业务仓 | 选择 / 晋升 business golden 候选前 |
| `../scripts/harness-business-golden-candidate-gate-test.sh` | sensor/computational | Business Golden candidate gate 或候选元数据契约变更后 | business golden eval | Orchestrator | self-audit | 回归验证候选清单、READY 必须 SANITIZED、缺 source change 阻断和 PROMOTED 缺 case 阻断 | 修改 business golden candidate intake 后 |
| `../scripts/harness-business-golden-candidate-intake.sh` | orchestration/computational | 真实历史 change 准备登记为 business golden 候选时 | business golden eval | Orchestrator | self-audit | 创建安全初始候选元数据：`CANDIDATE / NEEDS_REVIEW / BUSINESS_REPO_ACCESS=NO`；不读业务仓、不脱敏背书、不自动晋升 | 采集新的 business golden 候选前 |
| `../scripts/harness-business-golden-candidate-intake-test.sh` | sensor/computational | Candidate intake 脚本或元数据模板变更后 | business golden eval | Orchestrator | self-audit | 回归验证候选创建、gate 兼容、绝对路径阻断、缺 source change 阻断、重复候选阻断和 lane 校验 | 修改候选采集入口后 |
| `../scripts/harness-business-golden-candidate-report.sh` | sensor/computational | 查看 business golden 候选队列时 | business golden eval | Orchestrator | self-audit | 只读汇总候选状态、脱敏状态、lane、golden case 和下一步动作；不输出 source path 或业务原文 | 规划候选脱敏 / 晋升批次前 |
| `../scripts/harness-business-golden-candidate-report-test.sh` | sensor/computational | Candidate report 输出契约变更后 | business golden eval | Orchestrator | self-audit | 回归验证已晋升候选汇总、待脱敏候选 next action、以及不泄露 source refs / personal paths | 修改候选队列报告后 |
| `../scripts/harness-eval-suite.sh` | orchestration/computational | 需要完整评测回归或周报前 | eval suite | Orchestrator | self-audit | 编排 replay、live sandbox、live Codex wrapper、business golden、candidate gate、behavior reliability、telemetry、registry 和 hygiene，输出统一 summary；显式 `--record-telemetry` 时记录一条聚合 `eval_suite_event` | 完整评测回归、趋势记录或发布前自查 |
| `../scripts/harness-eval-suite-test.sh` | sensor/computational | Eval Suite runner 或输出契约变更后 | eval suite | Orchestrator | self-audit | 回归验证 suite 默认检查集合、关键指标汇总、opt-in telemetry 和子命令失败 fail-closed | 修改 Eval Suite 总入口后 |
| `../scripts/harness-eval-weekly-run.sh` | orchestration/computational | 需要执行周度评测采集时 | eval suite | Orchestrator | self-audit | 运行 Eval Suite、记录聚合 `eval_suite_event`，并生成 aggregate-only weekly summary；不接入外部 CI 或定时器 | 周度本地评测采集 |
| `../scripts/harness-eval-weekly-run-test.sh` | sensor/computational | Weekly eval runner 或 summary 输出契约变更后 | eval suite | Orchestrator | self-audit | 回归验证周度 runner 会记录 suite telemetry、生成 weekly summary，并且 summary 不泄露 source refs | 修改周度评测采集入口后 |
| `../scripts/harness-eval-trend-readiness.sh` | sensor/computational | 讨论 CI 试运行、gate 调整或评测采纳前 | eval suite | Orchestrator | self-audit | 聚合 `eval_suite_event` 趋势，检查最少运行次数、自然周覆盖、失败数和 golden/replay/pass_power 基线；只允许写采纳评审方案，不自动改 CI/gate | 评测结果进入治理决策前 |
| `../scripts/harness-eval-trend-readiness-test.sh` | sensor/computational | Eval trend readiness 阈值或输出契约变更后 | eval suite | Orchestrator | self-audit | 回归验证数据不足等待、四周稳定窗口通过、失败窗口阻断和不泄露 source refs | 修改趋势采纳门槛后 |
| `../scripts/harness-instinct-candidate-check.sh` | sensor/computational | `instinct_candidate` 记录进入 evidence / review 前 | memory profile | Orchestrator | self-audit | 校验 repo / project / global scope、promotion_state、confidence、source_type、global 晋升证据和敏感信息边界；不写 memory、不改规则 | 记录学习候选、设计 project/global memory 或讨论 instinct 晋升前 |
| `../scripts/harness-memory-profile-test.sh` | sensor/computational | memory profile contract 或候选校验器变更后 | memory profile | Orchestrator | self-audit | 验证 memory profile 契约、docs index、合法候选、global source/confidence 限制、敏感值拒绝和必填字段 | 修改 memory/profile、instinct promotion 或候选校验规则后 |
| `../scripts/harness-telemetry-readiness.sh` | sensor/computational | telemetry 数据窗口评估 | telemetry readiness | Orchestrator | self-audit | 聚合 ignored telemetry JSONL，输出 `SKILL_USAGE_MIGRATION_READY`、`MODEL_ROUTING_READY`、distinct changes/weeks 和事件计数；不迁移 gate、不自动 route model | 讨论 `skill-usage-gate.sh` 迁移、model routing 或数据窗口是否足够前 |
| `../scripts/harness-telemetry-readiness-test.sh` | sensor/computational | telemetry readiness contract 或脚本变更后 | telemetry readiness | Orchestrator | self-audit | 验证 `model_route_event` allowlist、数据不足等待、5 change readiness、空目录和 docs index | 修改 telemetry readiness 或 model route telemetry 字段后 |
| `../scripts/harness-telemetry-rehearsal.sh` | orchestration/computational | 实战前 telemetry 闭环演练 | telemetry readiness | Orchestrator | self-audit | 生成标记为 rehearsal-only 的脱敏事件，显式 include 后验证 readiness 与 weekly summary 链路；默认真实 readiness 不计入 rehearsal 数据 | 人工实战测试前、本地闭环演练时 |
| `../scripts/harness-telemetry-rehearsal-test.sh` | sensor/computational | telemetry rehearsal 脚本或 readiness exclude 规则变更后 | telemetry readiness | Orchestrator | self-audit | 验证 rehearsal 生成 5 change 数据、默认 readiness 排除 rehearsal、显式 include 才进入 ready path、summary 不泄露 source_ref | 修改 rehearsal 或 readiness include/exclude 逻辑后 |
| `../scripts/no-personal-paths.sh` | sensor/computational | 团队共享文件变更后 | team readiness | Orchestrator | self-audit | 扫描团队共享控制面文件中的真实个人绝对路径 | 控制面文档、模板、规则、脚本变更后 |
| `../scripts/ecc/ecc-sidecar.sh` | sensor/computational | 需要 ECC 参考能力时 | optional ECC | Orchestrator | self-audit | optional ECC sidecar 只读 / dry-run wrapper；ECC 缺失时输出提示但不阻断 harness | 需要 Codex 调用 ECC 参考能力时 |
| `../scripts/allowed-paths.sh` | sensor/computational | planned files 确认后 | 业务代码开工 / Pre-PR | Orchestrator | self-audit | 检查变更文件是否落在 spec 的 `allowed_paths` 内，并默认阻断 `.env*`、生产配置、prod k8s、DB migration 等 protected paths；失败输出包含 `CODE` / `FIX` / `SAMPLE` | 已自测通过，并修复 macOS bash 兼容问题 |
| `../scripts/assumption-leak-gate.sh` | sensor/computational | 实现文件变更后 | 业务代码开工 / Pre-PR | Orchestrator | self-audit | 检查 `[ASSUMP]` 标签或高信号假设标识是否进入实现文件 | 已接入 self audit |
| `../scripts/contract-delta-gate.sh` | sensor/computational | contract 或实现文件变更后 | Parallel Agent Pack | Orchestrator | self-audit | 检查契约变更是否同步 `contract-delta.md`；失败输出包含 `CODE` / `FIX` / `SAMPLE` | 已接入并行契约变更流程 |
| `../scripts/java-mechanical-quality.sh` | sensor/computational | Java / Mapper XML 变更后 | 后端 Pre-PR | Backend Agent | self-audit | 检查本次 Java / Mapper XML 改动中的高信号阿里 Java 规范问题 | 已接入，需随每次后端改动记录 evidence |
| `../scripts/swagger-model-documentation-gate.sh` | sensor/computational | `change-stage-gate.sh ... pre-commit` | Swagger 2 后端 API 文档 | Backend Agent / Orchestrator | self-audit | 对 active profile 仅检查本次新增 public response `*VO.java`，阻断缺 `@ApiModel` 或字段 `@ApiModelProperty`；不追溯 legacy/export/infrastructure DTO | `backend-sales-management` 已启用；其他仓须先新增 profile |
| `../scripts/code-comment-log-quality.sh` | sensor/computational | Java / Vue / JS 变更后 | Pre-PR / Reviewer | Orchestrator | self-audit | 检查本次 Java / Vue / JS 改动中的注释与日志问题；硬阻断前端调试日志，公共/导出方法缺文档注释输出 warning | 已接入，warning 需交 Reviewer 判断 |
| `../scripts/diff-hygiene-gate.sh` | sensor/computational | 业务仓 diff 收口前 | Pre-PR | Orchestrator | self-audit | 检查业务仓 diff 是否包含空白行/格式噪音，防止把无关空白变化带进 review | 业务代码 Pre-PR 前；需要明确基线时传 `--base <ref>` |
| `../scripts/mobile-mechanical-quality.sh` | sensor/computational | iOS / Android 变更后 | 移动端 Pre-PR | Mobile Agent | self-audit | 检查本次 iOS / Android 改动中的调试输出、硬编码 URL、异常直吐等高信号问题 | 移动端改动 Pre-PR 前 |
| `../scripts/architecture-drift-gate.sh` | sensor/computational | 业务代码收口前 | Pre-PR / Reviewer | Orchestrator | self-audit | 检查本次业务改动是否绕过 Controller/service/API/service/repository 等端侧架构边界 | 业务代码 Pre-PR 前；命中需修复或在方案和 review 中确认例外 |
| `../scripts/temp-hardcode-scan.sh` | sensor/computational | 合并前 | Pre-PR | Orchestrator | self-audit | 合并前扫描本次业务改动中的 `CODX` / `smoke` / `mock` / `localhost` / `token` / `password` / `TODO` / `FIXME` 临时写死标记；只输出路径、行号和命中词，不输出整行内容 | Pre-PR / 合并前 |
| `../scripts/gitnexus-impact.sh` | sensor/inferential | 高风险 symbol 计划变更前 | Impact Pack | Orchestrator | self-audit | 对计划修改的 class / method / DTO / Mapper / API symbol 执行 GitNexus impact；GitNexus 不可用时输出 `GITNEXUS_STATUS=UNAVAILABLE` 并降级为 `rg` / `git diff` / targeted checks 证据 | 高风险变更进入实现前；普通窄范围变更可记录 N/A |
| `../scripts/gitnexus-detect-changes.sh` | sensor/inferential | Pre-PR 或高风险改动收口前 | Impact Pack | Orchestrator | self-audit | 对本地 diff / staged diff / compare ref 执行 GitNexus detect_changes；输出包含 `HIGH` / `CRITICAL` 时以 `GITNEXUS/HIGH_RISK` 停止，要求用户确认影响范围 | Pre-PR 或高风险改动收口前 |
| `../scripts/reviewer-gate.sh` | sensor/inferential | Reviewer Agent 输出后 | Pre-PR | Reviewer Agent | self-audit | 检查独立 Reviewer Agent 输出是否覆盖技术方案一致性、harness 约束、架构漂移、注释 / 日志、可读性 / 可维护性和测试证据，并要求 HIGH 风险清零 | Reviewer Agent 输出 `review.md` 后、人工 review / PR 前 |
| `../scripts/codegraph-bootstrap.sh` | orchestration/computational | 新成员首次设置或新增业务仓后 | CodeGraph optional setup | Orchestrator | self-audit | 显式初始化业务仓 CodeGraph：读取 `config/repos.local.sh` / repo id，补本地 `.git/info/exclude`，执行 `codegraph init -i`，并支持 `--dry-run` / `--all` | 新成员首次设置或新增业务仓后 |
| `../scripts/codegraph-preflight.sh` | sensor/computational | CodeGraph MCP 查询前 | Impact Pack | Orchestrator | self-audit | 检查 CodeGraph CLI、业务仓 `projectPath`、`.codegraph/` 初始化状态，并可选执行 `--sync`；默认非阻塞，输出写入 evidence 后再做 MCP 查询 | CodeGraph 自查或影响面分析前 |
| `../scripts/codegraph-evidence-gate.sh` | sensor/computational | CodeGraph 结论进入 review 前 | Impact Pack / Reviewer | Orchestrator | self-audit | 检查 CodeGraph 证据是否记录 projectPath、preflight、explore/graph 查询、freshness/downgrade；阻断 miss 当无影响 | CodeGraph 影响面 / route 证据进入 review 前 |
| `../scripts/skill-usage-gate.sh` | sensor/computational | skill usage 更新后 | 计划确认 / Pre-PR | Orchestrator | self-audit | 检查 `changes/<change-id>/skill-usage.md` 存在、引用 harness skills、没有遗留 TODO，确保本仓 skill 被显式使用或写 N/A 原因 | 计划确认前、Pre-PR 前 |
| `../scripts/knowledge-reference-gate.sh` | sensor/computational | spec 引用 knowledge_refs 后 | knowledge lifecycle | Orchestrator | self-audit | 校验 spec 的 `knowledge_refs:` 引用的知识 ID 真实存在；`--audit` 列出从未被引用的衰减候选（只读、不改条目） | 实现 / ARCHIVE 阶段，及两周自审 |
| `../scripts/knowledge-lint.sh` | sensor/computational | 两周自审周期 | knowledge lifecycle | Orchestrator | self-audit | 按 `maturity` + `last_referenced` 只读报告知识条目的时间衰减 / 孤儿 / catalog 索引不一致；`--strict` 有 findings 时退出非 0（条目降级仍由人工执行） | 两周自审周期 |
| `../scripts/decision-gate.sh` | sensor/computational | decision 记录更新后 | 实现期 / 合并前 | Orchestrator | self-audit | 校验 `changes/<id>/decisions.md` 无遗留 `pending` 决策（fail-closed 阻断）；`--notify` 把待决项渲染成 Lark 文案（dry-run，本期不实发） | 实现期记录待决 / 合并前清零 |
| `../scripts/dev-env-check.sh` | sensor/computational | 新成员首次使用或本地服务启动前 | team rollout local mode | Orchestrator | self-audit | 检查团队成员本机 Git / Java / Maven / Node / npm / 业务仓路径 / lark-cli 能力 | 新成员首次使用或本地服务启动前 |
| `../scripts/parallel-worktree-gate.sh` | sensor/computational | 派发实现 agent 前 | Parallel Agent Pack | Orchestrator | self-audit | 检查实现 agent 是否使用隔离 worktree，避免多 agent / 多仓并行时共用脏工作区 | 派发实现 agent 前 |
| `../scripts/mvn-targeted-test.sh` | orchestration/computational | 后端改动验证时 | backend validation | Backend Agent | self-audit | 按 repo / module 执行最窄 Maven compile 或 targeted test，读取 `SFA_BACKEND_MAVEN_COMMAND` | 后端改动的窄验证 |
| `../scripts/canonical-command-gate.sh` | sensor/computational | 记录测试证据前 | backend validation | Backend Agent | self-audit | 验证命令执行前拦截已知无效命令；当前阻断 `sfa-sales-management-interfaces` Maven reactor 缺少 `-am` 的假失败 | 记录测试证据前 |
| `../scripts/frontend-lint-build.sh` | orchestration/computational | 前端改动验证时 | frontend validation | Frontend Agent | self-audit | 按 repo 执行 frontend lint / build / script / lint-files，普通脚本读取 `SFA_FRONTEND_PACKAGE_MANAGER` | 前端改动的窄验证 |
| `../scripts/frontend-dev-server.sh` | orchestration/computational | 启动 `mapSystem` 或 PC E2E Smoke 前 | UI Pack / E2E Pack | Frontend Agent | self-audit | 按 harness 本地运行时提示启动前端 dev server；`mapSystem` 默认使用 Node `14.21.3` | 启动 `mapSystem` 或 PC E2E Smoke 前 |
| `../scripts/eval-golden.sh` | sensor/inferential | 试点收口、模板变更或推广前 | golden scenario | Orchestrator | self-audit | 对 fullstack CRUD golden scenario 做本地 artifact / gate / review / PC smoke 摘要评分 | 试点收口、模板变更或推广前 |
| `../scripts/generate-local-routing.sh` | orchestration/computational | 本地前端需要命中本地后端时 | E2E Pack | Orchestrator | self-audit | 根据 active backend 项目和服务映射生成临时 `local-routing.yml` 与前端 smoke env | 本地前端需要命中本地后端时 |
| `../scripts/generate-local-routing.mjs` | implementation/computational | local routing generator 内部调用 | E2E Pack | Orchestrator | self-audit | `generate-local-routing.sh` 调用的 Node 实现，负责解析服务映射并生成路由 / env | 本地路由生成器内部实现 |
| `../scripts/generate-opencode-local-config.sh` | orchestration/computational | OpenCode 首次启用或路径异常时 | OpenCode adapter | Orchestrator | self-audit | 根据本机 `SFA_PROJECTS_ROOT` 生成 ignored 的 OpenCode 本地配置，兜底工具环境变量未传入的问题 | OpenCode 首次启用或路径异常时 |
| `../scripts/local-routing-gate.sh` | sensor/computational | 本地前端需要命中本地后端时 | E2E Pack | Orchestrator | self-audit | 检查 PC E2E Smoke 的本地代理配置，阻断 catch-all、非本地 target 和无契约来源 route | 本地前端需要命中本地后端时 |
| `../scripts/local-routing-business-config-gate.sh` | sensor/computational | 启动本地 PC smoke 前 | E2E Pack | Frontend Agent | self-audit | 本地联调前阻断业务前端 `vue.config.js` / `.env*` 代理配置改动，要求走 harness proxy 和 `local-routing.yml` | 启动本地 PC smoke 前 |
| `../scripts/miniapp-local-env-gate.sh` | sensor/computational | 小程序本地 smoke 前后 | E2E Pack | Frontend Agent | self-audit | 检查小程序本地联调环境记录，要求写明 `bd_owner_env_override` 当前值、实际请求 host、重新进入小程序和清理命令 | 小程序本地 smoke 前后 |
| `../scripts/temporary-state-ledger-gate.sh` | sensor/computational | 结束本地联调 / AI 测试报告前 | Temporary State Pack | Orchestrator | self-audit | 检查本地服务、微信 storage、测试数据、二维码、vConsole 等临时状态均已清理、转用户负责或写明保留原因 | 结束本地联调 / AI 测试报告前 |
| `../scripts/ui-confirmation-gate.sh` | sensor/computational | 复杂 UI 宣称通过前 | UI Pack | Frontend Agent | self-audit | 复杂 UI 未人工确认时 fail-closed；要求有确认状态、原型/截图/URL 和 reviewer CONFIRMED 行 | 复杂 UI 宣称通过前 |
| `../scripts/ui-screen-breakdown-gate-test.sh` | sensor/computational | UI rule / PRD 截图逐屏拆解变更后 | UI Pack | Frontend Agent | self-audit | 回归验证 `ui-rule-gate.sh` 对 `prd_screen_breakdown_status`、逐屏拆解行、BLOCKED 行和 side-by-side 证据计划的处理 | 修改 UI 逐屏拆解机制后 |
| `../scripts/harness-local-proxy.mjs` | orchestration/computational | PC E2E Smoke 执行期间 | E2E Pack | Orchestrator | self-audit | 按 `local-routing.yml` 启动 harness-only 本地 proxy，active backend 服务转本地，其他请求 fallback 到测试/预发环境 | PC E2E Smoke 执行期间 |
| `../scripts/business-repo-bootstrap.sh` | orchestration/computational | 业务仓首次接入 / change 切换后 | tool adapter | Orchestrator | self-audit | 在业务仓安装 ignored `AGENTS.md` stub、Cursor/Codex hooks 和 `.harness/active-change`，支持 `--check` / `--remove`；不修改业务代码、不覆盖 tracked `AGENTS.md` | 业务仓试点接入、真实开发流程前 |
| `../scripts/business-repo-bootstrap-test.sh` | sensor/computational | business repo bootstrap 变更后 | tool adapter | Orchestrator | self-audit | 回归验证业务仓本地 hook 安装、active-change 写入、本地 ignore、清理和 tracked `AGENTS.md` 保护 | 修改业务仓接入脚本后 |
| `../scripts/harness-sensor-runner.sh` | orchestration/computational | Agent loop 前置 / 后置 | tool adapter | Orchestrator | self-audit | 工具无关的轻量 sensor runner；Cursor / Codex / OpenCode adapter 只调用它，不复制强制逻辑 | Agent loop 前置/后置轻量门禁 |
| `../scripts/harness-sensor-runner-test.sh` | sensor/computational | sensor runner 变更后 | tool adapter | Orchestrator | self-audit | 回归验证危险 shell 命令结构化判定、绕过变体拒绝和低风险清理命令放行 | 修改 `harness-sensor-runner.sh` 后 |
| `../scripts/harness-team-readiness-test.sh` | sensor/computational | 团队化入口变更后 | team readiness | Orchestrator | self-audit | 检查团队化入口、个人路径硬编码、非阻塞问题和 forbidden paths 行为 | 已接入 self audit |
| `../scripts/agent-handoff-workflow-test.sh` | sensor/computational | Agent handoff / plan / reviewer / bootstrap 规则变更后 | Agent handoff | Orchestrator | self-audit | 回归验证 agent handoff workspace、task brief、review package、plan task contract、Reviewer 反诱导规则和 bootstrap smoke | 已接入 self audit |
| `../scripts/harness-gc-test.sh` | sensor/computational | lanes / AGENTS / Sensors / self-audit 变更后 | harness GC | Orchestrator | self-audit | 检查默认 lane 是否保持轻量、Sensors 是否有生命周期元数据、AGENTS 是否 scan-friendly、self-audit 是否委托 GC 检查 | 已接入 self audit |
| `../scripts/team-rollout-preflight.sh` | orchestration/computational | 团队成员首次正式使用前 | team rollout | Orchestrator | self-audit | 团队正式启用前的聚合检查；默认检查控制面，`--local` 额外检查个人工具链和业务仓路径 | 团队成员首次正式使用前 |

脚本只做最小门禁，不代替 Maven / npm / 人工 review。

## Lanes

| 文件 | 用途 |
| --- | --- |
| `../lanes/fullstack-crud.md` | 低风险 Vue2 + Java CRUD 的标准执行 lane |
| `../lanes/bugfix-fast.md` | 可复现 bugfix 的快速闭环 lane |
| `../lanes/pc-e2e-smoke.md` | PC 管理后台交付前浏览器自动冒烟 lane |

## Templates

| 文件 | 用途 |
| --- | --- |
| `../templates/spec-tier-s.md` | 单仓小修 spec 模板 |
| `../templates/spec-tier-m.md` | Vue2 + Java 小型功能 spec 模板 |
| `../templates/spec-tier-l.md` | 多仓或高风险变更 spec 模板 |
| `../templates/requirement-intake.md` | Tier M/L 需求 intake 模板：PRD 逐条编号、六类关键问题和质疑记录 |
| `../templates/frontend-style-profile.md` | 前端 repo 风格画像模板：样板文件、骨架 class、API/state pattern 和反例；配合 Reviewer `style_conformance` 裁决 |
| `../templates/plan-tier-m.md` | Tier M 实施计划模板 |
| `../templates/api-contract.md` | 前后端 API 契约模板 |
| `../templates/harness-status.md` | 用户可见的单一流程状态卡模板 |
| `../templates/agent-candidate-confirmation.md` | candidate implementation agent 派发前的确认文件模板；确认 allowed agent、code-start gate、allowed paths、worktree 和禁止 protected/global/DB/release 动作 |
| `../templates/technical-solution.md` | Tier M/L 完整技术方案和人工确认状态模板 |
| `../templates/verification-map.md` | Tier M/L 关键约束到验证方式的映射模板；`Verification` 列支持 `runner: shell/manual/N/A` 约定 |
| `../templates/ai-test-report.md` | AI 测试后给人工确认、进入测试 / 预发前的报告模板 |
| `../templates/retro.md` | Tier M/L、跨仓、返工/事故或高风险 change 的分层 closeout 复盘模板 |
| `../templates/miniapp-local-env.md` | 小程序本地环境 override / request host / 清理命令记录模板 |
| `../templates/temporary-state-ledger.md` | 本地联调、SIT 自测、二维码、服务、debug flag 等临时状态收口台账 |
| `../templates/codegraph-evidence.md` | CodeGraph explore-first workflow、freshness 和 downgrade 证据模板 |
| `../templates/review.md` | 独立 Reviewer Agent 输出模板；配合 `scripts/reviewer-gate.sh` |
| `../templates/dirty-worktree-ledger.md` | 业务仓 dirty diff 归属和处理决定台账 |
| `../templates/local-backend-services.yml` | harness-only 本地后端服务映射模板 |
| `../templates/local-routing.yml` | 由 generator 产出的 harness-only 临时代理 route 模板 |
| `../templates/codex-agent.toml` | 由 `scripts/codex-agent-generator.sh` 使用的 Codex agent 配置模板 |
| `../templates/skill-usage.md` | harness 本地 skill 使用记录模板 |
| `../templates/pc-e2e-smoke-plan.md` | PC 管理后台浏览器冒烟计划模板 |
| `../templates/pc-e2e-smoke-report.md` | PC 管理后台浏览器冒烟结果模板 |
| `../templates/pre-pr-review.md` | PR 前自审模板 |
| `../templates/business-repo-agents-stub.md` | 业务仓轻量 `AGENTS.md` stub 模板 |

## 工作流 Skills

| 文件 | 用途 |
| --- | --- |
| `../skills/explorer/SKILL.md` | 只读查证样板、事实和证据路径 |
| `../skills/reviewer/SKILL.md` | 只读审查 spec、plan、contract、diff、evidence |
| `../skills/grill/SKILL.md` | 需求和契约进入实现前的逐项澄清流程 |
| `../skills/diagnose/SKILL.md` | Bug / 回归 / 性能问题的复现优先诊断流程 |
| `../skills/tdd/SKILL.md` | 关键行为的轻量 red-green-refactor 测试流程 |
| `../skills/handoff/SKILL.md` | 长线程、阶段切换或上下文压缩前的交接文档 |
| `../skills/third-party/mattpocock-skills.md` | 第三方 skill 来源、许可和本地化说明 |
| `../skills/third-party/external-codex-skills.md` | 外部 Codex skill / Brooks lens 的只读使用边界、禁用项和归并规则 |
| `../skills/third-party/ecc-skills.md` | ECC skill/agent 能力作为可选 sidecar 和只读借鉴来源的边界 |

## OpenCode

| 文件 | 用途 |
| --- | --- |
| `../opencode.json` | OpenCode 项目级配置，显式加载控制面指令并设置权限 |
| `../config/agent-registry.yml` | Agent 定义 source of truth；OpenCode/Codex adapter 都必须从这里引用 |
| `../.cursor/hooks.json` | Cursor 项目级 hooks adapter，调用 `hooks/cursor-*.sh` 再委托通用 runner |
| `../.cursor/rules/` | Cursor Project Rules adapter；引用 `AGENTS.md` 和 `rules/` source of truth |
| `../.codex/hooks.json` | Codex 项目级 hooks adapter，调用 `hooks/codex-*.sh` 再委托通用 runner |
| `../.codex/config.toml` | Codex 项目级配置，启用 hooks；`AGENTS.md` 仍是指令 source of truth |
| `../hooks/` | Cursor / Codex hook 包装脚本；只做 adapter，不承载独立强制逻辑 |
| `../scripts/codex-agent-generator.sh` | 从 registry 生成 Codex agent TOML，默认 dry-run，不默认写全局目录 |
| `../scripts/agent-dispatch-plan.sh` | 从 registry 生成 Agent 派发计划；不直接执行 Agent，candidate implementation 需要确认文件 |
| `../scripts/agent-dispatch-plan-gate.sh` | 校验 Agent 派发计划和 registry 一致 |
| `../scripts/agent-output-contract-gate.sh` | 从 registry 校验 Agent 输出契约，再委托 Reviewer / Test Agent gate |
| `../config/opencode.local.json` | 本地生成的 OpenCode 绝对路径配置；ignored，不提交 |
| `../.opencode/agents/sfa-harness-explorer.md` | OpenCode 只读 Explorer agent |
| `../.opencode/agents/sfa-harness-reviewer.md` | OpenCode 只读 Reviewer agent |

## Evals

| 文件 | 用途 |
| --- | --- |
| `../evals/datasets/fullstack-crud-golden.yaml` | 第一条 fullstack CRUD golden scenario；路径使用 `SFA_REPO_*` 环境变量，不绑定个人机器 |

本地最小评分命令：

```bash
scripts/eval-golden.sh <change-id> <changed-files...>
```

## Contracts

首个试点契约已创建：

```text
contracts/pilot-crud-tbd-api.md
contracts/special-display-department-photo-list-api.md
```

契约必须先于前后端实现，至少包含：

- endpoint / method
- request fields
- response fields
- enum / status / error code
- pagination / empty state
- frontend mapping
- backward compatibility

## Decision Log

决策日志按日期命名：

```text
decision-log/YYYY-MM-DD-<topic>.md
```

必须记录：

- 试点选择
- 用户拍板项
- 规则保留 / 删除 / 延后
- 工具能力验证结果
- 复盘结论

可复用的 decision 条目建议带 front matter 元数据（`maturity` / `sources` / `last_referenced` / `referenced_by`），约定见 `decision-log/2026-05-29-knowledge-lifecycle.md`。

## Samples

`samples/` 用于记录可模仿样板，不直接复制业务代码。入口见 `samples/README.md`，条目按 `samples/TEMPLATE.md` 写，每条应写：

- repo id
- file path
- 适合模仿的点
- 不应模仿的点
- 适用 lane
- front matter 元数据（`maturity` / `sources` / `last_referenced`）
