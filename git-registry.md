# RZ Harness Git 仓库登记

> 清单以 `AGENTS.md`「Git仓库」为准。本机绝对路径以已忽略的 `config/runtime_local.sh` 中 `RZ_REPO_*` 为准，不要把业务仓拷进控制面。
> 后续 baseline、allowed paths、gate 和变更包应引用这里的 `repo_id`。
> 技术栈、模块、脚本名来自标本对同名 git 仓的扫描，新仓（无标本条目）标为待 baseline，不得把猜测写成事实。

版本化文件只记录变量名；真实磁盘路径、远端账号、打包凭据只放 `config/runtime_local.sh` 或钥匙串。

---

## 1. 仓库总览

| repo_id | path_env | 分组 | git 目录名 | 类型（标本或待确认） |
| --- | --- | --- | --- | --- |
| `sfa-sales-management` | `$RZ_REPO_SFA_SALES_MANAGEMENT` | 后端 | `sfa-sales-management` | Java 后端 |
| `sfa-backend` | `$RZ_REPO_SFA_BACKEND` | 后端 | `sfa-backend` | Java 后端 |
| `sfa-root` | `$RZ_REPO_SFA_ROOT` | 后端 | `sfa-root` | Java 后端 |
| `sfa-base` | `$RZ_REPO_SFA_BASE` | 后端 | `sfa-base` | Java 后端；`baselines/backend-sfa-base.md` |
| `arch-open` | `$RZ_REPO_ARCH_OPEN` | 后端 | `arch-open` | Java 后端；`baselines/backend-arch-open.md` |
| `arch-event` | `$RZ_REPO_ARCH_EVENT` | 后端 | `arch-event` | Java 后端；`baselines/backend-arch-event.md` |
| `sfa-common-sdk` | `$RZ_REPO_SFA_COMMON_SDK` | 后端 | `sfa-common-sdk` | 待 baseline |
| `mapSystem` | `$RZ_REPO_MAP_SYSTEM` | Web | `mapSystem` | Vue2 前端 |
| `sign-up` | `$RZ_REPO_SIGN_UP` | App | `sign-up` | Vue2 H5（标本归前端；本仓按 AGENTS 列入 App） |
| `sfa-ios` | `$RZ_REPO_SFA_IOS` | App | `sfa-ios` | iOS / Objective-C |
| `sfa-android` | `$RZ_REPO_SFA_ANDROID` | App | `sfa-android` | Android / Java |

不在本清单、标本曾登记的仓（`backend-ceo-member`、`merchant-wechatapp`、`SfaIntl`）默认不在 RZ Harness 工作范围内，除非用户改 `AGENTS.md` 并补本文件。

---

## 2. 后端

### 2.1 sfa-sales-management

```yaml
repo_id: sfa-sales-management
path_env: RZ_REPO_SFA_SALES_MANAGEMENT
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
```

建议验证命令：

```bash
mvn -DskipTests compile
mvn -pl sfa-sales-management-interfaces -DskipTests compile
mvn -pl sfa-sales-management-application -DskipTests compile
```

baseline 仍需确认：controller 所在模块、最窄 targeted test、生产配置 / 部署 / migration 保护路径。

### 2.2 sfa-backend

```yaml
repo_id: sfa-backend
path_env: RZ_REPO_SFA_BACKEND
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
```

建议验证命令：

```bash
mvn -DskipTests compile
mvn -pl wantwant-sfa-backend-webapi -DskipTests compile
mvn -pl wantwant-sfa-backend-service -DskipTests compile
```

baseline 仍需确认：与 `sfa-sales-management` 的依赖关系、本次需求相关的 openapi / webapi。

### 2.3 sfa-root

```yaml
repo_id: sfa-root
path_env: RZ_REPO_SFA_ROOT
type: backend
language: Java
build_tool: Maven
role: App / 移动端 root API 转发层（标本描述）
```

建议验证命令：`mvn -DskipTests compile`（模块名以仓内 pom 为准）。

### 2.4 sfa-common-sdk

```yaml
repo_id: sfa-common-sdk
path_env: RZ_REPO_SFA_COMMON_SDK
type: backend
status: 待 baseline
```

改该仓之前必须先读仓内 README/pom，补 `baselines/` 后再写 allowed_paths。无 baseline 时技术栈、模块、命令都不是 `[FACT]`。

`sfa-base`、`arch-open`、`arch-event` 见 `baselines/backend-sfa-base.md`、`baselines/backend-arch-open.md`、`baselines/backend-arch-event.md`。

---

## 3. Web

### 3.1 mapSystem

```yaml
repo_id: mapSystem
path_env: RZ_REPO_MAP_SYSTEM
type: web
framework:
  - Vue 2.6.10
  - Vue CLI 3.6
  - Element UI 2.12
build_tool: npm
package_name: mapSystem
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

管理后台形态。`src/views` 很大，实现前在 baseline 里指定可仿写的列表/表单样板；`src/api` 作为接口入口盘点。规则以本控制面已有规则文件为准，不要默认套标本 `legacy-sfa-web` 路径（文件尚未拷入时当缺口，不要编造）。

---

## 4. App

### 4.1 sign-up

```yaml
repo_id: sign-up
path_env: RZ_REPO_SIGN_UP
type: app
framework:
  - Vue 2.6.x
  - Vue CLI 4.5
  - Vant 2.x
  - Mint UI
  - Weixin JS SDK
build_tool: npm
package_name: sign-up
```

可用脚本：`npm run serve`、`npm run lint`、`npm run build:test` / `build:stage` / `build:prod`。

偏 H5 / 移动端，不要把 `mapSystem` 管理后台规则套过来。

### 4.2 sfa-ios

```yaml
repo_id: sfa-ios
path_env: RZ_REPO_SFA_IOS
type: app
language: Objective-C
```

改动前读该仓 baseline（若有）。打包脚本、签名、蒲公英等只走本机配置，不把证书和 token 写入本登记表。

### 4.3 sfa-android

```yaml
repo_id: sfa-android
path_env: RZ_REPO_SFA_ANDROID
type: app
language: Java
```

安装包与云构建凭据不进 git。共享包时记录任务、commit、variant、时间与 checksum。

---

## 5. 使用约定

- 写代码前 `source config/runtime_local.sh`，用 `test -d "$RZ_REPO_<ID>"` 确认仓在磁盘上。
- 每个目标仓第一次改业务代码：从 `main`/`master` 拉 `codex/<change-id>`，不在主干上改。
- 跨仓需求在 spec 里列出本次涉及的 `repo_id` 与 allowed_paths；未列入本表的仓默认禁止改。

后续补充（每个仓）：`baselines/` 下对应文件、受保护路径、最窄验证命令、业务仓是否需要轻量 `AGENTS.md` 指回本控制面。已从标本拷入的 baseline 文件名仍用标本 `Repo ID`（如 `baselines/frontend-map-system.md` 对应登记表 `mapSystem`）。
