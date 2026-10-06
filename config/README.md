# config/ —— 使用者配置层

本目录是**使用者专属配置**：换一个团队、一台机器或一批业务仓，就改这里。
控制面的其余目录是**产品本体**（装好即用、所有使用者相同），本目录是**你要填的部分**。

> 业务代码在各自 git 仓，用磁盘路径引用，**不要拷进本目录**。

## 开始使用前，按顺序做三步

1. **本机参数** —— 填写 `config/runtime_local.sh`：
   - 业务仓绝对路径（变量名与 `config/git-registry.md` 的 `path_env` 对齐）
   - 账号 / 凭据**来源**（只写来源，不写明文）
   - 数据库连接信息
   - 本地服务地址 / 代理 / 端口
   - 本机工具命令
2. **仓清单** —— 编辑 `config/git-registry.md`，登记你的仓（`repo_id` / `path_env` / 分组 / git 目录名 / 类型）。
3. **仓说明书** —— 为每个仓在 `config/baselines/` 放一份说明（仿写锚点、分层、受保护路径、最窄验证命令）。
   没有 baseline 的仓，其技术栈、模块、命令都**不算事实**。

## 还要接线

选定 runtime 后，按 `hooks/hook_setup.md` 把 hook 接到 Cursor / Codex / OpenCode。
接线文件本身（`.cursor/hooks.json`、`.codex/hooks.json`、OpenCode plugin 等）通常不入版本管理。

## 目录内容

| 文件 | 说明 | 归属 |
|---|---|---|
| `config/runtime_local.sh` | 本机参数（仓路径 / 凭据**来源** / DB / 端口 / 工具命令）；既是配置入口，也是你的本机值 | 使用者专属 |
| `config/git-registry.md` | 你的仓清单（**权威来源**） | 使用者专属，随你的仓库版本化 |
| `config/baselines/` | 每个业务仓的说明书 | 使用者专属，随你的仓库版本化 |

## 关于明文机密

- **永远不要**把明文密码 / token / cookie 写进会进 git 的文件、spec、evidence 或状态卡。
- 明文机密只放系统钥匙串；`config/runtime_local.sh` 只写凭据**来源**。
- 当前 demo 阶段 `config/` 纳入 git，尤其不要把明文写进本目录。

## 当前阶段说明

demo 开发阶段 `config/` **全部纳入 git** 做版本管理，`.gitignore` 暂不忽略本目录内文件。
正式使用时，建议把含密钥 / 本机路径的文件移出版本管理。
