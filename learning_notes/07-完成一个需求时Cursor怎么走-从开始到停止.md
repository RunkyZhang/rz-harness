# 完成一个需求时 Cursor 会怎么走（标本流程）

> 日期：2026-08-29  
> 用途：在「执行 Agent 是 Cursor、工作区是 rz-harness、你丢来一份需求文档」这个假设下，讲清：目录对不对、先看什么、整条流程、何时停止。  
> 这是标本 `learning_objectives` 的设计流程，不是我们已经写好的自建 harness。

---

## 1. 工作区到底该打开哪一层？

**可以用 rz-harness。不是 Cursor 禁止这一层，是标本把「仓库根 = 控制面根」写死了，而现在 rz-harness 比控制面多包了一层。**

已拍板（用户 2026-08-29）：

- **不改** `learning_objectives/`，保持原始标本只读，专门用来学。
- **要写的 harness 就是 rz-harness 根目录**（以后的 `AGENTS.md`、`scripts/`、`changes/` 都在这一层）。
- **学成后**会删掉 `learning_objectives/` 和 `learning_notes/`，仓库里只留自己的 harness。

因此学习期间 **一直 Open rz-harness 即可**，不必为了跑标本再去 Open 内层。脚本若要对照标本，由我在命令里写 `learning_objectives/scripts/...`，不把标本当工作区根。

Cursor 的工作区 = 你 Open 的文件夹。Agent 默认在这一层找 `AGENTS.md`、`.cursor/hooks.json`。

现在磁盘上是这样（学成后后两层会删掉）：

```text
rz-harness/                          ← 始终 Open 这一层；成品也写在这一层
  AGENTS.md                          ← 现在空；以后是你的入口
  learning_notes/                    ← 学习期；学成删除
  learning_objectives/               ← 只读标本；学成删除
    AGENTS.md、scripts/、templates/、.cursor/...
```

读标本时：他们文档里的 `scripts/xxx.sh` 在我们这里对应 `learning_objectives/scripts/xxx.sh`。写你的 harness 时：路径就是根上的 `scripts/`、`changes/`，不再经过内层。

业务仓（mapSystem 等）永远不是工作区，只是被改的代码。

下面第 2 节按标本自己的假设讲「控制面根上的流程」。对照时把路径加上 `learning_objectives/` 即可。



---

## 2. 标本设计：从需求文档到停止

假设：工作区 = 控制面根（`learning_objectives` 的内容在根上）、`config/repos.local.sh` 已配好、你是用户、我是 Cursor 里的主 Agent。

你丢来：一份需求文档（Markdown / 飞书链接 / 截图均可）。

### 2.1 开始：还不改业务代码

**第一件事不是写代码。** 标本要求（中/重、跨仓、后端行为、DB、复杂 UI）：我给你的**第一条回复**就要带「本次 harness 流程和停止点」，并开始用状态卡。

我会先读这些（控制面里，不是业务仓）：

| 顺序 | 文件 | 为什么 |
|---|---|---|
| 1 | `AGENTS.md` | 硬规矩、停止点、禁止项 |
| 2 | `docs/architecture/repo-registry.md` | 需求可能落在哪几个仓 |
| 3 | `docs/skills-routing.md` | 要不要先读 grill / explorer |
| 4 | `lanes/fullstack-crud.md` 或 `bugfix-fast.md` | 选一条任务路线 |
| 5 | 你的需求文档 | 抽 FACT / ASSUMP / QUESTION |

然后在控制面里**新建变更包**（还不碰业务仓）：

```text
changes/<change-id>/
  spec.md              ← 从 templates/spec-tier-*.md 复制
  status.md            ← 标本文件名是 harness-status.md
  （后面按档位再加）
```

`change-id` 用业务含义，例如 `promo-sku-unit`，不用 `pilot-crud-tbd`。

### 2.2 主线（中/重全栈需求）

```text
你给需求
  → 选 change-id + lane
  → 写 spec（三标签 + allowed_paths）     【停】有阻塞 QUESTION / 未确认 ASSUMP 就问你
  → API 契约
  → 全栈技术方案                          【停】等你确认；飞书 PRD 还要同步子文档
  → 独立角色写 AI 测试方案                【停】等你确认
  → 环境是否 READY（真 E2E 才强制）       【停】账号/数据/DB 边界不清
  → plan / verification-map / 状态卡
  → 开工检查（spec 关卡 + 路径 + 分支）    【停】gate 不过
  → 主 Agent 在业务仓实现（codex/<id> 分支，禁止 main）
  → 常规 compile / 单测 / lint，写入 evidence
  → 命中才做：UI / E2E / 影响分析 / 并行
  → Test Agent 对照测试方案验收           【停】BLOCKED；未 GOAL_ACHIEVED 主 Agent 不准说做完
  → AI 测试报告                           【停】进测试/预发前要你确认
  → 只读 Reviewer，high_risk = 0          【停】有 HIGH 回去改
  → 交给你人审 / PR
  → retro，变更包收口                     【停止工作】
```

你说「开始开发 / 下一步 / 确认 / ok」时：我**只走到下一个已经满足的关卡**，不能拿这句话跳过方案确认、开工检查、验收、审查。

### 2.3 每一段我在干什么、看什么、何时停

**A. 弄清需求（还在控制面）**

- 做：把 PRD 拆进 spec；标 FACT/ASSUMP/QUESTION；列出可能改的仓和路径。
- 看：需求文档；目标仓的 `docs/baseline/<仓>.md`；必要时 `skills/grill`、只读 explorer（业务仓只读）。
- 停：字段、状态、权限、错误码、默认值、回滚在 PRD/代码里找不到出处 → 写成 QUESTION 问你，**不写业务代码**。

**B. 契约和方案（仍在控制面）**

- 做：`docs/contracts/<id>-api.md` 或变更包里的 contract；`technical-solution.md` 覆盖 PRD 里每一面（前端/后端/导出…），不能只写后端。
- 跑：`scripts/technical-solution-gate.sh`；飞书来源再跑同步脚本。
- 停：你没把方案标成 CONFIRMED；或本地改了方案却没再同步飞书。

**C. 测试策略（独立角色，不是我自评）**

- 做：另一套 prompt/子 Agent 写 `ai-test-plan.md`。
- 跑：`scripts/ai-test-plan-gate.sh`。
- 停：你没确认测试方案 → **仍不准实现**。

**D. 开工前（第一次改业务文件之前）**

- 做：业务仓从 main 拉 `codex/<change-id>`；填 allowed_paths；若工作区已有别人的脏改动，先记台账。
- 跑：`confidence-gate`、`assumption-leak-gate`、`allowed-paths`、`business-code-start-gate`。
- 看：`config/repos.local.sh` 里的真实路径（这份文件不进 git）。
- 停：还在 main 上、路径越界、方案未确认、QUESTION 未清。

**E. 实现（业务仓 + 控制面证据）**

- 做：只改白名单；窄范围编译/测试；命令写进 `evidence.md`；更新状态卡。
- 看：目标仓样板代码（baseline 里点名的文件），不是凭空写一套风格。
- 停：要动 `.env`、生产配置、migration、宽 DELETE → 二次确认；高危 SQL 直接禁止。

**F. 验收与审查（我不能自己宣布成功）**

- Test Agent：维护 `test-agent-verification.md`，对照已确认的测试计划，PASS 或 BLOCKED。
- 若实现后又改了代码：旧验收作废，重跑。
- Reviewer：只读，写 `review.md`，跑 `reviewer-gate.sh`。HIGH>0 回去改。
- 停：没有独立验收通过、没有审查过门，主 Agent **不得说需求已完成**。

**G. 交给你之后**

- 人审、PR、SIT。
- 写 retro，按保留策略清理大文件。
- **停止工作：** 状态卡收到口，或状态是 BLOCKED 且最小缺口已写清、等你决策。不是模型说「我写完了」就算停。

### 2.4 轻量需求会短很多

若只是单仓小修（标本 Tier S / 我们说的 tiny）：

```text
spec + 状态卡 + evidence
→ spec 关卡 + 路径关卡
→ 改代码
→ 证据
→ Reviewer（轻量甚至可弱化，标本 S 档不强制技术方案全家桶）
→ 你确认
```

没有契约、没有飞书同步、没有 Test Agent，不代表没有停止点：QUESTION 没答、改到名单外，一样停。

---

## 3. 今天在这个对话里，你丢给我一份需求，我会怎样？

当前工作区是 **rz-harness 学习外壳**，根 `AGENTS.md` 为空。因此我**不会**自动当成 SFA 控制面主 Agent 去改 `mapSystem` / Java 仓。

我会：

1. 读你的需求，判断你要的是 **学习演练** 还是 **真交付**。
2. 若是学习：按 04 的步骤，只在 `learning_notes` 或将来你指定的自建目录里写 spec/状态卡，**不碰业务仓**。
3. 若你明确说「按标本在 `learning_objectives/changes/` 走一遍纸面流程」：只建变更包和 QUESTION，仍然不改业务代码，除非你另外打开控制面根并配好 `repos.local.sh`。
4. 若需求其实是「继续学 harness」：停在 QUESTION/笔记，不假装已经在做 SFA 功能。

**今天的停止条件**更简单：事实不够就问你；没有控制面根 + 本地仓配置，就不开工改业务代码。

---

## 4. 和你三个假设的对照

| 你的假设 | 结论 |
|---|---|
| 执行 Agent 是 Cursor（我） | 对。runtime 是 Cursor。 |
| 让我进入 rz-harness | **能用，学习就用这一层。** 不是禁止。标本假设「工作区根 = 控制面根」，所以要按他们的路径原样跑脚本/hook，再 Open `learning_objectives`。 |
| 给我一份需求文档 | 对，那是输入。下一项不是写代码，是变更包 + spec + 问清 QUESTION。结束不是「文件写完」，是状态卡收口或 BLOCKED 等你。 |

若你下一步想「拿一份假需求走一遍纸面流程」，用 tiny 档即可：一份短 PRD → 只练 spec / 状态卡 / 停止点，仍然不要上 38 个 gate。
