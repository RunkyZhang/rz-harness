# 团队首次使用手册

> 目标：让团队成员在自己的电脑上完成 `sfa-ai-harness` 初始化，明确需要提供哪些本地环境配置，并能跑通最小自检。

## 1. 需要你先准备的信息

首次使用前，请准备下面这些本地路径或命令。没有这些信息时，不要让 Agent 猜路径。

| 配置项 | 用途 | 示例 |
| --- | --- | --- |
| `SFA_HARNESS_ROOT` | 当前控制面仓库路径 | `$HOME/sfa-ai-harness` |
| `SFA_PROJECTS_ROOT` | 业务仓统一父目录 | `$HOME/codex/sfa-projects` |
| `SFA_REPO_BACKEND_SALES_MANAGEMENT` | `sfa-sales-management` 本地路径 | `$SFA_PROJECTS_ROOT/sfa-sales-management` |
| `SFA_REPO_BACKEND_SFA_BACKEND` | `sfa-backend` 本地路径 | `$SFA_PROJECTS_ROOT/sfa-backend` |
| `SFA_REPO_BACKEND_SFA_ROOT` | `sfa-root` 本地路径 | `$SFA_PROJECTS_ROOT/sfa-root` |
| `SFA_REPO_BACKEND_CEO_MEMBER` | `backend-ceo-member` 本地路径 | `$SFA_PROJECTS_ROOT/backend-ceo-member` |
| `SFA_REPO_FRONTEND_MAP_SYSTEM` | `mapSystem` 本地路径 | `$SFA_PROJECTS_ROOT/mapSystem` |
| `SFA_REPO_FRONTEND_SIGN_UP` | `sign-up` 本地路径 | `$SFA_PROJECTS_ROOT/sign-up` |
| `SFA_REPO_FRONTEND_MERCHANT_WECHATAPP` | `merchant-wechatapp` 本地路径 | `$SFA_PROJECTS_ROOT/merchant-wechatapp` |
| `SFA_REPO_FRONTEND_SFAINTL` | `SfaIntl` 本地路径 | `$SFA_PROJECTS_ROOT/SfaIntl` |
| `SFA_REPO_MOBILE_SFA_IOS` | 国内 iOS App 本地路径 | `$SFA_PROJECTS_ROOT/sfa-ios` |
| `SFA_REPO_MOBILE_SFA_ANDROID` | 国内 Android App 本地路径 | `$SFA_PROJECTS_ROOT/sfa-android` |
| `SFA_BACKEND_MAVEN_COMMAND` | 后端 Maven 命令 | `mvn` |
| `SFA_BACKEND_MAVEN_ARGS` | 后端 Maven 固定参数 | `-s /path/to/settings.xml` |
| `SFA_FRONTEND_PACKAGE_MANAGER` | 前端包管理命令 | `npm` |
| `SFA_FRONTEND_PACKAGE_MANAGER_ARGS` | 前端包管理固定参数 | `--foreground-scripts` |
| `SFA_BACKEND_JAVA_MAJOR` | 后端 Java 主版本 | `8` |
| `SFA_FRONTEND_NODE_VERSION` | `mapSystem` 推荐 Node 版本 | `14.21.3` |
| `SFA_FRONTEND_MERCHANT_WECHATAPP_NODE_VERSION` | `merchant-wechatapp` 最低 Node 版本 | `18.18.0` |
| `SFA_FRONTEND_NODE_BIN_DIR` | 可选，指定前端 Node bin 目录 | `$HOME/.nvm/versions/node/v14.21.3/bin` |
| `SFA_FRONTEND_MAP_SYSTEM_DEV_PORT` | `mapSystem` 本地端口 | `9527` |
| `SFA_FRONTEND_SIGN_UP_DEV_PORT` | `sign-up` 本地端口 | `8080` |
| `SFA_FRONTEND_SFAINTL_DEV_PORT` | `SfaIntl` 本地端口 | `9528` |
| `SFA_FRONTEND_DEV_HOST` | 前端 dev server host | `0.0.0.0` |
| `SFA_PC_E2E_USERNAME` | PC smoke 测试账号，仅写入本地 ignored 配置 | 不在文档记录真实值 |
| `SFA_PC_E2E_PASSWORD` | PC smoke 测试密码，仅写入本地 ignored 配置或 Keychain | 不在文档记录真实值 |
| `SFA_PC_E2E_PASSWORD_SOURCE` | PC smoke 密码来源说明 | `local-env` / `keychain` / `browser-session` |
| `SFA_HARNESS_PROXY_HOST` | harness-only 本地代理监听地址 | `127.0.0.1` |
| `SFA_HARNESS_PROXY_PORT` | harness-only 本地代理监听端口 | `19080` |
| `SFA_LOCAL_BACKEND_SALES_MANAGEMENT_URL` | `backend-sales-management` 本地服务地址 | `http://127.0.0.1:31010` |
| `SFA_LOCAL_BACKEND_SFA_BACKEND_URL` | `backend-sfa-backend` 本地服务地址 | `http://127.0.0.1:30080` |
| `SFA_LOCAL_BACKEND_SFA_ROOT_URL` | `backend-sfa-root` 本地服务地址 | `http://127.0.0.1:30081` |
| `SFA_LOCAL_BACKEND_CEO_MEMBER_URL` | `backend-ceo-member` 本地服务地址 | `http://127.0.0.1:9168` |
| `SFA_IOS_SCHEME` | iOS App 构建 scheme | `FProject` |
| `SFA_IOS_CONFIGURATION` | iOS App 构建 configuration | `Debug` |
| `SFA_IOS_SIMULATOR_NAME` | iOS 模拟器名称 | `iPhone 15` |
| `SFA_ANDROID_GRADLE_TASK` | Android 默认构建任务 | `:app:assembleDebug` |
| `SFA_ANDROID_BUILD_VARIANT` | Android 默认构建 variant | `debug` |
| `SFA_ANDROID_AVD_NAME` | Android 模拟器名称 | `harness_api28_arm64` |

## 2. 初始化本地配置

在控制面仓库根目录执行：

```bash
cp config/repos.local.example.sh config/repos.local.sh
vi config/repos.local.sh
source config/repos.local.sh
```

`config/repos.local.sh` 是个人本地配置，已经被 `.gitignore` 忽略，不能提交。

测试账号、测试密码、token 和 cookie 只能放在 `config/repos.local.sh`、系统 Keychain 或已有浏览器登录态中。版本化的 `spec.md`、`plan.md`、`pc-e2e-smoke-report.md`、`evidence.md`、截图说明和 review 文档只能记录“凭据来源已配置 / 未配置”，不能记录明文密码。

确认路径：

```bash
test -d "$SFA_HARNESS_ROOT"
test -d "$SFA_REPO_BACKEND_SALES_MANAGEMENT"
test -d "$SFA_REPO_BACKEND_CEO_MEMBER"
test -d "$SFA_REPO_FRONTEND_MAP_SYSTEM"
test -d "$SFA_REPO_MOBILE_SFA_IOS"
test -d "$SFA_REPO_MOBILE_SFA_ANDROID"
```

如果某个业务仓还没有 clone，请先 clone 到你在 `config/repos.local.sh` 中配置的位置。

## 2.1 本地代理使用前提

PC E2E Smoke 需要访问本地后端时，先确认：

- 已启动本次需要验证的本地后端服务。
- `SFA_LOCAL_BACKEND_*_URL` 指向这些后端的实际本地地址；默认值见上表。
- `--active-backends` 只声明本次真实启动、且会被当前前端访问的后端项目。
- 前端只在 smoke shell 临时使用 `VUE_APP_BASE_API=http://127.0.0.1:19080/`；不要写入 `.env*`，也不要改业务前端源码。
- 未声明的后端项目和其他请求会继续 fallback 到测试/预发环境。

## 2.2 Agent Registry 和 Codex Agent 生成

harness 的 Agent 定义统一放在 `config/agent-registry.yml`。`.opencode/agents/*` 是 OpenCode adapter 文件，Codex 子 Agent 配置由 registry 生成，不能长期散写在临时 prompt 或个人全局目录里。

修改或新增 Agent 后先运行：

```bash
scripts/agent-registry-gate.sh
scripts/codex-agent-generator.sh --dry-run
```

需要生成本仓本地可检查的 Codex 配置时，写到 `.harness/generated/codex-agents` 或其他明确的本地输出目录：

```bash
scripts/codex-agent-generator.sh --output-dir .harness/generated/codex-agents --apply
```

默认不写 `$HOME/.codex/agents`，也不修改 `.codex/config.toml`、`.codex/hooks.json`。确需写入个人全局 Codex agent 目录时，必须先二次确认，再显式传入：

```bash
scripts/codex-agent-generator.sh --output-dir "$HOME/.codex/agents" --apply --allow-global
```

Tier M/L change 通过 `scripts/change-scaffold.sh` 创建时会默认生成 `agent-dispatch-plan.md`。派发 Agent 前先生成或更新计划，而不是直接让模型自行选择：

```bash
scripts/agent-dispatch-plan.sh --stage pre_pr_or_human_review --runtime codex_generated --change-id <change-id> --output changes/<change-id>/agent-dispatch-plan.md
scripts/agent-dispatch-plan-gate.sh changes/<change-id>
```

候选 implementation agent 默认不会被派发。确实已满足 contract、allowed paths、隔离分支和业务代码开工 gate 时，先复制并填写确认文件，再显式加 `--allow-candidate` 与 `--candidate-confirmation`；确认文件仍要求 `protected_actions_allowed: no`、`global_config_write_allowed: no`、`db_or_release_actions_allowed: no`：

```bash
cp templates/agent-candidate-confirmation.md changes/<change-id>/agent-candidate-confirmation.md
scripts/agent-dispatch-plan.sh --stage implementation_after_contract_v0_1 --runtime codex_generated --allow-candidate --candidate-confirmation changes/<change-id>/agent-candidate-confirmation.md --change-id <change-id> --output changes/<change-id>/agent-dispatch-plan.md
scripts/agent-dispatch-plan-gate.sh changes/<change-id>
```

Agent 输出进入下游 gate 前，先校验 registry 声明的输出契约：

```bash
scripts/agent-output-contract-gate.sh changes/<change-id> sfa-harness-reviewer
scripts/agent-output-contract-gate.sh changes/<change-id> sfa-test-agent
```

## 3. 本地开发环境要求

团队成员要支持“本地编辑、本地启动、本地验证”，电脑至少需要安装：

| 工具 | 要求 | 用途 | 检查命令 |
| --- | --- | --- | --- |
| Git | 必需 | clone / branch / diff / worktree | `git --version` |
| JDK | 必需，后端建议 Java 8 | 编译和启动 `sfa-sales-management` / `sfa-backend` | `java -version` |
| Maven | 必需 | 后端 compile / test / package | `mvn -version` |
| nvm | 推荐 | 隔离前端 Node 版本，不影响其他项目 | `bash -lc 'type nvm'` |
| Node.js | `mapSystem` 推荐 `14.21.3` | 前端依赖安装、本地 dev server | `node -v` |
| npm | 随 Node 安装 | 前端 `npm install` / `npm run dev` | `npm -v` |
| lark-cli | 可选但推荐 | 读取/写入飞书 PRD、Wiki、评审文档 | `lark-cli version` |

`mapSystem` 是 Vue2 / Vue CLI 3 / `node-sass@4.14.1` 项目，高版本 Node 容易出现兼容问题。推荐用 `nvm` 切换到项目版本：

```bash
nvm install 14.21.3
nvm use 14.21.3
node -v
npm -v
```

如果不能联网安装 Node，可以把团队提供的 Node 14.21.3 压缩包解压到个人目录，再通过 shell `PATH` 或本地启动脚本指向该版本；不要覆盖系统 Node，也不要影响其他项目。

后端本地启动除 JDK / Maven 外，还依赖运行时环境：

- 公司网络或 VPN。
- Nacos 配置中心访问权限。
- Redis / MQ / 数据库访问权限。
- 本地端口不冲突，例如 `sfa-sales-management` 常用 `31010`。
- 测试环境账号、token 或浏览器登录态。

后端可先验证编译：

```bash
mvn -pl sfa-sales-management-interfaces -am -DskipTests compile
```

`mapSystem` 前端可先验证启动。优先使用 harness 脚本，它会读取 `config/repos.local.sh` 并优先选择 Node `14.21.3`：

```bash
scripts/frontend-dev-server.sh frontend-map-system 9527
```

手工启动时必须先确认当前 Node 版本。已知 Node 24 会触发 OpenSSL / `node-sass@4.14.1` 兼容问题，不要直接用当前 shell 的默认 Node 启动 `mapSystem`：

```bash
node -v
PATH="$HOME/.nvm/versions/node/v14.21.3/bin:$PATH" \
BROWSER=none \
npm run dev -- --host 0.0.0.0 --port 9527
```

注意：`mapSystem` 的 `npm run lint` 当前会执行 `eslint --fix`，可能自动修改文件。默认优先使用 harness 的窄范围 lint，不要随手全仓 auto-fix。

## 4. 业务仓扫描与 Registry 更新

团队成员的业务仓路径、分支、远端和依赖状态可能与初始作者不同。只有在用户要做业务需求开发、修 bug、跨仓分析或验证业务仓命令时，Agent 才需要先做业务仓扫描；纯文档阅读、讨论 harness 规则、查看历史 evidence 时可以跳过。

触发业务仓扫描时，Agent 应按下面顺序执行：

1. `source config/repos.local.sh`，读取当前用户自己的 `SFA_REPO_*` 路径。
2. 检查每个配置的业务仓是否存在、是否是 Git 仓、当前分支、远端地址、是否有 `AGENTS.md`、是否有 legacy `openspec`、后端 `pom.xml` 或前端 `package.json`。
3. 如果发现新增仓库、路径变量变化、远端变化、技术栈/baseline 信息变化，先更新 harness 对应文件，再进入业务实现。
4. 更新范围优先是：
   - `docs/architecture/repo-registry.md`：Repo ID、`path_env`、类型、远端、当前角色。
   - `docs/baseline/<repo-id>.md`：模块、验证命令、依赖状态、保护路径。
   - `docs/README.md`：新增 baseline 或新仓入口。
   - `changes/<change-id>/spec.md`：本次需求允许的仓库和路径。
   - `changes/<change-id>/evidence.md`：扫描命令和结果。
5. 如果扫描结果和当前 harness 文档冲突，不能直接实现业务代码；先把冲突列为 `[FACT]` / `[QUESTION]`，由用户确认后再继续。

业务仓扫描只写 harness 文档，不自动修改业务仓代码。扫描逻辑的目标是让每个团队成员都基于自己本机的真实业务仓状态启动任务，而不是继承其他人的本地路径或分支假设。

### 4.1 Change package 单一控制面

新需求只使用 `changes/<change-id>/` 作为 harness 控制面，不再创建顶层 `openspec/`，也不要求本机安装或运行 OpenSpec CLI。

每个 change package 至少按任务复杂度维护这些文件：

- `spec.md`：事实、范围、问题、允许路径和停止点。
- `contract.md` / `docs/contracts/<change-id>-api.md`：接口、字段、错误和兼容性。
- `plan.md`：分工、步骤、验证和停点。
- `harness-status.md`：用户可见状态卡。
- `verification-map.md`：关键约束到验证方式的映射。
- `evidence.md`：一手命令、截图、日志、SQL 只读结果或人工确认。

如果复杂状态机、权限矩阵、跨端一致性或能力边界需要独立规格，写在同一 change package 内：

```text
changes/<change-id>/capability-spec.md
changes/<change-id>/behavior-spec.md
```

这些文件不是强制产物；是否需要由本次需求风险决定。需要时必须在 `verification-map.md` 中映射到验证命令、Test Agent 结论、Reviewer 结论或人工确认。

业务仓已有的 `openspec/` 只作为 legacy context 读取，不再作为新需求默认工作流或门禁来源。读取 legacy `openspec/` 时，把用途、路径和结论写入 `changes/<change-id>/evidence.md`，但不要在业务仓新增、更新或 archive OpenSpec artifact。

历史 harness OpenSpec 内容已经迁移到对应 change package 的 `legacy-openspec/` 子目录，只保留审计价值，不参与新流程 gate。

## 5. 多工具 adapter 启用

### 5.1 Cursor / Codex hooks

本仓的 Cursor / Codex hooks 只做薄 adapter：项目级配置调用 `hooks/` 包装脚本，再统一委托 `scripts/harness-sensor-runner.sh`。不要把强制逻辑复制进某个工具的配置里。

首次启用时注意：

- Cursor：确认当前 workspace 是 Trusted，并在 Cursor Hooks 设置 / 输出面板里确认 `.cursor/hooks.json` 已加载。
- Codex：项目级 `.codex/hooks.json` 属于非 managed command hook，需要在 Codex 的 `/hooks` 界面 review / trust 后才会运行。
- hooks 是提前拦截层，不是唯一门禁；交付前仍要跑 readiness / allowed paths / lane 验证。

### 5.2 OpenCode 本地配置

版本化的 `opencode.json` 和 `.opencode/agents/*.md` 不声明 `external_directory`，避免环境变量缺失时把外部读取范围扩大。团队成员需要读取业务仓时，生成一份个人本地配置：

```bash
source config/repos.local.sh
scripts/generate-opencode-local-config.sh
OPENCODE_CONFIG=config/opencode.local.json opencode .
```

`config/opencode.local.json` 会写入你机器上的绝对路径，并同时给 OpenCode 主会话和 `sfa-harness-explorer` / `sfa-harness-reviewer` agent 配置 `external_directory`。该文件已被 `.gitignore` 忽略，不能提交。

也可以只输出到 stdout，用于检查或合并到用户级 OpenCode 配置：

```bash
scripts/generate-opencode-local-config.sh --output -
```

如果需要手工配置，核心是把本地启动配置里的 `external_directory` 替换为你机器上的绝对路径，例如：

### 5.3 ECC 可选 sidecar

ECC 不是使用本 harness 的前置条件。未安装 ECC 时，`scripts/team-rollout-preflight.sh` 仍应通过；`scripts/ecc/ecc-sidecar.sh status` 会输出 `ECC_STATUS=UNAVAILABLE` 和安装提示。

需要试用 ECC 参考能力时，把它放到 ignored 的 `artifacts/` 下：

```bash
mkdir -p artifacts/vendor
git clone https://github.com/affaan-m/ECC artifacts/vendor/ECC
cd artifacts/vendor/ECC
git checkout 5b173d2e6c11b976a0f13b2f59125e08956c1d47
npm ci --ignore-scripts
```

也可以使用本机已有 ECC checkout：

```bash
export SFA_ECC_HOME=/absolute/path/to/ECC
```

允许的默认调用都经过本仓 wrapper：

```bash
scripts/ecc/ecc-sidecar.sh status
scripts/ecc/ecc-sidecar.sh consult "verification loop"
scripts/ecc/ecc-sidecar.sh install-plan --profile minimal
scripts/ecc/ecc-sidecar.sh codex-sync-dry-run
```

`install-plan` 和 `codex-sync-dry-run` 只预览，不写全局 Codex 配置。任何真实写入 `~/.codex`、安装 global git hooks 或合并 MCP 的动作，都必须单独列出目标文件、备份路径和回滚方式后再确认。

```json
{
  "external_directory": {
    "/your/local/sfa-projects/**": "allow"
  }
}
```

不要把替换后的个人路径提交到仓库。需要长期保留时，放到个人本地配置或工具的用户级配置中。

### 5.3 CodeGraph 代码结构索引

CodeGraph 是可选但推荐的代码结构检索工具，用于在需求开发前快速理解业务仓符号、调用关系和影响面。它不替代 spec / contract / GitNexus / Maven / npm / 人工 review；结论进入交付前，仍要写入 `changes/<change-id>/evidence.md` 并用对应检查验证。

首次使用可直接运行官方 installer，也可先安装 CLI：

```bash
npx @colbymchenry/codegraph
# 或
npm install -g @colbymchenry/codegraph@latest
codegraph --version
```

每个成员在自己的业务仓本地初始化索引。索引目录是 `.codegraph/`，只应加入个人本地 `.git/info/exclude`，不要提交到业务仓。优先使用 harness bootstrap，它会读取 `config/repos.local.sh`，补本地 ignore，并只在显式调用时执行 `codegraph init -i`：

```bash
source config/repos.local.sh
scripts/codegraph-bootstrap.sh --all
scripts/codegraph-preflight.sh --required --all
```

新增业务仓时，把 repo 加入 `docs/architecture/repo-registry.md` 和 `config/repos.local.example.sh` 后，在本机配置对应 `SFA_REPO_*`，再运行：

```bash
scripts/codegraph-bootstrap.sh <new-repo-id>
scripts/codegraph-preflight.sh --required <new-repo-id>
```

`codegraph-preflight.sh` 默认只检查，不会自动初始化业务仓。需要先看会改什么时，运行：

```bash
scripts/codegraph-bootstrap.sh --dry-run <repo-id-or-path>
```

CodeGraph MCP server 默认会 auto-sync：agent 会启动 `codegraph serve --mcp`，文件 watcher 会在编辑后增量更新索引，并在短暂 debounce 窗口内用 staleness banner 提醒需要直接读取的文件。业务代码本地新增 / 修改后，正常 agent 会话里通常不需要手工 `codegraph sync`；MCP 连接时也会做一次 catch-up，覆盖 MCP server 未运行期间的 `git pull`、其他编辑器修改或上一次 agent 退出后的文件变化。需要做 CodeGraph 自查或影响面分析时，先用 harness preflight 确认实际 `projectPath`；通用格式是 `scripts/codegraph-preflight.sh <repo-id-or-path>`：

```bash
scripts/codegraph-preflight.sh backend-sales-management
scripts/codegraph-preflight.sh backend-sfa-backend
scripts/codegraph-preflight.sh backend-ceo-member
scripts/codegraph-preflight.sh frontend-map-system
```

`codegraph-preflight.sh` 会输出 `CODEGRAPH_PROJECT_PATH=...`。后续 MCP 查询业务符号时，必须把这个路径作为 `projectPath`；不要让 MCP 默认查询当前 harness 仓。

只有在 watcher 不可用、刚切分支 / 批量改动后怀疑索引未追上、`codegraph status` / MCP 响应显示 pending/stale，或脚本化预检时，才使用：

```bash
scripts/codegraph-preflight.sh --sync <repo-id-or-path>
```

在 Codex / OpenCode / Cursor 中使用时，把 CodeGraph 配为 MCP server。GUI 工具如果读不到 `nvm` 的 `PATH`，把 `command` 写成本机 `command -v codegraph` 输出的绝对路径。

Codex 用户级配置示例：

```toml
[mcp_servers.codegraph]
command = "codegraph"
args = ["serve", "--mcp"]
```

OpenCode 用户级配置示例：

```json
{
  "mcp": {
    "codegraph": {
      "type": "local",
      "command": ["codegraph", "serve", "--mcp"],
      "enabled": true
    }
  }
}
```

Cursor 用户级 MCP 配置示例：

```json
{
  "mcpServers": {
    "codegraph": {
      "type": "stdio",
      "command": "codegraph",
      "args": ["serve", "--mcp", "--path", "${workspaceFolder}"]
    }
  }
}
```

需求开发时推荐用法：

1. 分析阶段优先用 `codegraph_explore` 理解相关 controller / service / component / route，必须传入业务仓 `projectPath`。当前 MCP 工具面如果只暴露 `codegraph_context`，可把它作为兼容的 broad-context 入口，但仍必须写明 `projectPath`。
2. 查 API route / URL（例如 `/bsp/select`）时，不要只输入 URL。query 同时包含模块词、动作词、route 片段和目标，例如 `Bsp /bsp/select controller service mapper`。CodeGraph 支持 Spring `@GetMapping` / `@PostMapping` / `@RequestMapping` route 节点，但仍要看是否命中正确业务模块。
3. `codegraph_explore` 命中候选后，再用 `codegraph_node(..., includeCode=true)` 查看精确方法 / 文件；需要调用方或影响面时，用 `codegraph_callers`、`codegraph_trace` 或 CLI `codegraph impact` / `codegraph affected`。
4. 如果响应出现 staleness banner 或 pending sync，按提示直接读被点名的文件，或运行 `scripts/codegraph-preflight.sh --sync <repo-id-or-path>` 后再查。
5. 只有 PARTIAL / MISS / UNAVAILABLE、命中无关符号、或 route 覆盖不足时，才降级到 `rg "route|module|method"`、直接读文件、编译 / 测试和 Reviewer 证据；不要把 `rg` 当每次 HIT 后的固定复验。
6. 改关键类、方法、DTO、Mapper 或路由前，用 CodeGraph callers / trace / impact 辅助看结构影响面；高风险仍要 GitNexus。
7. 选窄测试前，用 callers / affected 辅助定位测试和调用方；没有输出不代表不需要测试，应结合业务入口和 baseline 命令判断。
8. 如果 MCP 工具不可用，退回 CLI，例如：

```bash
cd "$SFA_REPO_BACKEND_SALES_MANAGEMENT"
codegraph status
codegraph query BdOwnerConfirmController
codegraph impact BdOwnerConfirmController -d 2
codegraph callers confirm -l 20
codegraph affected sfa-sales-management-interfaces/src/main/java/com/wantwant/sfa/sales/management/interfaces/controller/BdOwnerConfirmController.java
```

注意：

- CodeGraph 输出是结构线索，不是业务事实；业务规则、字段语义、默认值和权限仍必须来自 PRD、contract、现有代码或用户确认。
- CodeGraph auto-sync 默认会保持索引新鲜；如果响应显示 stale/pending，先按 staleness banner 处理，不要静默相信旧内容。
- CodeGraph MCP 默认项目可能是当前 harness 仓；查业务符号必须显式传入业务仓 `projectPath`。
- API route / URL 查询必须带业务模块词和目标；优先 `codegraph_explore`，再按需要 node / callers / trace 精确跟进。
- CodeGraph 查不到新增符号不代表没有影响面；必须记录降级，并使用 `rg`、直接读文件、编译 / 测试和 Reviewer 证据兜底。
- `codegraph affected` 不一定能找到所有测试；没有输出时，不代表不需要测试，应结合 `callers`、业务入口和 baseline 命令判断。
- 高风险改动仍要尝试 GitNexus impact / detect_changes；CodeGraph 只能作为第二层影响面辅助。

## 6. 首次自检

在控制面根目录执行：

```bash
bash -n scripts/*.sh
scripts/dev-env-check.sh
scripts/harness-team-readiness-test.sh
scripts/harness-self-audit.sh
```

`scripts/dev-env-check.sh` 会检查本机 Git、Java、Maven、Node、npm、业务仓路径和可选的 `lark-cli`。通过后，说明控制面入口、配置样例、基础门禁、团队化检查和本地开发工具链可用。

团队正式启用前，优先使用聚合脚本：

```bash
scripts/team-rollout-preflight.sh
scripts/team-rollout-preflight.sh --local
```

默认模式检查共享控制面配置、hook/rule adapter 和 self-audit（self-audit 已包含 readiness）；`--local` 额外执行 `scripts/dev-env-check.sh`，用于确认当前成员本机工具链和业务仓路径。

## 7. 启动一个新需求

1. 选择 lane：小修走 `lanes/bugfix-fast.md`，低风险 Vue2 + Java CRUD 走 `lanes/fullstack-crud.md`。
2. 如果是业务需求开发或修 bug，先按“业务仓扫描与 Registry 更新”确认当前用户本地业务仓状态。
3. 复制合适模板到 `changes/<change-id>/spec.md`。
4. 把用户确认的信息写成 `[FACT]`，把推断写成 `[ASSUMP]`，把需要拍板的问题写成 `[QUESTION]`。
5. 所有阻塞性 `[QUESTION]` 解决前，不进入实现。
6. 先写或更新契约，再写计划，再实现。
7. 每次验证命令都记录到 `changes/<change-id>/evidence.md`。

## 8. 常见阻塞

| 问题 | 处理 |
| --- | --- |
| `node_modules missing` | 先按业务仓 baseline 或团队标准安装依赖，不能声称前端 lint/build 通过 |
| `mvn` 不存在 | 配置本机 Maven，或把 `SFA_BACKEND_MAVEN_COMMAND` 指向可用可执行文件；固定参数放到 `SFA_BACKEND_MAVEN_ARGS` |
| `confidence-gate.sh` 失败 | 真实 `[QUESTION]` 还没解决；非阻塞问题必须放在 `non_blocking_questions:` 小节 |
| `allowed-paths.sh` 失败 | 变更文件不在 spec 的 `allowed_paths` 内，或命中了 `forbidden_paths` / built-in protected paths；确需触碰时先在 spec 写 `approved_protected_paths` 和用户确认来源 |
| `assumption-leak-gate.sh` 失败 | `[ASSUMP]` 标签或假设标识进入了实现文件；先把假设升级为 `[FACT]`、移到问题区或移出实现 |
| 前端本地启动默认打测试环境，无法命中本地后端 | 声明 active backend 项目，运行 `scripts/generate-local-routing.sh` 生成 `changes/<change-id>/local-routing.yml`，再用 `SFA_HARNESS_SMOKE=1 node scripts/harness-local-proxy.mjs changes/<change-id>/local-routing.yml` 启动代理；本次 smoke shell 临时用 `VUE_APP_BASE_API=http://127.0.0.1:19080/ npm run dev` 启动前端 |
| 其他后端也需要本地验证 | 在 `--active-backends` 里追加对应 backend repo id，并确保 `SFA_LOCAL_BACKEND_*_URL` 指向该后端实际本地端口；生成器会为多个 active backend 生成多条服务前缀 route |
| `local-routing-gate.sh` 失败 | route 太宽、target 不是 localhost、缺少 contract 来源或 reason；检查 active backend 是否真实启动、服务映射是否正确 |
| OpenCode 读不到业务仓 | 检查 `SFA_PROJECTS_ROOT` 和工具的 `external_directory` 配置 |
| 业务仓扫描结果和 registry 不一致 | 先更新 harness 文档并记录 evidence，再决定是否进入实现 |
| Java 版本不是 8 | 用 SDKMAN、jEnv 或 IDE 配置切换到 JDK 8；不要修改项目源码绕过版本问题 |
| Node 版本不是 14.21.3 | 用 nvm 或项目本地 Node 切换版本；不要升级 `node-sass` 等依赖作为临时解决 |
| 后端 compile 通过但启动失败 | 检查 VPN、Nacos、Redis、MQ、数据库和端口占用；不要把运行时依赖失败当成代码编译失败 |
| lark-cli 不存在 | 代码开发可继续；飞书 PRD/Wiki 同步需要手工复制或先安装登录 `lark-cli` |

## 9. 不要做的事

- 不要把业务仓复制进控制面。
- 不要提交 `config/repos.local.sh`。
- 不要提交个人绝对路径到团队入口文件。
- 不要跳过业务仓扫描后继续使用其他人的路径、分支或远端假设。
- 不要修改 secrets、`.env*`、生产配置、部署脚本或 DB migration，除非 spec 明确允许。
- 不要为了 harness smoke 把全部后端项目切到本地；只声明本次真实启动的 active backend 项目，其他请求交给 proxy fallback 到测试/预发环境。
- 不要在没有 contract v0.1 和独立 worktree 的情况下并行派发实现 Agent。
