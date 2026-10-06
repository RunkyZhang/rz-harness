# hook 是什么、与 gate 的关系

> 日期：2026-09-13
> 用途：搞懂 hook 与 gate 的区别、hook 的能力边界、以及它对 agent 工具的技术原理。
> 对照：[06-领域名词总表-为什么用这个词用来做什么.md](06-领域名词总表-为什么用这个词用来做什么.md) §6「接线」

---

## 一句话

**hook = runtime（Cursor / Codex / opencode）在生命周期事件点上自动执行的外部脚本。**
**gate = 一段确定性检查脚本（exit code 判过/不过）。**
两者不是同类：**hook 是「何时自动触发」，gate 是「检查什么内容」。**

---

## 一、hook 是 runtime 的机制，不是 harness 自己的

runtime 在执行过程中会抛出**生命周期事件**，你可以在这些点上挂脚本：

| 事件 | 时机 | Cursor 里的名字 |
|---|---|---|
| PreToolUse | 工具**执行前**（要跑 shell / `git commit` 前） | `beforeShellExecution` |
| PostToolUse | 工具**执行后**（文件已改完） | `afterFileEdit` |
| SessionStart / Stop / PreCompact | 会话开始 / 结束 / 压缩上下文前 | 部分工具未支持 |

harness 不实现这些事件；它只做两件事：**在事件点挂脚本（接线）+ 脚本里的逻辑**。

## 二、关键：pre vs post 的能力天差地别

| | 能拦住吗 | 能改参数吗 |
|---|---|---|
| **pre（动作前）** | ✅ 能**硬停**——拦 `git commit`、危险命令 | ✅ 能改 / 阻断 |
| **post（动作后）** | ❌ **不能撤销**（文件已写盘），只能报警、拦**下一步** | ❌ 改不了已发生的 |

标本用 `can_block` 描述这个语义（`pre` / `post` / `none`）。
**结论：真正的硬拦截必须放 pre。** 别幻想“编辑完的 hook 能当撤销”。

## 三、hook 和 gate 的关系

```
gate = 检查内容（脚本，exit 0 过 / 非 0 停）
hook = 何时自动跑（runtime 在事件点调用脚本）
```

- **hook 可以调 gate，但 hook 本身不是 gate。**
- 一个 gate 能被两种方式触发：
  - **hook 推式**：事件点自动跑
  - **人 / agent 拉式**：主动执行 `scripts/xxx-gate.sh`
- “gate 像检查做的事”——对；但“自动拦”这件事是 hook 干的，不是 gate。

## 四、推式 vs 拉式

| | 怎么跑 | 忘了会怎样 |
|---|---|---|
| **拉式** | 人 / agent 主动跑 `scripts/xxx-gate.sh` | 忘了 = 没限制 |
| **推式** | hook 在事件点自动调同一脚本 | 忘了也拦得住 |

标本诊断过的问题：**关键安全门是拉式的**（靠 agent 记得跑），所以“没确认方案也能改代码”。hook 就是把拉式变推式。

> **它是专业术语吗？**
> `push` / `pull` 是软件/系统设计的通用术语（push notification、push-based vs pull-based）。
> 但**“拉式门禁 / 推式门禁”这个组合是标本的引申用法**，不是标准术语——借 push/pull 类比“自动触发 vs 主动调用”。CI 里的对应是 `pre-commit hook`（推式）。

## 五、hook 到底挂多少 gate？（标本做法）

**不是所有 gate 都走 hook。** 查标本 `scripts/harness-sensor-runner.sh`：它只调用了 **1 个 gate**（`allowed-paths.sh`），其余是**内联**的轻量检查。

runner 的 usage 原文：

> Heavy checks such as Maven, npm build, PC E2E, and golden eval **stay in lane/pre-PR flows**.

| 检查 | 触发方式 | 推/拉 |
|---|---|---|
| 危险命令拦截 | hook（shell 前，内联） | **推** |
| 飞书同步门禁 | hook（shell 前，内联） | **推** |
| code-start 门禁 | hook（shell 前 / 编辑后，内联） | **推** |
| `allowed-paths.sh` | hook（编辑后，**唯一被调的 gate**） | **推** |
| confidence / technical-solution / ai-test-plan / business-code-start / reviewer / diff-hygiene / temp-hardcode-scan | 流程各阶段 / pre-PR | 拉 |
| Maven / npm / E2E / eval | lane / pre-PR | 拉 |

**规律**：hook 只挂「**关键 + 轻量 + 必须在动作前后自动拦**」的检查；重检查、阶段性检查一律留在流程里拉式跑——因为 hook 是**同步阻塞**的，把 Maven / 构建这类重活塞进去会拖死每一次工具调用。

> **标本的一个瑕疵**：`code_start_block_reason` 是 runner **内联复刻**了 `business-code-start-gate` 的判断（读 technical-solution 字段），和独立 gate 成了两套逻辑。
> → **写自己的 hook 时应尽量让 hook 调 gate，而不是内联复制。**

## 六、hook_adapter（接线层）

> RZ 命名：叫 **hook_adapter**（“接线层”），强调它只做接线、不含检查逻辑。

Cursor / Codex / opencode 的事件名不同，所以：

```
.cursor/hooks.json ─┐
.codex/hooks.json  ─┼─→ hooks/hook_adapter.sh（只路由）→ hooks/harness-sensor-runner.sh（做事）
OpenCode plugin    ─┘
```

配置层**只做接线**，检查逻辑不复制进各工具配置。
标本的 `hooks/cursor-before-shell-execution.sh` 就一行：

```bash
exec "$root/scripts/harness-sensor-runner.sh" cursor beforeShellExecution
```

## 七、hook 的技术实现（纠正一个常见猜测）

常见猜测：*“hook 是个 tool，runtime 告诉 LLM 有这个 tool，LLM 决定调它”* —— **不对**。核心区别在**谁驱动**：

| | 谁决定调用 | 驱动方 |
|---|---|---|
| **tool** | **LLM** 输出 `tool_call` → runtime 执行 → 结果回 LLM | 模型驱动 |
| **hook** | **runtime** 在事件点自动 spawn 外部进程 | runtime 驱动，**不经 LLM 决策** |

**hook 的真实机制：**

1. runtime 到事件点（如 `PreToolUse`）时，**直接执行你配置的命令**
2. 脚本通过 **stdin 收到事件上下文 JSON**（要执行的命令、工具名等）
3. 脚本通过 **exit code / stdout JSON 返回决策**：
   - `exit 0` = 放行
   - 特定非 0 = 阻断
   - stdout JSON = 可改参数 / 注入警告

**“部分对”的地方**：hook 确实能**拦截 LLM 的 `tool_call`**（tool interception）——但决策权在 runtime，不在 LLM：

```
LLM 决定 tool_call（"跑 git commit"）
        │
        ▼
runtime 在该事件点自动 spawn hook 脚本   ← LLM 不参与，甚至不知道
        │  脚本 stdin 收 JSON，返回 exit code / stdout
        ├─ allow → runtime 执行原 tool_call
        └─ block → runtime 不执行，把拒绝信息回给 LLM（LLM 事后才知道）
```

**一句话**：hook 不是“给 LLM 的一个 tool”，而是 **runtime 自带的拦截 / 插桩点**——这正是它比提示词可靠的原因：它绕过了“模型愿不愿意调”。

---

## RZ 现状与落地

- 有 **30 个 gate**（拉式，靠人 / agent 跑）
- **`hooks/` 未建、runtime 未接线** → 目前没有推式拦截
- **RZ 落地（opencode）两条路**：
  - **A. `permission`**（配置级、零代码）：`bash: {"git *":"allow","git commit *":"ask","rm *":"deny"}`、`edit`、`external_directory`——立刻能拦 `git commit` / `rm` / `.env`
  - **B. opencode plugin**（`.opencode/plugin/*.ts`，钩 `tool.execute.before`）：对应标本的 runner，可跑自定义 gate、throw 阻断
- **原则**：hook 只挂**少数关键检查**（危险命令 / allowed-paths / code-start），**不要塞 30 个 gate**；其余照旧拉式
- 改配置 / 插件后需**退出重启 opencode** 才生效

## 出处（标本）

- `learning_objectives/docs/architecture/hook-lifecycle-contract.md`：生命周期矩阵、`can_block` 语义、各工具事件支持差异
- `learning_objectives/AGENTS.md`：hooks 只做 adapter，统一委托 `scripts/harness-sensor-runner.sh`
- `learning_objectives/hooks/*.sh`：包装脚本（`exec` 转发到 runner）
- `learning_notes/06-领域名词总表…md` §6「接线」
