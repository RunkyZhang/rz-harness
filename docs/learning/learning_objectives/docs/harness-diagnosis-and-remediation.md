# SFA AI Harness 诊断与整改方案

> 本文以**当前仓库实际状态**为准做诊断（不以已过时的 `harness-engineering-target-plan.md` v1 目标为基准）。
> 所有结论都附实测证据（文件计数、行数、抽样 change 产物）。
> 评估口径：harness 的价值 = 用更低的人工仪式，换取更高的"AI 在清晰可验证边界内交付"的成功率。仪式本身不是价值。

更新时间：2026-06-26。诊断者：AI 助手（基于仓库静态勘察 + 抽样）。
**v2 变更**：经 Codex 交叉评审 + 人工追问后收敛（详见文末 §7）。核心修正：① 产物从"必有/可选二分"改为"按 tier/触发条件的必选矩阵"；② `skill-usage` **降为轻量记录作过渡 + 进退役候选、用 audit 数据决定是否彻底删**（§P1-1 二轮自纠，非简单保留）；③ AGENTS 保留停止点；④ retro 仅对 Tier M/L·跨仓·事故/返工·高风险强制；⑤ gate 退役改多因子判据、安全 gate 豁免；⑥ B1 需先补 adapter 的 SessionStart 接线。注：Codex 的 7 点中真正改变立场的实质纠正仅 3 条，余为事实/澄清。

**v3 变更**：打破 §7.4(3) 的共同盲点，新增 **§8 控制面再架构**——回答"gate 作为机制是否正确、什么形态才能长久迭代维护"。核心结论：gate 不是错的方式，但"以 gate 为默认/唯一机制"是错的；长久可维护靠 gate 天生缺的三样——**分层施控（软为默认/硬为例外）+ 衰减反力（规则自动退役）+ 结果耦合（有效性数据驱动去留）**，目标形态是"小硬核 + 大软壳"。§1–§6 是框架内止血、§8 是其终点方向（见 §8.7 执行序）。

---

## 0. 结论速览（TL;DR）

**一句话**：当前 harness 的**机制方向是对的**（五层模型、Optional Packs、thin hook adapter、停止点、带 FIX 的 gate 报错都已落地），但**工程化收敛没跟上**——产物仪式过载且不收敛、规则真相源多处重复、度量闭环无数据。结果是"维护 harness 本身"开始和"用 harness 交付业务"抢资源。

**最该先修的 5 件事（按 ROI 排序）**：

| 优先级 | 问题 | 一句话解法 | 成本 |
| --- | --- | --- | --- |
| P0 | 每个 change 产 10–19 个文档且命名漂移 | 定义 canonical 产物集 + 一键 scaffold + 文件名校验 | 低 |
| P0 | 流程真相源散在 5+ 个文档且互相冲突 | 指定单一真相源，过时文档归档标 superseded | 低 |
| P1 | `skill-usage` 把"能力"管成"强制台账" | 降为轻量路由记录（不删除），同步改 self-audit/pre-pr/routing | 低 |
| P1 | 改进闭环无数据（无 retro / 无 audit 留痕 / baseline 无数值） | 高风险 change 强制 `retro.md`，其余记 closeout metrics；self-audit 周期落库 | 中 |
| P2 | 30 个 gate 持续增长、缺退役机制，harness 自身要测试套件 | 建 gate 注册表 + 多因子盘点（安全 gate 豁免） | 中 |

---

## 1. 诊断证据基线（实测）

> 计数口径锁定（经 Codex 复核对齐，避免后续漂移）：脚本按"顶层文件"计；gate 按严格 `*-gate.sh` 后缀计（不含 `-gate-test.sh`）；rules 按 `.mdc` 计。

| 指标 | 实测值 | 说明 |
| --- | --- | --- |
| `scripts/` 脚本数 | 71 顶层 / 74 含子目录 | gate 严格计 **30 个 `*-gate.sh`**（另有 3 个 `*-gate-test.sh`、2 个名字含 gate） |
| `scripts/` 总行数 | ~11,190 行 | 纯机器逻辑 |
| `templates/` | 33 份，~2,845 行 | |
| `rules/` | **27 个 `.mdc`**，~5,414 行 | 含 `frontends/legacy-sfa` 子树（旧版我把 README/manifest 也算进 30，已更正） |
| `docs/` | 50 个文件 | baseline 9 仓齐全 |
| `changes/` | 42 个，其中 **27（64%）是 harness 自身 meta 改造** | 业务 change 约 15 个 |
| 单个业务 change 产物数（抽样） | 10–19 个文件 | 见 §3 P0 |
| `evals/` golden scenario | 1–2 条 | |
| `decision-log/` retro | **0 篇**（有 selection，无 retro） | |
| `harness-self-audit.sh` 历史输出 | **无留痕** | |
| git 历史主旋律 | 大量 `harden harness ... gate`、`trim harness` | 反复"加固/收紧" |

### 1.1 现状里做对的部分（不要推翻）

- `docs/architecture/harness-workflow-and-design-principles.md`：五层模型 + 三类停止点 + **Optional Packs（渐进披露已落地）**，质量高。
- hook 架构正确：`.cursor/hooks.json` / `.codex/hooks.json` 都是 thin adapter，统一委托 `scripts/harness-sensor-runner.sh`（单一真相源）。
- `change-stage-gate.sh` 已把 gate 编排成 8 个 stage（intake → closeout），不是让人手跑 30 个脚本。
- gate 报错带 `CODE / FIX / SAMPLE`（符合 Lopopolo "linter 错误要告诉 agent 怎么修"）。
- 9 个业务仓 baseline 齐全。

**结论**：问题不在"机制缺失"，而在"机制实现后缺乏收敛与度量"。下面只针对后者。

---

## 2. 核心问题与解决方案

每个问题给：现象 → 证据 → 根因 → 影响 → 解决方案 → 验收。

### P0-1　交付仪式过载，且产物不收敛（命名漂移）

**现象**：一个普通业务需求要产出十几个 Markdown，且不同 change 的产物集合和文件名都不一样。

**证据**（抽样 4 个真实业务 change）：

| change | 产物数 | 命名漂移示例 |
| --- | --- | --- |
| `0612-bd-overstaff-elimination-app` | 19 | `contract.md` |
| `special-display-department-photo-list` | 13 | `technical-solution-2026-06-08.md`（带日期） |
| `add-distribution-qr-estimated-reward-amount` | 11 | `contract.md` + `ai-test-plan.md` |
| `long-promo-sku-single-pack-unit` | 10 | `api-contract.md`（又一种命名） |

同一类产物出现 `contract.md` / `api-contract.md` / `contract-delta.md` 三种命名；technical-solution 有的带日期有的不带。

**根因**：33 份模板，但**没有"单一规范产物集 + 固定文件名约定 + 文件存在性校验"**。每次靠人/AI 临时决定产哪些、叫什么。

**影响**：① 大量时间花在产文档而非解决问题（你痛点"笨重"的真实来源）；② Reviewer / 新人无法预期一个 change 长什么样；③ 依赖文件名的 gate 会因命名漂移而漏检或误报。

**解决方案**（采纳 Codex 修正：不是"必有/可选"二分，而是**按 tier/触发条件的必选矩阵**——很多产物是行为变更的保护层，不能降成自由可选）：
1. 定义 **产物必选矩阵**，写进 `docs/architecture/change-artifacts-spec.md`：

   | 产物（统一文件名） | 触发条件 | 性质 |
   | --- | --- | --- |
   | `spec.md` / `plan.md` / `evidence.md` / `harness-status.md` | 任何 change | 必有 |
   | `contract.md`（统一此名，contract delta 作为其一节，废弃 `api-contract.md`） | 行为/契约变更 | 条件必选 |
   | `technical-solution.md`（不带日期，版本用 git） | Tier M/L、跨仓 | 条件必选 |
   | `backend-test-plan.md` | **Java 后端行为变更**（AGENTS L23 要求；防"只靠 compile"） | 条件必选 |
   | `verification-map.md` | **Tier M/L**（模板已声明）；映射验收项↔证据 | 条件必选 |
   | `ai-test-plan.md` / `review.md` | Tier M/L、行为风险高 | 条件必选 |
   | `pc-e2e-smoke-*` / `ui-confirmation.md` / `temporary-state-ledger.md` | 命中对应 Optional Pack | 触发可选 |

   关键：**verification-map / backend-test-plan 属"条件必选"而非自由可选**——它们是行为变更的保护层，不是文书仪式。
2. 写 `scripts/change-scaffold.sh <change-id> <tier> [--packs ui,e2e,...]`：按矩阵一键生成规范文件名的空模板，杜绝手工命名。
3. `change-stage-gate.sh` 增加**文件名规范校验**：发现非规范命名（如带日期的 technical-solution）给 FIX。**采纳 Codex 修正**：仅对**新 change 直接 fail**；存量 42 个历史 change 只 **warning 不 fail**，避免一次性破坏历史产物。

**验收**：新 change 产物集合 100% 来自 scaffold；新 change 文件名零漂移；历史 change 仅告警。

---

### P0-2　流程真相源多处重复且互相冲突

**现象**：描述"该怎么走流程"的权威文档至少有 5 处，且口径不一致。

**证据**：
- `AGENTS.md`（80 行，但是密集强制流程墙）
- `README.md`（182 行，含 11 步 CRUD 启动）
- `docs/architecture/harness-workflow-and-design-principles.md`（五层 + Optional Packs）
- `multi-repo-harness-implementation-plan.md`（25K 字）
- `harness-engineering-target-plan.md`（73K 字，**已过时但仍被 design 文档引用**）

**冲突点（实证）**：`AGENTS.md` 要求"Tier M/L 首条回复必须列 spec/contract/solution/test-plan/env/code-start/UI/DB/Test-Agent/report/pre-merge 全套 gate"，而 design 文档强调"默认低风险 CRUD 不加载所有流程，只按 Optional Pack 追加"。**同一件事两种口径**——AI 和人都不知道以谁为准。

**根因**：文档只增不退役；没有落实"单一真相源"。

**解决方案**（采纳 Codex 修正：**保留 AGENTS 的停止点**，它是高风险任务的边界提醒，不是要删的"重复"；只去重"详细流程展开"）：
1. 明确**唯一流程真相源** = `harness-workflow-and-design-principles.md`（完整流程细节只在此处展开）。
2. `AGENTS.md` 保留**硬约束 + Tier M/L 首响停止点**（L12 那条边界提醒**不动**），仅把"逐项列全套 gate 的细节叙述"换成"按 Optional Pack 触发，详见 SSOT"。即：**停止点留，细节流程指向 SSOT**。
3. 过时文档移到 `docs/archive/` 并在首行加 `> SUPERSEDED by docs/architecture/harness-workflow-and-design-principles.md`：`harness-engineering-target-plan.md`、`multi-repo-harness-implementation-plan.md`、`deep-research-report.md`。
4. design 文档删除对 target-plan 的"引用清单"依赖（一手资料清单单独留档即可）。

**验收**：完整流程定义只在 1 个文档；AGENTS 停止点仍在且与 design 文档无矛盾断言。

---

### P1-1　skill 沦为强制文书（`skill-usage-gate` 反模式）

**现象**：每个 change 必须维护 `skill-usage.md` 并引用 `skills/*/SKILL.md` 路径，否则 gate 失败。

**证据**：`scripts/skill-usage-gate.sh` 强制 `skill-usage.md` 存在、必须引用 SKILL.md 路径、不能留 TODO。AGENTS.md 把它列为 mandatory。

**根因**：把"能力（skill）"当成"合规台账"来管。

**影响**：① 增加纯仪式工作；② 与 skill 应"按需自动建议/触发"的定位相悖；③ 鼓励为过 gate 而填表，不反映真实价值。

**解决方案**（第二轮自纠：Codex 主张"它被 AGENTS L20 / `skills-routing.md` / `pre-pr-review.md` / `harness-self-audit.sh` 串起来、是承重约束所以不能删"。**但"接线在 4 处"论证的是删除成本，不是它有价值**——反模式恰恰可能因扩散到 4 处才显得"承重"。故改为"降负作过渡 + 进退役候选 + 用数据决定是否彻底删"）：
1. 把 gate 从"逐项 N/A 台账"降为**轻量路由记录**：只要求一行——"本次命中的 skill + 证据/或不适用原因"，**不再逐 skill 填表、不卡 TODO**。
2. 轻量记录**并入 `evidence.md` 一节，取消独立 `skill-usage.md` 文件**——否则"降负"会变成"换个文件继续填表"，re-bloat。
3. **同步改 4 处接线**（否则降负会引发 self-audit/pre-pr 不一致）：`skill-usage-gate.sh`、`harness-self-audit.sh`、`templates/pre-pr-review.md`、`docs/skills-routing.md` 一起改。
4. **把 skill-usage 列入 gate 退役候选**（接入 P2-1 的注册表，`risk_tier=process`）：用 audit 数据查它在 N 周内**是否真正改变过任何一次产出 / 拦截过任何问题**。
   - 若**从未产生实际价值** → 连同 4 处接线**彻底删除**（不保留"轻量版"继续填表）。
   - 若**确有价值** → 保留轻量版。
   即"降负"是过渡态，最终去留由数据定，与本文 P2-1「数据驱动退役」自洽。
5. 是否"合理使用 skill"降为 **Reviewer 抽查**，不做机械判定。

**验收**：`skill-usage` 不再卡逐项台账/TODO；独立文件消失、并入 `evidence.md`；4 处接线口径一致；已登记进 gate 注册表并标记为退役候选，N 周后按 audit 数据裁决去留。

---

### P1-2　改进闭环无数据（最伤长期价值）

**现象**：harness 建了一整套，却拿不出"它把哪个指标改好了"的数字。

**证据**：`decision-log/` 有 `pilot-selection` 但 **0 篇 retro**；`docs/baseline/*` 无量化数值；`harness-self-audit.sh` 无任何历史输出；`evals/` 仅 1–2 条 golden。试点 `pilot-crud-tbd` 其实跑完了（Reviewer + 人工 SIT 通过），但**没沉淀复盘信号**。

**根因**：度量没有被固化为流程产物——做了事，没留数。

**影响**：后续"删哪条规则、哪个 lane 能升级"全靠拍脑袋；无法向团队证明 ROI。

**解决方案**（采纳 Codex 修正：retro 100% 强制会**重造仪式**，且与现有 `changes-retention-policy.md`「retro 有复盘价值时保留」冲突。改为**分层**）：
1. **分层 retro**：
   - **强制完整 `retro.md`**：Tier M/L、跨仓、**事故/返工**、高风险变更。
   - **轻量 closeout metrics**（小修 / 纯文档）：只在 `evidence.md` 或 `harness-status.md` 写几行数字，不单独产 retro。
   - 固定可机读字段：总耗时 vs 同类基线、返工次数、gate 触发/实际拦截次数、Reviewer HIGH 数、越界次数、`[ASSUMP]/[QUESTION]` 次数。
2. `harness-self-audit.sh` 周期运行并落 `docs/decision-log/audit/YYYY-WW.md`：本周哪些 gate 触发过 / 从未触发 / 被绕过。
3. 每条 lane 维护 golden scenario 计数（`evals/`），目标每 lane ≥ 3 条。

**验收**：连续 4 周有 audit 留痕；**高风险 change 100% 有完整 `retro.md`，小修有 closeout metrics**；能用数字回答"哪些 gate 从未拦截过"。

---

### P2-1　gate 持续增长、缺退役机制（harness 自我熵增）

**现象**：30 个 `*-gate.sh` 且仍在加；harness 复杂到需要给自己写测试套件（`*-gate-test.sh`）；git 历史反复 "harden ... gate"。

**证据**：原始诊断时 `scripts/` 11,190 行；`change-stage-gate-test.sh`、`harness-test-workflow-gates-test.sh` 等存在；27/42 的 change 是 harness meta。后续已移除 OpenSpec workflow scripts，历史 OpenSpec 内容迁移到 `changes/*/legacy-openspec/`。

**根因**：遇到问题就加 gate，但没有"合并 / 退役"的反向机制（Lopopolo 的 garbage collection 没落地）。

**影响**：维护成本与业务交付争资源；新人上手台阶高。

**解决方案**（采纳 Codex 修正：**不能只看命中次数退役**——secrets / 生产配置 / DB 高危 SQL / 主分支保护这类 gate 价值恰恰在于"很少触发"。改为多因子 + 安全豁免）：
1. 建 **gate 注册表** `docs/architecture/gate-registry.md`，每个 gate 一行，含 **`risk_tier` 列**（safety / quality / process）：名称 / 触发条件 / 归属 stage / 最近一次实际拦截时间 / 维护成本 / 是否有替代检查 / owner。
2. **多因子退役判据**（非单一标准）：`触发频率 + 维护成本 + 风险等级 + 是否有替代`。**`risk_tier=safety` 的 gate 结构性豁免**频率退役（即使几乎不触发也保留）。只有"process 类、低维护价值、有替代检查"的才进退役候选。
3. 新增 gate 必须先在注册表登记并说明"替代了哪条人工 review 反馈"（对应 Codex "犯错两次才加规则"）。

**验收**：注册表与 `scripts/*-gate.sh` 一一对应且每个有 `risk_tier`；安全 gate 永不因低频被退役；退役只发生在 process 类。

---

### P2-2　Inferential sensor 偏弱，Reviewer 无校准

**现象**：30 个确定性 gate 很全，但"行为/语义是否正确"这层（Fowler 所谓"屋里的大象"）几乎只靠一个未经校准的 Reviewer。

**证据**：`evals/` 1–2 条；Reviewer 无 judge-alignment 记录（无法证明它的判断与人一致）。

**根因**：确定性层先行（正确），但推断层停在起点。

**解决方案**（保持低成本，**不上 LLM-judge SaaS**）：
1. Reviewer 校准：前若干次人工 review 与 Reviewer Agent 输出做抽样比对，记录 alignment 到 `decision-log/`，达标后才提高对其信任。
2. 每条 lane 扩到 ≥ 3 条 golden scenario，用现有确定性 grader（compile/test/contract）打底。
3. 暂不引入向量检索 / 大平台（与现状"不先上 RAG"一致）。

**验收**：Reviewer alignment 有量化记录；fullstack-crud lane golden ≥ 3 条。

---

### P3　跨工具/外部依赖多（已部分处理，降级关注）

**现象**：同时适配 Cursor / Codex / OpenCode + 可选 ECC sidecar + CodeGraph + GitNexus + 多个 preflight。

**评估**：这条**大部分已处理得当**——thin adapter + `harness-sensor-runner.sh` 单一真相、ECC 明确为 optional sidecar、CodeGraph 明确"optional 非 gate"。剩余风险是**采用门槛**（新人要配 `repos.local.sh` + trust workspace + 多工具 hook review）。

**解决方案**：
1. `docs/onboarding.md` 配一键脚本：`scripts/dev-env-check.sh` 已存在，补一个 `scripts/bootstrap-new-member.sh` 串起 copy 配置 → 校验工具链 → 跑 preflight。
2. 依赖明确分层：**核心**（git/bash/node/maven/npm）vs **可选**（ECC/CodeGraph/GitNexus），onboarding 文档标清楚没装可选项也能用。

**验收**：新成员从 clone 到跑通第一个 gate ≤ 30 分钟、≤ 3 条命令。

---

## 2.8 每条方案的来源（可追溯）

> 说明：本轮我**实际抓取并阅读了两个参考仓的实现层文件**（不是 README）：
> superpowers 的 `hooks/session-start`、`skills/subagent-driven-development/SKILL.md`、`skills/writing-skills/SKILL.md`；
> ECC 的 `the-longform-guide.md`、`skills/continuous-learning(/-v2)`、`commands/instinct-import.md`。下表把每条方案对到真实依据。

来源图例：
- **[一手原则]** = OpenAI Lopopolo / Fowler / Anthropic / Karpathy / Databricks / Stripe（已在 `harness-engineering-target-plan.md` §11 与 design 文档引用的一手出处）。
- **[ECC]** = affaan-m/ECC 实现层。
- **[SP]** = obra/superpowers 实现层。
- **[工程常识]** = 通用软件工程实践，无特定出处，是我的工程判断（合理且行之有效则保留）。

| 方案 | 主要来源 | 具体依据 |
| --- | --- | --- |
| P0-1 canonical 产物集 + scaffold + 文件名校验 | [工程常识] + [SP] | convention-over-configuration / 脚手架生成器；产物"当文件交接而非粘贴"来自 SP 的 file-handoff |
| P0-2 单一真相源 + 过时文档归档 | [一手原则] + [工程常识] | Lopopolo「AGENTS.md 是目录不是百科」；SSOT 原则 |
| P1-1 取消 skill-usage 强制，改自动触发 | [SP] + [ECC] | SP 的 `session-start` hook 注入 bootstrap；ECC 短指南"durable unit 是 skill 不是台账" |
| P1-2 retro + self-audit 数据闭环 | [一手原则] + [ECC] | OpenAI traces→evals、Databricks coSTAR；ECC longform「验证回路 / pass@k / 状态快照」 |
| P2-1 gate 注册表 + 退役机制 | [一手原则] + [ECC] | Lopopolo garbage collection、Codex「犯错两次才加规则」；数据采集机制借 ECC continuous-learning |
| P2-2 Reviewer 校准 + golden + 不上 judge SaaS | [一手原则] + [ECC] | Databricks judge-alignment、Google 轨迹评估；ECC 的 pass@k vs pass^k |
| P3 onboarding 一键 + 依赖分层 | [ECC] + [SP] + [工程常识] | 两者的 plugin 安装模型；ECC 工具预算（<10 MCP / <80 tools） |

**诚实声明**：诊断证据（计数、行数、命名漂移、0 篇 retro）是我逐条实测、可信度最高。方案的**具体实现**（文件名、脚本名、retro 字段、排序）是 [工程常识] 级别的我的设计，未在你环境验证；标 [一手原则]/[ECC]/[SP] 的是机制有据可查，但落地形态仍是提案。

---

## 2.9 深度借鉴：ECC / superpowers 实现层机制（非 README）

> 原则：**只借机制与纪律，不借体量**。ECC 有 261+ skills / Rust 控制面 / Tkinter dashboard——那正是你要避免的"笨重"，一律不抄。下面每条都标注：解决你哪个现存问题 + 最小落地（很多反而**减负/降本**）。

### B1　用 SessionStart 注入"技能路由"，取代 `skill-usage` 强制台账　[SP]

- **机制（实测）**：superpowers 的 `hooks/session-start` 在会话开始把 `using-superpowers/SKILL.md` 内容直接注入 `additional_context`（兼容 Cursor / Claude / Copilot 三种字段名）。之后 skill 由模型按需用 Skill 工具加载，**不需要任何"使用台账"**。
- **解决**：P1-1（skill 沦为强制文书）。
- **最小落地（采纳 Codex 修正：不能假设 SessionStart 已生效）**：`harness-sensor-runner.sh` 虽支持 `sessionStart` 事件，但**当前 `.codex/hooks.json` 只配了 `PreToolUse/PostToolUse`、`.cursor/hooks.json` 只配了 `beforeShellExecution/afterFileEdit`，两边都没接 SessionStart**。所以先**给两个 adapter 补 SessionStart 接线**（委托 sensor-runner），再注入 ≤30 行"技能路由 + Confidence Gate 提醒"，然后才把 `skill-usage` 降为轻量记录（见 P1-1）。

### B2　文件交接 + 进度账本，治多 agent 上下文污染与重复劳动　[SP]

- **机制（实测）**：subagent-driven-development 把 task brief / report / diff(review-package) 全部落成**文件**，子代理只收文件路径；并维护 `progress.md` 账本，**compaction 后已完成任务绝不重派**。核心论断："凡粘贴进 prompt 的内容都会常驻上下文并每轮重读"，一次真实会话 dispatch 命中 42k 字符、99% 是粘贴的历史。
- **解决**：你痛点 #4（多 agent 混乱）+ 上下文成本。
- **最小落地**：① Explorer/Reviewer 的输入输出一律走文件路径（你已接近）；② 给每个 change 加 `progress.md` 账本字段；③ 写一条红线"不得把历史摘要粘进子代理 prompt"。

### B3　每角色模型路由 + 工具预算，直接降本　[ECC]

- **机制（实测）**：按角色选最弱够用模型（检索/转写→cheap，多文件→standard，架构+最终评审→capable）；"省钱看 turn 数不是单价"；工具预算 **<10 MCP / <80 tools enabled**，MCP 能换 CLI+skill 就换以省上下文。
- **解决**：你明确的成本约束；当前 codegraph/gitnexus/ecc/多适配器同时在、无模型口径。
- **最小落地**：写 1 份 `docs/standards/model-and-tool-budget.md`：各 stage 建议模型 + 默认禁用未用工具/MCP。

### B4　自学习 instinct 回路：给"犯错两次才加规则"提供数据　[ECC]

- **机制（实测）**：continuous-learning-v2 用 **PreToolUse/PostToolUse hook 观察（100% 可靠，skill 触发只有 50–80%）**，产出原子 **instinct**（confidence 0.3–0.9，被矛盾则衰减，带 domain 标签），Stop hook 在**会话末**汇总（不用 UserPromptSubmit，避免每条消息加延迟）；instinct 可 `export/import` yaml 做团队共享；演进路径 instinct → cluster → skill。
- **解决**：P2-1 / P1-2 的根缺口——你想"用数据驱动加/退 gate"，但**根本没采集数据**。
- **最小落地（低成本）**：加一个 Stop/closeout 钩子，把"本次重复出现的问题 / 用户纠正 / workaround"追加到 `docs/decision-log/instincts-candidates.md`（带 confidence）；每两周人工把高置信项**升级为 rule 或退役旧 gate**。这正是你 garbage collection 缺的输入源。

### B5　记忆持久化：长 change 跨会话续作　[ECC]

- **机制（实测）**：PreCompact 存状态 / Stop 存学习 / SessionStart 载回；session 文件固定三段——**已验证有效（带证据） / 试过无效 / 未做剩余**。
- **解决**：长需求跨会话丢上下文、重复探索。
- **最小落地**：把这三段并入你已有的 `harness-status.md`，compaction 前/会话末由 hook 落盘。**不新增体系，复用现有状态卡**。

### B6　评估升级：pass@k vs pass^k　[ECC] + 轨迹评估 [一手原则·Google]

- **机制（实测）**：`pass@k`（k 次至少 1 次过，"只要能工作"）vs `pass^k`（k 次全过，"一致性关键"）。文中数据 k=3 时 pass@k≈91% 但 pass^k≈34%。
- **解决**：P2-2，且呼应 Stripe「mostly correct is failure」。
- **最小落地**：golden scenario 标注用哪种判据；**财务/分销/考核口径 lane 要求 pass^k**，低风险 CRUD 用 pass@k。

### B7　子代理迭代检索 + 传"目的"而非"查询"　[ECC]

- **机制（实测）**：orchestrator 评估每次子代理返回，**先追问再接受，最多 3 轮**；dispatch 时传 objective context 而非裸 query（子代理只知字面查询、不知目的）。
- **解决**：Explorer/Reviewer 产出质量。
- **最小落地**：写进 `skills/explorer/SKILL.md` 和 `skills/reviewer/SKILL.md` 的调用约定。

### B8　评审禁止"预判" + 双裁决 + per-task/final 两层　[SP]

- **机制（实测）**：dispatch 评审时**严禁**写"别 flag X / 最多算 Minor / 计划已选定"（那是替自己省评审轮的自我开脱）；评审同时给 **spec 合规 + 代码质量两个裁决**；结构是 per-task 小评审（scoped）+ 末尾一次 whole-branch 大评审。
- **解决**：你的 `reviewer-gate` 是单次、只看 high_risk=0，没禁"预判"，也没 per-task/final 区分。
- **最小落地**：在 `skills/reviewer/SKILL.md` 加"禁止预判"红线 + 两个裁决字段；大 change 末尾追加一次 whole-branch 评审。

### 借鉴优先级（融进整改两波）

- **并入 Wave 1**：B8（reviewer 红线·改一份 SKILL）、skill-usage 降负（B1 的注入需先补 SessionStart 接线，故 B1 主体顺延 Wave 2）。
- **并入 Wave 2**：B4（instinct 数据源，喂给 P1-2/P2-1）、B3（模型/工具预算·降本）、B6（pass^k 用于高风险 lane）。
- **按需**：B2、B5、B7（长需求 / 多 agent 时才值得）。

---

## 3. 整改路线（两波，先止血后结构）

> 已按 Codex 建议改为**保守落地**：新 change 才约束、历史 change 只告警；skill-usage 降负不删除；retro 分层。

### Wave 1（1 周内，低成本高 ROI · 主要是"减"）

1. `docs/architecture/change-artifacts-spec.md`（产物必选矩阵）+ `scripts/change-scaffold.sh`（P0-1）
2. `change-stage-gate.sh` 文件名规范校验：**新 change fail / 历史 change warning**（P0-1）
3. `AGENTS.md` 去重详细流程指向 SSOT、**保留停止点**；过时文档移 `docs/archive/` 标 SUPERSEDED（P0-2）
4. `skill-usage` 降为轻量路由记录并入 `evidence.md`，**同步改 self-audit/pre-pr/routing 4 处**（P1-1）
5. `skills/reviewer/SKILL.md` 加"禁止预判"红线 + 双裁决（B8）

### Wave 2（2–4 周，结构性 · "建度量 + 控熵增"）

6. closeout 分层 retro（高风险强制 / 小修 metrics）+ `harness-self-audit.sh` 周期落库（P1-2）
7. `gate-registry.md`（含 `risk_tier`）+ **多因子盘点、安全 gate 豁免**（P2-1）
8. instinct 候选采集钩子 → `decision-log/instincts-candidates.md`（B4，喂给 P1-2/P2-1）
9. Reviewer 校准记录 + 每 lane golden ≥ 3（含 pass^k 用于高风险 lane）（P2-2 / B6）
10. `docs/standards/model-and-tool-budget.md`（B3 降本）+ `bootstrap-new-member.sh` + 依赖分层（P3）
11. 先补 `.codex/.cursor` 两个 adapter 的 **SessionStart 接线**，再做技能路由注入（B1 前置）

**顺序原则**：先做"减"（产物收敛、文档去重、台账降负），再做"建"（度量、注册表、校准）。**不要在没有度量前继续加 gate**。

---

## 4. 验收指标（怎么判断整改有效）

| 指标 | 现状 | Wave 1 后 | Wave 2 后 |
| --- | --- | --- | --- |
| 单业务 change 必有产物数 | 10–19（漂移） | ≤ 5 必有 + 按需 pack | 同 |
| 产物文件名漂移 | 多种命名并存 | 0（scaffold 统一） | 0 |
| 流程权威文档数 | 5+ 冲突 | 1 真相源 | 1 |
| 强制 gate 仪式（skill-usage 等） | 逐项台账 | 降为一行轻量记录 | 并入 evidence、独立文件消失 |
| 高风险 change 有 retro.md 比例 | 0% | — | 100%（小修只记 metrics） |
| self-audit 历史留痕 | 无 | 启动 | ≥ 4 周连续 |
| gate 净增长 | 仍在加 | 持平 | 季度负增长 |
| Reviewer alignment 记录 | 无 | — | 有量化 |
| 新人上手时间 | 高 | — | ≤ 30 分钟 |

---

## 5. 明确不做的事（避免过度工程）

- 不上 RAG / 向量检索 / LLM-judge SaaS（成本与现状一致）。
- 不照搬 ECC 体量（261+ skills / Rust 控制面 / dashboard）——只取其"instinct 持续学习、状态快照度量"的**原则**，用最小脚本实现。
- 不为"完整性"再加 gate；新增 gate 必须先证明替代了重复出现的人工反馈。
- 不重写已正确的部分（五层模型、Optional Packs、thin hook、停止点保持）。
- **不对历史 42 个 change 直接 fail**（文件名校验只 warning）；不无替代删除承重 gate（如 skill-usage）。
- **不以触发频率退役安全 gate**（secrets / 生产配置 / DB 高危 / 主分支保护即使几乎不触发也保留）。

---

## 6. 一句话收束

**现在的 harness 不缺机制，缺的是"收敛 + 度量 + 退役"三件事。** 先把每个需求的产物收敛到一套规范矩阵、把流程真相源收敛到一个文档、把承重台账降负（而非删除）；再把 retro 和 self-audit 变成有数字的固定产物，用**多因子**判据驱动 gate 的合并与退役（安全 gate 豁免）。这样才能在不牺牲"清晰可验证边界"的前提下，真正解决"笨重"。

---

## 7. 交叉评审记录（Codex check ⇄ 本文反向 check）

> 目的：让两个 agent 互相 check，避免任何一方"凭感觉"。本节先记 Codex 的评审结论，再记本文对 Codex 的反向核实，最后给逐条裁决。

### 7.1 Codex 的评审结论（原文要点）

Codex 认同主方向（收敛/度量/退役），但指出 6 条整改"过猛"，照单全收会削弱安全边界：

1. **P1-1 直接取消 `skill-usage-gate` 过激**——它被 AGENTS.md L20 / `skills-routing.md` / `pre-pr-review.md` / `harness-self-audit.sh` 串起来，应降负为"命中 skill + 证据/不适用原因"，并同步改 self-audit、pre-pr、routing，而非删除。
2. **P0-1 把 `verification-map` / `backend-test-plan` 降成普通可选不稳**——它们是 Tier M/L 及 Java 行为变更的保护层（防只靠 compile）；应改为"按 tier/触发条件的必选矩阵"。
3. **P0-2 不应删 AGENTS 停止点**——design 文档是 SSOT 没错，但 AGENTS L12 的 Tier M/L 首响停止点是高风险边界提醒，应保留，仅去重详细流程。
4. **retro 100% 强制会重造仪式**——与 `changes-retention-policy.md`「retro 有复盘价值时保留」冲突；应只对 Tier M/L、跨仓、事故/返工、高风险强制，小修只记 closeout metrics。
5. **"连续 N 周没拦截就退役 gate"不能单一标准**——secrets / 生产配置 / DB 高危 / 主分支保护价值就在于少触发；退役应看"频率 + 维护成本 + 风险等级 + 是否有替代"。
6. **B1 不能假设 SessionStart 已生效**——sensor-runner 支持，但 `.codex/.cursor` 两个 hooks 只配了 PreToolUse/PostToolUse，要先补 adapter。
7. **基线数字有漂移**——实测 `scripts=74 / *-gate.sh=30 / templates=33 / rules .mdc=27 / docs=50 / changes=42 / retro=0`，不要把 `35 gates / 71 scripts` 当硬验收数字。

Codex 建议：采纳 P0-1/P0-2/P1-2/P2-1 方向但保守落地；**不建议**按原文执行 Wave 1（尤其"删 skill-usage 强制"和"canonical 文件名直接 fail"）。

### 7.2 本文对 Codex 的反向 check（我实测核实）

我没有直接接受，而是逐条复核了 Codex 引用的文件/行号，结论：**Codex 的 7 条事实性声明全部属实**。

- ✅ 计数：`find scripts -type f`=74（顶层 71）；严格 `*-gate.sh`=30（我旧值 35 把 3 个 `-gate-test.sh` + 2 个名字含 gate 混入）；`rules/*.mdc`=27（我旧值 30 把 README/manifest 算进）；`docs`=50（我旧值 49 off-by-one）。**Codex 更精确，已全部更正（§1）。** 说明：两套数字并非谁错，是口径不同（顶层 vs 递归、含 gate vs 严格后缀），已锁定口径。
- ✅ hooks：`.codex/hooks.json` 仅 `PreToolUse/PostToolUse`，`.cursor/hooks.json` 仅 `beforeShellExecution/afterFileEdit`，**确实都没 SessionStart**。B1 已更正为"先补 adapter"。
- ✅ AGENTS L12（Tier M/L 停止点）、L20（skills-routing）、L23（backend-test-plan）、`changes-retention-policy.md`「retro 有复盘价值时保留」——逐条核对无误。

**反向 check 中我对 Codex 的 3 点补充/微调（不是反驳，是加固）**：

- **RC-1（针对点 1）**：同意不删除，但 Codex 的"降为轻量记录"若仍保留独立 `skill-usage.md` 文件 + 表格，会**换个文件继续填表 = re-bloat**。我加一条：轻量记录**并入 `evidence.md` 一节，取消独立文件**。否则降负名存实亡。
- **RC-2（针对点 2/3）**：Codex 略微**误读了我的原意**——我原文已把 `backend-test-plan` 列为"Tier M/L 追加"（非自由可选），真正错放的只有 `verification-map`；P0-2 我原文是"AGENTS 瘦身为索引+硬约束"（停止点属硬约束，本就保留）。但 Codex 的担忧有价值：原文措辞会让人误以为要删停止点。**故采纳其更清晰的表述**，已显式写明"停止点不动"。
- **RC-3（针对点 5）**：完全同意，并加固为可执行——在 gate 注册表加 **`risk_tier` 列**，让"安全 gate 豁免频率退役"成为**结构约束**而非口头原则。

### 7.3 逐条裁决与落地

| Codex 点 | 我的裁决 | 落地位置 |
| --- | --- | --- |
| 1 skill-usage 不删除 | **部分采纳 → 二轮自纠**：降负不鲁莽删（采纳），但反驳"承重=有价值"，改为进退役候选、数据定去留（见 §7.4） | P1-1、§3 Wave1-4 |
| 2 产物必选矩阵 | **采纳** | P0-1 矩阵表 |
| 3 保留 AGENTS 停止点 | **采纳**（+RC-2：原意如此，措辞改清晰） | P0-2 |
| 4 retro 分层 | **采纳** | P1-2、§4 |
| 5 gate 退役多因子 | **采纳**（+RC-3：加 `risk_tier` 结构豁免） | P2-1、§5 |
| 6 先补 SessionStart 接线 | **采纳** | B1、§3 Wave2-11 |
| 7 基线数字 | **采纳并更正** | §1（含口径锁定） |

**结论**：本轮交叉评审使整改方案从"方向对但偏激"收敛为"方向对且可安全落地"。两条原本会破坏安全边界的动作（删 skill-usage 强制、历史 change 直接 fail）已被纠正。后续若再迭代，建议保持这种"一方提案 + 另一方按文件/行号反向核实 + 逐条裁决留痕"的双 check 节奏。

### 7.4 第二轮自纠：警惕"全部采纳"本身（人工追问触发）

> 人工追问："你为什么把 Codex 6 条全部采纳？"——这是对**表演性同意（附和而非技术判断）**的警惕，记录于此。

**(1) "6 条全采纳"是误导性表述。** 按性质拆开它们并不对等：

- **纯事实题（无判断余地）**：基线数字、B1 的 SessionStart 未接线——实测为真，接受不算"让步"。
- **澄清我自身歧义（非反转）**：保留 AGENTS 停止点——我原意本就保留，Codex 实为误读，我只改了措辞。
- **真正改变立场的实质纠正**：仅 3 条——产物必选矩阵、retro 分层、gate 退役多因子。

即**真正"被说服"的只有 3 条**；把事实题/澄清题/判断题混说成"全采纳"，掩盖了它们的不对等。

**(2) 一条 over-yield，已在 §P1-1 二轮纠正。** 对 skill-usage，我曾接受 Codex"承重所以保留"。复核后发现该论据**把"删除成本高"偷换成"有价值"**。已改为：降负作过渡，同时进退役候选、用 audit 数据决定是否彻底删——这比 Codex 更激进，且与本文 P2-1 自洽。

**(3) 双 check 的共同盲点（已由人工追问打破，见 §8）。** Codex 与本文**都在"保留这套 gate 模型、只打磨它"的框架内**争论；没有任何一方质疑更根本的问题——**30 个 gate + 8 个 stage 的重控制面，对团队级 harness 是否本就过重**。两个 agent 共享同一前提时，对 check 不会发现它。这说明双 check 能收敛措辞与安全边界，但**打不破共享盲点**，仍需外部（人工）追问。**后续人工追问"gate 这种方式本身是否正确、有没有更利于长久维护的机制"已把这个盲点展开为 §8——它跳出"gate 多少"的框架，回答"gate 作为机制是否正确，以及什么形态才能长久迭代维护"。**

---

## 8. 控制面再架构：gate 作为机制是否正确，什么形态才能长久维护

> 本节是 §7.4(3) 共同盲点的正式展开（由人工追问触发）。前面 §1–§6 都在"保留 gate 模型、打磨它"的框架内；本节跳出该框架，回答两个更根本的问题：**(A) 用 gate 作为控制机制对不对？(B) 有没有更利于"长久迭代维护且行之有效"的方式可借鉴？** 结论来自对 ECC / superpowers 实现层的对照（非 README）。
>
> **核心结论先行**：gate 不是错的方式，但**"以 gate 为默认/唯一机制"是错的**。让 harness 长久可维护的不是"更好的 gate"，而是 gate 模型**天生缺的三样东西**：①分层施控（软为默认、硬为例外）②衰减反力（规则能自动退役）③结果耦合（用有效性数据驱动去留）。

### 8.1 三种控制模型对照

| 维度 | **SFA harness（现状）** | **superpowers** | **ECC** |
| --- | --- | --- | --- |
| 控制的基本单位 | **强制 gate**（30 个 shell + 8 stage） | **skill**（~12 个方法论技能） | **skill + instinct**（懒加载 + 学来的原子规则） |
| 施加方式 | 前置、统一、机械：每个 change 走流水线、产十几个产物 | 按需自动触发：SessionStart 注入"你有 skill"，技能自带 when-to-use 自选 | 懒加载 + 反应式：用到才加载；hook 是轻量事件反应 |
| 质量怎么保证 | 多个窄 computational gate 各查一点 | **一次有纪律的双阶段 LLM 评审**（per-task + whole-branch）+ TDD | 轻量 hook（format/lint/tdd-reminder/security）+ 评审 subagent |
| 规则怎么来 | **人工只增不减**（→ 熵增到 30 个） | 固定 ~12 个，几乎不加 | **从真实复现里学**：instinct 带 confidence、矛盾则衰减、可升级为 skill |
| 成本控制 | 无显式口径 | 每角色选最弱够用模型 | 模型路由 + 工具预算（<10 MCP / <80 tools） |

- **superpowers 模型 = 方法论即技能，几乎不用 computational gate**。实测其 `hooks/` 只有 `session-start`（注入 `using-superpowers`），**没有 PostToolUse 编译/lint/越界类 gate**。质量靠：技能写成带 STOP/红旗的强制工作流（模型读技能自律）+ subagent 双阶段评审（per-task scoped + whole-branch）+ TDD。它把"行为正确性"交给**推断层**，而非堆窄 gate。
- **ECC 模型 = harness 操作系统，懒加载 + 自学习**。表面更大（261 skills）但**不一次性背全部**：skill 懒加载；**instinct** 用 PreToolUse/PostToolUse hook 观察（100% 可靠，skill 触发只有 50–80%），沉成原子规则（confidence 0.3–0.9、被矛盾衰减、可 export/import、演进 instinct→cluster→skill）；hook 是轻量事件反应，不是 8-stage 强制产物流水线；成本是一等公民。

### 8.2 诚实校正（不掉进"别人草更绿"）

1. **它们不是"更轻"，是控制形态不同 + 风险语境不同**。superpowers/ECC 主要面向**单人/greenfield/OSS**，没有多仓 Java 企业、生产 DB、分销/财务口径。SFA 的 30 个 gate 里有一批（protected paths、DB 写边界、生产配置、跨仓契约）是**真实安全需求编码出来的，不能照它们删**。
2. **superpowers 几乎不做安全 computational gate**——对一个碰生产销售数据的团队是**危险的**，不能整套搬。**这点 SFA 比它强，别丢。**
3. **ECC 其实更复杂，只是懒加载**——复杂度搬进了"261 skill 库 + instinct 引擎"。"ECC 解决了笨重"有一半是错觉。

### 8.3 gate 作为机制的固有缺陷（为什么单一栽培伤长久维护）

gate 本质 = **前置阻断式检查点**。三个无法靠"打磨"消除、且恰好都是"长久维护"杀手的结构性毛病：

1. **只增不减的棘轮效应**：每次出事加一个、没人删 → 单调增长到 30。gate 模型**自带增长、不自带淘汰**。这是数学必然，与管得好不好无关。
2. **和结果脱钩**：gate 只证明"产物存在/命令跑过"，不证明"缺陷被拦住"。所以**无法判断它是否行之有效**，也就不敢删。
3. **改动成本高**：shell gate 接进多个 adapter 点，改一条规则要动代码+接线，比改一段文字贵一个数量级。

→ 痛苦来自 **gate 单一栽培（monoculture）**，不是 gate 数量。gate 适合**一类东西**（二元、不可逆的安全事实），不适合当**所有事**的统一机制。

### 8.4 让 harness 长久可维护的三件事（gate 天生缺、ECC/SP 有）

**① 分层施控：按"要管什么"选机制，软为默认、硬为例外**

| 层 | 机制 | 管什么 | 改动成本 | 谁示范 |
| --- | --- | --- | --- | --- |
| L0 引导（feedforward） | skill / 上下文注入 | 绝大多数"该怎么做" | 改一段文字 | superpowers |
| L1 学习规范 | **instinct** | 反复出现的坑/纠正 | **自动沉淀+自动衰减** | ECC |
| L2 推断评审 | 评审 subagent + TDD | 行为正确性、spec 合规 | 改评审 prompt | superpowers |
| L3 硬 gate | shell 阻断 | **不可逆安全**：生产配置/DB写/secrets/主分支/跨仓契约 | 改代码+接线 | SFA（这块本就做得对） |

关键：这不是"谁取代谁"，是匹配关系。**SFA 的 30 个 gate 里真正该留在 L3 的可能不到 1/3，其余是被错放到 L3 的 L0/L1/L2 的活。**

**② 衰减反力：任何控制系统都要有一个"自动删除"的对冲力**

ECC 的 instinct 带 confidence、被矛盾衰减、长期不复现沉底——**规则不靠人手删，靠机制自己淘汰**。gate 模型只有"加"没有"减"= 熵增系统。最小可行版（不必照搬 instinct 引擎）：

- 每个 gate 必须有 **owner + 命中统计 + 到期复审日**；
- **零命中 / 从未拦下真实问题的 gate，到期自动进退役候选**（安全 gate 豁免，见 §P2-1）；
- 加新 gate 要先回答"它替代/合并了哪条老的"。

**③ 结果耦合：用"是否改变结果"判断有效，而不是"是否跑过"**

"行之有效"唯一判据 = **这个控制是否真的改变了产出**（拦下了本会发生的缺陷/事故）。最小落地：给每个 gate 建一行**有效性台账**（命中次数 / 拦下的真实问题 / 误报次数）。三个月后这张表会自己告诉你哪些留、哪些砍、哪些降层——**让数据替你和 Codex 做那个谁都不敢碰的决定**。

### 8.5 目标形态：小硬核 + 大软壳

> 可长久维护的 harness 不是"gate 多/少"，而是这个形状：**一个很小、几乎冻结的硬 gate 核（只装不可逆安全）+ 一个很大、廉价可改、能自我淘汰的软壳（skill/instinct/评审）+ 一条横切的有效性度量闭环。**

ECC、superpowers 本质都是这个形状（ECC：安全 hook 硬、其余软且可学；superpowers：TDD/评审有纪律，但安全硬核不足——SFA 不要学它这点）。

### 8.6 落到 SFA 的迁移方向（换形状，不是砍数量）

1. **反转默认**：新需求默认走 L0 引导，只有命中"不可逆安全"才升到 L3。今天是反的——默认全流水线。
2. **30 个 gate 做一次分诊**，每个归一类：
   - **keep-hard（L3）**：safety/不可逆——保留硬 gate（即使低频）。
   - **fold-into-review（L2）**：quality/正确性——从窄 gate 收敛进一次有纪律的推断评审 + TDD。
   - **replace-with-skill-or-instinct（L0/L1）**：process/仪式（如 `skill-usage`）——删 gate，换懒加载 skill + 学来的 instinct。
3. **装上衰减反力 + 有效性台账**（§8.4 的 ②③）。**这两样才是"长久"的真正来源**——缺了它，分层做完照样会再次熵增。

### 8.7 与 §1–§6 整改方案的关系

§1–§6 是**框架内**的止血与收敛（产物收敛、文档去重、台账降负、注册表、度量），**短期立刻可做且低风险**，应照常执行。§8 是**框架外**的目标架构（控制分诊 + 小硬核大软壳），是 §1–§6 的**终点方向**：

- §8 的"衰减反力 + 有效性台账"正是 §P2-1（gate 注册表/退役）、§P1-2（度量闭环）、§B4（instinct 数据源）的**统一动机**——它们其实就是把软壳和度量闭环装起来的具体步骤。
- §8 的"30 个 gate 分诊（keep-hard/fold/replace）"是 §P2-1 多因子盘点的**升级版**：盘点不只为"退役"，而为"把错放层级的 gate 迁到正确的层"。
- **建议执行序**：先做 §1–§6 Wave 1/2（把度量和注册表建起来）→ 用积累 1 个季度的有效性数据**驱动** §8.6 的逐条分诊 → 完成"换形状"。**没有 §8.4 的数据，§8.6 的分诊仍是拍脑袋。**

**一句话**：gate 不是错的方式，错的是"以 gate 为默认/唯一机制"；更好的方式是**分层施控 + 让规则能自动衰减 + 用有效性数据驱动进退役**——前者解决"管得准"，后两者才解决"长久可迭代维护"。
