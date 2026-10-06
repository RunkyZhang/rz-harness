# SFA 多仓库 Registry

> 当前来源：2026-05-19 初始本地扫描；团队使用时以 `config/repos.local.sh` 中的路径变量为准。
> 用途：作为 `sfa-ai-harness` 控制面的初始仓库清单，后续 baseline、allowed paths、sensors 和 change package 都应引用这里的仓库 ID。

---

## 1. 仓库总览

| Repo ID | 本地路径 | 类型 | 当前分支 | Codeup 远端 | 初始角色 |
| --- | --- | --- | --- | --- | --- |
| `backend-sales-management` | `$SFA_REPO_BACKEND_SALES_MANAGEMENT` | Java 后端 | `master` | `want_sfa/sfa-sales-management.git` | 首个 CRUD 试点后端主仓 |
| `backend-sfa-backend` | `$SFA_REPO_BACKEND_SFA_BACKEND` | Java 后端 | `master` | `want_sfa/sfa-backend.git` | 第二后端仓；先做 baseline 和影响分析 |
| `backend-ceo-member` | `$SFA_REPO_BACKEND_CEO_MEMBER` | Java 后端 | `master` | `want/backend_ceo/backend-ceo-member.git` | CEO member 后端；会员、费用、库存、活动等业务域 |
| `frontend-map-system` | `$SFA_REPO_FRONTEND_MAP_SYSTEM` | Vue2 前端 | `master` | `want-ceo/H5/mapSystem.git` | 首个 CRUD 试点前端主仓；rule profile: `legacy-sfa-web` |
| `frontend-sign-up` | `$SFA_REPO_FRONTEND_SIGN_UP` | Vue2 前端 | `master` | `want-sfa/sign-up.git` | H5 / 移动端仓；rule profile: `vue2-h5-light` |
| `frontend-merchant-wechatapp` | `$SFA_REPO_FRONTEND_MERCHANT_WECHATAPP` | 微信小程序 | `main` | `want_want/merchant-wechatapp.git` | 原生小程序仓；rule profile: `wechat-miniprogram-ts` |
| `backend-sfa-root` | `$SFA_REPO_BACKEND_SFA_ROOT` | Java 后端 | 待配置 | `want_sfa/sfa-root.git` | 特陈移动端 root API 转发层 |
| `mobile-sfa-ios` | `$SFA_REPO_MOBILE_SFA_IOS` | iOS / Objective-C | 待配置 | `want-sfa/sfa-ios.git` | 特陈线下审核 iOS 主端；rule profile: `ios-objc-sfa` |
| `mobile-sfa-android` | `$SFA_REPO_MOBILE_SFA_ANDROID` | Android / Java | 待配置 | `want-sfa/sfa-android.git` | 特陈 Android 实现端；rule profile: `android-java-sfa` |
| `frontend-sfaintl` | `$SFA_REPO_FRONTEND_SFAINTL` | Vue2 前端 | 待配置 | `want-sfa/SfaIntl.git` | PC 特陈审核详情旧镜像 / 备用分支 |

---

## 2. 后端仓

### 2.1 backend-sales-management

```yaml
repo_id: backend-sales-management
path_env: SFA_REPO_BACKEND_SALES_MANAGEMENT
type: backend
language: Java 8
api_model_documentation_profile: swagger2-java-response-model
framework:
  - Spring Boot 2.2.5.RELEASE
  - Spring Cloud Hoxton.SR3
build_tool: Maven
packaging: multi-module pom
modules:
  - sfa-sales-management-interfaces
  - sfa-sales-management-api
  - sfa-sales-management-application
  - sfa-sales-management-domain
  - sfa-sales-management-infrastructure
legacy_openspec_observed: true
has_agents_md: true
pilot_role: primary_backend
```

建议验证命令候选：

```bash
mvn -DskipTests compile
mvn -pl sfa-sales-management-interfaces -DskipTests compile
mvn -pl sfa-sales-management-application -DskipTests compile
```

需要在 baseline 中继续确认：

- 哪个模块承载 controller / interface 层。
- 哪个模块最适合跑 targeted test。
- 生产配置、部署脚本、DB migration 的保护路径。
- 现有 legacy OpenSpec 是否仍有审计价值。

### 2.2 backend-sfa-backend

```yaml
repo_id: backend-sfa-backend
path_env: SFA_REPO_BACKEND_SFA_BACKEND
type: backend
language: Java 8
framework:
  - Spring Boot 2.2.5.RELEASE
build_tool: Maven
packaging: multi-module pom
modules:
  - wantwant-sfa-backend-api
  - wantwant-sfa-backend-webapi
  - wantwant-sfa-backend-service
  - wantwant-sfa-backend-openapi
legacy_openspec_observed: true
has_agents_md: false
pilot_role: secondary_backend
```

建议验证命令候选：

```bash
mvn -DskipTests compile
mvn -pl wantwant-sfa-backend-webapi -DskipTests compile
mvn -pl wantwant-sfa-backend-service -DskipTests compile
```

需要在 baseline 中继续确认：

- 是否被 `sfa-sales-management` 直接或间接依赖。
- 哪些 openapi / webapi 契约与首个 CRUD 试点相关。
- 是否需要业务仓 stub `AGENTS.md`。

### 2.3 backend-ceo-member

```yaml
repo_id: backend-ceo-member
path_env: SFA_REPO_BACKEND_CEO_MEMBER
type: backend
language: Java 8
framework:
  - Spring Boot
  - Spring Cloud Alibaba / Nacos
  - MyBatis Plus
build_tool: Maven
packaging: multi-module pom
modules:
  - backend-ceo-member-openapi
  - backend-ceo-member-api
  - backend-ceo-member-service
  - backend-ceo-member-webapi
  - backend-ceo-member-test
legacy_openspec_observed: false
has_agents_md: false
pilot_role: secondary_backend
local_context_path: /backend-ceo-member
local_default_port: 9168
```

建议验证命令候选：

```bash
mvn -DskipTests compile
mvn -pl backend-ceo-member-webapi -am -DskipTests compile
mvn -pl backend-ceo-member-service -am -DskipTests compile
mvn -pl backend-ceo-member-test -Dtest=<TestClass> test
```

需要在 baseline 中继续确认：

- 本地启动 profile、Nacos、DB、Redis、MQ、XXL-JOB 等依赖。
- PC / H5 / 小程序或 App 侧访问该服务时的 gateway 前缀是否统一为 `/backend/backend-ceo-member`。
- 业务实现涉及 member、gold coin、recharge、interlock、inventory、free sample 等多个域，改动前必须按 PRD 收窄模块。

---

## 3. 前端仓

### 3.1 frontend-map-system

```yaml
repo_id: frontend-map-system
path_env: SFA_REPO_FRONTEND_MAP_SYSTEM
type: frontend
framework:
  - Vue 2.6.10
  - Vue CLI 3.6
  - Element UI 2.12
build_tool: npm
package_name: mapSystem
pilot_role: primary_frontend
rule_profile: legacy-sfa-web
rule_entrypoint: rules/frontend-vue2.mdc
rule_pack_manifest: rules/frontends/legacy-sfa/manifest.yml
```

可用脚本：

```bash
npm run dev
npm run lint
npm run test:unit
npm run build:test
npm run build:stage
npm run build:prod
```

初步判断：

- 管理后台形态，适合作为首个 CRUD 试点前端仓。
- 默认加载旧 SFA Web rule pack：`rules/frontends/legacy-sfa/web/`。
- `src/views` 模块很多，baseline 需要先找一个相近列表 / 表单页面作为样板。
- `src/api` 应作为 API SDK / adapter 入口重点盘点。

### 3.2 frontend-sign-up

```yaml
repo_id: frontend-sign-up
path_env: SFA_REPO_FRONTEND_SIGN_UP
type: frontend
framework:
  - Vue 2.6.x
  - Vue CLI 4.5
  - Vant 2.x
  - Mint UI
  - Weixin JS SDK
build_tool: npm
package_name: sign-up
pilot_role: secondary_frontend
rule_profile: vue2-h5-light
rule_entrypoint: rules/frontend-vue2.mdc
```

可用脚本：

```bash
npm run serve
npm run lint
npm run build:test
npm run build:stage
npm run build:prod
```

初步判断：

- 更偏 H5 / 移动端，不作为首个后台 CRUD 试点主仓。
- 不默认加载 `legacy-sfa-web`，避免把 `mapSystem` 管理后台规则套到 H5 页面。
- 仍需要 baseline，因为后续可能涉及小程序/H5 与后端契约联动。

### 3.3 frontend-merchant-wechatapp

```yaml
repo_id: frontend-merchant-wechatapp
path_env: SFA_REPO_FRONTEND_MERCHANT_WECHATAPP
type: frontend
platform: wechat_miniprogram
framework:
  - WeChat Mini Program native
  - TypeScript 5.4
  - Vant Weapp 1.11
build_tool: npm
package_name: merchant-wechatapp
pilot_role: secondary_frontend
rule_profile: wechat-miniprogram-ts
rule_entrypoint: rules/frontend-wechat-miniprogram.mdc
```

可用脚本：

```bash
npm run tsc
npm run build
npm run dev
npm run lint
```

初步判断：

- 原生微信小程序仓，不属于 Vue2 / H5 规则范围。
- 默认加载 `rules/frontend-wechat-miniprogram.mdc`，不得套用 `legacy-sfa-web` 或 `frontend-vue2.mdc`。
- `project.config.json`、`miniprogram/config/env.ts`、`package-lock.json` 默认为受保护路径，除非 spec 明确允许。

---

## 4. 首个试点建议

```yaml
first_pilot:
  frontend_repo: frontend-map-system
  backend_repo: backend-sales-management
  excluded_initially:
    - backend-sfa-backend
    - backend-sfa-root
    - backend-ceo-member
    - frontend-sign-up
    - frontend-merchant-wechatapp
    - frontend-sfaintl
    - mobile-sfa-ios
    - mobile-sfa-android
```

选择理由：

- `frontend-map-system` 是 Vue2 + Element UI 管理后台，最贴近“后台 CRUD”。
- `backend-sales-management` 分层结构清晰，已有 `AGENTS.md`，且可读取 legacy `openspec` 作为历史 context，适合验证控制面。
- 首个试点要控制变量，不同时改两个后端仓或两个前端仓。

---

## 5. 后续补充项

- 每个仓补一份 `docs/baseline/<repo-id>.md`。
- 每个仓确认受保护路径。
- 每个仓确认最窄可用验证命令。
- 每个仓确认业务仓轻量 `AGENTS.md` 是否已存在或需要新增。
- 对当前业务仓跑一次 GitNexus / `rg` 级别的样板搜索，沉淀到 `docs/samples/`。

---

## 6. 特陈线下审核照片多图需求相关仓

来源：`changes/special-display-department-photo-list`，2026-05-26 只读扫描。

```yaml
change_id: special-display-department-photo-list
repos:
  backend-sfa-root:
    path_env: SFA_REPO_BACKEND_SFA_ROOT
    role: /sfa/root/display/departmentUploadPic 入口和 /display/check 转发
  backend-sfa-backend:
    path_env: SFA_REPO_BACKEND_SFA_BACKEND
    role: /display/check 实际保存、DTO/list-string 转换、mapper 落库
  mobile-sfa-ios:
    path_env: SFA_REPO_MOBILE_SFA_IOS
    role: 区域经理上传和审核详情展示主端
  mobile-sfa-android:
    path_env: SFA_REPO_MOBILE_SFA_ANDROID
    role: Android 特陈检核上传与回看实现端，走 AgainVisit/TechenAdapter 链路
  frontend-map-system:
    path_env: SFA_REPO_FRONTEND_MAP_SYSTEM
    role: PC 特陈审核详情主实现仓
  frontend-sfaintl:
    path_env: SFA_REPO_FRONTEND_SFAINTL
    role: PC 特陈审核详情旧镜像/备用分支
```

说明：版本化文件只记录 `SFA_REPO_*` 变量名；每个人的真实本地路径写入 ignored 的 `config/repos.local.sh`。

---

## 7. SFA iOS 打包工具

Harness 内置 SFA iOS packaging 入口：

```bash
scripts/sfa-ios-pack.sh --check
scripts/sfa-ios-pack.sh --configuration Debug --method Development --upload none --notes "SIT validation"
```

使用边界：

- 仅当 iOS 改动需要真机 / SIT 安装包验证，或 Harness 需要从本地 `mobile-sfa-ios` 生成可复现 pak/package 时使用。
- 工具读取 `$SFA_REPO_MOBILE_SFA_IOS`，并兼容旧变量 `$SFA_REPO_IOS_SFA`。
- 产物输出到 ignored `artifacts/ios-pack/`；不得提交 `.ipa`、`.xcarchive`、`Packaging.log`、`.DS_Store` 或 `AutoPacking/build/**`。
- 蒲公英和 Apple 签名相关值只能放在本地环境或 ignored `config/repos.local.sh`，不得进入仓库。
- `sfaios` 开发签名验证必须找对应同事陈正文确认；签名 identity、profile、设备注册、证书权限或 Apple developer account 权限不清楚时，先停止修改签名配置。

详细说明见 `docs/ios-packaging.md`。

---

## 8. SFA Android 阿里云打包入口

Android 打包优先使用阿里云 EMAS DevOps Build：

```text
https://emas.console.aliyun.com/emasService/devTool/devopsBuild/build?ProductId=3909886&AppKey=335500513&AppType=2
```

使用边界：

- 仅当 Android 改动需要生成安装包验证、SIT 提测包或团队共享包时使用。
- 运行该页面内的打包任务前，必须确认当前账号具备打包运行权限；未开通时停止执行，找运维支持开通权限。
- 不在 Harness 记录阿里云登录 cookie、访问令牌、短信验证码、账号密码或临时授权凭据。
- 打包产物 `.apk`、`.aab`、`.apks` 为运行产物，不提交到 Harness；共享时记录构建任务、commit、variant、时间、下载位置和 checksum。

详细说明见 `docs/android-packaging.md`。
