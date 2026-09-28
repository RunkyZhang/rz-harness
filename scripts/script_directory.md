# 脚本字典目录（scripts/script_directory.md）

> 给 Agent 查 `scripts/` 里有什么、何时跑。门禁脚本在 `gates/`，不在这里。跑过的命令记入 `changes/<change-id>/evidence.md`。

| 脚本 | 何时跑 | 做什么 |
|---|---|---|
| `verification-run.sh` | verification-map 有可执行行，进入 Tester / Reviewer 前 | 跑 map 里的命令，写出 `verification-run-report.md` |
| `mvn-targeted-test.sh` | Java 行为变更，要最窄编译或单测 | 指定模块 `compile` 或 `test`，避免无故全仓 reactor |
| `java-mechanical-quality.sh` | Java / Mapper XML 改动、Reviewer 前 | 扫本次 diff 的高信号机械问题 |
| `code-comment-log-quality.sh` | 业务代码审查前 | 扫 Java / Vue / JS 的注释和调试日志；warning 交 Reviewer |
| `mobile-mechanical-quality.sh` | iOS / Android 改动、Reviewer 前 | 扫调试输出、硬编码 URL、异常堆栈 |
| `frontend-lint-build.sh` | 前端改动要 lint 或构建 | `lint` / `lint-files` / `build` / 指定 npm script |
| `frontend-dev-server.sh` | 起 `mapSystem` 或 `sign-up` 本地页面 | `mapSystem` 用 Node 14.21.3，默认端口 9527 |
| `generate-local-routing.sh` | 本地前后端联调 | 生成 `local-routing.yml`。实现在 `generate-local-routing.mjs`，调用走这个 shell |
| `harness-local-proxy.mjs` | PC 冒烟要把前端打到本地后端 | 按 `local-routing.yml` 起代理，不改业务 `.env` |
| `local-service-lifecycle.sh` | 要声明本地后端可验收 | `start` / `status` / `check-web-stack`。只有 HEALTH=UP 且 web-stack 通过才算可用 |
| `technical-solution-feishu-sync.sh` | PRD 来源是飞书，方案确认后或方案又改了 | 把技术方案同步到飞书子文档并回读 |
| `harness-telemetry-record.sh` | 要记本机控制面事件 | 写入忽略的 `.harness/telemetry/`。不进变更包，不替代 evidence |
