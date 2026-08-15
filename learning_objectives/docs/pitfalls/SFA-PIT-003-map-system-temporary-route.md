---
id: SFA-PIT-003
title: mapSystem 新页面未挂临时路由会跳首页
domain: frontend-map-system
maturity: verified
last_referenced: 2026-06-02
sources:
  - changes/0612-bd-overstaff-elimination-app/evidence.md
  - docs/baseline/frontend-map-system.md
---

# SFA-PIT-003：mapSystem 新页面未挂临时路由会跳首页

## 症状

- 新增页面组件已经存在，直接访问 `http://localhost:9527/sfamap/<route>` 后没有进入目标页面。
- 登录后页面回到 `HomeIndex`，误以为登录或 dev server 有问题。
- 左侧菜单或“临时路由”区域看不到新增页面入口。

## 原因

`mapSystem` 的后台页面依赖权限 / 菜单路由生成。新增页面如果只写 `src/views/**` 和 API，不补临时路由菜单映射，登录态恢复或路由守卫处理后会把未知页面导向首页。

## 规避方式

1. 新增页面前先读取 `docs/baseline/frontend-map-system.md`。
2. 在本地 smoke 前，把新增页面挂到临时路由菜单。
3. 当前可参考 `src/store/modules/permission.js` 中 `tempRoute` / `sfaTemporary` / `wangTemporary` 的既有写法。
4. 使用 history URL 访问：`http://localhost:9527/sfamap/<route>`。
5. 记录临时路由入口可见，并确认直接访问或点击入口不会跳到 `HomeIndex`。

## 验证记录

2026-06-02 在 `0612-bd-overstaff-elimination-app` 中验证：

- 新增页面 route：`/bdOverstaffEliminationTask`。
- 页面挂入“临时路由”后，左侧临时路由菜单可见 `承揽业务BD超编待处理`。
- 登录后访问 `http://localhost:9527/sfamap/bdOverstaffEliminationTask` 进入目标页面，不再跳首页。

## 禁止做法

- 不要只凭组件文件存在就声明页面可访问。
- 不要把跳到 `HomeIndex` 当作 smoke 通过。
- 不要在未记录临时路由入口的情况下要求人工确认复杂 UI。
