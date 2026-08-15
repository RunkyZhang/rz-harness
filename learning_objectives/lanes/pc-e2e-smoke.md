# PC E2E Smoke Lane

> 适用于 PC 管理后台需求开发完成后的交付前自动冒烟。第一阶段目标是让 AI 用真实浏览器验证主路径并留证，不替代测试人员 SIT / UAT。

## 适用条件

- 页面属于 PC 管理后台，例如 `frontend-map-system`。
- 前后端实现已完成，目标页面可在本地或测试环境打开。
- 后端接口可在本地或测试环境访问。
- API contract 已完成前后端字段对齐。
- 已有测试账号、登录态或明确说明无需登录。
- 已有至少一组可验证测试数据；如果没有，只允许覆盖页面渲染、空态或错误态。

## 项目维度本地代理

当本次前端页面需要验证本地后端改动时，必须使用 harness 本地代理，而不是修改 `.env*` 或把全部后端项目都切到本地。

- 长期服务映射放在 `templates/local-backend-services.yml` 或 change 专属覆盖文件。
- 本次 smoke 只声明实际启动的 active backend 项目，例如 `backend-sales-management`。
- 如果同时启动多个后端，用逗号声明多个 repo id，例如 `backend-sales-management,backend-sfa-backend`。
- 各后端本地地址通过 `SFA_LOCAL_BACKEND_*_URL` 配置；新增后端只补服务映射和本地 URL，不改代理代码。
- 运行 `scripts/generate-local-routing.sh` 生成 `changes/<change-id>/local-routing.yml`；不要长期手写堆积每个需求的接口 route。
- active backend 项目的服务前缀走本地；未声明项目和其他请求由 proxy fallback 到测试环境或预发环境。
- 运行前必须执行 `scripts/local-routing-gate.sh changes/<change-id>/local-routing.yml`。
- 启动命令使用 `SFA_HARNESS_SMOKE=1 node scripts/harness-local-proxy.mjs changes/<change-id>/local-routing.yml`，日志写入 `artifacts/<change-id>/pc-e2e-smoke/local-proxy.ndjson`。
- 前端启动只在本次 smoke shell 临时设置 `VUE_APP_BASE_API=http://127.0.0.1:19080/`；不要写入 `.env*`。

## 登录规则

- PC 管理后台页面默认需要登录态；如果目标 URL 跳转到登录页，必须先完成登录再执行 smoke 主路径。
- 默认测试账号标识为 `00441211`，对应环境变量为 `SFA_PC_E2E_USERNAME`。
- 测试环境默认密码为 `123456`，对应环境变量为 `SFA_PC_E2E_PASSWORD`；该测试密码允许写入 PC E2E Smoke plan、report、evidence 和模板。
- 生产密码、token、cookie 或个人真实账号凭据不得写入版本化文档。
- 如果使用已有浏览器登录态，plan / report 只记录“已有登录态”，不记录 token、cookie 或密码。
- 如果登录失败、账号无权限或缺少密码 / 登录态，结果必须标记为 `BLOCKED`，并写清缺少的最小条件。

## 不适用

- APP / H5 / 小程序端测试。
- 需要完整多角色权限矩阵的测试。
- 需要复杂造数、清数、数据修复或生产数据验证的测试。
- CI 定时回归或准测试平台建设。
- 历史页面全量回归。

## 流程位置

PC E2E Smoke 默认插入在基础验证和 Reviewer Agent 之间：

```text
后端 compile / targeted test
-> 前端 lint / build 或记录阻塞
-> contract 对齐
-> allowed-paths / confidence gate
-> PC E2E Smoke
-> Reviewer Agent
-> 用户人工 review
```

这样 Reviewer Agent 可以审查真实浏览器证据、截图、失败原因和残余 SIT 风险。

## 标准流程

1. 创建 `changes/<change-id>/pc-e2e-smoke-plan.md`，使用 `templates/pc-e2e-smoke-plan.md`。
2. 如需要本地后端验证，声明 active backend 项目并运行 `scripts/generate-local-routing.sh` 生成 `changes/<change-id>/local-routing.yml`。
3. 确认目标 URL、环境、账号/登录态、测试数据和核心路径。
4. 如配置本地代理，运行 `scripts/local-routing-gate.sh changes/<change-id>/local-routing.yml`，再启动 `node scripts/harness-local-proxy.mjs changes/<change-id>/local-routing.yml`。
5. 如目标页面需要登录，使用已有登录态、默认测试账号密码或人工输入完成登录；测试环境默认账号为 `00441211`，默认密码为 `123456`。
6. 打开目标页面，确认页面主容器、搜索区、表格或详情区完成渲染。
7. 执行默认查询，记录列表或空态结果。
8. 执行 1-3 个核心筛选，记录查询条件和结果变化。
9. 验证分页、刷新或列表状态变化。
10. 从列表进入详情页，检查关键字段和返回路径。
11. 验证空态或错误提示，不展示旧数据。
12. 保存关键截图或截图路径。
13. 创建 `changes/<change-id>/pc-e2e-smoke-report.md`，使用 `templates/pc-e2e-smoke-report.md`。
14. 把执行摘要、本地代理 route 命中摘要同步写入 `changes/<change-id>/evidence.md`。
15. Reviewer Agent 审查 smoke plan、smoke report、local-routing、代理日志、截图、接口观察和残余风险。

## 必须产物

| 文件 | 目的 |
| --- | --- |
| `changes/<change-id>/pc-e2e-smoke-plan.md` | 记录浏览器冒烟计划、账号/登录态、数据、步骤和期望 |
| `changes/<change-id>/local-routing.yml` | 可选；记录 harness-only 本地代理 route |
| `changes/<change-id>/pc-e2e-smoke-report.md` | 记录执行结果、截图、接口观察、失败点、是否建议进入人工 SIT |
| `changes/<change-id>/evidence.md` | 汇总 PC E2E Smoke 命令、浏览器操作摘要和阻塞原因 |
| `changes/<change-id>/review.md` | Reviewer Agent 对 PC E2E 证据的审查结论 |

## 阻断条件

- 目标页面无法打开，且没有记录为阻塞原因。
- 后端接口不可访问，且没有记录为阻塞原因。
- 目标页面需要登录但没有有效登录态，也没有可用测试账号登录结果。
- 没有可用账号、登录态或测试数据，却声称 E2E 通过。
- 本次需要本地后端验证，但没有声明 active backend 项目、没有生成 `local-routing.yml`、没有运行 `local-routing-gate.sh`，或 route 覆盖了未启动的后端项目。
- 计划中的主路径没有执行，也没有说明跳过原因。
- 截图、接口观察或失败点没有写入 report。
- E2E 失败后未修复，也未列为人工 SIT 风险。

## 允许降级

如果浏览器环境、账号、登录态、测试数据或本地服务不可用，可以降级为“未执行 PC E2E Smoke”。降级必须写清：

- 缺少什么条件。
- 已尝试的命令或操作。
- 对交付判断的影响。
- 进入人工 SIT 前需要补什么。

降级不能写成通过。

## 输出口径

给人工 review 的结论使用中文。URL、API path、字段名、命令、错误码、截图路径和引用原文保持原样。
