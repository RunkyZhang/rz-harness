# learning_objectives 第一轮回复存档

> 日期：2026-08-29  
> 用途：把当轮对话里对 `learning_objectives` 的三点回答落成文件，方便后面分段追问、查缺补漏。  
> 不要把本文当成 `learning_objectives` 的权威说明；权威仍以那份 harness 仓库内文档为准。  
> 对照图（可在 Cursor 聊天旁打开）：[`learning-objectives-deconstruction.canvas.tsx`](/Users/00545579/.cursor/projects/Users-00545579-Documents-codes-rz-rz-harness/canvases/learning-objectives-deconstruction.canvas.tsx)

待拍板（当时提出、尚未回答）：

1. 自己的 harness 服务谁？几个仓、什么技术栈？
2. 先挂哪个 runtime？（建议先 Cursor-only）
3. 最痛的是哪一类：未确认假设进代码 / 改到范围外 / 假完成？
4. 抽原则自建，还是 fork `learning_objectives` 再删？

---

能一起学几个月。先把三点答完。

对照图放在上面的 canvas 链接，可以在聊天旁边打开，后面几个月都能对着看。Canvas 是 Cursor 里一份可交互的侧边面板，适合这种要长期对照的架构图，而不是一次性塞进聊天。

---

## 1. `learning_objectives` 也是 harness，但和 Cursor / Codex / OpenCode 不是同一类

**是 harness。** 行业里现在说的 harness，本来就不等于「一个可执行的 agent 内核」。

更准确的公式是：

**Agent = Model + Runtime Harness + Control-Plane Harness**

| | Runtime（Cursor / Codex / OpenCode） | Control Plane（`learning_objectives`） |
|---|---|---|
| 是什么 | 可执行核心：agent loop、工具、沙箱、权限引擎 | 团队工程控制面：事实源、规则、模板、gate、状态卡 |
| 有没有核心文件 | 有。IDE / CLI / 桌面进程就是它 | **没有。** 核心是 Markdown + shell gate + 薄 adapter |
| 强制力 | 工具层 deny / ask / allow、sandbox、hook 退出码 | 流程层 fail-closed gate + 用户可见停止点 |
| 知不知道你的业务 | 不知道你的仓、契约、环境 | 知道：10 个业务仓、baseline、UI 规则、飞书同步 |

Fowler 的定义是 **Agent = Model + Harness**，并把 harness 拆成 Guides（喂给模型的规则）和 Sensors（跑完再压回来的检查）。OpenAI 讲的 Harness Engineering 也是 `AGENTS.md` + 结构测试 + 知识进 repo，不是再写一个 Codex。

所以你的观察对了一半：它确实没有传统那种可执行核心；**错的一半是「没有核心就不算 harness」**。它故意不造 runtime，而是挂在已有 runtime 上面。`opencode.json`、`.cursor/hooks.json`、`.codex/hooks.json` 都只是薄适配，真正逻辑在 `scripts/` 和 `AGENTS.md`。

一句话：**Cursor 负责「能跑」；`learning_objectives` 负责「在边界里跑，不清楚就停」。**

---

## 2. 解构：不要按文件夹记，按五层记

这套东西自己的定位写得很清楚：

> 不是让 AI 多写代码，而是让 AI 在清晰、可验证、可回滚的边界内持续推进，不清楚或风险升高时及时停止。

### 五层（做自己的 harness 时抄这个，不要先抄 38 个 gate）

1. **Instructions** — 告诉 Agent 怎么做：`AGENTS.md`（短入口，像目录不是百科）、`docs/`、`rules/`、`templates/`、`lanes/`、`skills/`
2. **Constraints** — 什么不能碰、何时必须停：protected paths、`allowed_paths`、权限配置、hooks
3. **Sensors** — 用脚本反向校验，不靠模型「记得」：`scripts/*-gate.sh`（登记了 38+ 个），先确定性（compile / lint / gate），再推断性（Reviewer / Test Agent）
4. **Memory** — 事实进 repo：`docs/`、contracts、decision-log、`changes/<id>/evidence.md`。明确不上 RAG
5. **Orchestration** — 把阶段、角色、状态卡、复盘串起来：`harness-status.md`、`agent-registry.yml`、lane、retro

### 三块能力

- **知识控制面**：仓在哪、规则是什么、Agent 能做什么
- **端到端交付**：一次变更一个包 `changes/<change-id>/`，状态卡驱动，不靠聊天历史
- **评测反馈**：golden / replay / telemetry，用来衡量 harness 自己稳不稳。做自己的 MVP 时可以最后做

### 交付主线和三类停止点

```text
status → spec → contract → solution → AI test plan → env
     → plan → code → Main tests → Test Agent → report → reviewer → PR → retro
```

用户说「开始开发 / 确认 / ok」只推进到**下一个已满足的 gate**，不豁免技术方案、环境、Test Agent、Reviewer。

| 停止点 | 触发 | 机制 |
|---|---|---|
| 业务口径不清 | 字段、状态、权限、错误码无法从 PRD/代码/契约证明 | `[FACT]` / `[ASSUMP]` / `[QUESTION]` + `confidence-gate` |
| 工程边界不安全 | 生产配置、secrets、migration、主分支、范围外 dirty diff | `allowed-paths`、`business-code-start`、dirty-worktree |
| 验证证据不足 | 方案、测试、环境、Reviewer 缺失 | 不宣称完成；Main Agent 不能替代 Test / Reviewer |

### 角色很少，权限先于智能

- Orchestrator：唯一控制面可写
- Explorer / Reviewer：默认只读
- Test Agent：只验收，不能宣称实现完成
- Backend / Frontend / Mobile：默认 **candidate**，要契约 + 隔离 worktree 才启用

### 自己做时：抄什么、先别抄什么

**必须抄的机制：** 短 `AGENTS.md`、一次变更一个包、FACT/ASSUMP/QUESTION、4–6 个 L3 硬安全门、状态卡、只读 Reviewer。

**按你的业务重写：** `rules/`、`docs/baseline/`、repo registry。

**先别抄：** 38 个 gate 全量、飞书同步、SFA 的 Vue2/Java/iOS 细则、evals/telemetry、多实现 agent 并行。

---

## 3. 学习计划（按周的旧表）

> 已替换为「从 0 写文件、用到再查词」的路径，见 [04-由浅入深学习路径-从0按标本写harness.md](04-由浅入深学习路径-从0按标本写harness.md)。下面旧表仅作索引，不再按周执行。

原则：**先读机制，再走通一次别人的闭环，最后用最小子集做自己的。不要从复制 `scripts/` 开始。**

| 阶段 | 做什么 | 产出 |
|---|---|---|
| Week 0–1 心智模型 | 精读 `AGENTS.md`、`README.md`、`docs/architecture/harness-workflow-and-design-principles.md` | 一页「我理解的 harness」 |
| Week 2 只读走闭环 | 对照 `lanes/fullstack-crud.md` + `change-artifacts-spec.md`，把阶段、工件、gate 对上 | 「阶段 × 工件 × gate」对照表 |
| Week 3 解剖 Sensors | 只精读 6 个 L3：confidence、assumption-leak、allowed-paths、business-code-start、environment-readiness、diff-hygiene | 每张卡片写清：拦什么、读什么、失败怎么修 |
| Week 4 角色与权限 | `config/agent-registry.yml`、`subagent-dispatch.md`、`skills/explorer`、`skills/reviewer` | 自己 harness 的角色清单（建议 ≤4 个） |
| Week 5–6 适配层 | `hook-lifecycle-contract.md`、`hooks/`、`opencode.json` | 你选的 runtime 适配草图 |
| Week 7–8 自己的 v0 | 短 AGENTS + 1 个 lane + tier-s 三件套 + 4 个 L3 gate + 1 个只读 Reviewer | 用一个真实低风险需求跑通 |
| Week 9+ 按痛点加厚 | 每两周只加一类 pack；重复犯错才加规则 | changelog：加的是机制还是又一条「请记住」 |

---

## 需要你先拍板的 4 件事

这四项会决定后面几个月读哪些文件、先写哪一层：

1. **自己的 harness 服务谁？** 几个仓、什么技术栈？和 SFA（Vue2 + Java 多仓）一样，还是另一套产品？
2. **先挂哪个 runtime？** 建议先 Cursor-only，Codex / OpenCode 以后再加薄适配。
3. **你最痛的是哪一类？** 「把没确认的假设写进代码」 / 「改到范围外」 / 「模型说做完了其实没验证」——这决定第一批 gate 抄哪几个。
4. **目标形态？** 抽原则自建一个更瘦的控制面，还是 fork `learning_objectives` 再删？更建议前者，否则很容易把 SFA 的 38 个 gate 一起背回来。

回这四项之后，下一轮建议直接精读 Week 0–1 那三份入口文档，并一起写出「一页理解」。
