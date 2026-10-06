# superpowers 与 ECC 详细比较

> 日期：2026-08-29  
> 用途：学完 `learning_objectives` 之后，用这两套开源控制面精进自己的 harness。**现在不要安装、不要整仓替换。**  
> 相关笔记：  
> - [01-第一轮回复-标本是不是harness-五层解构.md](01-第一轮回复-标本是不是harness-五层解构.md)  
> - [02-标本对照同类控制面的优劣势与是否调整.md](02-标本对照同类控制面的优劣势与是否调整.md)

三套东西的关系先钉死：

| 层 | 是什么 | 现在怎么用 |
|---|---|---|
| Runtime | Cursor / Codex / OpenCode | 执行循环，先只盯一个 |
| 跳板标本 | `learning_objectives` | 先学完：五层、停止点、变更包、拉式门禁的教训 |
| 精进教材 | superpowers、ECC | 学完标本后再读；抽原则写进自己的 v0/v1，不整包安装 |

`learning_objectives` 自己的结论也是这个口径：OSS 当设计模式，不要当控制面替身（adoption matrix A15）。

---

## 0. 一句话定位

**superpowers** 是一套**短、硬、可组合的软件开发方法论**，做成跨 runtime 的 skills 插件。核心不是「技能很多」，而是：**先问清楚 → 人签设计 → 计划细到白痴也能执行 → 隔离 worktree → 真 TDD → 每任务新 subagent + 两段式只读审查 → 宣称完成前必须跑出新证据。**

**ECC**（Everything Claude Code / agent harness performance system）是一套**通用 harness 操作系统**：skills、agents、hooks、rules、memory、continuous learning、AgentShield、harness-audit。口号是 `plan → test → implement → review → verify → remember → improve`，以及 **Optimize the context window. Persist everything else.**

对照上一份笔记里的四象限：

- superpowers ≈ 把「怎么把一个功能做对」做成强制技能链。轻、可抄、对个人/小团队最强。
- ECC ≈ 把「怎么让 agent 系统自己变好」做成可安装套件。全、可度量、对 harness 工程最强，也最容易把上下文和权限撑爆。
- `learning_objectives` ≈ 企业多仓交付控制面。停止点和业务边界最强，仪式和拉式门禁是它的病。

精进顺序建议：**标本给骨架 → superpowers 给执行纪律 → ECC 给度量、hook 生命周期和衰减。** 不要反过来，否则会先装 200+ skills，再回头发现没有停止点。

---

## 1. 资料与版本（读本文时先看）

公开源（抓取日 2026-08-29）：

| 项目 | 入口 | 作者/组织 |
|---|---|---|
| superpowers | https://github.com/obra/superpowers | Jesse Vincent / Prime Radiant |
| ECC | https://github.com/affaan-m/ECC · https://ecc.tools | affaan-m；原名 everything-claude-code |

`learning_objectives` 内部做过源码级对照（当时快照，**比今天的公开仓库旧**）：

| 项目 | 当时 HEAD | 本地研究文件 |
|---|---|---|
| ECC | `2bc924f`（集成文档另钉过 `5b173d2`） | `docs/research/ecc-superpowers-source-evidence.md` |
| superpowers | `896224c` | 同上 + `docs/research/ecc-superpowers-adoption-matrix.md` |

今天的公开规模已经涨过那次快照：

- superpowers：技能库仍然很小（约十几项流程 skill），但安装面扩到 Claude / Codex / Cursor / OpenCode / Gemini / Copilot / Kimi / Pi / Hermes 等；behavior eval 用独立仓 `superpowers-evals` 的 drill harness。
- ECC：自称约 **68 agents、286 skills、94 command shims**，另有 AgentShield、Memory Vault、Plan Canvas、hook profile。主战场仍是 Claude Code；Codex **没有 ECC hook runtime**；Cursor 是 beta adapter。

后文机制以「公开 README + SFA 源码证据」为准。数字会变，**机制不会每月换一套**。真开读源码时，先自己 `git log -1` 记一版，不要假定本文数字仍准。

---

## 2. 各自解决什么失败模式

| 失败模式 | superpowers 怎么挡 | ECC 怎么挡 | `learning_objectives` 怎么挡 |
|---|---|---|---|
| 还没想清楚就开始写 | `brainstorming`：分段给人看设计，签字后才进计划 | `/ecc:plan`，计划变成可编辑工件；2.1 还有 Plan Canvas 人审 | spec + FACT/ASSUMP/QUESTION + 技术方案确认 |
| 计划太粗，执行时靠猜 | `writing-plans`：2–5 分钟一步，精确路径，禁止占位符 | planner agent + 多语言 TDD/verification skill | `plan.md` / 技术方案，但常仍偏宽 |
| 先写代码再补测试 | `test-driven-development`：先看红，再写最少绿；先写的代码要删 | `tdd-workflow`：RED 证据进门 | Java 要 `backend-test-plan`；不是全仓 TDD |
| 模型说「好了」其实没跑 | `verification-before-completion`：先跑完整命令，读输出，再宣称 | `verification-loop` / `quality-gate` / eval harness | Test Agent + reviewer-gate；但 gate 常是拉式 |
| 实现者给自己打分 | 每任务新 subagent；reviewer 读 brief+report+diff，不信实现者报告 | fresh-context `/code-review` | Reviewer 只读 + `high_risk_count: 0` |
| 长会话遗忘、重复劳动 | 文件交接 + progress ledger | Memory Vault、session summary、instincts | `changes/<id>/` + handoff skill；SessionStart 未接线 |
| 规则改了但行为没变 | 改 skill 要有 behavior eval（drill 真跑 agent） | `skill-comply`、eval-harness、harness-audit | 纸面 eval + 很少 telemetry |
| harness 自己变肥、变危 | 技能少；领域流程不准进核心 | hook profile、skill-health、AgentShield 扫 harness 攻击面 | gate-registry 有分层，缺退役数据 |
| 企业多仓 / 环境 / DB / PRD | **不管**。明确说项目/领域工作流放外面 | 有语言/框架 skill，**没有**你的仓 registry 和飞书 | 这正是它存在的理由 |

结论：superpowers 不管「你们公司怎么交付」；ECC 管「agent 系统怎么运转」；标本管「SFA 怎么在边界里交付」。三套互补，不是三选一。

---

## 3. 架构对照

### 3.1 体量与形状

```text
superpowers（瘦方法论插件）
  skills/          强制工作流：brainstorm → worktree → plan → SDD/TDD → review → finish
  hooks/           主要是 SessionStart 注入 using-superpowers
  tests/           插件代码测
  evals/           真 LLM 会话的 skill 合规 eval（drill）

ECC（厚操作系统）
  agents/          ~68 个专用 subagent
  skills/          ~280+ 可按需加载工作流（含大量语言/框架/业务域）
  commands/        slash 入口，正迁到 skills-first
  rules/           常驻：common + 语言目录
  hooks/           完整生命周期 + profile（minimal/standard/strict）
  scripts/         audit、skill-health、install、orchestration
  AgentShield      扫 prompt/hooks/MCP/权限/secrets
  memory/instincts 跨会话、跨 harness 的持久化
```

`learning_objectives` 更像「企业交付控制面」：`AGENTS.md` + `changes/` + 38 gate + 薄 adapter。技能只有 6 个本地 skill，但文档和脚本远比 superpowers 重。

### 3.2 五层模型上怎么落

用标本的五层来看，后面精进时才不会把「技能」和「传感器」混在一起。

| 层 | superpowers | ECC | 学完标本后该从谁补 |
|---|---|---|---|
| Instructions | 少而硬的 SKILL.md；`using-superpowers` 要求「适用就必须调用」 | skills 按需 + rules 常驻；目录极大 | 计划粒度、TDD 措辞抄 superpowers；语言细则不要从 ECC 整包灌 |
| Constraints | worktree 隔离；用户指令 > skill > 默认 | 权限、hook exit code、AgentShield、hook profile | hook 生命周期和 profile 抄 ECC；硬安全仍要自己的 L3 |
| Sensors | 真跑测试；verification-before-completion；reviewer 不信报告 | harness-audit 打分、quality-gate、eval、skill-health | **度量/审计抄 ECC**；「完成必须有新命令输出」抄 superpowers |
| Memory | 设计文档、计划文件、task brief、ledger | Memory Vault、instincts、session summary | 变更包继续用标本；跨会话摘要可学 ECC，但记忆 ≠ 政策 |
| Orchestration | 每任务新 subagent + 两段审查；或同会话分批 + 人卡点 | 68 agents、tmux/worktree orchestration、autonomous loops | 默认保持标本的「少角色」。不要一上来上 ECC 的 agent swarm |

### 3.3 强制力从哪来

这是三套差异最大的地方。

| | 主要强制力 | 弱点 |
|---|---|---|
| superpowers | **技能文本纪律** + SessionStart 提醒 + eval 证明 skill 真被调用。`using-superpowers` 写明：有 1% 可能适用就必须 invoke。 | 没有企业级 gate。模型仍可能不调 skill；靠 eval 和重复压力发现，不是 fail-closed 脚本。 |
| ECC | **hooks 在模型外面跑** + 权限 + audit 分数。Claude 上最完整；Codex **没有 ECC hook runtime**。 | 目录太大，装全量会污染上下文。Cursor/Codex 能力不对等。continuous-learning 可能把未确认经验写成规则。 |
| 标本 | **shell gate fail-closed**（设计上） | 实际多为拉式：Agent 必须自己跑脚本。hooks 未接 SessionStart；业务仓 workspace 不加载规则。 |

精进自己的 harness 时，目标组合是：

1. superpowers 级的「计划/TDD/完成证据」纪律（短 skill）
2. ECC 级的「hook 在工具层执行 + 可打分 + 可衰减」
3. 标本级的「停止点 + 变更包 + 业务仓边界」
4. 不要 ECC 级的技能目录，也不要标本级的 38 个拉式 gate

---

## 4. 工作流对照

### 4.1 superpowers 主链（强制，不是建议）

来自公开 README「The Basic Workflow」：

1. **brainstorming** — 写代码前。追问、探替代、分段给人看设计、存设计文档。
2. **using-git-worktrees** — 设计批准后。新分支隔离工作区，跑项目 setup，确认测试基线是绿的。
3. **writing-plans** — 拆成 2–5 分钟任务。每步：精确路径、完整代码、验证命令、期望输出。禁止「稍后补上」「添加错误处理」这类占位。
4. **subagent-driven-development**（推荐）或 **executing-plans** — 每任务新 subagent，两段审查（先 spec 合规，再代码质量）；或同会话分批执行、人卡点。
5. **test-driven-development** — RED 必须亲眼看到失败原因是「功能不存在」而不是 typo；先写的实现代码要删。
6. **requesting-code-review** — 任务之间。Critical 阻断。
7. **finishing-a-development-branch** — 测过、给选项（merge/PR/keep/discard）、清 worktree。

配套铁律：

- `verification-before-completion`：宣称 pass/fixed/complete 之前，必须**重新跑完整命令**，读退出码和失败数。Agent 口头成功、上次跑过、`should pass` 都不算。
- 回归测试要走：写 → 绿 → 撤修复必须红 → 恢复再绿。
- 用户指令 > skill > 默认行为。人明确说跳过才能跳过。

这和标本的「用户说 ok 只推进到下一个已满足 gate」是同一类思想，但 superpowers 把压力放在**任务级证据**，标本放在**阶段级文件**。

### 4.2 ECC 主链（可安装系统）

公开默认：

```text
/ecc:plan "..."     → planner 出蓝图，人确认
tdd-workflow        → RED 证据 → 最少实现到 GREEN
/code-review        → 新鲜上下文审查
verify / quality-gate
remember / learn-eval
```

另外还有一整套「系统自我改进」环，这是 superpowers 几乎不碰、标本想做但没做成的：

| 命令/能力 | 干什么 |
|---|---|
| `/harness-audit` | 对当前仓的 harness 配置打分（工具覆盖、上下文效率、质量门、记忆、eval、安全护栏等） |
| `/skill-health` | skill 组合健康度：运行次数、成功率、趋势 |
| `continuous-learning-v2` | 从会话抽 atomic instinct，带置信度；可 promote 到全局 |
| `/skill-create` | 从 git 历史生成 SKILL.md |
| AgentShield | 把 harness 自己当攻击面扫 |
| Memory Vault | 跨 Claude/Codex/Kimi 等的本地 Markdown 记忆 |
| hook profile | `minimal` / `standard` / `strict`，可用 env 关单个 hook |

ECC 自己也强调：**从你需要的工作流开始，不要一次装全目录。** 这和标本「Optional Packs」、和你自建「先 4 个 L3」是同一原则。

### 4.3 和标本主链的映射（以后精进时用）

标本：

```text
status → spec → contract → solution → AI test plan → env
      → plan → code → Main tests → Test Agent → report → reviewer → PR → retro
```

| 标本阶段 | superpowers 对应 | ECC 对应 | 以后怎么精进自己的 |
|---|---|---|---|
| spec / 技术方案确认 | brainstorming 分段签字 | `/ecc:plan` + Plan Canvas | 保持标本停止点；计划正文学 superpowers「无占位符」 |
| plan | writing-plans | planner 蓝图 | **这是 superpowers 最该抄的一块** |
| code-start / 分支 | git worktrees | worktree / 多 agent 编排 | 隔离抄 superpowers；不要默认 tmux |
| 实现 | TDD skill | tdd-workflow | 行为变更默认 TDD；docs/config 允许 N/A |
| Test Agent | verification-before-completion | verification-loop | 完成声明必须带**本轮命令输出** |
| Reviewer | 两段式只读 review | fresh-context code-reviewer | 保持只读；brief+diff 包学 superpowers |
| retro | 几乎没有产品级 retro | learn-eval / instincts | 学 ECC 的「可度量关闭」，不要自动 promote 到全局规则 |
| harness 自身进化 | 改 skill 要 eval | harness-audit + skill-health | **v1 才做**；v0 不做审计平台 |

---

## 5. 技能与角色：少而硬 vs 多而全

### 5.1 superpowers 技能清单（流程核心，几乎应整表吃透）

**Testing**

- `test-driven-development`（含 testing anti-patterns）

**Debugging**

- `systematic-debugging`（四阶段根因）
- `verification-before-completion`

**Collaboration**

- `brainstorming`
- `writing-plans`
- `executing-plans`
- `dispatching-parallel-agents`
- `requesting-code-review`
- `receiving-code-review`
- `using-git-worktrees`
- `finishing-a-development-branch`
- `subagent-driven-development`

**Meta**

- `writing-skills`（含如何测 skill）
- `using-superpowers`（开机纪律）

哲学四条（公开 README）：TDD；Systematic over ad-hoc；Complexity reduction；Evidence over claims。

`CLAUDE.md` 级治理（SFA 快照 SP-9）：**skill 是行为整形代码；改 skill 要有 eval 证据；项目/领域工作流不准进核心。** 这是防「第二个 learning_objectives 养肥」的关键句。

### 5.2 ECC 的目录逻辑（不要背 286 个）

按**机制族**记，不按文件名记：

| 族 | 例子 | 以后精进时 |
|---|---|---|
| 交付工作流 | plan、tdd-workflow、verification-loop、e2e-testing | 对照 superpowers，只吸收差异 |
| 审查 | code-reviewer、security-review、语言 *-reviewer | 保持「一个只读 Reviewer」；语言 reviewer 当 lens 不是新门禁 |
| harness 工程 | harness-audit、skill-health、eval-harness、skill-comply | **v1 主菜** |
| 记忆与学习 | continuous-learning-v2、unified-memory、learn-eval | 只学「消毒后的观察 → 候选规则」，禁止自动晋升 |
| 框架包 | springboot-*、django-*、laravel-*、frontend-patterns | 按你的技术栈**自己写** baseline，不要装 ECC 的 Spring 包当 SFA 规则 |
| 编排 | multi-plan、tmux worktree orchestrator、autonomous-loops | 默认 DO_NOT_COPY tmux；并行必须有契约+隔离 |
| 安全 | AgentShield、security-scan、hooks 护栏 | 学「harness 自己是攻击面」；不要把扫描分数当业务完成 |

ECC 把 Skills / Agents / Rules / Hooks / Instincts 分开，避免每次会话倾倒整个仓库。这个**分层加载**值得抄；286 这个数字不值得抄。

### 5.3 角色数量

| | 默认角色策略 |
|---|---|
| superpowers | 实现 subagent（每任务新鲜）+ 只读 reviewer。主会话编排。 |
| ECC | 几十个专用 agent（planner、tdd-guide、code-reviewer、build-error-resolver…） |
| 标本 | Orchestrator + 只读 Explorer/Reviewer + Test Agent；实现 agent 默认 candidate |

你的 v0 继续用标本策略（≤4 角色）。从 superpowers 抄「每任务新鲜上下文 + reviewer 不信报告」。从 ECC 抄「审查必须换上下文」，不要抄 68 个 agent 文件。

---

## 6. Hook、权限、平台：你以后真会踩的坑

### 6.1 Hook 生命周期

SFA 快照里 ECC 的价值（ECC-7/8）：

- 事件：PreToolUse / PostToolUse / Stop / SessionStart / SessionEnd / PreCompact
- exit 2 阻断 vs exit 0 警告（注意：有的实现里 exit 1 是 fail-open，不能当安全边界）
- profile：`minimal` / `standard` / `strict`，可用 `ECC_DISABLED_HOOKS` 关单个 hook
- SessionStart 有字符上限（ECC 默认可到 8000；标本合同写过 30 行 / 2000 字——**你自建应偏标本的短预算**，不要把本能、规则、计划一次性注入）

superpowers 的 hook 更窄：Codex SessionStart 注入 `using-superpowers`，让模型先找 skill。不试图当安全内核。

标本已经写了 hook-lifecycle-contract，但 Cursor/Codex 的 SessionStart **未接线**。这是你学完标本后最该用 ECC/superpowers 补的洞：**开机只注入「当前 change、停止点、去读哪个 skill」**，不要注入百科。

### 6.2 平台不对等（装之前必须看）

ECC 自己承认的矩阵（公开 README）：

| Harness | ECC 状态 | 关键限制 |
|---|---|---|
| Claude Code | Stable 主场 | 插件会把目录暴露给模型；上下文敏感时要 selective install |
| Codex | sync 可用；marketplace 实验 | **没有 ECC hook runtime** |
| Cursor | Beta | hook 集合与安装路径仍和 Claude 不完全一样 |
| OpenCode | Beta 子集 | 不是全目录 |
| Copilot 等 | instruction-only | 无 hook、无原生 skill 发现 |

superpowers 走的是「每个 runtime 装一份 plugin」，工作流宣称跨工具同一套 skill。强制力仍主要靠模型遵守 skill，而不是各工具 hook 奇偶一致。

对你：先 Cursor-only 自建控制面时，

- **不要**把 ECC 当 Cursor 上的完整操作系统来装（beta + 目录膨胀）。
- **可以**把 superpowers 当「对照用的技能文案和 eval 思路」，即使以后才装插件。
- 自己的强制逻辑继续放在**你的** `scripts/` + 薄 `.cursor/hooks.json`，这是标本做对的事。

### 6.3 安装污染

两边都警告「不要叠装」。

- ECC：同一 harness 不要 plugin + 全量 manual；Codex 不要 sync + marketplace 双份。
- superpowers：每个 runtime 分别装。
- 标本：ECC 只允许 sidecar dry-run；禁止 wrapper 去 apply install、global sync、auto-fix、instinct promote。

你的精进阶段默认沿用标本这条：**OSS 只读参考或 sidecar，不写 `~/.codex`、不覆盖项目 AGENTS。**

---

## 7. 测试与评测：两套都比标本强的地方

标本的缺口（诊断已写）：shell 测试证明**脚本能跑**，不证明 **agent 会遵守规则**；behavior eval 一度是检查文案的纸面 eval。

| | 代码/脚本测试 | Agent 行为 eval |
|---|---|---|
| superpowers | `tests/`：插件加载、sync、部分集成 | `evals/` + drill：真开 Claude/Codex/Gemini 会话，查 skill 是否被调用、是否过早动工具。慢（3–30+ 分钟），不在普通 CI。改 skill 视为要有这类证据。 |
| ECC | hooks/lib 的单测 | eval-harness、skill-comply：从规则生成期望轨迹，跑 agent，对 tool-call 分类，出合规率。另有 pass@k。harness-audit 是确定性打分，不是 LLM judge。 |
| 标本 | 大量 `*-gate-test.sh` | 少量 scenario md；telemetry 进料不足 |

Adoption matrix 已标成原则（A5、A16）：

- 脚本测试 ≠ 行为 eval
- 改 AGENTS / skill / hook 文案，要有行为证据或明确 N/A

这是你 **v1 harness** 相对 v0 最值得从这两套补的能力。v0 仍不必建 drill。

---

## 8. 记忆与持续学习：ECC 独有，也最危险

superpowers 几乎把记忆交给**人签过的文件**（设计、计划、ledger）。不自动从 transcript 提炼规则。

ECC 明确做：

- SessionStart 加载摘要 / instincts（有数量和置信度阈值）
- Stop / 学习技能从会话抽模式
- instincts 可从项目晋升到全局
- Memory Vault：跨 harness 的本地 Markdown；ECC 自己写了 **Memory is unreviewed context, not executable policy**

标本对这条的态度（A17、ECC sidecar 禁令）：

- 可以学「关闭时记消毒过的观察」
- 禁止 raw transcript、密码、业务数据
- 禁止 automatic promotion 变成规则
- 不让 ECC continuous-learning 覆盖 `AGENTS.md`

你以后若做「本能/经验沉淀」，采用 ECC 的**置信度 + 人工晋升 + 记忆≠政策**，不要采用它的默认自动抽取强度。

---

## 9. 优劣势（只比这两套，标本当参照系）

### superpowers 相对 ECC

**优势**

- 方法论完整且短，一周能读完所有核心 SKILL.md。
- 计划质量和「完成必须有新证据」是目前开源里最清楚的实现。
- 改 skill 要 eval，从根上限制养肥。
- 领域知识不准进核心，正好克制你把公司 UI class 写进通用 harness。
- 跨很多 runtime 以 plugin 分发，心智负担低。

**劣势**

- 几乎没有企业控制面：多仓、环境、DB、PRD、权限矩阵不管。
- 强制力偏「模型必须调用 skill」，不是 fail-closed 脚本。没有标本那种 confidence-gate。
- 默认很强的 TDD / 每任务 subagent，对遗留 Vue2/Java、不可单测的页面会摩擦。需要 N/A 通道。
- 安全内核、harness 自审计、hook profile 不是它的主场。
- SessionStart 依赖各 runtime 是否真注入；长会话 compact 后可能丢 bootstrap（Hermes 已有此限制）。

### ECC 相对 superpowers

**优势**

- 真正把 harness 当成可优化系统：audit 分数、skill 趋势、hook 在模型外、AgentShield。
- 生命周期合同完整，profile 能「软默认、硬例外」——正是标本诊断要的「小硬核 + 大软壳」。
- 记忆、跨工具交接、Plan Canvas 等人机接口更完整。
- 语言/框架包适合当**对照样例**（你写自己的 Java baseline 时可以看它 Spring 包怎么拆，而不是拷规则）。

**劣势**

- 体量是陷阱。286 skills / 68 agents 和 Karpathy 的 context engineering 直接冲突；装全量就是第二个养肥标本。
- Claude 主场，Cursor/Codex 不对等；你若 Cursor-first，会高估 hook 覆盖。
- continuous-learning 和全局 promote 能把未确认业务经验写成「本能」。
- tmux / 多 agent 自动执行容易绕过停止点（标本 A14/A15 已拒绝）。
- 安装路径多，叠装会复制 hook/skill，排障成本高。
- 商业层（GitHub App、Pro）和 OSS 核心要分清；学机制只看 MIT 仓库。

### 相对 `learning_objectives`（你已经在学的跳板）

| 你已经从标本得到 | 还缺、该向谁要 |
|---|---|
| 停止点、FACT/ASSUMP、变更包、多仓 registry | 计划粒度、TDD 铁律、完成证据 → superpowers |
| gate 分层思想、薄 adapter | 推式 hook、audit/衰减、skill 事件而非台账 → ECC |
| 独立 Reviewer / Test Agent | 每任务新鲜上下文、不信 implementer report → superpowers |
| 诚实诊断「仪式过载」 | 少技能、改规则要 eval → superpowers；gate 要打分才能退役 → ECC |

---

## 10. 学完标本之后：精进清单（按优先级）

下面是「写进你自己的 harness」的吸收表，不是「去 fork 那两个仓」。决策词沿用标本：ADOPT PRINCIPLE / ADAPT / PILOT / DO_NOT_COPY。

### 10.1 第一批（v0 尚未做完也可以先记原则）

| ID | 来源 | 吸收 | 落成你 harness 的什么 |
|---|---|---|---|
| SP-plan | superpowers `writing-plans` | ADOPT PRINCIPLE | 实现计划：精确路径、验证命令、禁止占位符 |
| SP-evidence | `verification-before-completion` | ADOPT PRINCIPLE | 状态卡「完成」必须引用本轮命令输出 |
| SP-review | SDD reviewer | ADOPT PRINCIPLE | Reviewer 只读，不信实现者报告；先 spec 再质量 |
| SP-core | 领域流程不进核心 | ADOPT PRINCIPLE | 公司规则放 baseline/rules，不放通用 skill |
| SP-tdd | TDD 默认 | ADAPT | 行为代码默认；docs/config/原型允许 N/A |
| ECC-hook-profile | hooks README | ADAPT | L3 硬拦，L1 警告；不要所有规则都 exit 2 |
| ECC-sessionstart | SessionStart 短注入 | ADAPT | 只提醒 change-id / 停止点 / 读哪个 skill；≤标本 2000 字预算 |
| ECC-audit-idea | harness-audit | PILOT（v1） | 先有 4 个 L3 再谈打分；v0 不做 |

### 10.2 第二批（v1，有一次真实闭环之后）

| ID | 来源 | 吸收 | 注意 |
|---|---|---|---|
| SP-eval | drill / 改 skill 要证据 | ADAPT | 先 3 个场景：假设泄漏、未确认就改代码、假完成 |
| ECC-skill-health | 事件而非台账 | ADAPT | 用来替代标本那种 `skill-usage.md` 硬门 |
| ECC-memory | Memory Vault 思想 | ADAPT CAREFULLY | 记忆 ≠ 政策；不自动晋升 |
| ECC-agentshield | harness 是攻击面 | PILOT | 扫自己的 hooks/AGENTS，不扫业务当完成证明 |
| SP-worktree | 隔离实现 | ADAPT | 已有则加强；与标本 parallel-worktree 对齐 |
| ECC-plan-canvas | 人审计划 UI | PILOT | 可选；停止点仍以文件+gate 为准 |

### 10.3 明确不要

| ID | 来源 | 为什么 |
|---|---|---|
| 整包 ECC plugin 当控制面 | ECC | 无你的仓、环境、DB、PRD；Cursor 不对等；目录会淹没停止点 |
| 整包 superpowers 替代 AGENTS | superpowers | 没有企业停止点；TDD/subagent 默认过强 |
| tmux 默认编排 | ECC | 标本 A14；和 Cursor 桌面流不合 |
| continuous-learning auto promote | ECC | 未确认经验变规则 |
| 286 skills / 68 agents | ECC | 上下文自杀；违反「短入口」 |
| 把 post-edit 当物理阻断 | 两边都可能让人误会 | 只有 PreToolUse / beforeShell 能拦 git 版本化 |

---

## 11. 以后怎么读这两套（学完标本再执行）

不要现在开读源码。标本 Week 0–8 走完、自己的 v0 跑通一次低风险需求之后，用下面这条线。

### 阶段 S1（约 3–5 天）：只读 superpowers 核心 skill

按这个顺序，每份只问三个问题：它挡哪种失败？强制点在哪？我的 v0 缺不缺？

1. `skills/using-superpowers/SKILL.md`
2. `skills/brainstorming/SKILL.md`
3. `skills/writing-plans/SKILL.md`
4. `skills/test-driven-development/SKILL.md`
5. `skills/verification-before-completion/SKILL.md`
6. `skills/subagent-driven-development/SKILL.md`（含 reviewer prompt）
7. `skills/using-git-worktrees/SKILL.md`
8. `docs/testing.md`（脚本测试 vs drill eval）

产出：一页「v0 → v0.1」补丁列表，目标 ≤5 条（例如：计划禁止占位符、完成必须贴命令、Reviewer 双裁决）。

### 阶段 S2（约 3–5 天）：只读 ECC 的 harness 工程，不读框架包

1. README 的 Why / Key Concepts / Platform Support（先看 Cursor/Codex 限制）
2. `hooks/README.md` + profile / exit code
3. `scripts/harness-audit.js` 或 `/harness-audit` 文档：打分类别
4. skill-health / tracker 的事件字段
5. `skills/eval-harness` 或 `skill-comply` 的「规则 → 场景 → 轨迹」
6. continuous-learning-v2：**只读晋升门槛和消毒要求**，不启用

产出：一份「v1 度量最小集」——例如 4 个 L3 的 runs/blocks/false-positive 日志，而不是 dashboard。

### 阶段 S3：对着你的 harness 做差异补丁

每次只合一类：

1. 计划模板（superpowers）
2. 完成证据字段（superpowers）
3. SessionStart 短注入（两边）
4. hook profile：危险命令 allowlist + code-start 推式（ECC 思想 + 标本 L3）
5. 行为 eval 三个场景（两边）

不合：ECC 语言包、Agent 动物园、飞书、SFA UI 细则。

---

## 12. 和标本研究文档怎么分工

`learning_objectives` 里已经有很密的对照，**以后精进时当索引，不当教材正文**：

| 文件 | 用来干什么 |
|---|---|
| `docs/research/ecc-superpowers-source-evidence.md` | 证据 ID（ECC-1…、SP-1…），引用时用编号 |
| `docs/research/ecc-superpowers-adoption-matrix.md` | A1–A18 决策，避免重复争论 tmux / 整包替换 |
| `docs/architecture/ecc-integration.md` | sidecar 边界：只读、dry-run、禁止 apply |
| `skills/third-party/ecc-skills.md` | ECC 当 lens 的白名单 |
| 本文 | 给你的学习路径和「抄什么/不抄什么」总表 |

若公开仓库和快照冲突：以你当时 clone 的 HEAD 为准，回写一句到本文「版本」节。机制冲突时，**停止点和业务边界听标本，执行纪律听 superpowers，度量与 hook 听 ECC。**

---

## 13. 三套叠在一起的目标形态（自建终点，不是现在）

```text
你的控制面（薄）
  AGENTS.md          目录，不是百科
  changes/<id>/      状态卡 + spec/evidence
  4–6 个 L3 gate     其中 1–2 个 hook 推式
  1 个 lane
  ≤4 个角色

从 superpowers 长进去的肌肉
  无占位符计划
  TDD 或显式 N/A
  完成=本轮命令输出
  只读、不信报告的 Reviewer

从 ECC 长进去的神经系统
  hook profile（软默认硬例外）
  SessionStart 短提醒
  gate/skill 事件，而不是 skill-usage 表格
  改规则要有行为证据
  harness 自审计（有数据才退役）

永远不从任何一套长进去
  286 skills、68 agents、tmux 默认、自动 promote 本能
  38 个拉式 gate、飞书当唯一真相源、业务仓无 stub
```

一句话：**标本给边界，superpowers 给手艺，ECC 给仪表盘。** 先边界，再手艺，最后仪表盘。
