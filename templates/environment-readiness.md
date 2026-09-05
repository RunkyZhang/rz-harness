# Environment Readiness：<change-id>

> 需求开发和测试前的环境、账号、数据与权限准备清单。先使用 Markdown 维护；
> 后续可接入飞书环境查询文档。不得记录可复用的访问凭据、连接凭据或认证信息。

## 状态

```yaml
environment_status: PENDING
owner: -
updated_at: -
target_environments: -
credential_storage_policy: no-secrets-in-repo
```

`environment_status` 可选值：`PENDING` / `READY` / `BLOCKED` / `NOT_APPLICABLE`。

## 本轮必测系统

> 先锁定本轮测试必须跑起哪些系统。`Required?=yes` 的系统必须在下方
> `系统运行标准` 中有对应 `READY` 行；不在本轮范围内的系统写 `Required?=no`
> 且 `Status=N/A`，说明原因。

| Target ID | System | Required? | Runtime standard | Status | N/A reason |
| --- | --- | --- | --- | --- | --- |
| TGT-001 | `<PC Web / H5 / Mini Program / Backend API / BFF / iOS / Android / Local proxy / External service>` | `yes/no` | `<SYS-ID / APP-ID / N/A>` | `READY/PENDING/BLOCKED/N/A` |  |

## 环境矩阵

| Environment | Purpose | URL / entry | Network requirement | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| local | `<本地联调/本地前端>` | `<本地端口或 N/A>` | `<VPN/Nacos/Redis/MQ>` | `READY/PENDING/BLOCKED/N/A` |  |
| test | `<测试环境验收>` | `<环境入口，不写密钥>` | `<VPN/内网>` | `READY/PENDING/BLOCKED/N/A` |  |
| pre-release | `<预发回归>` | `<环境入口，不写密钥>` | `<VPN/内网>` | `READY/PENDING/BLOCKED/N/A` |  |

## 系统运行标准

> 记录每个系统如何在本机跑起来或如何接入目标环境。没有本地启动能力的系统，
> 也要写清使用测试 / 预发服务的入口、健康检查和限制。

| Standard ID | System | Repo ID | Local command or launch method | Env profile | Port or entry | Upstream dependencies | Health check | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SYS-001 | PC Web | `frontend-map-system` | `scripts/frontend-dev-server.sh frontend-map-system 9527` | `local frontend + selected API` | `http://localhost:9527` | `backend API / proxy / VPN` | `<login page / route / screenshot>` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |
| SYS-002 | Backend API | `<backend repo id>` | `<mvn command / IDE run / N/A>` | `<local/test/pre-release>` | `<local URL or env entry>` | `<Nacos/DB/Redis/MQ/OSS/VPN>` | `<health endpoint / compile / smoke API>` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |
| SYS-003 | Local proxy | `Harness` | `node scripts/harness-local-proxy.mjs changes/<change-id>/local-routing.yml` | `local` | `<proxy URL>` | `<active backend routes>` | `scripts/local-routing-gate.sh` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |

## 本地联调拓扑

> 明确每个前端或 App 连接本地后端、测试后端、预发后端还是 Harness fallback proxy。
> 不能只写“测试环境”，要写清入口和上游依赖边界。

| Topology ID | Client system | API target | Data target | Fallback target | Network requirement | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TOPO-001 | `<PC Web / H5 / iOS / Android / Mini Program>` | `<local backend / test API / pre-release API / proxy>` | `<local DB / test DB / fixture / natural data>` | `<test/pre-release/N/A>` | `<VPN/Nacos/OSS/etc.>` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |

## App 端运行标准

> iOS / Android 必测时必须写清 scheme/flavor、构建 variant、环境切换方式、
> 模拟器/真机覆盖边界，以及相机、定位、推送、第三方 SDK 等限制。

| App ID | Platform | Repo ID | Scheme / flavor / variant | Build or launch command | Environment switch | Simulator coverage | Real device required for | Third-party SDK limits | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| APP-001 | iOS | `mobile-sfa-ios` | `<scheme/config>` | `<xcodebuild / Xcode run>` | `<debug menu/config/env file>` | `<展示/预览/登录>` | `<相机/定位/推送/N/A>` | `<AMap/Face/etc. or N/A>` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |
| APP-002 | Android | `mobile-sfa-android` | `<flavor/build variant>` | `<Gradle install/run>` | `<debug menu/config/env file>` | `<展示/预览/登录>` | `<相机/定位/推送/N/A>` | `<地图/征信/人脸/etc. or N/A>` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |

## 角色账号

| Role | Environment | Account identifier | Credential source | Data scope | Status |
| --- | --- | --- | --- | --- | --- |
| `<角色>` | `<环境>` | `<账号标识，可脱敏>` | `<Keychain/飞书权限文档/用户临时提供>` | `<组织/门店/单据范围>` | `READY/PENDING/BLOCKED` |

## 数据与权限

| Item | Environment | Permission level | Write allowed? | Rollback / cleanup | Confirmation |
| --- | --- | --- | --- | --- | --- |
| Database | `<test/pre-release/local>` | `none/read-only/write-scoped/admin` | `yes/no` | `<回滚方案或 N/A>` | `<用户二次确认/N/A>` |
| Object storage / image | `<环境>` | `<权限>` | `yes/no` | `<清理方式>` | `<确认>` |
| Job / MQ / external service | `<环境>` | `<权限>` | `yes/no` | `<回滚方式>` | `<确认>` |

## 测试数据准备

| Dataset | Purpose | Owner | Preparation method | Reset / rollback | Status |
| --- | --- | --- | --- | --- | --- |
| `<数据集>` | `<展示/提交/边界/回归>` | `<人/Agent>` | `<自然数据/造数/fixture>` | `<回滚或保留>` | `READY/PENDING/BLOCKED` |

## 设备与工具

| Tool / Device | Required for | Status | Notes |
| --- | --- | --- | --- |
| Chrome / Browser | `<PC/H5 验证>` | `READY/PENDING/BLOCKED/N/A` |  |
| iOS simulator | `<iOS 展示/预览>` | `READY/PENDING/BLOCKED/N/A` |  |
| Android emulator | `<Android 展示/预览>` | `READY/PENDING/BLOCKED/N/A` |  |
| Real iOS / Android device | `<相机/推送/定位/外设>` | `READY/PENDING/BLOCKED/N/A` |  |
| lark-cli | `<飞书同步>` | `READY/PENDING/BLOCKED/N/A` |  |

## 阻塞项

| Blocker | Impact | Minimum required input | Owner | Status |
| --- | --- | --- | --- | --- |
| `<阻塞点>` | `<影响>` | `<需要什么>` | `<负责人>` | `OPEN / RESOLVED` |
