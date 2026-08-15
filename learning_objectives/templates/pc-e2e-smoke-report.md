# PC E2E Smoke Report：<change-id>

> 面向人工 review 的结论默认中文；URL、API path、field、enum、error code、命令、截图路径和引用原文保持原样。

## 执行结论

| Item | Value |
| --- | --- |
| Change | `<change-id>` |
| Plan | `changes/<change-id>/pc-e2e-smoke-plan.md` |
| Execute time | 写入执行时间 |
| Executor | 写入执行者 |
| Environment | 写入本地或测试环境 |
| Browser tool | 写入 Codex Browser / Chrome / Playwright 等 |
| Artifact dir | `artifacts/<change-id>/pc-e2e-smoke/` 或外部存储路径 |
| Login state | `已有登录态` / `测试账号登录` / `人工输入` / `免登录` / `BLOCKED` |
| Test account | 写账号标识；如来自本地配置，写 `SFA_PC_E2E_USERNAME configured` |
| Test password source | `local-env configured` / `keychain configured` / `browser-session` / `manual input` / `not configured`，不得写明文密码 |
| Local routing | `changes/<change-id>/local-routing.yml` / `未使用` |
| Proxy log | `artifacts/<change-id>/pc-e2e-smoke/local-proxy.ndjson` / `未使用` |
| Result | `PASS` / `FAIL` / `BLOCKED` |
| Recommendation | `允许进入人工 SIT` / `修复后重跑` / `补齐环境后重跑` |

## 执行摘要

| Step | Result | Evidence |
| --- | --- | --- |
| 启动环境确认 | `PASS` / `FAIL` / `BLOCKED` | `mapSystem` 记录 Node 版本、启动脚本或阻塞原因 |
| 登录态确认 | `PASS` / `FAIL` / `BLOCKED` | 账号标识、密码来源状态、登录方式或阻塞原因；不写明文密码 |
| `mapSystem` 产品组加载 | `PASS` / `FAIL` / `BLOCKED` / `N/A` | 记录账号 blur 后是否出现产品组、是否选择第一项；不写敏感值 |
| `mapSystem` 临时路由 | `PASS` / `FAIL` / `BLOCKED` / `N/A` | 新页面记录临时路由入口、目标 route、是否跳 `HomeIndex` |
| 打开目标页面 | `PASS` / `FAIL` / `BLOCKED` | 截图路径或错误摘要 |
| 默认查询 | `PASS` / `FAIL` / `BLOCKED` | 接口观察或页面结果 |
| 核心筛选 1 | `PASS` / `FAIL` / `BLOCKED` | 输入、结果、截图路径 |
| 核心筛选 2 | `PASS` / `FAIL` / `BLOCKED` | 输入、结果、截图路径 |
| 分页或列表刷新 | `PASS` / `FAIL` / `BLOCKED` | 页码、total、截图路径 |
| 详情查看 | `PASS` / `FAIL` / `BLOCKED` | 详情 URL、关键字段、截图路径 |
| 返回列表 | `PASS` / `FAIL` / `BLOCKED` | 页面状态 |
| 空态或错误态 | `PASS` / `FAIL` / `BLOCKED` | 输入、提示文案、截图路径 |

## 本地代理命中

| Route | Expected target | Observed hits | Result |
| --- | --- | --- | --- |
| 写 route id | 写入 local target | 写入命中次数和典型 path | `PASS` / `FAIL` / `BLOCKED` |
| fallback | 写入测试环境或预发环境 | 写入未命中本地 route 的请求摘要 | `PASS` / `FAIL` / `BLOCKED` |

## 截图证据

| Screenshot | Path | Purpose |
| --- | --- | --- |
| 初始页面 | `artifacts/<change-id>/pc-e2e-smoke/...` 或外部链接 | 证明页面可打开且主区域渲染 |
| 查询结果 | `artifacts/<change-id>/pc-e2e-smoke/...` 或外部链接 | 证明列表、分页或空态可见 |
| 详情页面 | `artifacts/<change-id>/pc-e2e-smoke/...` 或外部链接 | 证明详情关键字段可见 |
| 空态或错误态 | `artifacts/<change-id>/pc-e2e-smoke/...` 或外部链接 | 证明异常路径不展示旧数据 |

## 接口观察

| API | Request summary | Response summary | Result |
| --- | --- | --- | --- |
| 写入 API path | 写入关键入参，不写敏感值 | 写入 code、total、关键字段 | `PASS` / `FAIL` / `BLOCKED` |

## 失败与阻塞

| Type | Description | Impact | Next action |
| --- | --- | --- | --- |
| `FAIL` / `BLOCKED` | 写入失败或阻塞原因 | 写入是否阻塞人工 review / SIT | 写入修复或补测动作 |

## 残余风险

- 浏览器冒烟只覆盖主路径，不替代测试人员 SIT / UAT。
- 多角色权限、复杂数据边界和历史页面回归未覆盖，除非本报告明确列出。
- 未执行或降级的步骤必须在进入人工 SIT 前确认影响。
- 截图、trace、录屏和原始浏览器日志不提交到 Git；本报告只记录路径和结论。
- 报告不得记录明文密码。生产密码、token、cookie 或个人真实账号凭据不得记录。如登录缺失，只能记录为 `BLOCKED` 或人工补测项。

## Reviewer 检查点

- [ ] 如果目标页面需要登录，报告已证明进入业务页面，而不是停留在登录页、401 或 403。
- [ ] 如果目标是 `mapSystem` 测试账号登录，报告已证明账号 blur 后加载产品组，并选择或确认第一项。
- [ ] 如果目标是 `mapSystem` 新页面，报告已证明页面挂入临时路由，目标 route 没有跳到 `HomeIndex`。
- [ ] 报告没有记录明文密码、token、cookie 或个人真实账号凭据。
- [ ] 如目标是 `mapSystem`，报告记录了 `scripts/frontend-dev-server.sh frontend-map-system 9527` 或等价 Node `14.21.3` 启动命令。
- [ ] 如使用本地代理，`local-routing.yml` 已通过 gate，且没有 catch-all / wildcard / 未启动后端项目 route。
- [ ] 如使用本地代理，报告证明 active backend 服务前缀命中本地后端，未声明 backend 和其他请求继续走 fallback 环境。
- [ ] smoke plan 中的核心步骤已执行，或跳过原因已说明。
- [ ] 截图和接口观察能支撑执行结论。
- [ ] `FAIL` / `BLOCKED` 项已修复、重跑，或列为人工 SIT 风险。
- [ ] 没有把未覆盖范围写成已通过。
