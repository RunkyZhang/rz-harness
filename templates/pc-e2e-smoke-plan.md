# PC E2E Smoke Plan：<change-id>

> 面向人工 review 的说明默认中文；URL、API path、field、enum、error code、命令、截图路径和引用原文保持原样。

## 基本信息

| Item | Value |
| --- | --- |
| Change | `<change-id>` |
| Lane | `lanes/pc-e2e-smoke.md` |
| Frontend repo | `$RZ_REPO_MAP_SYSTEM` |
| Backend repo | `$RZ_REPO_SFA_SALES_MANAGEMENT` |
| Target page | 写入实际页面名称 |
| Target URL | 写入本地或测试环境 URL |
| Backend base URL | 写入本地或测试环境后端地址 |
| Artifact dir | `artifacts/<change-id>/pc-e2e-smoke/` 或外部存储路径 |
| Local routing | `changes/<change-id>/local-routing.yml` / `不使用本地代理` |
| Harness proxy URL | `http://127.0.0.1:19080` / `不使用本地代理` |

## 进入条件

- [ ] 后端接口可访问，或阻塞原因已写入 `evidence.md`。
- [ ] 前端页面可打开，或阻塞原因已写入 `evidence.md`。
- [ ] API contract 已完成前后端字段对齐。
- [ ] 后端 compile / targeted test 已执行，或阻塞原因已写入 `evidence.md`。
- [ ] 前端 lint / build 已执行，或阻塞原因已写入 `evidence.md`。
- [ ] 测试账号、登录态或免登录条件已明确；如需要密码，来源只能是 `config/runtime_local.sh`、Keychain 或已有浏览器登录态，不能写入本计划。
- [ ] 测试数据已明确；如果没有数据，本次只覆盖页面渲染、空态或错误态。
- [ ] 如需要本地后端验证，已声明 active backend 项目，生成的 `local-routing.yml` 已通过 `scripts/local-routing-gate.sh`，且只包含本次实际启动的后端项目。
- [ ] 如目标是 `mapSystem`，已读取 `baselines/frontend-map-system.md`，并优先使用 `scripts/frontend-dev-server.sh frontend-map-system 9527` 或记录等价的已验证 Node `14.21.3` 启动命令。
- [ ] 如目标是 `mapSystem` 新页面，已挂入临时路由菜单；直接访问目标 route 或点击临时路由入口不会跳到 `HomeIndex`。

## 环境与登录态

| Item | Value |
| --- | --- |
| Browser tool | 例如 Codex Browser / Chrome / Playwright |
| Login state | 写明使用现有浏览器登录态、测试账号登录、人工输入或免登录 |
| Test account | 写入测试账号标识；如来自本地配置，写 `RZ_E2E_USERNAME configured` |
| Test password source | `local-env configured` / `keychain configured` / `browser-session` / `manual input` / `not configured`，不得写明文密码 |
| Required role | 写明角色或权限范围 |
| Data source | 写明本地库、测试库、mock 或空态 |

## 项目维度本地代理

| Active backend | Frontend prefix | Local target | Source registry | Reason |
| --- | --- | --- | --- | --- |
| 写 backend repo id | 写入生成的 `frontend_prefix` | 写入 `local_target` | 写入服务映射文件 | 写清为什么本次启动该后端项目 |

生成和启动命令：

```bash
mkdir -p artifacts/<change-id>/pc-e2e-smoke
scripts/generate-local-routing.sh \
  --change-id <change-id> \
  --frontend-repo frontend-map-system \
  --active-backends backend-sales-management,backend-sfa-backend \
  --services templates/local-backend-services.yml \
  --output changes/<change-id>/local-routing.yml \
  --env-output artifacts/<change-id>/pc-e2e-smoke/frontend.env
scripts/local-routing-gate.sh changes/<change-id>/local-routing.yml
RZ_HARNESS_SMOKE=1 \
RZ_HARNESS_PROXY_LOG=artifacts/<change-id>/pc-e2e-smoke/local-proxy.ndjson \
node scripts/harness-local-proxy.mjs changes/<change-id>/local-routing.yml
```

`mapSystem` 优先使用 harness 启动脚本，避免默认 Node 过高导致启动失败：

```bash
scripts/frontend-dev-server.sh frontend-map-system 9527
```

如果必须手工启动，先确认 Node 为 `14.21.3`。前端启动时只在本次 smoke shell 临时把 API base 指向 harness proxy；不要写入 `.env*`：

```bash
PATH="$HOME/.nvm/versions/node/v14.21.3/bin:$PATH" \
BROWSER=none \
VUE_APP_BASE_API=http://127.0.0.1:19080/ \
npm run dev -- --host 0.0.0.0 --port 9527
```

如果只启动一个后端，`--active-backends` 只写一个 repo id；如果同时启动多个后端，用逗号分隔。各后端本地地址来自 `RZ_LOCAL_BACKEND_*_URL`。如果不使用本地代理，写明原因，例如本次没有后端改动、后端改动不被当前前端直接调用，或只做测试环境 smoke。

## 核心测试数据

| Scenario | Input | Expected result |
| --- | --- | --- |
| 默认查询 | 打开页面后自动查询 | 页面展示列表或明确空态 |
| 核心筛选 1 | 写入查询条件 | 结果符合条件，页面无报错 |
| 核心筛选 2 | 写入查询条件 | 结果符合条件，页面无报错 |
| 详情查看 | 从列表点击查看 | 进入详情页并展示关键字段 |
| 空态或错误态 | 输入不存在的数据或触发接口错误 | 展示空态或错误提示，不展示旧数据 |

## 浏览器步骤

1. 打开 `Target URL`。
2. 如果跳转登录页，优先使用已有 Chrome 登录态；否则读取本地-only 的 `RZ_E2E_USERNAME` 和密码来源，或记录为人工输入 / `BLOCKED`。不得把密码写入报告、截图说明或 evidence。
3. 如果目标是 `mapSystem` 且需要测试账号登录，真实输入账号并触发账号输入框 blur，等待 `/sfa/backend/employee/organizationFor123` 加载产品组；选择或确认第一项已选中，再输入 / 安全填充密码并点击登录。
4. 登录后重新进入 `Target URL`，确认没有停留在登录页、401、403 或 `HomeIndex`。
5. 如果目标是 `mapSystem` 新页面，确认临时路由菜单入口可见；从入口进入或直接访问都能打开目标页面。
6. 等待页面主容器渲染完成。
7. 截图：页面初始态。
8. 执行默认查询，观察表格、分页或空态。
9. 执行核心筛选 1，记录输入和结果变化。
10. 执行核心筛选 2，记录输入和结果变化。
11. 如果页面有分页，切换页码或每页条数。
12. 从列表进入详情页。
13. 截图：详情页关键字段。
14. 返回列表页，确认页面不空白、不报错。
15. 执行空态或错误态验证。
16. 如启用本地代理，保存 `local-proxy.ndjson` 并统计 route 命中与 fallback 命中。
17. 将截图路径、接口观察、代理命中摘要和结论写入 `pc-e2e-smoke-report.md`；截图默认放在 `artifacts/<change-id>/pc-e2e-smoke/`，不直接提交到 Git。

## 关键断言

- 如页面需要登录，已进入业务页面而不是登录页、401 或 403 页面。
- `mapSystem` 账号登录已触发产品组加载，并选择或确认第一项产品组。
- `mapSystem` 新页面已挂临时路由，目标 route 没有跳到 `HomeIndex`。
- 页面主容器完成渲染。
- 搜索区、表格或详情区可见。
- 默认查询完成后页面无前端异常。
- 核心筛选会触发列表刷新或明确空态。
- 分页参数和列表结果变化符合 contract。
- 详情页能展示 contract 中定义的关键字段。
- 返回列表后不丢失基本页面状态。
- 空态或错误态不展示旧数据。
- 启用本地代理时，active backend 服务前缀命中本地后端，未声明 backend 和其他请求走 fallback 环境。

## 覆盖边界

- 本次只覆盖 PC 管理后台主路径。
- 本次不覆盖 APP / H5 / 小程序端。
- 本次不覆盖完整多角色权限矩阵。
- 本次不自动造复杂测试数据。
- 本次不替代测试人员 SIT / UAT。
- 截图、trace、录屏和原始浏览器日志不提交到 Git；report 只记录路径和结论。
- 本地代理只在 `RZ_HARNESS_SMOKE=1` 的 harness smoke 中启用，不影响普通 `npm run dev`。
