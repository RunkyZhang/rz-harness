# RZ Harness Git 仓库登记

> 本文件是仓库清单的**权威来源**（source of truth）；`AGENTS.md` 第 2 节的「仓清单」指向本文件。本机绝对路径以 `config/runtime_local.sh` 中 `RZ_REPO_*` 为准，不要把业务仓拷进控制面。
> 后续 baseline、allowed paths、gate 和变更包应引用这里的 `repo_id`。
> 技术栈、模块、脚本名来自标本对同名 git 仓的扫描，新仓（无标本条目）标为待 baseline，不得把猜测写成事实。
> 字段口径：`language` = 源码语言版本；`build_jdk` = 本机构建用 JDK 大版本（脚本按仓选 `RZ_JAVA_HOME_<REPO_ID>`，回退 `RZ_BACKEND_JAVA_HOME`）；`local_port` = 本地服务端口（实际值以 `config/runtime_local.sh` 为准）。

版本化文件只记录变量名；真实磁盘路径、远端账号、打包凭据只放 `config/runtime_local.sh` 或钥匙串。

---

## 1. 仓库总览

| repo_id | path_env | 分组 | git 目录名 | 本地端口 | Swagger | 类型（标本或待确认） |
| --- | --- | --- | --- | --- | --- | --- |
| `sfa-sales-management` | `$RZ_REPO_SFA_SALES_MANAGEMENT` | 后端 | `sfa-sales-management` | `31010` | http://localhost:31010/swagger-ui.html | Java 后端；`config/baselines/backend-sales-management.md` |
| `sfa-backend` | `$RZ_REPO_SFA_BACKEND` | 后端 | `sfa-backend` | `9171` | http://localhost:9171/doc.html | Java 后端；`config/baselines/backend-sfa-backend.md` |
| `sfa-root` | `$RZ_REPO_SFA_ROOT` | 后端 | `sfa-root` | `9170` | http://localhost:9170/doc.html | Java 后端；`config/baselines/backend-sfa-root.md` |
| `sfa-base` | `$RZ_REPO_SFA_BASE` | 后端 | `sfa-base` | `34040` | http://localhost:34040/swagger-ui.html | Java 后端；`config/baselines/backend-sfa-base.md` |
| `sfa-data-fusion` | `$RZ_REPO_SFA_DATA_FUSION` | 后端 | `sfa-data-fusion` | `32020` | http://localhost:32020/swagger-ui.html | Java 后端；`config/baselines/backend-sfa-data-fusion.md` |
| `arch-open` | `$RZ_REPO_ARCH_OPEN` | 后端 | `arch-open` | `41010` | http://localhost:41010/swagger-ui.html | Java 后端；`config/baselines/backend-arch-open.md` |
| `arch-event` | `$RZ_REPO_ARCH_EVENT` | 后端 | `arch-event` | `43030` | http://localhost:43030/swagger-ui.html | Java 后端；`config/baselines/backend-arch-event.md` |
| `arch-notification` | `$RZ_REPO_ARCH_NOTIFICATION` | 后端 | `arch-notification` | `42020` | http://localhost:42020/swagger-ui.html | Java 后端；`config/baselines/backend-arch-notification.md` |
| `sfa-common-sdk` | `$RZ_REPO_SFA_COMMON_SDK` | 后端 | `sfa-common-sdk` | — | —（不是服务） | 基础 jar 包（`sfa-common-base` / `sfa-common-architecture`）；`config/baselines/backend-sfa-common-sdk.md` |
| `mapSystem` | `$RZ_REPO_MAP_SYSTEM` | Web | `mapSystem` | — | — | Vue2 H5 Web；`config/baselines/frontend-map-system.md` |
| `sign-up` | `$RZ_REPO_SIGN_UP` | App | `sign-up` | — | — | Vue2 H5（标本归前端；本仓按 AGENTS 列入 App）；`config/baselines/frontend-sign-up.md` |
| `sfa-ios` | `$RZ_REPO_SFA_IOS` | App | `sfa-ios` | — | — | iOS / Objective-C；`config/baselines/mobile-sfa-ios.md` |
| `sfa-android` | `$RZ_REPO_SFA_ANDROID` | App | `sfa-android` | — | — | Android / Java；`config/baselines/mobile-sfa-android.md` |

不在本清单、标本曾登记的仓（`backend-ceo-member`、`merchant-wechatapp`、`SfaIntl`）默认不在 RZ Harness 工作范围内，除非用户确认后补进本文件。

---

## 2. 后端

### 2.1 sfa-sales-management

```yaml
repo_id: sfa-sales-management
path_env: RZ_REPO_SFA_SALES_MANAGEMENT
type: backend
language: Java 8
build_jdk: 8
local_port: 31010
swagger_url: http://localhost:31010/swagger-ui.html
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
build_jdk: 8
local_port: 9171
swagger_url: http://localhost:9171/doc.html
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
build_jdk: 8
local_port: 9170
swagger_url: http://localhost:9170/doc.html
build_tool: Maven
role: App / 移动端 root API 转发层（标本描述）
```

建议验证命令：`mvn -DskipTests compile`（模块名以仓内 pom 为准）。

### 2.4 sfa-common-sdk

```yaml
repo_id: sfa-common-sdk
path_env: RZ_REPO_SFA_COMMON_SDK
type: backend
role: 基础 jar 包（不是服务、不部署）：给后端服务提供标准化 DTO / RpcResult / 注解 / 异常 / 缓存 / Feign / 日志 / MQ 等公共能力与工具
language: Java 8
build_jdk: 8
local_port: N/A（不是服务）
swagger_url: —（不是服务）
framework:
  - Spring Boot 2.2.5.RELEASE
  - Spring Cloud Alibaba（Nacos / Sentinel）
build_tool: Maven
packaging: multi-module pom（root artifactId: sfa-common）
modules:
  - sfa-common-base
  - sfa-common-architecture
```

关键依赖：Nacos config / discovery、Sentinel、Lombok、Jackson、commons-lang3、Feign、Swagger、Hutool、Redisson、JJWT。

建议验证命令：

```bash
mvn -DskipTests compile
mvn -pl sfa-common-base -DskipTests compile
mvn -pl sfa-common-architecture -DskipTests compile
```

改该仓前先确认：变更是否属于公共能力（会影响所有依赖服务），明确影响面后再写 allowed_paths。

baseline：`config/baselines/backend-sfa-common-sdk.md`。

### 2.5 sfa-data-fusion

```yaml
repo_id: sfa-data-fusion
path_env: RZ_REPO_SFA_DATA_FUSION
type: backend
language: Java 8
build_jdk: 8
local_port: 32020
swagger_url: http://localhost:32020/swagger-ui.html
framework:
  - Spring Boot 2.2.5.RELEASE
  - Spring Cloud Hoxton.SR3
build_tool: Maven
packaging: multi-module pom
modules:
  - sfa-data-fusion-interfaces
  - sfa-data-fusion-api
  - sfa-data-fusion-application
  - sfa-data-fusion-domain
  - sfa-data-fusion-infrastructure
```

角色：数据融合 / BI 报表与看板、库存与订单等数据服务（Controller 集中在 `interfaces`；含 QuickBI、实时库存、运输费、合伙人库存等）。
关键依赖：`sfa-common-base` / `sfa-common-architecture`、MyBatis-Plus、dynamic-datasource、XXL-JOB、Redisson、Knife4j、fastexcel、PDFBox、`arch-notification-api`。

建议验证命令：

```bash
mvn -DskipTests compile
mvn -pl sfa-data-fusion-interfaces -DskipTests compile
mvn -pl sfa-data-fusion-application -DskipTests compile
```

候选 targeted test（示例）：

```bash
mvn -pl sfa-data-fusion-interfaces -Dtest=BiDashboardControllerTest test
```

baseline：`config/baselines/backend-sfa-data-fusion.md`。

### 2.6 arch-notification

```yaml
repo_id: arch-notification
path_env: RZ_REPO_ARCH_NOTIFICATION
type: backend
language: Java 8
build_jdk: 8
local_port: 42020
swagger_url: http://localhost:42020/swagger-ui.html
framework:
  - Spring Boot 2.2.5.RELEASE
  - Spring Cloud Hoxton.SR3
build_tool: Maven
packaging: multi-module pom
modules:
  - arch-notification-interfaces
  - arch-notification-api
  - arch-notification-application
  - arch-notification-domain
  - arch-notification-infrastructure
```

角色：统一通知服务（站内信 / 联系人 / 告警等；含个推 `gexin-rp-sdk-http`、Freemarker 模板）。
关键依赖：`sfa-common-base` / `sfa-common-architecture`、MyBatis-Plus、dynamic-datasource、XXL-JOB、`arch-open-api`。

建议验证命令：

```bash
mvn -DskipTests compile
mvn -pl arch-notification-interfaces -DskipTests compile
mvn -pl arch-notification-application -DskipTests compile
```

候选 targeted test（示例）：

```bash
mvn -pl arch-notification-application -Dtest=InAppMessageServiceTest test
```

baseline：`config/baselines/backend-arch-notification.md`。

`sfa-base`、`arch-open`、`arch-event` 见 `config/baselines/backend-sfa-base.md`、`config/baselines/backend-arch-open.md`、`config/baselines/backend-arch-event.md`（均为 Java 8 / `build_jdk: 8`）。

Swagger / 端口：`sfa-base` 34040 → http://localhost:34040/swagger-ui.html；`arch-open` 41010 → http://localhost:41010/swagger-ui.html；`arch-event` 43030 → http://localhost:43030/swagger-ui.html。

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

H5 Web 形态。`src/views` 很大，实现前在 baseline 里指定可仿写的列表/表单样板；`src/api` 作为接口入口盘点。规则以本控制面已有规则文件为准，不要默认套标本 `legacy-sfa-web` 路径（文件尚未拷入时当缺口，不要编造）。

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

偏 H5 / 移动端，不要把 `mapSystem` 的 H5 Web 规则套过来。

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
- 每个目标仓第一次改业务代码：从 `main`/`master` 拉 `harness/<change-id>`，不在主干上改。
- 跨仓需求在 spec 里列出本次涉及的 `repo_id` 与 allowed_paths；未列入本表的仓默认禁止改。

后续补充（每个仓）：`config/baselines/` 下对应文件、受保护路径、最窄验证命令、业务仓是否需要轻量 `AGENTS.md` 指回本控制面。已从标本拷入的 baseline 文件名仍用标本 `Repo ID`（如 `config/baselines/frontend-map-system.md` 对应登记表 `mapSystem`）。
