# SFA AI Harness Control Plane

这个仓库是 SFA 多仓库 AI Coding Agent 的控制面，不承载业务代码。

它的职责是让 Codex、Cursor 或其他 Agent 在多个业务仓之间工作时，有统一的事实源、规则、模板、验证脚本和复盘记录。

完整工作流、设计理念和行业借鉴见 `docs/architecture/harness-workflow-and-design-principles.md`。

## 团队首次使用

先看 `docs/onboarding.md`，并复制本地配置样例：

```bash
cp config/repos.local.example.sh config/repos.local.sh
vi config/repos.local.sh
source config/repos.local.sh
scripts/harness-self-audit.sh
```

`config/repos.local.sh` 是个人本地配置，不要提交。团队成员需要提供自己的业务仓父目录、当前业务仓路径、Maven 命令、前端包管理命令和 App 构建提示。

## 当前业务仓

当前业务仓默认通过 `config/repos.local.sh` 中的环境变量定位：

| Repo ID | 路径 | 类型 | 当前用途 |
| --- | --- | --- | --- |
| `backend-sales-management` | `$SFA_REPO_BACKEND_SALES_MANAGEMENT` | Java 后端 | 首个 CRUD 试点后端主仓 |
| `backend-sfa-backend` | `$SFA_REPO_BACKEND_SFA_BACKEND` | Java 后端 | 第二后端仓，先做 baseline 和影响分析 |
| `backend-sfa-root` | `$SFA_REPO_BACKEND_SFA_ROOT` | Java 后端 | App root API 转发层，按需求启用 |
| `backend-ceo-member` | `$SFA_REPO_BACKEND_CEO_MEMBER` | Java 后端 | CEO member 后端，按需求启用 |
| `frontend-map-system` | `$SFA_REPO_FRONTEND_MAP_SYSTEM` | Vue2 前端 | 首个 CRUD 试点前端主仓 |
| `frontend-sign-up` | `$SFA_REPO_FRONTEND_SIGN_UP` | Vue2 前端 | H5 / 移动端仓，先做 baseline 和影响分析 |
| `frontend-merchant-wechatapp` | `$SFA_REPO_FRONTEND_MERCHANT_WECHATAPP` | 微信小程序 | 原生小程序仓 |
| `frontend-sfaintl` | `$SFA_REPO_FRONTEND_SFAINTL` | Vue2 前端 | PC 特陈审核详情旧镜像 / 备用分支 |
| `mobile-sfa-ios` | `$SFA_REPO_MOBILE_SFA_IOS` | iOS / Objective-C | 国内 iOS App 仓 |
| `mobile-sfa-android` | `$SFA_REPO_MOBILE_SFA_ANDROID` | Android / Java | 国内 Android App 仓 |

详细信息见 `docs/architecture/repo-registry.md`。

## 第一阶段目标

Phase 0-2 的目标不是先做平台，而是用一个真实低风险 CRUD 跑通最小闭环：

```text
status -> spec -> contract -> technical solution -> AI test plan -> environment readiness -> plan -> implementation -> Main Agent regular tests -> Test Agent verification loop -> AI test report -> reviewer -> PR/SIT -> retro
```

首个试点推荐组合：

```yaml
frontend_repo: frontend-map-system
backend_repo: backend-sales-management
```

## 使用方式

1. 先读 `AGENTS.md`。
2. 需要理解完整机制时，读 `docs/architecture/harness-workflow-and-design-principles.md`。
3. 再读 `multi-repo-harness-implementation-plan.md`。
4. 查当前业务仓信息：`docs/architecture/repo-registry.md`。
5. 新需求先在 `changes/<change-id>/spec.md` 写 spec。
6. spec 里的 `[ASSUMP]` 和 `[QUESTION]` 没有处理前，不进入实现。
7. 实现完成后，把命令证据写入 `changes/<change-id>/evidence.md`。

## CRUD 试点启动

低风险 Vue2 + Java CRUD 默认走：

```text
lanes/fullstack-crud.md
```

最小启动顺序：

1. 复制 `templates/spec-tier-m.md` 到 `changes/<change-id>/spec.md`。
2. 复制 `templates/api-contract.md` 到 `docs/contracts/<change-id>-api.md`。
3. 复制 `templates/plan-tier-m.md` 到 `changes/<change-id>/plan.md`。
4. 复制 `templates/harness-status.md` 到 `changes/<change-id>/harness-status.md`，作为用户查看当前阶段、下一步和待确认项的入口。
5. 复制 `templates/technical-solution.md` 到 `changes/<change-id>/technical-solution.md`，人工确认后运行 `scripts/technical-solution-gate.sh changes/<change-id>`。
6. 技术方案确认后，复制 `templates/ai-test-plan.md` 到 `changes/<change-id>/ai-test-plan.md`，由独立 Test Strategy Agent 生成测试方案；用户确认后运行 `scripts/ai-test-plan-gate.sh changes/<change-id>`。未确认前不得进入业务代码实现。
7. 开工前复制 `templates/environment-readiness.md` 和 `templates/local-dev-readiness.md`，记录环境/账号/数据权限、本地机器状态、各系统运行标准和联调拓扑；真实 E2E 前运行 `scripts/environment-readiness-gate.sh changes/<change-id>`。
8. 用 `scripts/confidence-gate.sh`、`scripts/assumption-leak-gate.sh` 和 `scripts/allowed-paths.sh` 做门禁。
9. 主 Agent 实现并完成常规测试后，复制 `templates/test-agent-verification.md` 到 `changes/<change-id>/test-agent-verification.md`；测试 Agent 独立验收、反馈问题、复测修复，直到 `verification_status: GOAL_ACHIEVED` 或 `BLOCKED`。
10. AI 测试后复制 `templates/ai-test-report.md` 到 `changes/<change-id>/ai-test-report.md`；进入测试 / 预发前运行 `scripts/ai-test-report-gate.sh changes/<change-id>`，该 gate 会同时检查测试方案和测试 Agent 验收。
11. Reviewer Agent 用 `skills/reviewer/SKILL.md` 只读审查，输出 `changes/<change-id>/review.md` 后运行 `scripts/reviewer-gate.sh changes/<change-id>`，再交给人工 review。

## OpenCode 适配

本仓已包含 OpenCode 薄适配层：

```text
.cursor/hooks.json
.codex/hooks.json
hooks/
opencode.json
.opencode/agents/sfa-harness-explorer.md
.opencode/agents/sfa-harness-reviewer.md
```

使用 Cursor / Codex 时，项目级 hooks 只调用 `hooks/` 包装脚本，再统一委托 `scripts/harness-sensor-runner.sh`；不要把强制逻辑复制进某个工具的配置里。Cursor 需要 Trusted workspace；Codex 需要在 `/hooks` 中 review / trust 项目 hook。

使用 OpenCode 时，从 `$SFA_HARNESS_ROOT` 启动。需要读取业务仓时，先运行 `scripts/generate-opencode-local-config.sh`，再用 `OPENCODE_CONFIG=config/opencode.local.json opencode .` 启动。版本化配置不声明 `external_directory`，避免环境变量缺失时扩大读取范围；生成的本地配置只放个人机器，不提交。

团队正式使用前先跑：

```bash
scripts/team-rollout-preflight.sh
scripts/team-rollout-preflight.sh --local
```

第一条检查共享控制面；第二条在个人 `config/repos.local.sh` 准备好后检查本机工具链和业务仓路径。

## ECC 可选增强

ECC 只作为 optional sidecar 能力源，不是本仓必需依赖。没有安装 ECC 的团队成员仍可正常使用本 harness。需要试用时，把 ECC clone 到 ignored 的 `artifacts/vendor/ECC`，或设置 `SFA_ECC_HOME`，再通过 `scripts/ecc/ecc-sidecar.sh status` / `install-plan` / `consult` 等 dry-run 或只读命令调用。不要用 ECC 覆盖本仓 `AGENTS.md`、项目 hooks 或全局 Codex 配置；全局 `~/.codex` 同步必须另行二次确认。

## 当前目录职责

| 目录 | 职责 |
| --- | --- |
| `docs/` | 知识库、仓库 registry、baseline、contract、decision log |
| `templates/` | spec、plan、AI 测试方案、测试 Agent 验收、环境就绪、Pre-PR review 等模板 |
| `rules/` | Cursor / Agent 可读取的分层规则 |
| `skills/` | Explorer / Reviewer 等可复用工作流 |
| `scripts/` | confidence gate、allowed paths、验证脚本 |
| `hooks/` | Cursor / Codex hook 包装；只做 adapter，统一调用 `scripts/harness-sensor-runner.sh` |
| `lanes/` | 可复制的任务 lane |
| `evals/` | golden scenarios 和运行结果 |
| `changes/` | 每个真实变更的轻量事实源、审计摘要、review、retro；不保存大体积过程数据 |
| `artifacts/` | 本地 ignored 产物目录，放截图、录屏、trace、原始日志、临时原型草稿 |
| `.cursor/` | Cursor 项目级 adapter 配置 |
| `.codex/` | Codex 项目级 adapter 配置 |
| `.opencode/` | OpenCode 项目级 agent 适配层 |

`changes/` 的保留策略见 `docs/architecture/changes-retention-policy.md`。团队使用时，Git 只长期保存可 review 的 Markdown 摘要；大文件和原始过程数据放 `artifacts/<change-id>/` 或外部存储，并在 `evidence.md` / report 中记录路径和结论。

## 当前硬约束

- 不把业务仓复制进控制面。
- 给人工 review / 用户确认的文档默认使用中文。
- 代码标识、命令、API 路径、字段名、错误码、YAML key、日志 key 和引用原文保持原样。
- 不先上 RAG。
- 不做无契约的多实现 agent 并行；CRUD 契约达到 v0.1 后，允许后端 Agent 与前端 Agent 基于同一 API contract 并行开发，但必须使用独立 git worktree，控制面只允许 Orchestrator 写入。
- 不先做全仓系统地图。
- 不把 hooks 当作唯一门禁。
- 不用 AI 代码占比衡量成效。

## 下一步

1. 新需求使用业务含义明确的 `<change-id>`，不要复用 `pilot-crud-tbd` 作为默认上下文。
2. 从模板创建 `changes/<change-id>/spec.md`、`docs/contracts/<change-id>-api.md` 和 `changes/<change-id>/plan.md`。
3. 把 allowed paths 收窄到本次真实模块和文件；触碰 protected paths 时必须写入 `approved_protected_paths` 并记录用户确认。
4. 交付前运行 confidence gate、assumption leak gate、allowed paths、后端/前端验证、PC E2E Smoke、Test Agent verification 或明确阻塞原因；试点级收口可再跑 `scripts/eval-golden.sh <change-id> <changed-files...>`。
5. 阶段切换或用户询问“下一步是什么”时，运行 `scripts/harness-status.sh changes/<change-id>`，并更新 `harness-status.md`。

PC E2E Smoke 如果需要让本地前端命中本地后端，使用 active backend 项目生成 harness-only 本地代理：

团队成员使用前提：

- 已按 `docs/onboarding.md` 初始化 `config/repos.local.sh`，或本机后端服务端口使用默认值。
- 已启动本次需要验证的本地后端服务。
- `--active-backends` 只声明本次真实启动、且会被当前前端访问的后端项目。
- 普通开发不把 `VUE_APP_BASE_API` 指到 harness proxy，仍按原项目环境访问测试/预发。

```bash
scripts/generate-local-routing.sh \
  --change-id <change-id> \
  --frontend-repo frontend-map-system \
  --active-backends backend-sales-management,backend-sfa-backend \
  --services templates/local-backend-services.yml \
  --output changes/<change-id>/local-routing.yml \
  --env-output artifacts/<change-id>/pc-e2e-smoke/frontend.env
scripts/local-routing-gate.sh changes/<change-id>/local-routing.yml
SFA_HARNESS_SMOKE=1 \
SFA_HARNESS_PROXY_LOG=artifacts/<change-id>/pc-e2e-smoke/local-proxy.ndjson \
node scripts/harness-local-proxy.mjs changes/<change-id>/local-routing.yml

VUE_APP_BASE_API=http://127.0.0.1:19080/ \
npm run dev
```

只声明本次实际启动的 active backend 项目；这些项目的服务前缀走本地，未声明项目和其他请求由 proxy fallback 到测试/预发环境。普通开发不把 `VUE_APP_BASE_API` 指到 harness proxy，仍按原环境访问。各后端本地 URL 由 `SFA_LOCAL_BACKEND_*_URL` 配置，例如 `SFA_LOCAL_BACKEND_SALES_MANAGEMENT_URL` 和 `SFA_LOCAL_BACKEND_SFA_BACKEND_URL`。
