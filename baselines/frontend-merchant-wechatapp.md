# Baseline：frontend-merchant-wechatapp

> 当前不在 `git-registry.md` 工作范围内；仅保留标本 baseline 供对照。路径变量已改为 `RZ_*`，若启用该仓须先补登记表和 `config/runtime_local.sh`。


日期：2026-06-08  
仓库路径变量：`$RZ_REPO_MERCHANT_WECHATAPP`  
本机参考路径：`$RZ_PROJECTS_ROOT/merchant-wechatapp`  
当前分支：`main`  
仓库类型：原生微信小程序 / TypeScript  
试点角色：纳入 registry 和 baseline，按真实 PRD 决定是否进入小程序 lane

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `frontend-merchant-wechatapp` |
| Codeup 远端 | `want_want/merchant-wechatapp.git` |
| package name | `merchant-wechatapp` |
| 技术栈 | 微信小程序原生、TypeScript 5.4、Vant Weapp 1.11 |
| Node | `>=18.18.0` |
| 包管理 | npm |
| lockfile | 有 `package-lock.json` |

## 2. 可用脚本

来自 `package.json`：

| 命令 | 用途 | 自测结果 |
| --- | --- | --- |
| `npm run tsc` | TypeScript noEmit 检查 | 未执行 |
| `npm run build` | TypeScript 编译 | 未执行 |
| `npm run dev` | TypeScript watch | 未执行 |
| `npm run lint` | ESLint 检查 `miniprogram/**/*.{ts,js}` | 未执行 |
| `npm run format` | Prettier 格式化 | 不作为默认 harness 验证 |

推荐最小验证：

```bash
npm run tsc
npm run lint
```

需要微信开发者工具确认的项：

- `project.config.json` 可被微信开发者工具打开。
- 页面路由、授权弹窗、定位权限、扫码入口和真机/模拟器行为。
- 小程序发布、提审、体验版二维码和线上配置由人工确认，不由 harness 自动判定通过。

## 3. 目录结构

关键目录：

```text
miniprogram/pages/
miniprogram/services/
miniprogram/components/
miniprogram/config/
miniprogram/utils/
miniprogram/static/
```

当前页面：

```text
pages/home/index
pages/profile/index
pages/bind/index
pages/task-detail/index
pages/error/index
pages/privacy/index
pages/settings/index
```

API 封装：

```text
miniprogram/services/bd-owner.ts
miniprogram/services/types.ts
```

## 4. 受保护路径

默认禁止 AI 修改，除非 spec 明确允许：

```text
project.config.json
project.private.config.json
miniprogram/config/env.ts
miniprogram/config/constants.ts
package-lock.json
```

说明：

- `project.config.json` / `project.private.config.json` 影响微信开发者工具项目配置。
- `miniprogram/config/env.ts` 包含环境地址和当前环境选择，不能为本地 smoke 随意改动。
- `package-lock.json` 涉及依赖锁定，依赖升级必须单独说明。

## 5. 已知风险 / baseline 噪声

- 该仓不是 Vue2 / H5 项目，不适用 `rules/frontend-vue2.mdc`。
- 本地 TypeScript / lint 可覆盖语法和静态问题，但不能替代微信开发者工具预览、真机授权、定位、扫码和提审检查。
- 小程序配置和发布相关信息不得写入 harness evidence、截图或 memory。
