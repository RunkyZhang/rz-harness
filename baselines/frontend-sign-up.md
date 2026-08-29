# Baseline：frontend-sign-up

日期：2026-05-19  
仓库路径：`$RZ_REPO_SIGN_UP`（本机值见 `config/runtime_local.sh`）  
当前分支：`codex/harness-self-test-20260519`  
仓库类型：Vue2 H5 / 移动端前端  
试点角色：纳入 registry 和 baseline，暂不作为首个后台 CRUD 主仓

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `frontend-sign-up` |
| Codeup 远端 | `want-sfa/sign-up.git` |
| 技术栈 | Vue 2.6.x、Vue CLI 4.5、Vant 2、Mint UI、Weixin JS SDK |
| 包管理 | npm |
| lockfile | 有 `package-lock.json` |
| 当前依赖状态 | 未发现 `node_modules` |

## 2. 可用脚本

来自 `package.json`：

| 命令 | 用途 | 自测结果 |
| --- | --- | --- |
| `npm run serve` | 本地开发服务 | 未执行 |
| `npm run lint` | Vue CLI lint | 已执行，失败于依赖缺失 |
| `npm run build:test` | test 环境构建 | 未执行 |
| `npm run build:stage` | staging 环境构建 | 未执行 |
| `npm run build:prod` | production 构建 | 未执行 |

自测证据：

```text
Command: npm run
Exit: 0
Result: 脚本可读取
```

```text
Command: npm run lint
Exit: 127
Result: 依赖未安装导致失败
Key output: sh: vue-cli-service: command not found
```

## 3. Harness 推荐验证命令

因为存在 `package-lock.json`，候选安装流程优先考虑：

```bash
npm ci
npm run lint
npm run build:test
```

如果公司镜像或旧依赖导致 `npm ci` 不可用，再退回团队确认的 `npm install`。

## 4. 目录结构

关键目录：

```text
src/api/
src/router/
src/store/
src/views/visit/
src/components/
```

API 文件：

```text
src/api/interface.js
src/api/sales.js
src/api/dify.js
src/api/Qwen3.js
```

## 5. 样板候选

| 类型 | 路径 | 适合模仿的点 |
| --- | --- | --- |
| H5 visit 页面 | `src/views/visit/` | 移动端页面组织 |
| 商品选择 | `src/views/visit/visit-product-select.vue` | 移动端选择类页面 |
| API 封装 | `src/api/interface.js`、`src/api/sales.js` | H5 API 调用样板 |

## 6. 受保护路径

默认禁止 AI 修改，除非 spec 明确允许：

```text
.env.production
.env.staging
.env.test
.env.development
vue.config.js
package-lock.json
```

说明：

- `.env.*` 涉及环境配置，默认只读。
- `package-lock.json` 涉及依赖锁定，首个试点不应修改。

## 7. 已知风险 / baseline 噪声

- 当前缺少 `node_modules`，lint/build 不能直接作为代码质量结论。
- 本机 Node 是 `v22.22.2`，Vue CLI 4 通常比 Vue CLI 3 更兼容，但仍需真实安装验证。
- 该仓更偏 H5 / 移动端，不适合作为第一个后台 CRUD 试点主仓。

## 8. 试点关系

Phase 0-2 只做 baseline 和影响分析。除非选中的真实 PRD 明确涉及 H5，否则首个 CRUD 试点不修改此仓。
