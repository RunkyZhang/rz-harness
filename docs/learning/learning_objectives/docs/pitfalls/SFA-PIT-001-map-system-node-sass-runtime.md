---
id: SFA-PIT-001
type: pitfall
title: mapSystem 在高版本 Node 下启动失败
domain: frontend-map-system
maturity: verified
sources:
  - 0612-bd-overstaff-elimination-app
last_referenced: 2026-06-02
referenced_by:
  - 0612-bd-overstaff-elimination-app
tags:
  - frontend
  - node-sass
  - local-dev
  - pc-e2e-smoke
---

# mapSystem 在高版本 Node 下启动失败

## 现象

[FACT] 在本机使用 Node `24.15.0` 直接启动 `mapSystem` 时，`npm run dev` 进入 webpack 后失败，错误包含 `ERR_OSSL_EVP_UNSUPPORTED`。

[FACT] 加 `NODE_OPTIONS=--openssl-legacy-provider` 后，OpenSSL 错误被绕过，但继续失败在 `node-sass@4.14.1`，错误包含 `Node Sass does not yet support your current environment`。

## 根因

[FACT] `mapSystem` 是 Vue2 / Vue CLI 3 项目，依赖 `node-sass@4.14.1`。该组合对现代 Node runtime 兼容性差，高版本 Node 会先触发 webpack/OpenSSL 兼容问题，随后触发 node-sass runtime 支持问题。

## 触发条件

- 入口：`mapSystem` 本地 dev server / PC E2E Smoke。
- 环境：当前 shell 默认 Node 为高版本，例如 Node 24。
- 命令：直接执行 `npm run dev` 或只加 `NODE_OPTIONS=--openssl-legacy-provider npm run dev`。

## 规避做法

[FACT] 优先使用 harness 启动脚本：

```bash
source config/repos.local.sh
scripts/frontend-dev-server.sh frontend-map-system 9527
```

[FACT] 等价手工命令需要显式把 Node `14.21.3` 放到 `PATH` 前面：

```bash
PATH="$HOME/.nvm/versions/node/v14.21.3/bin:$PATH" \
BROWSER=none \
npm run dev -- --host 0.0.0.0 --port 9527
```

[FACT] `mapSystem` 验证 URL 使用 history 模式，例如：

```text
http://localhost:9527/sfamap/<route>
```

## 排查步骤

1. 运行 `node -v && npm -v && npm ls node-sass --depth=0`。
2. 如 Node 不是 `14.21.3`，先改用 `scripts/frontend-dev-server.sh frontend-map-system 9527`。
3. 如仍失败，记录完整错误到 `changes/<change-id>/evidence.md`，不要直接修改 `.env*`、`vue.config.js` 或前端依赖。
4. 如页面跳登录页，优先使用已有 Chrome 登录态或本地-only 的 `config/repos.local.sh` 登录提示；不要把密码写入 report / evidence。

## 关联

- 相关 baseline：`docs/baseline/frontend-map-system.md`
- 相关 guideline：`AGENTS.md` 的 frontend / UI changes
- 相关脚本：`scripts/frontend-dev-server.sh`
