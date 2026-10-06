# 各 runtime 如何接到 `hooks/hook_adapter.sh`

> 本仓**不提交**各 runtime 的接线文件：`.cursor/hooks.json`、`.codex/hooks.json`、`.opencode/plugins/*.ts`（OpenCode V2）。  
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

> **V1 的 plugin API 在 V2 不运行。** V2 用 `Plugin.define({ id, setup })`，hook 通过 `ctx.tool.hook("execute.before", ...)` 注册，回调收到一个可变的 `event`（`event.tool` / `event.input`）。deny 仍然是 `throw`。见 [V2 plugin 迁移指南](https://opencode.ai/v2/docs/build/plugins/migrate-v1)。

OpenCode **不读** `hooks.json`。官方机制是 plugin（TypeScript / JavaScript）；V2 自动加载 `.opencode/plugins/` 下的文件。plugin 里 spawn `hooks/hook_adapter.sh`，并传入不同参数：

| 工具 | `spawnSync` 的 argv |
|---|---|
| `bash` / `shell` | `["opencode", "beforeShellExecution"]` |
| `write` / `edit` | `["opencode", "afterFileEdit"]` |

不要直接调 runner，方便以后改路由。

1. 在项目根创建 `.opencode/plugins/rz-hook-adapter.ts`（本机文件，不提交；V2 也接受 `.js`）：

```typescript
import { Plugin } from "@opencode/plugin"
import { existsSync } from "node:fs"
import { spawnSync } from "node:child_process"
import path from "node:path"

function resolveHarnessRoot(workspaceDir: string): string {
  if (process.env.RZ_HARNESS_ROOT) {
    return process.env.RZ_HARNESS_ROOT
  }
  const candidates = [workspaceDir, path.resolve(workspaceDir, "..")]
  for (const candidate of candidates) {
    if (existsSync(path.join(candidate, "hooks/hook_adapter.sh"))) {
      return candidate
    }
  }
  return workspaceDir
}

function runAdapter(root: string, event: string, payload: unknown) {
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

export default Plugin.define({
  id: "rz-hook-adapter",
  async setup(ctx) {
    const root = resolveHarnessRoot(ctx.location.directory)
    await ctx.tool.hook("execute.before", (event) => {
      const tool = String(event.tool || "").toLowerCase()
      const input = (event.input ?? {}) as Record<string, unknown>
      let mapped: { event: string; payload: Record<string, unknown> } | null = null
      if (tool === "bash" || tool === "shell") {
        mapped = {
          event: "beforeShellExecution",
          payload: {
            hook_event_name: "beforeShellExecution",
            command: input.command ?? input.cmd ?? "",
            cwd: input.directory ?? input.cwd ?? ctx.location.directory,
          },
        }
      } else if (tool === "write" || tool === "edit") {
        mapped = {
          event: "afterFileEdit",
          payload: {
            hook_event_name: "afterFileEdit",
            file_path: input.filePath ?? input.path ?? input.file_path ?? "",
            cwd: ctx.location.directory,
          },
        }
      }
      if (!mapped) {
        return
      }
      const result = runAdapter(root, mapped.event, mapped.payload)
      if (result.permission === "deny") {
        throw new Error(result.agentMessage || result.userMessage || "rz hook_adapter denied this tool call")
      }
    })
  },
})
```

2. 工作区是 **rz-harness** 时，plugin 会沿目录找到 `hooks/hook_adapter.sh`。工作区是业务仓时，还要：

```bash
export RZ_HARNESS_ROOT=/绝对路径/rz-harness
```

3. 重启 OpenCode（或 `opencode service restart`）。deny 时 plugin `throw`，该次工具不执行。

官方：[OpenCode Plugins](https://opencode.ai/v2/docs/plugins/) · [Build a plugin](https://opencode.ai/v2/docs/build/plugins/) · [V1 → V2 插件迁移](https://opencode.ai/v2/docs/build/plugins/migrate-v1)

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
