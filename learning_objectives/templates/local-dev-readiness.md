# Local Dev Readiness：<change-id>

> 需求开工前的本机配置检查记录。由 `scripts/dev-env-check.sh`、人工检查和项目特定补充共同维护。
> 不记录可复用的访问凭据、连接凭据或认证信息。

## 状态

```yaml
local_dev_status: PENDING
owner: -
updated_at: -
dev_env_check_result: -
```

`local_dev_status` 可选值：`PENDING` / `READY` / `BLOCKED` / `NOT_APPLICABLE`。

## 基础工具

| Tool | Required version / condition | Actual | Status | Fix guidance |
| --- | --- | --- | --- | --- |
| Git | available | `<actual>` | `PASS/FAIL/WARN` |  |
| rg | available | `<actual>` | `PASS/FAIL/WARN` |  |
| Java | `<major>` | `<actual>` | `PASS/FAIL/WARN` |  |
| Maven | available | `<actual>` | `PASS/FAIL/WARN` |  |
| Node.js | `<version per repo>` | `<actual>` | `PASS/FAIL/WARN` |  |
| lark-cli | available when Feishu is needed | `<actual>` | `PASS/FAIL/WARN/N/A` |  |

## 业务仓路径

| Repo ID | Expected path | Git branch | Git status | Status |
| --- | --- | --- | --- | --- |
| `<repo-id>` | `<path>` | `<branch>` | `clean/dirty/no-git/missing` | `PASS/FAIL/WARN` |

## 本地服务

| Service | System type | Repo ID | Start command / launch method | Port / URL | Required for | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `<frontend/backend/app/proxy>` | `<PC Web/H5/Mini Program/Backend/iOS/Android/Proxy>` | `<repo-id>` | `<command or IDE launch>` | `<port/url/device>` | `<场景>` | `READY/PENDING/BLOCKED/N/A` |  |

## 按系统启动标准

| System | Required toolchain | Local run standard | Environment target | Health check | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| PC Web | `Node <version> / package manager` | `<npm run dev / frontend-dev-server>` | `<local/test/pre-release API>` | `<login page screenshot>` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |
| H5 | `Node <version> / package manager` | `<npm run serve>` | `<test/pre-release API>` | `<route screenshot>` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |
| Mini Program | `Node >=18 / WeChat DevTools` | `<npm run dev/build + DevTools import>` | `<test/pre-release API>` | `<compile or preview>` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |
| Backend API / BFF | `Java 8 / Maven` | `<mvn command / IDE run>` | `<local DB/test DB/Nacos>` | `<compile/health/API smoke>` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |
| iOS App | `Xcode / CocoaPods` | `<scheme + simulator/device>` | `<test/pre-release API>` | `<launch screenshot>` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |
| Android App | `JDK / Gradle / Android emulator` | `<variant + install/run>` | `<test/pre-release API>` | `<launch screenshot>` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |
| Local proxy | `Node` | `<harness-local-proxy + routing gate>` | `<active backend routes>` | `<routing gate output>` | `READY/PENDING/BLOCKED/N/A` | `<path or N/A>` |

## 降级与联调策略

| Scenario | Preferred path | Fallback path | Limitation | Status |
| --- | --- | --- | --- | --- |
| 本地后端跑不起来 | `<本地前端 + 本地后端>` | `<本地前端 + 测试后端/proxy>` | `<无法覆盖本地后端逻辑>` | `READY/PENDING/BLOCKED/N/A` |
| App 模拟器缺能力 | `<模拟器展示/预览>` | `<真机拍照/定位/推送联调>` | `<相机/定位/推送不可自动化>` | `READY/PENDING/BLOCKED/N/A` |
| 外部依赖不可本地化 | `<本地服务 + 测试依赖>` | `<测试环境真实链路>` | `<需 VPN/权限/自然数据>` | `READY/PENDING/BLOCKED/N/A` |

## 已补齐事项

| Item | Action | Evidence | Status |
| --- | --- | --- | --- |
| `<缺失项>` | `<怎么补>` | `<命令/截图/说明>` | `DONE/PENDING/BLOCKED` |

## 仍需用户协助

| Item | Why needed | Minimum input | Owner |
| --- | --- | --- | --- |
| `<事项>` | `<原因>` | `<最小输入>` | `<用户/测试/运维>` |
