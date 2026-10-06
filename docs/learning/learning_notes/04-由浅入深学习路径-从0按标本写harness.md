# 由浅入深学习路径：从 0 按标本写 harness

> 日期：2026-08-29  
> 用途：不按周。按「你自己从空目录写一份最小控制面」的顺序学。每一步只写一个文件（或一对：模板 + 实例），写的时候会碰到一个词，再去标本里把这个词搞懂。  
> 替换：[01-第一轮回复-标本是不是harness-五层解构.md](01-第一轮回复-标本是不是harness-五层解构.md) 里按周排的计划。那份仍可当目录，执行以本文为准。  
> 标本根目录：`learning_objectives/`

你要的学法是：**做中学，用到再查**，不是先背完全部术语再动手。

---

## 0. 怎么用这篇

- 一次只做 **一步**。步内「对照读」最多两三份标本文件，不要顺手点开 `scripts/` 全目录。
- 每一步有「做到什么算完成」。没完成不要跳。
- 标本里的 SFA、飞书、Vue2、mapSystem 是**他们的业务积木**，不是你要抄的。看机制，不看产品名。
- 现在还不到 superpowers / ECC。那两份比较笔记以后再用。

起步时只要记住一句：

**Cursor 负责让 AI 能改文件、能跑命令。你要写的 harness 负责：AI 在什么边界里改、不清楚时必须停、宣称做完时必须有证据。**

你写的是控制面（规则 + 工件 + 检查脚本），不是再做一个 Cursor。

---

## 1. 整条路径一览（先看地图，再一步步走）

每一步格式：先写什么 → 因此必须搞懂什么词。

| 步 | 你写下的东西 | 这一步逼你搞懂的词 | 不写会怎样 |
|---|---|---|---|
| 1 | `AGENTS.md` | 控制面入口、渐进披露 | Agent 没有「读我」的第一页 |
| 2 | `templates/spec.md` + `changes/demo-001/spec.md` | 变更包、FACT/ASSUMP/QUESTION | 工作只活在聊天里，无法停止 |
| 3 | `scripts/confidence-gate.sh` | **gate（你的第一个）** | 「请先确认」只是一句话，模型可以不理 |
| 4 | `templates/harness-status.md` + 实例 | 状态卡、停止点 | 你不知道现在卡在哪 |
| 5 | `templates/evidence.md` + 实例 | 证据、宣称完成 | 模型说测过了，你看不到命令输出 |
| 6 | spec 里的 `allowed_paths` + `scripts/allowed-paths.sh` | 约束、第二条 gate | AI 改到范围外文件 |
| 7 | `lanes/tiny.md` | lane | 每次任务都重新发明流程 |
| 8 | `scripts/assumption-leak-gate.sh` | 为什么一个 gate 不够 | spec 过了，代码里仍写着「先假设…」 |
| 9 | `skills/reviewer/SKILL.md` + `templates/review.md` | skill、只读 Reviewer | 写代码的自己给自己打分 |
| 10 | `scripts/reviewer-gate.sh` | 第三条相关 gate | review.md 写了但没人检查有没有 HIGH |
| 11 | `.cursor/hooks.json` + 一个薄 hook 脚本 | hook，以及 hook≠gate | 模型忘记跑脚本时，commit 照样发生 |
| 12 | 停。用一个真的小需求把 1–11 跑通 | v0 | — |

第 12 步之前，不要写技术方案模板、不要写 38 个脚本、不要接飞书。

---

## 第 1 步：写 `AGENTS.md`

### 你写什么

仓库根目录一份短文件，给 **Agent** 读（人也读）。先写 30～60 行就够，不要冲 100 行上限。

建议只放：

- 这是控制面，不放业务代码
- 文档给人看的用中文
- 一次工作一个 `changes/<id>/`
- 没确认的假设不准进代码
- 细节去哪些目录（此时那些目录可以还不存在，写「将要有」也可以，下一步再补）

### 为什么第一个写它

Agent 进仓库后，第一份约定俗成会找的就是 `AGENTS.md`（Cursor / Codex 都认）。你不先立入口，后面的模板和脚本等于没人保证会读。

标本自己说：这份文件要像**目录**，不要像百科。百科会让模型变笨，也会让你改一处漏三处。

### 对照标本读

- `learning_objectives/AGENTS.md`：只看结构（有哪些小节），不要背里面的 SFA 仓名和全部流程。
- `learning_objectives/README.md` 开头「一句话职责」那几段。

### 这一步的词

**控制面**：不管业务功能怎么实现，只管「AI 按什么规矩工作」。业务代码在别的 git 仓。

**渐进披露**：入口短，细节按需打开。`AGENTS.md` 指到 `docs/`、`templates/`，而不是把技术方案写法贴满入口。

### 做到什么算完成

你能用自己的话讲清：`AGENTS.md` 是给谁看的、为什么必须短。文件里还没有 gate、没有仓列表，这是正常的。

---

## 第 2 步：写 spec 模板，并做第一次「变更包」

### 你写什么

1. `templates/spec.md`（以后每次复制）
2. `changes/demo-001/spec.md`（第一次真实填写，目标可以假：例如「给 README 加一行说明」）

模板里先只要这几块：

- 一句话目标
- 范围内 / 范围外
- `[FACT]` / `[ASSUMP]` / `[QUESTION]` 三行起
- 允许改哪些路径（这一格可以先空，第 6 步再填严）

### 为什么现在写它

第 1 步只告诉 Agent「要有规矩」。第 2 步才有**这一次工作的事实源**。没有 spec，停止、确认、范围都无处可写，只能靠聊天记忆。

标本把一次需求叫做一个 **change**，目录是 `changes/<change-id>/`。这叫**变更包**：这次相关的 spec、状态、证据都放这里，不散落在对话里。

### 对照标本读

- `learning_objectives/templates/spec-tier-s.md`（只要 Tier S，不要打开 M/L）
- `learning_objectives/docs/architecture/change-artifacts-spec.md` 里 **Profiles 表的 `tier-s` 那一行**：只要 `spec.md`、`harness-status.md`、`evidence.md`。后面两个文件还没写，知道「最小就这三件」即可。

### 这一步的词

**变更 / change / change-id**：一次有边界的工作的名字和文件夹。例如 `demo-001`。

**工件 / artifact**：变更包里那些规定文件名的 Markdown。不是「文档越多越好」，是「这类工作必须有这些文件」。

**`[FACT]`**：能指出处的话（用户原话、PRD、仓库里已有代码）。没有出处就不是 FACT。

**`[ASSUMP]`**：你猜的。确认之前不准写进实现。

**`[QUESTION]`**：必须问人的。没回答就停。

这三标签是标本最值钱的机制之一。先会填，不必一次填对所有业务字段。

### 做到什么算完成

`changes/demo-001/spec.md` 里三标签都有；至少有一个 `[QUESTION]` 或明确写了「无阻塞问题」。你还没有脚本去检查它——下一步才做检查。

### 这里会卡住的自然问题

「Agent 填完 spec 直接去改代码怎么办？」  
对，规矩写在 Markdown 里不等于会执行。这就是第 3 步要发明 **gate** 的原因。

---

## 第 3 步：写你的第一个 gate —— `scripts/confidence-gate.sh`

### 你写什么

一个可执行的 shell 脚本。输入是 spec 路径。检查失败就 `exit 1`，并打印：

- 错在哪
- **怎么修**（FIX）
- 可以抄的样例路径

最小检查（抄标本意图，自己写十几行 grep 即可）：

- 文件存在
- 正文里出现过 `[FACT]`、`[ASSUMP]`、`[QUESTION]`
- 若还有未勾掉的阻塞 `[QUESTION]`，失败

### 为什么现在写它

第 2 步的三标签如果只靠「请 Agent 遵守」，长对话、用户催「先写代码」时，模型会丢掉这句话。

**Gate 不是「一扇门的装饰」，是一道检查关卡：条件不满足就失败，后面的动作不该继续。**

英文 gate 在这里 = 准入检查。标本里文件名经常是 `*-gate.sh`。它是 **Sensor（传感器）**：不靠模型记忆，靠脚本读文件、给反向压力。失败时错误信息是写给 Agent 读的，所以要带 FIX。

### 对照标本读

- `learning_objectives/scripts/confidence-gate.sh` 从头读到第一个 `fail` 函数即可。看它如何 `CODE / FIX / SAMPLE`。
- 不必读完 38 个 `*-gate.sh`。

### 这一步的词（就是你问的 gate）

**gate**：一段**确定性**检查（通常是脚本）。通过 = 退出码 0；不通过 = 非 0，并说明怎么修。  
它限制的是「能不能进入下一动作」，例如：能不能开始写业务代码、能不能宣称完成。

它**不是**：

- 不是 Cursor 本身
- 不是 AI 角色（Reviewer 不是 gate；检查 review 文件的脚本才是 gate）
- 不是 hook（hook 是「工具事件触发时自动跑」；gate 是「被调用时跑」。第 11 步再区分）

**fail-closed**：说不清就当失败。不要「找不到文件就当通过」。

**Computational vs Inferential**：gate 属于前者（规则固定、可重复）。「代码好不好看」属于后者，交给 Reviewer，不要用 grep 假装能判断架构。

### 做到什么算完成

对本仓库执行：

```bash
scripts/confidence-gate.sh changes/demo-001/spec.md
```

故意留一个阻塞 QUESTION 时会失败；改掉后再通过。你亲自看到红/绿一次。

---

## 第 4 步：写状态卡 `harness-status.md`

### 你写什么

1. `templates/harness-status.md`（极简版，不要抄标本那张十几行 Gate 表）
2. `changes/demo-001/harness-status.md`

极简版只要：

- 当前阶段（例如：写 spec / 等确认 / 允许改代码 / 已收口）
- 下一步
- 是否允许往下走：YES / NO
- 当前阻塞
- 需要你确认什么
- 最近一次 `confidence-gate` 是过还是不过

### 为什么现在写它

有了 spec 和 gate，信息仍可能只在终端滚动里。状态卡是给你看的一张纸：**现在停在哪、谁该做决定**。标本叫它用户可见入口。聊天历史不是入口。

### 对照标本读

- `learning_objectives/templates/harness-status.md` **只看最上面那张 6 行表**。下面那些 Gate 状态、Agent Roster 是他们养肥后的，v0 不要抄。

### 这一步的词

**状态卡**：变更包里给人看的仪表。聚合状态，不替代 spec。

**停止点**：必须停下来问人或补证据的时刻。标本后来分成三类（口径不清 / 边界不安全 / 证据不足）。v0 你只要会用状态卡写「卡住了，因为 QUESTION 没答」。

**编排 / Orchestration**：谁更新这张卡、阶段怎么切。v0 就是你（或主 Agent）改 Markdown，没有调度器。

### 做到什么算完成

`demo-001` 的状态卡能让一个没看过聊天的人知道：现在能不能改代码、卡在什么问题上。

---

## 第 5 步：写 `evidence.md`

### 你写什么

1. `templates/evidence.md`
2. `changes/demo-001/evidence.md`

先只要：跑过什么命令、退出码、关键输出摘要、结论。禁止贴密码。

### 为什么现在写它

状态卡可以写「测试过了」。没有证据文件，这句话无法核对。标本和以后要学的 superpowers 都咬同一件事：**宣称完成必须有本轮命令输出**，不是「应该能过」。

### 对照标本读

- 扫一眼 `learning_objectives/templates/` 里带 evidence 的模板文件名即可；有现成 `evidence` 相关模板就抄结构，没有就自己写一节「命令 / 结果 / 链接」。

### 这一步的词

**证据 / evidence**：可复查的痕迹（命令、退出码、日志摘要、截图路径）。Agent 的自我汇报不是证据。

这一步**还不必**再写一个 gate。你先养成「跑了就记」。以后若模型空口完成，再加检查「evidence 里有没有本轮命令」的 gate。

### 做到什么算完成

你对 `demo-001` 跑过 `confidence-gate`，并把命令和结果抄进 `evidence.md`。

---

## 第 6 步：收紧路径 —— 第二条 gate `allowed-paths`

### 你写什么

1. 把第 2 步 spec 里的 `allowed_paths` 填成真实可检查的路径（先允许一个目录即可）
2. `scripts/allowed-paths.sh`：传入 spec + 若干将要改的文件，不在名单里就失败

### 为什么现在写它

到这里，Agent「理论上」可以动手改文件了。最大的新风险不是写错业务逻辑，而是**改到不该碰的文件**（`.env`、别的模块、生产配置）。

这是 **Constraints（约束）**：gate 管「事实清不清」，这条管「手能不能伸到这儿」。

### 对照标本读

- `learning_objectives/scripts/allowed-paths.sh` 的 `usage()` 注释（文件开头）
- `templates/spec-tier-s.md` 里 `allowed_paths` 那一小段 YAML

### 这一步的词

**allowed paths**：本次允许修改的路径白名单。

**protected / forbidden**：默认不准碰的（密钥、生产配置、migration）。要碰必须显式批准。

**Constraints**：五层模型里「什么不能碰」。和 Instructions（怎么做）不是一层。

### 做到什么算完成

对一个白名单内的文件脚本通过；对一个 `.env` 或名单外路径失败。结果记进 `evidence.md`，状态卡勾一下。

---

## 第 7 步：写一条 lane `lanes/tiny.md`

### 你写什么

一份「最小任务怎么走」的清单，例如：

1. 复制 spec 模板到 `changes/<id>/spec.md` 并填三标签
2. 复制状态卡
3. 跑 `confidence-gate`
4. 人回答 QUESTION
5. 再跑 `confidence-gate` 和 `allowed-paths`
6. 改代码（仅白名单）
7. 把命令写入 evidence
8. （第 9 步之后才有）Reviewer

### 为什么现在写它

第 1～6 步你已经有零件。没有 lane，下次做需求又会在聊天里现编顺序。**lane = 某类任务的默认路线**，不是新语言。

标本有 `fullstack-crud.md`、`bugfix-fast.md`。那些是他们的产品路线。你只要 `tiny`：单仓、小改、不碰库。

### 对照标本读

- `learning_objectives/lanes/bugfix-fast.md` 或 `fullstack-crud.md` **只看「默认最小流程」编号列表的前几条**。下面的 Optional Packs 先当「以后才加载的插件」，不要学。

### 这一步的词

**lane**：任务类型选的流程套餐。小修走 tiny，以后全栈 CRUD 再开另一条。避免一条巨流程套所有事。

**Optional Pack**：默认不加载的附加流程（UI、E2E…）。v0 没有 pack。

### 做到什么算完成

`lanes/tiny.md` 能让 Agent 按编号做完一次 `demo-001` 这类事。`AGENTS.md` 里加一句：小改走 `lanes/tiny.md`。

---

## 第 8 步：第三条 gate —— 假设泄漏 `assumption-leak-gate.sh`

### 你写什么

脚本：扫**将要提交的实现文件**（不是 spec），如果出现未消化的 `[ASSUMP]`、或明显的「暂且假设 / TODO 按 XX 实现」高信号，就失败。

### 为什么现在写它

`confidence-gate` 只看 spec。模型可以 spec 写得很干净，代码注释里仍写着没确认的规则。这是第二道、打在**实现文件**上的传感器。

到这里你会理解：**同类风险往往要两道检查**——文档关 + 代码关。不是 gate 越多越好，是「漏了哪一层就补哪一层」。

### 对照标本读

- `learning_objectives/scripts/assumption-leak-gate.sh` 开头 usage 和它 grep 什么（读意图，不必抄完所有正则）

### 做到什么算完成

造一个带 `[ASSUMP]` 的 `.js`/`.md` 实现文件，脚本能抓住；删掉后再过。

---

## 第 9 步：写只读 Reviewer skill

### 你写什么

1. `skills/reviewer/SKILL.md`：规定 Reviewer **只读**，输出 `changes/<id>/review.md`，先列 HIGH/MEDIUM，引用路径，不直接改业务代码
2. `templates/review.md`

### 为什么现在写它

主 Agent 又写代码又说「没问题」，就是自我评分。标本和 superpowers 都要求：**审查换一个角色（最好换上下文），并且只读。**

### 对照标本读

- `learning_objectives/skills/reviewer/SKILL.md` 前半：只读、输出什么、禁止什么
- 不要此时去读 explorer/tdd/grill 全部 skill

### 这一步的词

**skill**：可复用的工作说明书（什么时候读、产出什么、禁止什么）。不是 Cursor 插件市场必装项；标本是仓库内 `SKILL.md`，由 `AGENTS.md` 或路由表指向。

**Reviewer**：审查角色。v0 可以仍是同一个 Cursor 会话，但必须换一份 prompt/skill，并且约定不改业务文件。独立子 Agent 是以后的事。

**Orchestrator / 主 Agent**：负责推进流程、集成、改允许范围内的代码。它不能替代 Reviewer 的裁决。

### 做到什么算完成

对 `demo-001` 写出一份 `review.md`，里面至少有「看了 spec / diff / evidence」的痕迹。即使是你自己扮演 Reviewer 也可以，先走通文件形状。

---

## 第 10 步：第四个相关检查 —— `reviewer-gate.sh`

### 你写什么

脚本：`review.md` 是否存在；是否声明 `high_risk_count`；若 HIGH>0 则失败。

### 为什么现在写它

有 skill 仍可能「写了 review 但没结论」。gate 把「审查发生过且没有未处理 HIGH」变成可检查的关卡。

注意：这个 gate **不判断代码好不好**（那是推断）。它只检查审查工件是否按合同存在。好不好仍由人读 `review.md`。

### 对照标本读

- `learning_objectives/scripts/reviewer-gate.sh` 开头：它要求哪些字段（扫 usage / 前 80 行）

### 做到什么算完成

缺 `review.md` 会红；补上一份 `high_risk_count: 0` 的会绿（字段名你自己定，与模板一致即可）。

---

## 第 11 步：薄 hook（可以稍晚，但概念要在 v0 结束前搞懂）

### 你写什么

Cursor 项目里：

- `.cursor/hooks.json` 只调用你的一个包装脚本
- 包装脚本再去调已有 gate（例如：在 `git commit` 业务仓之前跑 `allowed-paths` + `confidence-gate`）

若你还不想碰 Cursor hook 配置：至少在 `docs/` 写清「哪些检查必须在 commit 前发生」，并在 `AGENTS.md` 写「commit 前跑这些脚本」。然后**读**标本的 hook 合同，理解能力边界。

### 为什么现在才写 / 才读

前 10 步的 gate 都是**拉式的**：Agent 得想起来去跑。标本栽过的跟头就是：模型一催代码，就不跑 gate。

**hook**：runtime 在某类工具事件上自动执行的脚本（例如 shell 将要执行前、文件已编辑后）。

关键事实（必须记住）：

| 事件 | 能不能挡住「已经发生的事」 |
|---|---|
| 执行 shell 前（beforeShell / PreToolUse） | 能挡住 `git commit` / 危险命令 |
| 文件已经改完（afterFileEdit / PostToolUse） | **不能撤销已写盘**，只能报警、拦下一步 |

所以：真正的硬拦截放在 **commit 前**，不要幻想「编辑 hook 能当撤销」。

### 对照标本读

- `learning_objectives/docs/architecture/hook-lifecycle-contract.md` 第 1～4 节（状态表 + can_block）
- `learning_objectives/hooks/cursor-before-shell-execution.sh` 扫一眼它是否只做转发

### 这一步的词

**adapter / 适配**：Cursor 的 hook 文件只做接线，逻辑仍在 `scripts/`。换 Codex 时再接一根线，不把检查复制两份。

**推式 vs 拉式**：hook 推着跑；「请记得执行 scripts/xxx」是拉。标本诊断说关键安全必须推式。你的 v0 至少对 `git commit` 做到推式，或诚实地写「尚未接线，commit 前人工跑」。

### 做到什么算完成

你能讲清 gate 和 hook 的差别，并且知道哪一种事件能物理阻断。接线可稍后，概念不能糊。

---

## 第 12 步：用一件真小事跑通，然后停

拿一个**真的**低风险改动（改一句文案、加一条注释、修一个错别字），走 `lanes/tiny.md` 全流程。不要用「给 harness 再加 10 个 gate」当第一次任务。

跑通后 v0 就这些文件：

```text
AGENTS.md
lanes/tiny.md
templates/spec.md
templates/harness-status.md
templates/evidence.md
templates/review.md
skills/reviewer/SKILL.md
scripts/confidence-gate.sh
scripts/allowed-paths.sh
scripts/assumption-leak-gate.sh
scripts/reviewer-gate.sh
changes/<一次真实id>/   上述实例
.cursor/hooks.json        若已接线
```

**到这里为止不要做的：** 技术方案全家桶、飞书、38 个 gate、agent-registry、evals、ECC、superpowers 插件。

---

## 2. 词表（遇到再查，不必先背）

按你在路径里出现的顺序。详细解释在对应步骤里。

| 词 | 人话 |
|---|---|
| harness | 套在模型外面的规矩和检查，让 AI 按工程方式干活 |
| 控制面 | 这份规矩仓库本身，不放业务代码 |
| runtime | Cursor / Codex 等真正执行 loop 的程序 |
| AGENTS.md | 给 Agent 的入口目录 |
| 变更包 | `changes/<id>/`，一次工作的文件集合 |
| 工件 | 变更包里约定的那些文件 |
| FACT/ASSUMP/QUESTION | 事实 / 猜测 / 必须问人 |
| **gate** | 条件不满足就失败的检查脚本（关卡） |
| fail-closed | 说不清就失败 |
| 状态卡 | 给人看现在走到哪、卡在哪 |
| 停止点 | 必须停、不能装做没看见 |
| 证据 | 本轮命令和结果，不是口头「过了」 |
| allowed paths | 这次能改的路径白名单 |
| 约束 Constraints | 什么不能碰 |
| lane | 某类任务的默认步骤清单 |
| skill | 可复用角色说明书 |
| Reviewer | 只读审查角色 |
| hook | 工具事件上自动跑的脚本 |
| 适配 adapter | 把 Cursor/Codex 接到同一套 scripts |
| 拉式 / 推式 | 想起来才跑 / 事件一到就跑 |
| Guides / Sensors | 喂给模型的说明 / 跑完压回来的检查 |

标本里暂时**不要深究**的词（看到当「他们的加厚」即可）：Tier M/L、Optional Pack、Test Agent、contract v0.1、Feishu sync、gate-registry L0–L3 全表、agent-registry、golden eval、CodeGraph。

---

## 3. 第 12 步之后（仍不按周，仍由浅入深）

v0 跑通、你不再问「gate 是什么」之后，按需加厚，一次只加一类：

1. 从标本读「三类停止点」全文（工作流文档里那一张表），看你的状态卡要不要拆成三类。
2. 若痛点是「没确认方案就写代码」：再学 `business-code-start-gate`（开工前门，会串起方案确认 + 路径 + 分支）。仍只读这一个脚本的 usage，不要顺带打开邻文件 20 个。
3. 若痛点是「假完成」：给 evidence 加一个极小 gate（必须有本轮命令）。这就是以后 superpowers 的 verification-before-completion。
4. 再读标本诊断里「拉式门禁 / 规则不跟随业务仓」——那是 v1 问题，不是 v0 文件清单。
5. 然后才是比较笔记里的 superpowers / ECC 精进清单。

---

## 4. 和「先读三份架构再动手」的关系

可以先翻 `docs/architecture/harness-workflow-and-design-principles.md` 的「五层」和「三类停止点」两节，建立地图。  
**不要**等读完 38 个 gate、全部模板再写第 1 个文件。

读是为了走路不迷路；写才是学习。下一步就是第 1 步：在你自己的 harness 目录写下第一份短 `AGENTS.md`。若你希望下一步在这个仓库里直接起草那份文件，说一声从哪一个空目录开始即可。
