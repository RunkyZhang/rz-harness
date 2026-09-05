# 标本一条中型需求：从 PRD 到结束（步骤与文件全表）

> 日期：2026-09-05  
> 用途：查阅用。按标本 **Tier M（中型）** 走完一条需求：你把需求文档交给主 Agent，到可以人审 / 提 PR / 收口。用来判断 RZ Harness 哪些文件保留、哪些可舍弃。  
> 这是标本 `learning_objectives` 的设计流程，不是 RZ 根上已经全部落地的脚本。  
> 看完若某一步仍迷惑，直接问文档里的章节号或文件名。

和 [07-完成一个需求时Cursor怎么走-从开始到停止.md](07-完成一个需求时Cursor怎么走-从开始到停止.md) 的差别：07 讲工作区和停止点；本文按时间线 **尽量列全文件**，并给裁剪建议。

---

## 假设

- 档位：**M**（一个 Web 仓 + 一个后端仓、1～2 个 API、列表/表单、不改生产配置）。
- 你丢来：Markdown / 飞书链接 / 截图均可。
- 工作区：控制面根（学习期 Open `rz-harness`；标本路径在 `learning_objectives/` 下）。
- 本机仓路径：已忽略的 `config/runtime_local.sh`（标本原名 `repos.local.sh`）。
- **第一件事不是写业务代码。** 开工关卡过了才能改业务仓。

档位对照：S = 单仓小修；M = 普通全栈/多文件；L = 跨仓、高风险、强依赖真实环境。M 比 S 多方案、契约、测试方案、独立验收和审查。

---

## 0. 开场（第一条回复，还不改代码）

中/重、跨仓、后端行为、DB、复杂 UI：给用户的**第一条回复**就要带「本次 harness 流程和停止点」，并开始用状态卡。

### 读（常驻，不是这次新建）

| 文件 | 作用 |
|---|---|
| `AGENTS.md` | 硬规矩、停止点、禁止项、完成定义 |
| `git-registry.md`（标本：`docs/architecture/repo-registry.md`） | 需求可能落在哪几个仓 |
| `config/runtime_local.sh`（gitignore） | 本机仓路径、账号**来源** |
| `baselines/<该仓>.md` | 仿写锚点、启动方式、保护路径 |
| `docs/skills-routing.md` | 要不要先读 grill / explorer |
| `lanes/fullstack-crud.md` 或 `bugfix-fast.md` | 选一条任务路线 |
| `skills/grill/SKILL.md` | 字段/权限/状态不清时拆 PRD |
| 你给的 PRD | 抽 `[FACT]` / `[ASSUMP]` / `[QUESTION]` |

### 新建

`changes/<change-id>/`（`change-id` 用业务含义，如 `promo-sku-unit`）。至少马上有状态卡；M 档会 scaffold 一整套根文件。

**停：** 阻塞 `[QUESTION]` 没答，不写业务代码。

---

## 1. 弄清需求（仍在控制面）

| 本次文件 | 作用 |
|---|---|
| `spec.md`（从 `templates/spec-tier-m.md` 拷） | 目标、IN/OUT、三标签、`allowed_paths`、改哪些仓 |
| `harness-status.md` | 你看到的阶段、下一步、Agent Roster |
| `requirement-intake.md` | M/L 结构化收需求（有则跑 intake gate） |
| Explorer 产出（可写进 spec 或独立 facts） | 仓内样板路径 |

**常驻对照：** 目标仓 `baselines/`；必要时只读 Explorer（`subagents/explorer_agent.md` / 标本 `skills/explorer/SKILL.md`）。

**跑：** `confidence-gate`（QUESTION / ASSUMP 清没清）。

**停：** 字段、状态、权限、错误码、默认值、回滚找不到出处。

---

## 2. 契约 + 全栈方案（仍不写业务代码）

| 本次文件 | 作用 |
|---|---|
| `contract.md` 或 `docs/contracts/<id>-api.md` | 接口、字段、错误码（前端只读这份） |
| `technical-solution.md`（模板 `templates/technical-solution.md`） | M/L 强制；PRD 每一面（前后端/导出…）都要覆盖 |
| 飞书子文档 | PRD 来自飞书时，方案要同步过去 |

**跑：** `technical-solution-gate.sh`；飞书再跑 `technical-solution-feishu-sync.sh`。

**停：** 你没把方案标成 CONFIRMED；本地改了方案却没再同步飞书。

---

## 3. 测试策略（独立角色，实现前）

| 本次文件 | 作用 |
|---|---|
| `ai-test-plan.md` | Test Strategy 写；**你确认**后才能写代码 |
| `verification-map.md` | 每条约束怎么验（命令 / 人确认 / N/A） |
| `backend-test-plan.md` | 有 Java 行为变更时 |
| `plan.md` | 实现步骤清单 |

**人设：** `subagents/test_strategy_agent.md`  
**跑：** `ai-test-plan-gate.sh`

**停：** 测试方案未确认。

---

## 4. 开工前（第一次改业务文件）

| 本次文件 | 作用 |
|---|---|
| spec 里的 `allowed_paths` | 白名单 |
| dirty-worktree 台账（若业务仓已脏） | 避免覆盖你未提交的改动 |
| `agent-dispatch-plan.md` | 准备派哪些子 Agent |
| `agent-candidate-confirmation.md` | **仅当**派 Backend / Frontend 实现 Agent |
| `skill-usage.md` | 用过哪些 skill 或写明 N/A |

**业务仓 git：** 从 `main`/`master` 拉 `codex/<change-id>`，不在主干上改。

**跑：** `business-code-start-gate`、`allowed-paths`、`assumption-leak`、`parallel-worktree-gate`（若派实现子 Agent）。

**读：** `rules/backend-java.mdc` 和/或 `rules/frontend-vue2.mdc`；`mapSystem` 再按需读 `rules/frontends/legacy-sfa/web/` 里和本次相关的几份。

**停：** 还在 main、路径越界、方案/测试方案未确认、QUESTION 未清。

---

## 5. 实现（业务仓 + 记证据）

主 Agent（或候选 Backend/Frontend）只改白名单；控制面默认只由主 Agent 写。

| 本次文件 | 作用 |
|---|---|
| `evidence.md` | 跑过的命令和结果（无密码） |
| `contract-delta.md` | 实现中契约有增量 |
| `ui-rule-checklist.md` | PRD 带 UI 时 |
| `ui-confirmation.md` | 复杂 UI：可跑页面/截图/URL |
| `data-model.md` + 可执行 SQL | **仅当**改 DB |
| `local-routing.yml` 等 | 本地前端打后端时 |

**命中才加：** CodeGraph 证据、小程序本地环境、临时状态台账。

**跑：** 最窄 compile/lint/单测；UI 则 `ui-rule-gate` / `ui-confirmation-gate`。

**停：** 要动 `.env`、生产配置、migration、宽 DELETE → 二次确认；高危 SQL 全局禁止。

---

## 6. 真环境 / E2E（只有真要点页面、打真实依赖时）

| 本次文件 | 作用 |
|---|---|
| `environment-readiness.md` | 环境、账号来源、数据、写库边界、回滚 |
| `pc-e2e-smoke-plan.md` / `pc-e2e-smoke-report.md` | PC 冒烟 |
| `temporary-state-ledger.md` | 本地服务、测试数据、二维码等要清理 |

**跑：** `environment-readiness-gate`；本地后端「可验收」要 HEALTH，不是只看端口。

**停：** 环境/账号/写库边界不清。纯编译验证可以没有这一段。

---

## 7. 独立验收 + 报告 + 审查（主 Agent 不能宣布成功）

| 本次文件 | 作用 |
|---|---|
| `test-agent-verification.md` | Tester 对照已确认测试方案；`GOAL_ACHIEVED` 或 `BLOCKED` |
| `ai-test-report.md` | 进测试/预发前，**你再确认**（标本 L 强制；M 若要提测/发布也常要） |
| `review.md` | 只读 Reviewer；`high_risk_count: 0` |

**人设：** `tester_agent.md`、`reviewer_agent.md`  
**派发协议：** `subagents/dispatch_subagent.md`  
**跑：** `ai-test-report-gate`、`reviewer-gate`

实现后又改代码：旧 Tester / Reviewer 结论作废，重跑。

**停：** 没有独立验收结论、审查未过门，主 Agent **不得说需求已完成**。

---

## 8. 人审 / 合并 / 收口

| 本次文件 | 作用 |
|---|---|
| `diff-hygiene` / 临时硬编码扫描 | 合并前脏 diff |
| `pre-pr.md` / `pre-pr-review.md` | 有则给人审包 |
| `retro.md` | M/L 复盘 |
| `decisions.md` | 过程中拍板记录（L 更强制） |

**停止工作：** 状态卡收口，或状态是 `BLOCKED` 且最小缺口已写清、等你决策。不是模型说「我写完了」就算停。

你说「开始开发 / 下一步 / 确认 / ok」时：只推进到**下一个已满足前置的关卡**，不能跳过方案确认、开工、Tester、Reviewer。

---

## 时间线（必经 vs 可跳）

```text
PRD
 → spec + 状态卡 + 问你 QUESTION          【必经】
 → 契约 + 技术方案（你确认）              【M 必经；S 可无方案全家桶】
 → 测试方案（你确认）                    【M 要独立验收则必经】
 → 分支 + allowed_paths + 开工检查       【必经】
 → 实现 + evidence                       【必经】
 → UI / DB / E2E 专用文件                【仅命中场景】
 → Tester +（发布前）测试报告你确认       【要宣称完成/提测则必经】
 → Reviewer 过门                         【M 建议必经；S 可弱化】
 → 人审 / PR / retro                     【交付必经人审；retro 可后补】
```

**完成定义**对应：M 档文档对齐、没有带着问号写代码、测试方案已确认、该跑的 E2E 环境清楚、Tester 有结论、Reviewer 过门、残余风险写清。

---

## 标本 M 档变更包：强制根文件

来源：`learning_objectives/docs/architecture/change-artifacts-spec.md` 的 `tier-m`。

`spec.md`、`harness-status.md`、`evidence.md`、`plan.md`、`contract.md`、`technical-solution.md`、`verification-map.md`、`ai-test-plan.md`、`test-agent-verification.md`、`agent-dispatch-plan.md`、`skill-usage.md`、`review.md`。

`agent-candidate-confirmation.md` 只在启用候选实现 Agent 时再加。

L 档再加：`environment-readiness.md`、`ai-test-report.md`、`decisions.md`。

---

## 裁剪：保留 vs 舍弃

**常驻** = 仓库里长期放着；**每次变更** = `changes/<id>/` 里长出来。

### A. 建议先留（没有就不成控制面）

| 常驻 | 每次变更（比 M 档标本更小也能起步） |
|---|---|
| `AGENTS.md` | `spec.md` |
| `git-registry.md` | `harness-status.md` |
| `config/runtime_local.example.sh` | `evidence.md` |
| `baselines/`（按仓） | 三标签能卡住开工 |
| `subagents/dispatch` + explorer / reviewer（tester 若要独立验收） | |

开工至少还要：**路径白名单 +「QUESTION 未清不能写代码」**（脚本可以后补，纪律要先有）。

### B. 做中型全栈时建议留（对应完成定义）

| 常驻 | 每次变更 |
|---|---|
| `templates/`：spec、技术方案、测试方案、review、验收 | `technical-solution.md`（你确认） |
| `rules/`：按栈入口 `.mdc`，不要 27 份 always-on | `contract.md`（有 API） |
| | `ai-test-plan.md`（你确认） |
| | `plan.md` 或把步骤写进状态卡（不要两份打架） |
| | `verification-map.md`（可与测试方案合并，标本是分开的） |
| | `review.md` |
| | `test-agent-verification.md`（若启用 Tester） |

### C. 按场景再加（没有场景可以不建）

| 场景 | 文件 |
|---|---|
| 飞书 PRD | 同步脚本 + 方案子文档 |
| 复杂 UI | `ui-rule-checklist`、`ui-confirmation`、legacy-sfa web 细则 |
| 改 DB | 数据模型 + SQL |
| 真 E2E | `environment-readiness`、smoke plan/report |
| 派 Backend/Frontend 子 Agent | `agent-dispatch-plan`、candidate 确认、worktree |
| Swagger 对外 VO | `rules/backends/swagger2` + gate |
| 小程序 / iOS 打包 | 对应 baseline + 专用规则/脚本 |
| CodeGraph | 可选，不是关卡 |

### D. 标本很厚、v1 可先舍弃或后补

- `agent-registry.yml` 全家桶（Cursor 派 Task 不靠它）
- 38 个 gate 一次上齐；先留 confidence / code-start / reviewer
- `skill-usage.md` + 对应 gate
- ECC、golden eval、telemetry、adapter 矩阵
- 多条 `lanes/`、飞书白板强制、OpenSpec
- intake / decisions / retro / pre-pr 包
- iOS/Android archive 规则、某次特陈需求专属仓表

裁剪口诀：**常驻要薄（入口 + 登记 + baseline + 人设）；每次变更只强制「spec / 状态 / 证据 /（M）方案与测试方案 / 审查」；其余全部场景触发。**

---

## 和相邻笔记

- 工作区、停止点：07  
- 名词：06  
- 从 0 写 harness 的步骤：04  
- 完成定义那句话：spec/plan/契约对齐 M/L 技术方案 + 无未决 QUESTION 进代码 + 需要时测试方案已确认 + Tester/Reviewer/E2E 环境
