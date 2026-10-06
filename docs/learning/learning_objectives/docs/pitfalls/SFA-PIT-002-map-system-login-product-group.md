---
id: SFA-PIT-002
title: mapSystem 登录必须先触发账号 blur 加载产品组
domain: frontend-map-system
maturity: verified
last_referenced: 2026-06-02
sources:
  - changes/0612-bd-overstaff-elimination-app/evidence.md
  - docs/baseline/frontend-map-system.md
---

# SFA-PIT-002：mapSystem 登录必须先触发账号 blur 加载产品组

## 症状

- 自动化给账号 / 密码输入框赋值后，登录按钮仍不可点击。
- 页面没有出现 `请选择渠道` / 产品组单选项。
- 以为账号密码错误，但真实人工点击可以登录。

## 原因

`mapSystem` 登录页在账号输入框失焦时调用 `/sfa/backend/employee/organizationFor123` 查询产品组 / 渠道列表。产品组返回后页面才启用登录按钮，并默认选中第一个产品组。直接修改 Vue input value 不一定触发页面的 `blur` / `change` 逻辑。

## 规避方式

1. 打开 `http://localhost:9527/sfamap/login`。
2. 使用本地 ignored 配置、Keychain 或浏览器安全保存项提供账号密码；不要在版本化文件记录明文密码。
3. 通过真实键盘输入账号。
4. 让账号输入框失焦，等待 `请选择渠道` 出现。
5. 确认第一个产品组已选中；未选中时选择第一项。
6. 输入或安全填充密码，点击 `登录`。
7. 登录后重新进入目标页面，确认不是登录页、401 或 403。

## 验证记录

2026-06-02 在本机 `mapSystem` dev server `http://localhost:9527/sfamap/` 上验证，连续 3 轮自助登录均通过：

- 先通过页面菜单退出登录。
- 从登录页真实输入账号并触发 blur。
- 页面加载 27 个产品组，第一项 `GenZ组` 默认选中。
- 点击 `登录` 后进入本次需求临时路由 `/sfamap/bdOverstaffEliminationTask`。

## 禁止做法

- 不要把测试密码写入 `AGENTS.md`、模板、evidence、截图说明、PR 描述或其他版本化文件。
- 不要用只改 DOM / Vue input value 的方式声称登录通过。
- 不要把 `localhost:9527/sfa/backend/...` 当成真实 API 预检地址；dev server 对该路径可能返回前端 HTML。真实开发配置的 API base 以 `mapSystem` 当前 `.env.development` 和请求封装为准。
