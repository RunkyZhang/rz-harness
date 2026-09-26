# 各 runtime 如何接到 `hooks/hook_adapter.sh`

> 本仓**不提交**各 runtime 的接线文件：`.cursor/hooks.json`、`.codex/hooks.json`、`.opencode/plugins/*.js`。  
> **两层：** `hooks/hook_adapter.sh` 只路由；`hooks/harness-sensor-runner.sh` 做事（标本同名脚本的 RZ 本地化）。  
> 各 runtime 在事件点 spawn **adapter**，并传入 **不同的两个参数**（runtime + event），stdin 一包 JSON。adapter 再 `exec` runner。怎么接线写在本文，本机按文创建。

工作区必须是本仓库根（`rz-harness`），脚本才能解析到 `gates/` 和 `config/runtime_local.sh`。

旁路：`RZ_HOOK_OVERRIDE=1` 跳过 code-start 瘦身，不跳过危险命令拦截。

## 参数一览（必须显式传入）

`hooks/hook_adapter.sh` **不会**从 JSON 推断事件。四个标本薄脚本合成这一个，靠调用时参数区分：

| runtime | 何时 | 调用 |
|---|---|---|
| Cursor | shell 将执行 | `hooks/hook_adapter.sh cursor beforeShellExecution` |
| Cursor | 文件已改完 | `hooks/hook_adapter.sh cursor afterFileEdit` |
| Codex | 工具将执行 | `hooks/hook_adapter.sh codex PreToolUse` |
| Codex | 工具已执行 | `hooks/hook_adapter.sh codex PostToolUse` |
| OpenCode | `bash` / `shell` 将执行 | `hooks/hook_adapter.sh opencode beforeShellExecution` |
| OpenCode | `write` / `edit` 将执行 | `hooks/hook_adapter.sh opencode afterFileEdit` |
| 本机自检 | — | `hooks/hook_adapter.sh plain <event>` |

OpenCode 没有 `hooks.json`：上面两行参数写在 plugin 的 `spawnSync(script, ["opencode", event])` 里，见下文。

---

## Cursor

1. 工作区设为 **Trusted**，否则 hook 不跑。
2. 在项目根创建 `.cursor/hooks.json`（本机文件，不提交）。**每条 command 带齐两个参数：**

```json
{
  "version": 1,
  "hooks": {
    "beforeShellExecution": [
      { "command": "hooks/hook_adapter.sh cursor beforeShellExecution" }
    ],
    "afterFileEdit": [
      { "command": "hooks/hook_adapter.sh cursor afterFileEdit" }
    ]
  }
}
```

路径相对**仓库根**。

3. 可选：把 `failClosed` 设为 `true`，避免脚本崩溃时 Cursor 默认放行。
4. 打开 Agent 会话，让它跑一条无害命令（如 `ls`），再故意 `git reset --hard`（应被 deny）。也可看 Cursor Hooks 输出面板确认已加载。

官方：[Cursor Hooks](https://cursor.com/docs/hooks)

---

## Codex

1. 项目根创建 `.codex/hooks.json`：

```json
{
  "hooks": {
    "PreToolUse": [
      { "type": "command", "command": "hooks/hook_adapter.sh codex PreToolUse" }
    ],
    "PostToolUse": [
      { "type": "command", "command": "hooks/hook_adapter.sh codex PostToolUse" }
    ]
  }
}
```

若你本机 Codex 的 schema 要求 `matcher` 或不同的 `command` 字段，以 Codex `/hooks` 界面为准，**command 仍指向** `hooks/hook_adapter.sh`，参数带 `codex` 和事件名。

2. 在 Codex 的 `/hooks` 里 **review / trust** 这份子项目 hook，否则不执行。
3. 不要改 `~/.codex` 全局配置，除非用户二次确认。

---

## OpenCode

OpenCode **不读** `hooks.json`。官方机制是 plugin（JavaScript / TypeScript），启动时加载 `.opencode/plugins/`。plugin 里 spawn `hooks/hook_adapter.sh`，并传入不同参数：

| 工具 | `spawnSync` 的 argv |
|---|---|
| `bash` / `shell` | `["opencode", "beforeShellExecution"]` |
| `write` / `edit` | `["opencode", "afterFileEdit"]` |

不要直接调 runner，方便以后改路由。

1. 在项目根创建 `.opencode/plugins/rz-hook-adapter.js`（本机文件，不提交）：

```javascript
import { existsSync } from "node:fs"
import { spawnSync } from "node:child_process"
import path from "node:path"
import { fileURLToPath } from "node:url"

function resolveHarnessRoot(pluginDir) {
  if (process.env.RZ_HARNESS_ROOT) {
    return process.env.RZ_HARNESS_ROOT
  }
  const candidates = [
    path.resolve(pluginDir, "../.."),
    path.resolve(pluginDir, ".."),
  ]
  for (const candidate of candidates) {
    if (existsSync(path.join(candidate, "hooks/hook_adapter.sh"))) {
      return candidate
    }
  }
  return path.resolve(pluginDir, "../..")
}

function runAdapter(root, event, payload) {
  const script = path.join(root, "hooks/hook_adapter.sh")
  const result = spawnSync(script, ["opencode", event], {
    input: JSON.stringify(payload),
    encoding: "utf8",
    cwd: root,
    env: process.env,
    timeout: 15000,
  })
  const stdout = (result.stdout || "").trim()
  if (!stdout) {
    return { permission: "allow" }
  }
  try {
    return JSON.parse(stdout)
  } catch {
    return { permission: "allow" }
  }
}

function mapBefore(input, output) {
  const tool = String(input.tool || "").toLowerCase()
  const args = output.args || {}
  if (tool === "bash" || tool === "shell") {
    return {
      event: "beforeShellExecution",
      payload: {
        hook_event_name: "beforeShellExecution",
        command: args.command || args.cmd || "",
        cwd: args.directory || args.cwd || process.cwd(),
      },
    }
  }
  if (tool === "write" || tool === "edit") {
    return {
      event: "afterFileEdit",
      payload: {
        hook_event_name: "afterFileEdit",
        file_path: args.filePath || args.path || args.file_path || "",
        cwd: process.cwd(),
      },
    }
  }
  return null
}

export const RzHookAdapter = async () => {
  const pluginDir = path.dirname(fileURLToPath(import.meta.url))
  const root = resolveHarnessRoot(pluginDir)
  return {
    "tool.execute.before": async (input, output) => {
      const mapped = mapBefore(input, output)
      if (!mapped) {
        return
      }
      const result = runAdapter(root, mapped.event, mapped.payload)
      if (result.permission === "deny") {
        throw new Error(result.agentMessage || result.userMessage || "rz hook_adapter denied this tool call")
      }
    },
  }
}
```

2. 工作区是 **rz-harness** 时，plugin 会沿目录找到 `hooks/hook_adapter.sh`。工作区是业务仓时，还要：

```bash
export RZ_HARNESS_ROOT=/绝对路径/rz-harness
```

3. 重启 OpenCode。deny 时 plugin `throw`，该次工具不执行。

官方：[OpenCode Plugins](https://opencode.ai/docs/plugins/)

---

## 本机自检（不经过 runtime）

```bash
# 应 PASS
printf '%s' '{"command":"ls"}' | hooks/hook_adapter.sh plain beforeShellExecution

# 应 FAIL（危险命令）
printf '%s' '{"command":"git reset --hard"}' | hooks/hook_adapter.sh plain beforeShellExecution

# 也可直接打 runner（跳过路由）
printf '%s' '{"command":"ls"}' | hooks/harness-sensor-runner.sh plain beforeShellExecution
```

需要路径检查时，先 `export RZ_CHANGE_SPEC=changes/<id>/spec.md`，再喂带 `file_path` 的 JSON。
