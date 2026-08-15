# SFA AI Harness 使用期问题诊断与解决方案（2026-07-02）

> 定位：上一轮改造（`harness-evolution-architecture`，Phase 0–5F）已完成"度量管道 + 分层架构"的建设；本文针对**真实使用中暴露的 7 个问题**做第二轮诊断。
> 所有结论基于：飞书《sfa-harness 自身的 Tier L 架构演进方案》及其 11 个子文档、飞书《ECC 的 Harness 调研》、本地 `docs/harness-diagnosis-and-remediation.md`（v3）、当前仓库源码实测。
> 证据标注沿用演进方案的归因规范：`[LOCAL-FACT]` / `[AI-INFERENCE]` / `[USER-DECISION]` / `[PENDING-DECISION]`。其中 `[USER-DECISION]` 必须有明确用户确认来源；未经确认的执行口径一律标为 `[PENDING-DECISION]`。
> 停止点：本文是诊断和方案，**方案确认前不实施任何 gate / hook / 脚本 / 模板改造**。

---

## Codex 审阅修正记录（2026-07-02）

> 本节记录对 Fable 5 生成稿的二次审阅修正，作为后续执行前的约束。若本节与正文旧表述冲突，以本节为准。

1. **不能把方案建议写成已拍板事实**：原稿 §7 使用 `[USER-DECISION]` 记录“同意整体 commit + tag”等内容，但当前上下文没有可引用的真实确认来源。已修正为 `[PENDING-DECISION]`，执行前必须再次确认或补充确认来源。
2. **Wave 0 不是立即提交，而是立即形成提交口径**：当前用户曾明确要求“改动先别 git 提交”。因此未提交成果收口应先做 scope inventory、敏感信息扫描、提交分组建议和回滚点方案，只有获得明确授权后才能 commit/tag。
3. **post-edit hook 不能物理阻断已发生的编辑**：`afterFileEdit` / `PostToolUse` 只能事后报警，不能撤销落盘修改。物理阻断点应放在 `beforeShellExecution/PreToolUse` 对 `git add` / `git commit` / `git push` 等版本化动作的拦截，以及 stage gate 兜底。
4. **SessionStart 结论需区分“runner 有入口”和“hook 未接线”**：`harness-sensor-runner.sh` 已有 `sessionStart / SessionStart` 使用约定，但 `.codex/hooks.json` / `.cursor/hooks.json` 未把它接入正常会话，所以实际不可达。
5. **verification-map 机读化应兼容现有 `Verification` 列**：不是简单新增一个孤立 `command` 列，而是把验证描述规范为 `runner / command / expected / actual / evidence / status`，人工项保留 `manual`。
6. **telemetry best-effort 不能静默失败**：埋点失败不应阻断业务 gate，但必须输出 warning，并被 weekly audit / harness-self-audit 统计，否则会产生“以为有数据、实际无数据”的假安全感。
7. **业务仓 hook/stub 分发应先试点再全量**：建议先选 `mapSystem` + 一个后端仓试点，验证零版本污染、低误拦和 preflight 可用后，再扩展到全部业务仓。

---

## 0. 结论速览（TL;DR）

7 个问题背后是 **3 个共同根因**，先看清它们，7 个问题的解法就不再是零散补丁：

| 根因 | 一句话描述 | 波及的问题 |
| --- | --- | --- |
| **RC-A 执行面覆盖窄：约束是"拉式"不是"推式"** | 关键 gate（code-start、技术方案确认、allowed-paths）都要靠 Agent **自觉去跑**；runtime hook 只拦"危险 shell 命令"和"设置了 `SFA_CHANGE_SPEC` 时的路径越界"，其余全靠模型读文档自律 | #2、#4、#5 |
| **RC-B 规则不跟随业务仓 workspace** | rules / hooks / AGENTS 约束都住在 harness 仓；当人或子 Agent 直接在 `mapSystem` 等业务仓工作时，这些约束**一条都不生效** | #1、#2、#4 |
| **RC-C 度量管道建好了但没有自动进料，复盘闭环没有强制收口** | telemetry / weekly audit / instinct validator / readiness 全部就绪，但真实数据只有 8 条事件（`DECISION=WAIT_DATA_WINDOW`）；埋点靠手动、closeout 无强制 retro | #7（也拖累 #1–#6 的持续改进） |

**最该先做的 5 件事（按 ROI 排序）**：

| 优先级 | 动作 | 解决 | 成本 |
| --- | --- | --- | --- |
| P0 | post-edit 强报警 + pre-shell 版本化动作阻断：命中 `SFA_REPO_*` 路径时强制校验 code-start 条件 | #2、#4 | 低 |
| P0 | 业务仓 bootstrap 试点：把 hooks + AGENTS stub + rule_profile 指针先分发到试点仓并纳入 preflight 校验，验证后再全量 | #1、#2、#4 | 低 |
| P1 | 每个前端仓建 style-profile 基线 + plan 强制"样板引用"字段 + Reviewer 增加 `style_conformance` 裁决 | #1、#3 | 中 |
| P1 | 技术方案增加"PRD 截图逐屏拆解表" + 实现后 side-by-side 截图对照证据 | #3 | 中 |
| P1 | gate 自动埋点（gate 运行即写 telemetry）+ closeout 分层 retro 强制 | #7、#5 | 中 |

**AI 主动排查的额外发现（§5，不在 7 个问题内但同等重要）**：危险命令黑名单可被平凡变体绕过（`git push -f`、`rm -Rf` 全放行，L3 硬核强度被高估）；控制面自身存在大量未提交状态记录，Phase 4A–5F 成果缺少版本保护；上一轮诊断的 P0 减负项（scaffold / 产物矩阵 / SSOT 归档）整体未落地而产物过载仍在发生；`afterFileEdit/PostToolUse` 是事后事件不能物理阻断（本文方案已按此修正为三层设计）；behavior eval 是静态"纸面 eval"；telemetry 数据窗口与重流程互锁形成死锁；hook 链路依赖 node/git 任一缺失即静默 fail-open。其中"未提交收口"应**先于一切改造形成提交口径和授权方案**，但不得绕过用户"暂不提交"指令。

---

## 1. 诊断证据基线（实测 2026-07-02）

| 项目 | 实测状态 | 来源 |
| --- | --- | --- |
| runtime hooks（Cursor） | 仅 `beforeShellExecution`（拦危险命令）+ `afterFileEdit`（仅 `SFA_CHANGE_SPEC` 已设置时查 allowed-paths，否则**直接放行**） | `.cursor/hooks.json`、`scripts/harness-sensor-runner.sh` L184–191 |
| runtime hooks（Codex） | 仅 `PreToolUse` + `PostToolUse`，同上 | `.codex/hooks.json` |
| SessionStart / Stop / PreCompact | hook 配置层**均未接线**；`harness-sensor-runner.sh` 有 `sessionStart / SessionStart` 使用约定，但 `.codex/hooks.json` / `.cursor/hooks.json` 未接入正常会话，因此实际不可达 | `[LOCAL-FACT]` |
| code-start 强制机制 | `business-code-start-gate.sh` 逻辑完备（技术方案 CONFIRMED + `allowed_next_stage: code_start` + allowed_paths + 非 main/master 分支），但**没有任何 hook 自动触发它** | `scripts/business-code-start-gate.sh` |
| 前端风格规则 | `rules/frontend-vue2.mdc`（157 行，含样板清单、失败复盘规则）+ `rules/frontends/legacy-sfa/web/*.mdc`（11 个文件，class 级细则），质量高；但都住在 harness 仓 | `[LOCAL-FACT]` |
| UI 门禁 | `ui-rule-checklist.md` 模板 + `ui-rule-gate.sh`（查状态字段）+ 复杂 UI HTML 原型门禁（写在 frontend-vue2.mdc） | `[LOCAL-FACT]` |
| 多 Agent 契约 | Phase 5A `agent-handoff-contract.md` 已落地：task brief / implementer report / review package / progress ledger / read-only reviewer / 双裁决（`spec_compliance` + `code_quality`）/ 禁止预判措辞 | `[LOCAL-FACT]` |
| 方案一致性机制 | `verification-map-gate.sh` + `ai-test-plan-gate.sh` + Test Agent 循环（GOAL_ACHIEVED/BLOCKED）+ reviewer `spec_compliance` 裁决 | `[LOCAL-FACT]` |
| 需求质疑机制 | `skills/grill/SKILL.md`（先查证后提问、单问题追问、默认建议+影响）+ `confidence-gate.sh`（支持 `STRICT_QUESTIONS=1`）+ `assumption-leak-gate.sh` | `[LOCAL-FACT]` |
| 自我迭代管道 | Phase 4A–5F 全部就绪：control-audit、behavior-eval（5 场景）、reliability（pass@k/pass^k）、telemetry（5 类事件）、weekly-audit-summary、readiness checker、instinct validator、rehearsal | `[LOCAL-FACT]` |
| 自我迭代真实数据 | `.harness/telemetry/events.jsonl` 仅 **8 条**（1 个真实 change）；`harness-telemetry-readiness.sh` 输出 `SKILL_USAGE_MIGRATION_READY=0`、`MODEL_ROUTING_READY=0`、`DECISION=WAIT_DATA_WINDOW` | 实测命令输出 |
| retro / closeout 复盘 | **无 retro 模板、无 closeout 强制**；诊断文档 v3 P1-2 的"分层 retro"尚未落地 | `[LOCAL-FACT]` |

---

## 2. 七个问题逐一诊断

### 问题 1　Vue2 前端代码风格偏后端写法，不贴合仓库既有风格

**现象**：功能可用，但写法不像 `mapSystem` 既有代码——布局不套系统 class、API 调用方式偏"后端直连"思维、组件组织不遵循仓库惯例。

**排查结果**：

- `[LOCAL-FACT]` 规则本身**不缺且相当细**：`rules/frontends/legacy-sfa/web/` 有 11 个 `.mdc`（ui-search-list-layout、ui-details-patterns、button-standards、ui-color-design 等），`frontend-vue2.mdc` 写到了 `customerlist-table` / `new-search-wrapper` / `all-el-pagination` 这种 class 级约束，还有"本次失败复盘规则"（功能可用但视觉不像系统 → 先查是否没消费用户指定参考页）。
- `[LOCAL-FACT]` 但这些规则的生效前提是**会话运行在 harness 仓 workspace**。当你或子 Agent 直接在业务仓（`mapSystem`）里开发时，harness 的 `.mdc` 规则、hooks 全部不加载；业务仓只有一个可选的 `templates/business-repo-agents-stub.md`（且没有分发/校验机制确保它真的存在于业务仓）。
- `[LOCAL-FACT]` "样板优先/抽样 2-3 个同模块页面并写进 plan"是规则文字，**没有任何 gate 校验它被执行**；Reviewer 检查"参考页是否被实际消费"也是软要求。
- `[AI-INFERENCE]` 风格偏后端不是因为你是后端出身"带偏"了 AI——是模型在**缺少仓库风格锚点**时回落到自己的通用先验（偏工程直译、少视觉惯例）。锚点缺失的原因就是上面两条：规则没跟进 workspace + 样板引用没有强制。

**解决方案**：

1. **建 repo 级风格画像（style profile）**：每个前端仓一份 `docs/baseline/<repo>-style-profile.md`，内容从真实代码提炼——目录/命名惯例、API 层封装方式（必须走 `src/api`）、列表/详情/表单三类页面的骨架 class 清单、状态管理惯例、**正例文件路径 + 反例（不要这样写）**。它和现有 `.mdc` 规则的区别：规则是"约束"，画像是"喂给 Agent 的仿写锚点"，实现前必读。
2. **plan / technical-solution 增加"样板引用"必填结构化字段**：本次每个页面参考了哪些真实文件（`repo/path` 列表）+ 复用了哪些骨架 class。`ui-rule-gate.sh`（或 code-start stage）校验该字段非空且路径真实存在。
3. **Reviewer 双裁决扩为三裁决**：在 `spec_compliance` / `code_quality` 之外增加 `style_conformance`——对照 style profile 和样板引用检查"是否像这个仓的代码"；不达标列 HIGH。
4. **规则试点分发进业务仓**（与问题 2/4 共用）：bootstrap 脚本先把 AGENTS stub（内嵌 rule_profile 指针，指向 harness 的 style profile 和 `.mdc` 包）写入试点业务仓，`team-rollout-preflight.sh` 增加存在性校验；试点通过后再扩展到全部业务仓。
5. **机械层兜底**：`architecture-drift-gate.sh`（查绕过 `src/api`、硬编码 URL）纳入 pre-commit stage 必跑，而不是 pre-PR 自查清单里的一项。

**验收**：新前端 change 的 plan 100% 有样板引用字段；Reviewer 输出含 `style_conformance` 裁决；人工 review "不像系统代码"类反馈次数下降（用 telemetry `reviewer_event` 追踪）。

---

### 问题 2　没确认技术方案，AI 就直接进入代码开发

**现象**：别人使用时偶发——完全按 harness 流程走的前提下，AI 跳过技术方案确认直接改代码。

**排查结果**：

- `[LOCAL-FACT]` 防线逻辑本身完备：`technical-solution-gate.sh` 要求 `confirmation_status: CONFIRMED` 且 `allowed_next_stage: code_start`；`business-code-start-gate.sh` 会级联校验方案、verification-map、contract allowed_paths、非保护分支。**问题是这些 gate 全是"拉式"**——Agent 必须自觉调用。模型在长上下文、用户催促、或规则被压缩掉时，最先丢的就是"我应该先跑 gate"这个动作。
- `[LOCAL-FACT]` runtime 层没有兜底：`afterFileEdit` hook 只在 `SFA_CHANGE_SPEC` 环境变量已设置时才查 allowed-paths（没设置就输出 "skipped" 并放行），且**完全不检查技术方案确认状态**。`SFA_CHANGE_SPEC` 是手动 env，别人多数不会设。
- `[LOCAL-FACT]` SessionStart 在 hook 配置层未接线。runner 有 `sessionStart / SessionStart` 使用约定，但 `.codex/hooks.json` / `.cursor/hooks.json` 未接入正常会话，因此会话开始时没有机制把"当前 change 处于什么 stage、code-start 是否 BLOCKED"注入上下文。
- `[LOCAL-FACT]` `evals/harness-behavior/scenarios/technical-solution-stop.md` 已覆盖此场景，但它是静态 eval，只能回归验证规则文案，防不了真实会话。
- `[AI-INFERENCE]` 这正是诊断文档 v3 §8.3 的结论在真实使用中的显影：**行为纪律放在 L0（文字引导）层，但它的风险等级其实要求 L3（硬门禁）兜底**。"未确认方案不得改业务代码"属于停止点类约束，应该推式强制。

**解决方案**：

1. **把 code-start 从拉式变推式（核心，三层组合）**——注意一个关键技术事实（详见 §5-D）：Cursor 的 `afterFileEdit` 和 Codex 的 `PostToolUse` 都是**编辑后事件，deny 无法撤销已发生的编辑**，所以"推式强制"必须由三层组合实现，而不是单点 hook：
   - **第一层（即时报警）**：升级 `harness-sensor-runner.sh` 的 `afterFileEdit/PostToolUse` 分支——编辑路径命中 `config/repos.local.sh` 任一 `SFA_REPO_*` 前缀且 code-start 条件不满足（Tier M/L 且 `allowed_next_stage != code_start`）时，返回强错误消息（带 FIX），让 Agent 在下一步就地停止并回滚该编辑。这是"吓停"，不是物理阻断。
   - **第二层（物理阻断点）**：`beforeShellExecution/PreToolUse` 是真正的 pre 事件——拦截业务仓内的 `git add` / `git commit` / `git push`，code-start 条件不满足时 deny。编辑可以发生，但**永远进不了版本历史**。
   - **第三层（流程兜底）**：pre-commit stage gate（已有）保持硬校验，作为 hook 失效时的最终防线。
   - 性能守护：只对业务仓路径触发，harness 仓自身编辑不受影响。
2. **active change 自动发现**：用 `.harness/active-change`（一行 change-id，ignored 文件，由 `agent-workspace.sh` / scaffold 写入）替代手动 `SFA_CHANGE_SPEC` env，消除"没设 env 所以跳过"这个洞。
3. **业务仓 hook 试点分发**：别人直接在业务仓开 Cursor 时 harness hook 不存在，是最大盲区。bootstrap 脚本先向 `mapSystem` + 一个后端仓写入指向 harness sensor-runner 的薄 `.cursor/hooks.json` / `.codex/hooks.json`（`$SFA_HARNESS_ROOT` 解析）并纳入 preflight；试点证明零版本污染、低误拦、可一键回滚后，再扩展到全部业务仓。
4. **SessionStart runtime pilot**（按 Phase 5B0 已定契约：≤30 行 / ≤2000 字符预算）：注入当前 active change 的 stage、code-start 是否 BLOCKED、三条停止点提醒。先在 Codex runner 路径做最小接线；Cursor 按 lifecycle matrix 现状标注 NOT_SUPPORTED，依赖第 1 条 post-edit 告警兜底。
5. **behavior eval 升级**：technical-solution-stop 场景从"检查规则文案"升级为可对新 hook 做 fixture 回放（喂伪造 afterFileEdit payload，断言输出强报警；再喂 beforeShellExecution/PreToolUse 的 `git add`/`git commit` payload，断言 deny），并纳入 `harness-behavior-reliability.sh --mode safety`（要求 pass^k）。

**验收**："方案未确认即编辑业务文件"会在 post-edit hook 输出强报警，且后续 `git add` / `git commit` / `git push` 被 pre-shell hook 或 stage gate deny（fixture 测试证明）；真实使用 4 周内 telemetry `gate_run` 出现该阻断记录或零发生；试点业务仓 workspace preflight 全部通过。

---

### 问题 3　前端页面还原度与 PRD 截图有差距

**现象**：功能没大问题，但页面样式相对 PRD 截图还原度不足。

**排查结果**：

- `[LOCAL-FACT]` 现有三层机制：`ui-rule-checklist.md`（PRD UI source / 规范映射 / 缺口确认）+ `ui-rule-gate.sh`（查 `ui_rule_status: READY` 和缺口状态字段）+ 复杂 UI HTML 原型门禁（人工确认前不得正式实现）。
- `[LOCAL-FACT]` 缺口一：**PRD 截图没有被强制结构化拆解**。`templates/technical-solution.md` §7 的页面矩阵只有"页面/入口/交互/API/验证方式"，没有逐张截图的布局分解；`ui-rule-checklist.md` 的"UI 规范映射"粒度是组件/交互条目，是否逐屏覆盖靠自觉。gate 只查状态字段，不查拆解完整性。
- `[LOCAL-FACT]` 缺口二：**实现后没有强制对照证据**。验收截图计划在模板里，但没有"PRD 截图 vs 实现截图并排对照"的必填证据格式，Test Agent 验证项也不含视觉对照。
- `[AI-INFERENCE]` 缺口三：模型的注意力天然吸附在字段和接口上，布局/间距/密度这类视觉信息如果不被显式转成文字清单，就会被降权处理。`frontend-vue2.mdc` 的"失败复盘规则"已经写明这一点（"实现前必须从参考页提炼结构约束，而不是只看字段和接口"），但同样是没有机制化的文字。
- **回答你的问题**："是不是提前在技术方案里写前端实际的开发详细方案？"——方向对，但关键不是"写更多自由文本"，而是**把 PRD 截图转成 gate 可校验的结构化拆解表 + 实现后可对照的证据环**。自由文本再详细，模型实现时还是可能漂移；有对照证据环才闭环。

**解决方案**：

1. **技术方案 §7 增加"PRD 截图逐屏拆解表"**（Tier M/L 含 UI 时必填）：

   | 截图编号 | PRD 截图引用 | 区域分解 | 目标骨架/class 映射 | 与现有样板差异点 | 差异处理 |
   | --- | --- | --- | --- | --- | --- |
   | UI-01 | `<飞书图片/本地路径>` | header / 搜索区 / 表格 / 操作列 / 分页 | `new-search-wrapper` / `customerlist-table` / ... | `<PRD 特有元素>` | `复用 X` / `用户确认新增样式` |

   每张 PRD 截图必须有一行；差异点未确认 → 该行 BLOCKED，不得进 code-start。`ui-rule-gate.sh` 增加对该表存在性和 BLOCKED 行的校验。
2. **原型确认升级**：复杂 UI 的 HTML 原型确认记录必须包含"原型 vs PRD 截图逐屏对照结论"（哪些一致、哪些有意偏离及用户确认），而不是只记"用户已确认"。
3. **实现后 side-by-side 证据**：smoke 证据强制格式——同一表格里 PRD 截图和实现截图并排，一屏一行，差异标注；Test Agent 的 `ai-test-plan` 对 UI change 必含"视觉对照"验证项，还原度不达标返回 issue 而不是只验功能。
4. **Reviewer `style_conformance` 裁决**（与问题 1 共用）覆盖"逐屏拆解表是否被实际消费"。
5. **失败样本回流**：每次"还原度不足"的人工反馈按问题 7 的 instinct-candidate 流程沉淀（`issue_category: ui-fidelity`），积累到阈值后升级为规则或样板补充。

**验收**：新 UI change 100% 有逐屏拆解表且零 BLOCKED 进入实现；evidence 有 side-by-side 对照；"还原度不足"类人工反馈次数用 telemetry 追踪并下降。

---

### 问题 4　多 Agent 同时开发时如何保证遵守 harness 约束

**现象**：多 Agent 并行时约束执行不稳定（问题 3 的 UI 漂移多发生在此场景）。

**排查结果**：

- `[LOCAL-FACT]` Phase 5A 已建立完整的**文件交接契约**：`agent-handoff-contract.md` 定义了 task brief（含 `change_id`/`task_number`/`source_plan`/`source_repo` 稳定元数据）、implementer report 状态机、review package（`READ_ONLY` + 双裁决 + 禁止预判措辞）、progress ledger（compaction 后恢复源）。`agent-workspace.sh` / `agent-task-brief.sh` / `agent-review-package.sh` / `parallel-worktree-gate.sh` 脚本齐备。
- `[LOCAL-FACT]` 缺口一：**约束继承靠 brief 文字**。子 Agent 收到 task brief 后是否遵守 allowed_paths、停止点，没有 runtime 兜底——worktree 里没有 hook（worktree 是业务仓的，回到 RC-B），`SFA_CHANGE_SPEC` 不会自动传入子会话。
- `[LOCAL-FACT]` 缺口二：**per-task review 是契约要求但不是 gate 要求**。ledger 里 `Review verdict` 可以填 `N/A: reason`，没有 stage gate 校验"每个 DONE 任务都经过 task review"。
- `[LOCAL-FACT]` 缺口三：behavior eval 5 个场景里没有多 Agent 场景（子 Agent 越界、brief 约束被忽略）。
- `[AI-INFERENCE]` 多 Agent 的可靠性来源应是"隔离写入面 + 主 Agent 汇总 + 阶段门禁"（ECC 调研 §五的结论），其中"隔离写入面"SFA 已有（worktree），最弱的是写入面上的 runtime 校验。

**解决方案**：

1. **worktree bootstrap 自动布防**（核心，与问题 2 共用机制）：`agent-workspace.sh` 创建/初始化 worktree 时自动完成——写入业务仓薄 hooks（指向 harness sensor-runner）、写入 `.harness/active-change` 指针、写入 AGENTS stub。子 Agent 在 worktree 里的越界编辑会被 post-edit hook 强报警，后续 `git add` / `git commit` / `git push` 被 pre-shell hook 或 stage gate fail-closed 校验（allowed_paths + code-start 状态），**约束从 brief 文字变成可执行事实**。
2. **task brief 内嵌机读约束块**：`agent-task-brief.sh` 自动生成 `constraints:` 段（allowed_paths 摘录、禁止事项、停止点、"不得派生子 Agent"），implementer report 模板要求逐条自查确认。
3. **ledger 完整性 gate 化**：pre-pr / closeout stage 校验 progress ledger——每个 `COMPLETE` 任务必须有 implementer report 路径 + review verdict（`PASS`/`ISSUES_FOUND` 已处理）；`N/A` 必须带 reason 且 Orchestrator 签注。
4. **并行红线沿用并写进 brief**：只并行互不依赖、不写同一文件/同表的任务（ECC 的约束）；`parallel-worktree-gate.sh` 在 dispatch 前跑，检查任务间 allowed_paths 无交集。
5. **behavior eval 增加多 Agent 场景**：`subagent-out-of-scope-edit`（子 Agent 编辑 brief 外文件后触发 post-edit 强报警，且版本化动作被 deny）、`ledger-incomplete-closeout-stop`（ledger 缺 review verdict 时 closeout 被拒），纳入 safety 模式 pass^k。

**验收**：worktree 内越界编辑触发 hook 强报警，后续版本化动作被 deny（fixture 证明）；closeout 时 ledger 完整率 100%；多 Agent change 的 review 漏检类反馈下降。

---

### 问题 5　技术方案和目标已确认后，如何保证 AI 严格按方案实现、自动 check 修复直到完成

**排查结果**：

- `[LOCAL-FACT]` 闭环的骨架已经在：`verification-map.md`（方案验收项 ↔ 证据映射，gate 校验行数和状态）、`ai-test-plan.md`（独立 Test Strategy Agent 产出 + 用户确认）、Test Agent 循环（AGENTS 明确"returns issues, retests until GOAL_ACHIEVED or BLOCKED"）、Reviewer 的 `spec_compliance` 裁决（"diff 实现了 task brief 和已确认方案，无未批准范围"）。
- `[LOCAL-FACT]` 缺口一：**verification-map 是人填的静态表**。`verification-map-gate.sh` 校验的是表格形状（行数、状态字段），不是逐项可执行；"实现是否覆盖方案每一项"没有机器跑得出来的清单。
- `[LOCAL-FACT]` 缺口二：**循环纪律是文字约定**。"修复→复跑→直到全过"写在 AGENTS 里，但中途停下没有机器信号；Main Agent 可以在部分项 FAIL 时口头解释后收口。
- `[AI-INFERENCE]` 缺口三：Test Agent 复验如果只是"读 Main Agent 的报告"，独立性形同虚设；必须独立复跑同一套机读清单。

**解决方案**：

1. **verification-map 机读化**：兼容现有 `Verification` 列，把每行验证描述规范为 `runner`（shell/manual/tool）、`command`（可执行验证命令，可空）、`expected`（期望输出/退出码/人工判定标准）、`actual`、`evidence`、`status`。纯人工项（视觉对照、真机）标 `manual` 并指向证据路径。
2. **新增 `scripts/verification-run.sh <change-dir>`**：逐行执行 shell/tool 类型 command、对照 expected，manual 项只校验证据路径和人工判定字段，输出 `PASS/FAIL/MANUAL_PENDING` 清单和总判定。这就是"自动 check"的机器载体。
3. **修复循环协议**：Main Agent 的完成定义收紧为——`verification-run` 全绿（manual 项证据齐）→ 才能请求 Test Agent 复验；任何 FAIL 必须修复后**复跑全量**（防止修 A 坏 B），循环无轮数上限，直到全绿或写明 `BLOCKED`。该协议写入 `skills/tdd` 和 orchestrator 约定，并由 closeout stage gate 校验 verification-run 输出存在且全绿。
4. **Test Agent 独立复跑**：`test-agent-verification.md` 要求 Test Agent 亲自执行 `verification-run.sh`（而非引用 Main Agent 输出），两份输出都进 evidence；不一致本身就是 finding。
5. **方案覆盖的双向校验**：Reviewer `spec_compliance` 保持"实现不超出方案"（已有）；verification-map 建立时由 Test Strategy Agent 对照技术方案逐节生成（方案每个设计小节至少映射一行），保证"方案不漏进实现"——`verification-map-gate.sh` 增加"方案章节引用覆盖"检查。

**验收**：closeout 前 `verification-run` 全绿成为硬条件；Test Agent 与 Main Agent 的双份运行记录都在 evidence；"实现与方案不符"类人工反馈用 telemetry 追踪下降。

---

### 问题 6　需求进来后分析和质疑不够，存在遗漏和 AI 自行猜测

**排查结果**：

- `[LOCAL-FACT]` 机制存量：`skills/grill/SKILL.md` 质量很好——先查证后提问、一次一个阻塞问题、每问带默认建议和影响、禁止把默认建议写成用户已确认；`confidence-gate.sh` 校验 `[FACT]/[ASSUMP]/[QUESTION]` 存在且阻塞 QUESTION 未解决则 FAIL（支持 `STRICT_QUESTIONS=1`）；`assumption-leak-gate.sh` 防 ASSUMP 漏进实现。
- `[LOCAL-FACT]` 缺口一：**grill 是路由建议不是强制**。`docs/skills-routing.md` 把 grill 列为"复杂需求"场景必读，但没有 gate 校验"grill 被执行且输出落盘"；intake stage 只跑 confidence-gate（查 spec 里标记存在）。
- `[LOCAL-FACT]` 缺口二：**PRD 逐项拆解出现得太晚**。"PRD 端到端覆盖矩阵"在技术方案模板 §0——那是方案阶段；intake 阶段没有"PRD 原文逐条 → 逐条归类 FACT/ASSUMP/QUESTION"的强制产物，遗漏在 spec 成形前就已发生。
- `[LOCAL-FACT]` 缺口三：形式可以骗过 gate——spec 写 `[ASSUMP] None.` 即可通过 confidence-gate；质疑深度没有任何度量。
- `[AI-INFERENCE]` "AI 自己猜测"的机制学根源：模型倾向用先验补全信息缺口而不是暴露缺口。对抗手段只有一种被验证有效——**强制枚举**：先逼它逐条列出 PRD 每一项和信息缺口，再逼它给每个缺口标来源或标问题。这正是 grill 的设计，缺的是把它从"可选技能"变成"intake 的结构性产物"。

**解决方案**：

1. **新增 intake 产物 `requirement-intake.md`**（Tier M/L 必有，模板化）：
   - **PRD 逐条编号表**：PRD 每个章节/页面/字段/验收项一行，逐行标 `[FACT]（带来源）/ [ASSUMP] / [QUESTION]`——不允许整段归纳，必须逐条。
   - **六类关键问题显式回答**（来自 grill 的清单）：业务对象、入口和角色、CRUD 范围、字段口径（默认值/必填/枚举/空态/错误码）、DB/权限/状态机/MQ/job 涉及面、最小回滚——每类必须有答案或列为 QUESTION，不允许空缺。
   - **质疑记录**：本次向用户提出的问题 + 用户答复原文引用。
2. **intake stage gate 升级**：校验 `requirement-intake.md` 存在、PRD 条目行数 > 0、六类问题无空缺、所有阻塞 QUESTION 已解决；Tier M/L 默认启用 `STRICT_QUESTIONS=1`。
3. **grill 强制化**：skills-routing 中 grill 对 Tier M/L 从"命中场景必读"升级为"intake gate 检查 evidence/skill-usage 有 grill 执行记录"。
4. **反猜测红线进 AGENTS**（一句话级）：PRD 未写明的业务规则/字段/权限/错误码一律不得默认，必须落 `[QUESTION]`——现有 Confidence Gate 段已有此意，把"未写明"的判定锚到 requirement-intake 的逐条表上，让"遗漏"变成表上可见的空行。
5. **behavior eval 增加场景**：`prd-gap-probe`——给一份故意缺字段口径的 PRD，断言 Agent 停下提问而不是补默认值；纳入 safety 模式。

**验收**：Tier M/L change 100% 有 requirement-intake.md 且六类问题零空缺；实现后发现"需求理解偏差"的返工次数（telemetry / retro 记录）下降；behavior eval `prd-gap-probe` pass^3。

---

### 问题 7　harness 如何自我迭代进化（工作流完成后自动复盘、总结、优化）

**排查结果**：

- `[LOCAL-FACT]` 这是 7 个问题里**基础设施最完备**的一个——Phase 4A–5F 已建成完整管道：
  - 结构健康度：`harness-control-audit.sh`（30/30 gate registry 覆盖）
  - 行为合规：`harness-behavior-eval.sh`（5 场景）+ `harness-behavior-reliability.sh`（pass@k / pass^k）
  - 效果数据：`harness-telemetry-record.sh`（`gate_run` / `gate_effectiveness_review` / `skill_route_event` / `reviewer_event` / `model_route_event`，字段 allowlist + 敏感值 fail-closed）
  - 周期汇总：`harness-weekly-audit-summary.sh`
  - 迁移门槛：`harness-telemetry-readiness.sh`（5 changes / 4 weeks 数据窗口）
  - 经验沉淀：`harness-instinct-candidate-check.sh`（confidence 门槛、scope 隔离、禁自动晋升）
  - 演练闭环：`harness-telemetry-rehearsal.sh`（rehearsal 数据默认排除）
- `[LOCAL-FACT]` 但管道**空转**：真实 events 仅 8 条（1 个 change），`DECISION=WAIT_DATA_WINDOW`。三个断点：
  - **断点一：埋点靠手动**。gate 运行不会自动写 `gate_run` 事件；靠人记，就永远记不满。
  - **断点二：closeout 无强制复盘**。没有 retro 模板；诊断文档 v3 P1-2 的"分层 retro"未落地；工作流走完，经验（用户纠正、返工原因、gate 误报）随会话蒸发，instinct-candidate 校验器没有进料来源。
  - **断点三：无周期节律**。weekly summary 没有固定运行机制，`docs/decision-log/audit/` 只有一篇 baseline。
- `[AI-INFERENCE]` "自我迭代"不需要再建任何新系统——需要的是把已建好的管道**接上三个自动进料口**（gate 埋点、closeout retro、周期 audit），然后按 readiness 门槛让数据驱动 gate/skill 的进退役。这正是诊断文档 v3 §8.4 的"衰减反力 + 结果耦合"从设计变成运转。

**解决方案**（按闭环层级）：

1. **单次 change 级——closeout 分层 retro（自动触发的"问题复盘"）**：
   - 新增 `templates/retro.md`，固定机读字段：总耗时、返工次数、gate 触发/误报、Reviewer HIGH 数、用户纠正清单、`[ASSUMP]/[QUESTION]` 次数、残余风险。
   - closeout stage gate 强制：Tier M/L、跨仓、发生返工/事故的 change 必有 `retro.md`；小修只需在 `harness-status.md` 写 closeout metrics 几行。
   - retro 中"用户纠正/重复 workaround"条目按 Phase 5D 契约生成 `instinct_candidate`（`harness-instinct-candidate-check.sh` 校验后进 `docs/decision-log/instinct-candidates.md`）——**这是自我学习的进料口**。
2. **数据级——gate 自动埋点**：在 `change-stage-gate.sh`（及各 gate 的公共 fail/pass 出口）追加对 `harness-telemetry-record.sh` 的调用，自动记 `gate_run`（result=pass/block + block_code）。埋点失败不阻断原 gate 判定，但必须输出 warning，并由 weekly audit / harness-self-audit 统计。一次改造，此后数据随使用自动积累，8 条 → 数据窗口达标不再依赖自觉。
3. **周级——audit 节律**：每周跑 `harness-weekly-audit-summary.sh` + `harness-control-audit.sh` 落 `docs/decision-log/audit/YYYY-WW.md`（可用 Cursor Automation 或团队值周固定动作）；连续 4 周留痕是诊断文档定下的验收线。
4. **季度级——数据驱动进退役**：readiness 达标（`SKILL_USAGE_MIGRATION_READY=1` 等）后，按 Phase 1 registry 的 KEEP_HARD / KEEP_MEASURE / CANDIDATE_SOFTEN 分组做第一次真实分诊——用 `true_catches` / `false_positives` / `manual_overrides` 决定哪些 gate 降层、哪些 instinct 晋升为规则。安全 gate 结构性豁免（既定原则不变）。
5. **红线保持**：instinct 不自动晋升（`auto_promotion_allowed: false`）、rehearsal 数据不计入真实 readiness、`skill-usage-gate.sh` 迁移和 model routing 仍等真实数据窗口——这些 Phase 5D/5E/5F 的停止点全部沿用。

**验收**：连续 4 周 audit 留痕；高风险 change retro 覆盖率 100%；telemetry 真实事件随使用自动增长（无需人工补记）；instinct-candidates 出现首批经校验条目；数据窗口达标后完成第一次 gate 分诊评审。

---

## 3. 方案与根因的映射（为什么这样修是收敛的而不是加仪式）

| 根因 | 对应动作 | 性质 |
| --- | --- | --- |
| RC-A 拉式约束 | 问题 2-1（post-edit 强报警 + pre-shell 版本化动作阻断）、问题 4-1（worktree 布防）、问题 5-3（verification-run 硬条件） | 把**已有** gate 逻辑接到 runtime，不新增规则文字 |
| RC-B 规则不跟随 workspace | 问题 1-4 / 2-3（业务仓 bootstrap 试点分发 + preflight 校验） | 分发机制，先试点再全量 |
| RC-C 管道无进料 | 问题 7-1/2/3（retro + 自动埋点 + 周期 audit） | 接进料口，管道本身零新建 |

新增产物只有 3 个：`requirement-intake.md`（Tier M/L）、`retro.md`（分层强制）、PRD 截图逐屏拆解表（并入技术方案 §7，不是独立文件）。其余全部是对既有机制的接线和收紧，符合"小硬核 + 大软壳"目标形态——本轮加硬的三处（code-start 推式、worktree 布防、verification-run）都属于 L3 应管的"停止点/边界"类，不是流程仪式。

## 4. 实施波次建议

| 波次 | 内容 | 前置 |
| --- | --- | --- |
| Wave 0（立即，先于一切） | §5-B 未提交成果 scope inventory + 敏感信息扫描 + 提交分组/回滚点建议 + "暂不提交"指令到期规则；获得明确授权前不 commit/tag | 用户确认提交口径和提交授权 |
| Wave 1（本周，止血） | 问题 2-1/2-2（hook 三层推式 + active-change 自动发现）、问题 2-3/4-1（业务仓与 worktree bootstrap）、问题 7-2（gate 自动埋点）、§5-A 危险命令解析升级、§5-D can_block 契约列、§5-E eval 打标、§5-G hook 端到端自检 | 本方案确认；hook 改动需按 Phase 5B0 契约走单独 runtime 方案 + fixture 测试 + rollback |
| Wave 2（1–2 周） | §5-C P0 减负补课（artifact matrix + scaffold + SSOT 归档，按 §5-F 原则不等数据窗口）、问题 1（style profile + 样板引用字段 + 三裁决）、问题 3（逐屏拆解表 + side-by-side 证据）、问题 6（requirement-intake + intake gate 升级） | Wave 1 的 runtime 兜底就位 |
| Wave 3（2–4 周） | 问题 5（verification-map 机读化 + verification-run）、问题 7-1/3（retro 模板 + closeout gate + 周期 audit）、behavior eval 新场景 + 最小 live eval | — |
| Wave 4（数据窗口后） | 问题 7-4（gate 分诊、skill-usage 迁移评审、model routing 预算） | `harness-telemetry-readiness.sh` 真实 READY |

**注意**：Wave 1 的 hook 改动触碰了演进方案多个 Phase 明确的"禁止范围"（`.cursor/hooks.json`、`.codex/hooks.json`、`harness-sensor-runner.sh`）——这些禁止是"未经单独技术方案不得改"，不是永久冻结。按既定规则，需先为它写独立技术方案（含 payload fixture、上下文预算、opt-out、rollback plan）、用户确认后实施，并同步飞书留痕。

## 5. 补充诊断：七个问题之外的重要发现（AI 主动排查）

> 以下问题不在你列的 7 个之内，但按风险排序，其中 A/B 的严重度不低于任何一个已列问题。

### 5-A　"危险命令拦截"是纸防线：黑名单可被平凡变体绕过　[LOCAL-FACT]　严重度：高

`harness-sensor-runner.sh` 的 `dangerous_command_reason()` 用**固定子串匹配** 8 个模式（`rm -rf`、`git reset --hard`、`git push --force`…）。以下命令全部直接放行：

- `git push -f`（只匹配了 `--force` 长形式）
- `rm -Rf` / `rm -r -f` / `rm -fr`（参数顺序/大小写变体）
- `find . -delete`、`xargs rm`、`shred`、`> file` 截断
- `git branch -D` + `git push origin :branch`（删远程分支）

这层是当前 runtime 唯一真正的"推式"防线（beforeShellExecution），也是诊断 v3 §8.5 "小硬核"里最核心的一块——但它目前经不起最基本的变体。**这意味着 L3 硬核的实际强度被系统性高估了**，而所有演进文档都把"保留硬安全 gate"当作已成立的前提。

**解法**：不追求黑名单穷举（永远追不完），改为**结构化解析 + 默认可疑**——按 token 解析命令（处理引号/管道/`&&`），对 `rm`/`git push`/`git clean`/`chmod`/`find -delete` 等高危动词做参数级判定；解析失败或含混（eval、base64、多重转义）时降级为"要求用户确认"而不是放行。给这层建独立 fixture 测试集（含绕过变体），纳入 behavior reliability 的 safety 模式。

### 5-B　控制面自身存在大量未提交状态记录：Phase 4A–5F 成果缺少版本保护　[LOCAL-FACT]　严重度：高

实测：当前分支 `codex/harness-evolution-architecture`，最后一次 commit 停在 **2026-06-25**；此后 Phase 4A/4B/5A/5B0/5C/5D/5E/5F 的产出（telemetry、behavior eval、handoff contract、gate registry、audit baseline 等）以大量未提交状态记录留在工作区，已持续一周。注意：`git status --porcelain` 的条目数不是严格文件数，untracked 目录会被折叠展示；后续必须以 scope inventory 为准。

这和 harness 自己的原则直接矛盾：

- Phase 3 飞书文档写明"**本地 Markdown 是可 diff 的主事实源**"——未提交的文件没有历史、不可 diff、不可回滚。
- 每个 Phase 方案都要求"风险与回滚"——但整个演进本身此刻没有回滚点。
- 一次误操作（恰好是 7-A 拦不住的 `git clean` 变体）、磁盘故障或误 `rm`，将同时抹掉控制面和全部演进证据。
- "不 git commit" 是当时的用户口头指令，但它作为**临时停止点被无限延长**了，没有任何机制提醒"该收口了"。

**解法**：① 立即做 scope inventory：列出 Phase 4A–5F 已验收成果、未验收成果、明确不入库文件、疑似敏感/个人路径文件；② 在不提交的前提下先跑敏感信息扫描、个人路径扫描和图片/附件人工检查，形成按 Phase 分组提交建议与 tag/rollback 方案；③ 只有获得明确提交授权后，才按分组提交（或一个整体 commit + tag）；④ 给 harness 自身立一条规则：`changes/<change-id>` 收口（closeout PASS）后 N 天内必须形成提交口径，`harness-self-audit.sh` 增加"未提交状态记录数 + 最老未提交天数"检查项；⑤ 用户的"暂不提交"指令必须带到期日或触发条件，写入 harness-status。

### 5-C　上一轮诊断的两个 P0 一个都没落地，演进跑偏去建了 P1/P2 层　[LOCAL-FACT]　严重度：中高

`docs/harness-diagnosis-and-remediation.md` v3 的 ROI 排序里，P0 是"产物矩阵 + scaffold + 文件名校验"和"SSOT 收敛 + 过时文档归档"。实测：

- `scripts/change-scaffold.sh` 不存在；`docs/architecture/change-artifacts-spec.md` 不存在。
- `docs/archive/` 不存在；`harness-engineering-target-plan.md`（73K 字、已明确过时）仍在仓库根目录，未标 SUPERSEDED。
- 产物过载仍在真实发生：`DXY-BD-001-002-bd-overstaff-task-click`（一个点击类小需求）8 个文件，`download-center-export-integration` 15 个文件。
- `bootstrap-new-member.sh`（P3）也未落地。

而实际做掉的 Phase 4A–5F 对应的是 P1-2/P2-1/P2-2（度量、registry、eval）。**度量管道很有价值，但它是"判断哪些该删"的工具；最直接减轻团队日常负担的 P0 减负项被整体跳过**。这也部分解释了你的问题 2——流程越重，人和 Agent 绕过它的动机越强。另外 changes 目录已到 45 个，其中业务 change 仍只有约 15 个，harness meta 占比持续 2/3，维护成本继续挤占业务交付。

**解法**：把 P0-1（artifact matrix + scaffold + 命名校验，新 change fail / 历史 warning）和 P0-2（target-plan 等归档标 SUPERSEDED）纳入本轮 Wave 2，优先级排在 style-profile 之前——它们是纯减法，不需要等任何数据窗口。

### 5-D　"事后 hook 当事前闸门"的技术误区（修正本文 Wave 1 的原始设计）　[LOCAL-FACT + AI-INFERENCE]　严重度：中

Cursor 的 `afterFileEdit` 与 Codex 的 `PostToolUse` 都是**编辑已落盘之后**才触发的事件——在这两个点 deny，文件已经改完了，deny 只能产生一条消息，不能撤销编辑。当前 sensor-runner 在 `PostToolUse` 用 `continue:false` 阻断，实际效果是"编辑成功 + 会话被打断"，越界内容仍留在磁盘上。hook lifecycle contract（Phase 5B0）登记了各 adapter 支持哪些事件，但**没有登记每个事件"能否真正阻断"这一列**——这是契约本身的缺口。

**解法**：① lifecycle matrix 增加 `can_block: pre/post/none` 列；② 所有"必须物理阻断"的约束（越界写入、code-start 未确认）设计为三层：post-edit 强报警（让 Agent 自行回滚）→ pre-shell 拦 `git add/commit/push`（真阻断点）→ stage gate 兜底。本文 §2 问题 2 的方案已按此修正。

### 5-E　behavior eval 是"纸面 eval"：验证的是规则文案，不是模型行为　[LOCAL-FACT]　严重度：中

`evals/harness-behavior/` 的 5 个场景（scenario 是几行 markdown 描述 + expected yaml），`harness-behavior-eval.sh` 做的是静态断言（规则文件里存在某些约束文字、gate 脚本存在），不启动任何真实 agent。`harness-behavior-reliability.sh` 跑出的 `PASS_POWER_K=1` 证明的是**脚本输出确定性**（shell 脚本本来就是确定的），不是模型在压力下会不会遵守停止点。ECC `skill-comply` 的核心价值——生成场景、跑真实 agent、按 tool-call timeline 判定合规——目前只落地了名字，没落地机制。飞书 Phase 5C 文档诚实标注了 `live_agent_trace_supported: false`，但周边表述（"5 个 required scenario 全部通过"）容易让人误读为行为已验证。

**解法**：分两步——短期在每个 eval 输出里强制打标 `EVAL_TYPE=STATIC`，杜绝误读；中期做最小 live eval：用 cursor-agent/codex CLI headless 跑 1–2 个场景（给一个诱导跳过方案的 prompt，断言 transcript 里出现停止行为、没有出现业务文件编辑），每周期抽跑而不是每次 gate 跑，控制成本。

### 5-F　数据窗口造成自我锁死：越不用越没数据，越没数据越不能减负　[AI-INFERENCE]　严重度：中

Phase 5E 给 `skill-usage-gate` 迁移和 model routing 设了"5 个真实 change 或 4 周数据"的门槛（方向正确，防拍脑袋）。但结合 7-C 看形成了死锁：**流程重 → 团队少用 / 绕过 → 真实 telemetry 不增长（当前 8 条）→ readiness 永远 WAIT_DATA_WINDOW → 重流程永远不能降负**。数据窗口本意是"用数据决定去留"，实际效果变成"维持现状的无限延期"。

**解法**：① 区分两类改造——"减负类"（P0 产物收敛、scaffold）**不需要等数据窗口**，直接做；只有"降硬度类"（软化/删除 gate）才等数据。② gate 自动埋点（§2 问题 7-2）优先落地，让数据随任何真实使用自动积累，而不是依赖人自觉记录。③ 给 readiness 加一个"窗口健康检查"：若 N 周后事件数仍近零，这本身就是"流程太重没人走完整流程"的信号，应触发人工复盘而不是继续等。

### 5-G　hook 链路的环境脆弱性：任何一环缺失都静默 fail-open　[LOCAL-FACT]　严重度：中低

hook 命令是 `bash -lc '"$(git rev-parse --show-toplevel)/hooks/...sh"'`，sensor-runner 内部再依赖 `node` 解析 JSON payload。链路上任何一环失败——login shell 里没有 node（nvm 用户很常见）、git 不在 PATH、workspace 不是 git repo——hook 报错，而宿主（Cursor/Codex）对 hook 报错的默认处置基本是**忽略并继续**，即整套 runtime 防线静默消失，没有任何人会察觉。团队推广（问题 2/4 的 bootstrap 方案）会放大这个问题：每台新机器都是一次静默失效的机会。

**解法**：① sensor-runner 去 node 化（用 bash/awk 解析所需的 2-3 个 JSON 字段，或改用 jq 并在缺失时输出显式 deny 而非报错退出）；② `team-rollout-preflight.sh` 增加"hook 端到端自检"：喂一条 post-edit fixture payload，断言返回强报警；再喂一条 pre-shell fixture payload，断言版本化动作被 deny——把"hook 活着且关键阻断点有效"变成可验证事实；③ 每次 SessionStart（接线后）输出一行 hook 健康状态。

### 补充发现与既有方案的关系

| 发现 | 并入波次 | 说明 |
| --- | --- | --- |
| 5-A 黑名单绕过 | Wave 1 | 与 code-start 推式改造同属一个 hook runtime 技术方案 |
| 5-B 未提交收口 | **立即**（先于 Wave 1） | 先形成提交口径和授权方案；真正 commit/tag 必须等明确授权 |
| 5-C P0 减负补课 | Wave 2 提前 | 纯减法，无前置依赖 |
| 5-D can_block 列 | Wave 1 | 修 lifecycle contract 文档 + 三层设计 |
| 5-E 纸面 eval 打标 | Wave 1（打标）/ Wave 3（live eval） | 打标是一行改动 |
| 5-F 死锁拆解 | 原则性，立即生效 | 减负类不等数据窗口 |
| 5-G hook 自检 | Wave 1 | 并入 bootstrap/preflight |

## 6. 二阶风险分析：每个方案可能引入的新问题与防护（先想清楚再动手）

> 原则：任何"加约束"的方案都有两类经典副作用——**误拦导致团队禁用整套机制**（比没有约束更糟，因为制造假安全感）和**仪式回潮**（与减负目标自相矛盾）。逐项分析如下，防护措施与方案本体同为验收项。

| 方案 | 可能引入的新问题 | 防护措施 | 回滚方式 |
| --- | --- | --- | --- |
| code-start 三层推式（问题 2） | ① 误拦合法编辑（Tier S 小修、紧急 hotfix、业务仓内非业务文件），团队被卡死后**永久关掉 hook** → 假安全感比无 hook 更危险；② 每次编辑跑 bash/node 的延迟 | ① Tier S 走轻路径（有 spec 即可，不要求技术方案确认）；**必须保留显式紧急旁路**（如 `SFA_HOOK_OVERRIDE=1` + 自动记 `manual_override` telemetry 事件），旁路被使用本身就是数据；deny 消息必须带可执行 FIX；② 只对命中 `SFA_REPO_*` 前缀的路径触发，active-change 解析结果缓存 | hook 配置一行注释掉即恢复现状；stage gate 防线不受影响 |
| 危险命令解析升级（§5-A） | 过度拦截日常合法命令（`rm -rf node_modules`、`rm -rf /tmp/xxx` 是高频正常操作），造成 alert fatigue → 用户加 `--yes` 心态泛化或直接关 hook | 按"动词+目标路径"双因子判定：高危动词 + 目标在业务仓/harness 受保护路径才 deny；`/tmp`、`node_modules`、ignored 目录白名单放行；解析失败时降级为"要求确认"而非 deny；fixture 测试集必须同时包含**绕过变体**（防漏）和**合法高频命令**（防误拦），两个方向都纳入回归 | 同上，hook 层可独立回退 |
| 业务仓分发 hooks/stub（问题 1/2/4） | ① 污染业务仓 `git status`，不用 AI 的同事可能困惑甚至误把这些文件提交到业务仓远端；② 各机器路径差异导致 stub 失效；③ 一次性全仓铺开会放大误拦和环境差异 | ① 先 `mapSystem` + 一个后端仓试点，通过后再全量；② 分发文件一律写入业务仓 `.git/info/exclude`（本地排除，**不改业务仓的 .gitignore**，零版本足迹）；bootstrap 幂等可重跑；分发清单在 harness 侧登记；③ stub 通过 `$SFA_HARNESS_ROOT` 解析 + preflight 端到端自检 | `bootstrap --remove` 一键清除分发文件，业务仓回到零痕迹 |
| requirement-intake + retro 新产物（问题 6/7） | 仪式回潮，与 §5-C 的 P0 减负方向直接冲突；变成"为过 gate 填表" | 只对 Tier M/L 强制；模板控制在一页内、scaffold 自动生成骨架；retro 分层（小修只写几行 metrics）；**两者登记进 gate registry 标 `risk_tier=process` + 到期复审日**，6 个月后用 telemetry 数据裁决去留——新产物从出生起就在退役机制管辖内 | 从 stage gate 检查项移除即回滚，已产出文档保留 |
| gate 自动埋点（问题 7） | ① 埋点代码故障反过来阻断 gate 本身（本末倒置）；② 敏感信息渗入 telemetry；③ 埋点失败被 `\|\| true` 静默吞掉，继续制造"以为有数据"的假安全感 | ① 埋点调用必须 best-effort（`\|\| true`），任何记录失败不影响 gate 判定，且埋点逻辑收敛在一个公共函数里；② 失败必须输出 warning，并进入 weekly audit / harness-self-audit 统计；③ 复用既有 allowlist fail-closed 机制，`gate_run` 只记 `gate_id/result/block_code` 等脱敏字段（Phase 4B 契约已定） | 公共函数置空即全局停止埋点 |
| verification-run 机读化（问题 5） | ① 把本质上不可机读的验证硬凑成命令 → **假绿**比没有更危险；② `expected` 写得过宽形同虚设 | ① `manual` 类型合法存在，UI 对照/真机类强制标 manual 并指向证据路径，Test Agent 抽查 manual 项证据真实性；② Reviewer 的 `spec_compliance` 裁决包含"expected 是否有区分度"检查 | 脚本独立新增，不改现有 gate，删除即回滚 |
| style profile（问题 1/3） | ① 画像与仓库实际演进脱节，Agent 照着过时画像写出"标准但已废弃"的代码；② 画像变成创新禁令 | ① 画像头部带生成日期 + 来源 commit hash，Reviewer 发现画像与仓库现状冲突时**以仓库为准**并开画像更新任务；② 画像定位是"仿写锚点"，允许偏离但必须在 plan 里写明理由 | 纯文档，删除即回滚 |
| 三裁决 `style_conformance`（问题 1） | Reviewer 负担与主观性增加，裁决通胀（全部 PASS 走过场） | 裁决必须引用 style profile / 样板引用的具体条目，不允许裸 PASS/FAIL；`reviewer_event` telemetry 记录三裁决分布，走过场可被数据发现 | 契约回退到双裁决 |
| Wave 0 提交口径与授权（§5-B） | 一次性提交可能混入敏感内容（截图含业务数据、个人路径、token）或已被用户决定不入库的文件；若未经授权直接提交，还会违反"暂不提交"停止点 | 提交前强制完成 scope inventory、`temp-hardcode-scan`、`no-personal-paths`、图片类文件人工检查和提交分组建议；`docs/harness-diagnosis-and-remediation.md` 是否入库必须以明确用户决策为准；获得明确授权前不 commit/tag | 未提交时直接调整 scope；commit 未 push 前可 soft reset；tag 可删 |

**总原则（三条红线）**：
1. 任何新硬约束必须带**显式且被记录的旁路**——被迫的全局禁用是最大的失败模式。
2. 任何新产物/新 gate 出生即登记退役候选机制，防止本轮整改自己成为下一轮的熵增来源。
3. 所有 runtime 改动先 fixture 后上线，上线后第一周观察 `manual_override` / 误拦事件，超阈值立即回退而不是打补丁。

## 7. 待确认拍板项（2026-07-02）　[PENDING-DECISION]

| # | 决策项 | 当前建议 / 待确认点 |
| --- | --- | --- |
| 1 | Phase 4A–5F 未提交成果收口 | 先做 scope inventory + 扫描 + 提交分组/回滚点建议；**获得明确授权前不 commit/tag** |
| 2 | hook runtime 推式强制立项（含 §5-A/§5-D/§5-G） | 建议立项；方案确认后实施；post-edit 只做强报警，pre-shell/stage gate 做物理阻断 |
| 3 | 业务仓分发薄 hooks + AGENTS stub | 建议先 `mapSystem` + 一个后端仓试点，通过 preflight 和误拦观察后再全量 |
| 4 | requirement-intake.md + 分层 retro.md | 建议纳入，但仅 Tier M/L 或高风险场景强制，避免仪式回潮 |
| 5 | gate 自动埋点 | 建议纳入；best-effort 不阻断 gate，但失败必须 warning + audit 统计 |
| 6 | 减负类改造不等数据窗口（§5-F 原则） | 建议确认：减负类直接做，降硬度/删 gate 类才等真实数据窗口 |
| 7 | style profile 首批范围 | 建议先 `mapSystem` + `sign-up` 两个前端仓 |
| 8 | change-id | 建议新开 `harness-usage-hardening`，但以当前分支策略和用户确认口径为准 |

补充说明：本节不是已执行授权，只是把需要用户/团队最终确认的执行口径集中列出。若后续有真实确认，应补充确认来源、时间、确认人和确认原文，再把对应条目标为 `[USER-DECISION]`。

---

## 8. 一句话收束

上一轮改造把"度量与分层"的骨架建对了；这一轮暴露的 7 个问题共同指向三件事——**约束要从"模型自觉"下沉到"runtime 事实"（推式 hook + workspace 分发），视觉与需求信息要从"自由文本"升级为"gate 可校验的结构化拆解"，已建好的复盘管道要接上自动进料口让它真正转起来**。每一步都遵守 §6 的三条红线：新硬约束必带被记录的旁路、新产物出生即入退役机制、runtime 改动先 fixture 后上线且超阈值即回退——彻底解决问题的同时，不让本轮整改成为下一轮的问题来源。
