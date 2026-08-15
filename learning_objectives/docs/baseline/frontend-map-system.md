# Baseline：frontend-map-system

日期：2026-05-19  
仓库路径：`/Users/00555733/codex/sfa-projects/mapSystem`  
当前分支：`codex/harness-self-test-20260519`  
仓库类型：Vue2 管理后台  
试点角色：首个 Fullstack CRUD lane 的前端主仓

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `frontend-map-system` |
| Codeup 远端 | `want-ceo/H5/mapSystem.git` |
| 技术栈 | Vue 2.6.10、Vue CLI 3.6、Element UI 2.12、Vue Router 3、Vuex 3 |
| 包管理 | npm |
| lockfile | 未发现 `package-lock.json` / `yarn.lock` / `pnpm-lock.yaml` |
| 当前依赖状态 | 未发现 `node_modules` |

## 2. 可用脚本

来自 `package.json`：

| 命令 | 用途 | 自测结果 |
| --- | --- | --- |
| `npm run dev` | 本地开发服务 | 已通过 harness 启动脚本在 Node 14.21.3 下执行 |
| `npm run lint` | ESLint 自动修复检查：`eslint --fix --ext .js,.vue src` | 已执行，失败于依赖缺失 |
| `npm run test:unit` | Jest 单测 | 未执行 |
| `npm run test:ci` | `npm run lint && npm run test:unit` | 未执行 |
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
Key output: sh: eslint: command not found
```

## 3. Harness 推荐验证命令

当前项目已知对 Node 版本敏感。`mapSystem` 使用 Vue CLI 3 / `node-sass@4.14.1`，在本机 Node 24 下启动会失败；已验证 Node `14.21.3` 可以启动 dev server。

推荐启动方式：

```bash
source config/repos.local.sh
scripts/frontend-dev-server.sh frontend-map-system 9527
```

等价手工命令：

```bash
PATH="$HOME/.nvm/versions/node/v14.21.3/bin:$PATH" \
BROWSER=none \
npm run dev -- --host 0.0.0.0 --port 9527
```

验证过的目标 URL 使用 history 模式：

```text
http://localhost:9527/sfamap/<route>
```

不要使用 `http://localhost:9527/sfamap/#/<route>` 作为 `mapSystem` 管理后台默认验证 URL，除非当前路由实现明确使用 hash。

新增页面路由要求：

1. 新增 `mapSystem` 页面不能只新增组件文件和 API wrapper。
2. 本地 smoke 前必须把页面挂到临时路由菜单，当前项目可参考 `src/store/modules/permission.js` 中 `tempRoute` / `sfaTemporary` / `wangTemporary` 相关逻辑。
3. 打开目标 URL 后如果跳转到 `HomeIndex`，按路由失败处理，不能声明页面已可访问。
4. 验证通过时 evidence / PC smoke report 必须记录：目标 route、临时路由入口可见、点击入口或直接访问不会跳首页。

PC 登录流程：

1. 打开 `http://localhost:9527/sfamap/login` 或目标页面跳转后的登录页。
2. 测试账号和密码只能来自本地 ignored 的 `config/repos.local.sh`、Keychain 或已有浏览器保存密码 / 登录态；版本化文档不得记录明文密码。
3. 真实输入账号并让账号输入框失焦，页面会调用 `/sfa/backend/employee/organizationFor123` 查询产品组 / 渠道列表。
4. 等待 `请选择渠道` 区域出现；当前页面会默认选中返回的第一个产品组，必要时人工或自动化选择第一项。
5. 输入或通过浏览器安全保存项填充密码，再点击 `登录`。
6. 登录成功后应进入 `http://localhost:9527/sfamap/HomeIndex` 或原目标业务路由；若仍停留登录页，不能声明 PC smoke 登录通过。

注意：不要只用自动化脚本直接改 Vue input value。必须触发真实输入和 blur / change 行为，否则产品组接口不会按页面逻辑加载，登录按钮可能保持 disabled。

依赖和验证流程：

```bash
npm install
scripts/frontend-lint-build.sh "$SFA_REPO_FRONTEND_MAP_SYSTEM" lint-files <changed-files...>
npm run build:test
```

如果团队确认要使用 lockfile，应先补齐或确认 lockfile 策略；当前仓库没有 lockfile，因此不建议默认使用 `npm ci`。

## 4. 目录结构

关键目录：

```text
src/api/          # API SDK / adapter 入口
src/router/       # 路由入口
src/store/        # Vuex
src/views/        # 页面模块，数量较多
src/components/   # 公共组件
```

首个后台 CRUD 试点优先从 `src/views` 中找相近列表 / 表单样板，再在 `src/api` 增加或复用 API 方法。

## 5. 样板候选

| 类型 | 路径 | 适合模仿的点 |
| --- | --- | --- |
| 客户列表/详情 | `src/views/customermanagement/customer_list/index.vue`、`detail.vue` | 列表页、详情页、搜索筛选结构 |
| 客户管理组合页 | `src/views/customermanagement/list/index.vue`、`detail.vue` | 多组件详情、tab/组件拆分 |
| 稽核列表/详情 | `src/views/audit/distributionAuditList.vue`、`distributionDetail.vue` | 后台业务列表和详情联动 |
| 稽核规则页 | `src/views/audit/ruleList.vue` | 规则类页面样板 |
| API 文件 | `src/api/customermanagement.js`、`src/api/customer-audit.js`、`src/api/sfa-api.js` | API 方法封装样板 |

## 6. 受保护路径

默认禁止 AI 修改，除非 spec 明确允许：

```text
.env.production
.env.staging
.env.test
.env.development
vue.config.js
build/**
public/**
```

说明：

- `.env.*` 可能包含环境 URL 或发布相关配置，默认只读。
- `vue.config.js` 涉及构建、代理、发布行为，首个 CRUD 试点不应修改。

## 7. 已知风险 / 噪声

- 本地没有 `node_modules` 时，前端 sensor 必须先完成依赖安装策略确认。
- 没有 lockfile，构建可重复性弱；真实试点时需要记录本地 Node/npm 版本。
- Vue CLI 3 / `node-sass@4.14.1` 与高版本 Node 不兼容。本机曾在 Node `24.15.0` 下遇到 `ERR_OSSL_EVP_UNSUPPORTED`；加 `NODE_OPTIONS=--openssl-legacy-provider` 后继续遇到 `Node Sass does not yet support your current environment`。已验证 Node `14.21.3` 能启动。
- `npm run lint` 带 `--fix`，会修改文件；真实 harness 中应考虑增加只检查不修复的 lint 命令，或在运行前明确允许自动修复。

## 8. 首个试点建议

适合作为首个 CRUD 前端主仓，但试点前必须先完成：

1. 确认依赖安装命令。
2. 确认是否允许 `npm run lint` 自动修复。
3. 选定一个相近 `src/views/**/index.vue` 页面作为样板。
4. 选定对应 `src/api/*.js` 作为 API 封装样板。

## 9. 特陈审核详情多图需求补充

来源：`changes/special-display-department-photo-list`，2026-05-26 只读扫描。

关键页面：

```text
src/views/zweat/specialChenAudit/detail.vue
```

本需求证据：

- `上传角色` 当前按 `departmentNearPictureUrl || departmentFarPictureUrl` 判断区域经理行。
- `陈列近景照片` 当前区域经理使用单图 viewer 展示 `departmentNearPictureUrl`。
- `陈列远景照片` 当前区域经理使用单图 viewer 展示 `departmentFarPictureUrl`。

实施注意：

- 2026-06-04 复核后，PC 主实现仓定为 `frontend-map-system`：该页近期持续迭代，且当前图片表格为 40px 紧凑态。
- `frontend-sfaintl` 同页只有 2025-07-15 初版提交，作为旧镜像/备用分支处理。
- 审核详情页只读展示，不能出现上传、删除、已达上限或上传拦截提示。
- 图片适配器应优先消费 list 字段，fallback 拆分 string。
