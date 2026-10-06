# 本地开发环境配置指南

> 面向产品经理、测试同学和全栈工程师。目标是在需求开发前一次性确认本机工具链、
> 业务仓路径、运行环境、账号来源和联调边界，减少开发中途才发现“跑不起来、进不去、没数据”。
> 本文不记录可复用的访问凭据、连接凭据或认证信息。

## 1. 初始化 Harness 本地配置

```bash
cd <Harness repo>
cp config/repos.local.example.sh config/repos.local.sh
vi config/repos.local.sh
source config/repos.local.sh
scripts/dev-env-check.sh
```

`config/repos.local.sh` 是本机忽略文件，不提交到 Git。它只保存路径、工具命令、端口和凭据来源，不保存可复用凭据。

## 2. 必备工具

| Tool | 用途 | 常见要求 |
| --- | --- | --- |
| Git | 多仓库分支、worktree、提交审计 | 可访问 Codeup 远端 |
| rg | 快速搜索代码和文档 | 必装 |
| Java | Java 后端编译和单测 | SFA 旧后端通常使用 Java 8 |
| Maven | 后端 targeted test | `SFA_BACKEND_MAVEN_COMMAND` 可配置 |
| Node.js | PC/H5/小程序前端 | mapSystem 通常需要 Node `14.21.3` |
| npm / package manager | 前端安装、lint、build | 不默认运行会全仓 auto-fix 的命令 |
| Xcode / CocoaPods | iOS App 构建、安装和模拟器验证 | 真实拍照/定位等仍需真机联调 |
| JDK / Gradle / Android SDK | Android App 构建、安装和模拟器验证 | 真实拍照/定位等仍需真机联调 |
| WeChat DevTools | 小程序导入、预览和真机调试 | CI 可先用 `npm run tsc/build` |
| lark-cli | 飞书 PRD、技术方案、测试报告同步 | Feishu 任务需要 |

## 3. 业务仓路径

在 `config/repos.local.sh` 中至少确认：

| Env var | Repo |
| --- | --- |
| `SFA_REPO_BACKEND_SALES_MANAGEMENT` | sales-management 后端 |
| `SFA_REPO_BACKEND_SFA_BACKEND` | sfa-backend 后端 |
| `SFA_REPO_BACKEND_SFA_ROOT` | sfa-root / 移动端 root API 转发层 |
| `SFA_REPO_BACKEND_CEO_MEMBER` | backend-ceo-member 后端 |
| `SFA_REPO_FRONTEND_MAP_SYSTEM` | PC mapSystem |
| `SFA_REPO_FRONTEND_SIGN_UP` | H5/sign-up |
| `SFA_REPO_FRONTEND_MERCHANT_WECHATAPP` | 商户小程序 |
| `SFA_REPO_FRONTEND_SFAINTL` | PC 特陈审核详情旧镜像 / 备用前端 |
| `SFA_REPO_MOBILE_SFA_IOS` | 国内 iOS App |
| `SFA_REPO_MOBILE_SFA_ANDROID` | 国内 Android App |

每个路径必须：

- 目录存在。
- 是 Git 仓库。
- 当前分支、远端和 dirty 状态清楚。
- 不在 Harness 控制面仓库内部复制业务代码。

## 4. 需求开工前检查

每个需求建议复制：

```bash
cp templates/local-dev-readiness.md changes/<change-id>/local-dev-readiness.md
cp templates/environment-readiness.md changes/<change-id>/environment-readiness.md
```

然后运行：

```bash
scripts/dev-env-check.sh
```

把结果摘要写入 `local-dev-readiness.md`：

- 工具链是否满足。
- 业务仓路径和 Git 状态。
- 哪些前端、后端、App、proxy 或外部依赖需要本地启动。
- 每个必测系统的启动命令、环境 profile、端口/入口和健康检查。
- 前端/App 连接本地后端、测试后端、预发后端还是 Harness fallback proxy。
- 哪些环境、账号、数据或权限需要用户/测试/运维提供。

## 5. 按系统启动标准

把本轮涉及的系统写入 `environment-readiness.md` 的 `本轮必测系统`、
`系统运行标准`、`本地联调拓扑` 和 `App 端运行标准`。不要只写“测试环境可用”，
要写清楚本机如何跑、跑不起来时如何降级。

| System | 常见 repo | 本地标准 | 健康检查 |
| --- | --- | --- | --- |
| PC Web | `frontend-map-system` / `frontend-sfaintl` | Node 版本正确，前端 dev server 可启动，可选 Harness proxy | 登录页、目标路由、截图或 browser smoke |
| H5 | `frontend-sign-up` | Node 版本正确，`npm run serve` 或项目等价命令可启动 | 移动端路由可打开 |
| 小程序 | `frontend-merchant-wechatapp` | Node >= 18，`npm run tsc/build/dev` 可跑，必要时导入 WeChat DevTools | 编译、预览或真机调试截图 |
| 后端 API / BFF | `backend-sales-management` / `backend-sfa-backend` / `backend-sfa-root` / `backend-ceo-member` | Java 8、Maven、Nacos/DB/Redis/MQ 等依赖明确 | targeted compile、health endpoint 或 smoke API |
| iOS App | `mobile-sfa-ios` | Xcode scheme/config 明确，模拟器可安装启动，环境切换方式明确 | 首页/目标入口截图；相机/定位/推送列真机 |
| Android App | `mobile-sfa-android` | JDK/Gradle/variant 明确，模拟器可安装启动，环境切换方式明确 | 首页/目标入口截图；相机/定位/推送列真机 |
| Harness proxy | `Harness` | `local-routing.yml` 通过 gate，proxy 可启动 | `local-routing-gate` 输出和浏览器/API smoke |

本地后端需要重启或验收时，使用统一生命周期命令，并以健康检查结果作为可用性证据：

```bash
scripts/local-service-lifecycle.sh backend-sales-management restart
scripts/local-service-lifecycle.sh check-web-stack --backend backend-sales-management
```

只有 `HEALTH=UP` 且 `check-web-stack` 成功后，才能声明本地后端已重启并可验收。
Successful `restart` or launch-command return alone is insufficient to establish readiness.

## 6. 本地前端与本地后端联调

PC E2E Smoke 如果需要让本地前端命中本地后端，使用 Harness 本地代理：

```bash
scripts/generate-local-routing.sh \
  --change-id <change-id> \
  --frontend-repo frontend-map-system \
  --active-backends backend-sales-management,backend-sfa-backend \
  --services templates/local-backend-services.yml \
  --output changes/<change-id>/local-routing.yml \
  --env-output artifacts/<change-id>/pc-e2e-smoke/frontend.env

scripts/local-routing-gate.sh changes/<change-id>/local-routing.yml
node scripts/harness-local-proxy.mjs changes/<change-id>/local-routing.yml
```

只声明本次真实启动的 active backend。未声明项目和其他请求由 proxy fallback 到测试/预发环境。

常见联调拓扑：

| Topology | 适用场景 | 限制 |
| --- | --- | --- |
| 本地前端 + 本地后端 + 本地/测试库 | 需要验证前后端新契约和本地修复 | 依赖 Nacos/DB/Redis/MQ/VPN 配置完整 |
| 本地前端 + 测试后端 | 只验证 PC/H5 UI 和已部署接口 | 不能证明本地后端改动生效 |
| 本地 App + 测试 API | 模拟器/真机验证入口、展示、预览 | 真实拍照/OSS/定位可能必须真机 |
| 本地前端/App + Harness proxy + 部分本地后端 | 只替换本次相关 API，其余走测试环境 | 需要维护 `local-routing.yml` |

## 7. 环境与账号

把环境、账号、数据和系统运行准备写入 `environment-readiness.md`：

- 本地、测试、预发分别用于什么。
- 本轮必测系统有哪些，不测的系统为什么 N/A。
- 每个系统的启动方式、环境 profile、端口/入口、上游依赖和健康检查。
- 前端/App 到 API/DB/OSS 的联调拓扑。
- 哪些角色账号需要准备。
- 账号凭据来源是什么。
- 是否需要 VPN/内网。
- 数据库是只读、可写还是可造数。
- 写操作是否需要二次确认和回滚方案。
- 是否需要真机、模拟器、浏览器登录态或 OSS。

不得在任何 versioned 文件中写入可复用凭据、连接凭据或认证信息。

## 8. 常见问题

| 问题 | 常见原因 | 处理 |
| --- | --- | --- |
| mapSystem 启动报 Node Sass 架构错误 | Node 版本或 arm64 运行时与旧 node-sass 不兼容 | 切到 `SFA_FRONTEND_NODE_VERSION` 指定版本，或使用项目既有兼容启动方式 |
| PC 登录页空白 | 路由刷新、本地代理、历史登录态异常 | 清理登录态，确认 proxy 命中，刷新后真实点击登录 |
| Android/iOS 模拟器无法覆盖相机 | 模拟器不等于真机能力 | 展示/预览可自动化，拍照/OSS/删除补拍列真机联调 |
| 能登录但看不到数据 | 角色、组织、单据状态或入口不匹配 | 在 `environment-readiness.md` 中锁定角色、路径、数据集 |
| 正确运行目录没有 Git | 拿到了打包目录或非正式工作副本 | 停止提交，定位对应 Codeup 仓库后迁移干净分支 |
