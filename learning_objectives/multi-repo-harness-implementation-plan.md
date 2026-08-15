# 多仓库 AI Harness 搭建实施计划

> SUPERSEDED by docs/architecture/harness-workflow-and-design-principles.md.
> Historical implementation-plan context only; do not use this file as the active execution SSOT.

> 输入依据：`harness-engineering-target-plan.md` 与 `deep-research-report.md`。  
> 当前目标：在 `sfa-ai-harness` 当前项目中先搭出可运行的多仓库控制面，用一个真实低风险全栈试点验证闭环，再决定是否推广到更多业务仓。

---

## 0. 结论摘要

本计划不把目标定义为“先做一个大平台”，而是定义为：

1. 当前项目 `sfa-ai-harness` 作为控制面仓，承载跨仓规则、模板、知识库、sensors、evals、changes 和复盘记录。
2. 业务仓只放轻量 stub：`AGENTS.md` 指向控制面，本仓只保留命令、受保护路径和少量特例。
3. 第一个月只跑 1 条真实 Fullstack CRUD 试点 lane，验证 `spec -> plan -> 实现 -> sensors -> reviewer -> PR/SIT -> retro`。
4. 所有机制优先解决四个痛点：AI 不确定性伪装成事实、技术方案可读性差、harness 过重、多 agent 边界混乱。
5. 三个月后才考虑团队推广、低风险 lane 升级和 CI/Codeup 深度集成；起步阶段不上 RAG、不做多写代码 agent swarm、不追求无人值守。

---

## 1. 从两个文档合并出的实施原则

### 1.1 必须保留的方向

| 方向 | 来自文档的依据 | 本计划落点 |
| --- | --- | --- |
| 控制面 + 多业务仓 | 两份文档都建议用 control-plane 统一承载 OpenSpec、规则、eval、contracts | 当前项目成为 `sfa-ai-harness` 控制面仓 |
| 100 行 AGENTS.md | `harness-engineering-target-plan.md` 明确 AGENTS.md 是入口，不是百科 | 根目录 `AGENTS.md` 严格控制在 100 行以内 |
| 置信度门 | 目标方案把痛点 #2 作为首要问题 | 所有 spec 必须区分 `[FACT]` / `[ASSUMP]` / `[QUESTION]` |
| 渐进披露 | 两份文档都反对一次加载全部上下文 | `docs/README.md` 做索引，按场景读取子文档 |
| 确定性 sensor 优先 | deep research 强调 feedback/sensors；目标方案拆 computational/inferential | 先做脚本级 sensor，再做 reviewer/eval |
| 多 agent 最小化 | 目标方案明确默认只用 Explorer / Reviewer | Phase 0-2 不启用多个写代码 agent |
| 知识库版本化 | deep research 明确知识库是 memory 主体 | `docs/` 先做 Markdown，不先上 RAG |
| 真实试点先行 | 目标方案和历史经验都指向 pilot-first | 先选 1 个真实低风险 Fullstack CRUD |

### 1.2 必须压住的冲动

| 不做 | 原因 | 何时再看 |
| --- | --- | --- |
| 不改造旧 `.ai/harness/` 为主线 | 当前项目的目标是新控制面验证，不是搬旧规则 | 一个月试点 retro 后决定迁移 |
| 不先做 RAG / 向量库 | 起步阶段检索问题不明确，且不可追溯风险高 | `docs/` 超过 200 份且目录索引失效后 |
| 不先做多实现 agent 并行 | 契约、ownership、验证门未稳定前会增熵 | Phase 3 之后，且每个 agent 有独立 allowed paths |
| 不先做全仓系统地图 | 成本高，容易变成文档工程 | Phase 0 只做试点业务域局部地图 |
| 不先绑定 CI 平台 | Codeup 能力和 webhook 未验证 | 先保证脚本本地可运行，再接 CI |
| 不用“AI 写码占比”做成功指标 | 会鼓励错误优化 | 用越界次数、字段一致性、sensor 通过率、SIT escape 衡量 |

---

## 2. 需要你拍板的问题

这些问题不阻塞控制面骨架建设，但会影响 Week 1 是否能进入真实试点。当前已按 2026-05-19 的确认结果更新。

| 编号 | 决策项 | 已确认方案 | 后续动作 |
| --- | --- | --- | --- |
| D1 | `sfa-ai-harness` owner | 目前先由你一个人 owner | 试点结束后再决定是否设 2-3 人共管 |
| D2 | 第一个试点需求范围 | 四个业务仓全部写入控制面 registry；第一个真实低风险 CRUD 优先选 `mapSystem + sfa-sales-management`，范围仍控制为 1 个 Vue2 页面 + 1-2 个 Java 接口 + 不动复杂状态机 | Week 1 D2 继续选定具体需求 ID / PRD |
| D3 | 控制面到业务仓同步方式 | Phase 0-2 不把业务仓搬进当前项目；采用“兄弟目录相对路径 + 业务仓轻量 AGENTS stub”，必要时再补 raw URL | 先约定本地 workspace 布局；验证 Codeup raw URL 后再决定是否使用 |
| D4 | 飞书知识如何进入控制面 | 本地可用 `lark-cli` 读取和写入飞书文档 | Phase 0 先用 `lark-cli` 手工拉取 3-5 篇核心文档转 Markdown，自动同步脚本延后 |
| D5 | Reviewer subagent 校准 | 先用独立 Agent 做 review，再由你人工 review 一次 | 前 5 次记录 reviewer 输出与人工结论的 alignment |
| D6 | 是否回灌旧 `.ai/harness/` | 先不用考虑回灌旧 `.ai/harness/` | Phase 0-2 只维护当前控制面方案 |

### 2.1 D3 的落地建议

Phase 0-2 不建议把业务仓库放进当前项目目录。团队使用时，业务仓通过 `config/repos.local.sh` 中的 `$SFA_PROJECTS_ROOT` 和 `SFA_REPO_*` 变量定位；更稳的方式是让控制面通过明确环境变量引用这些兄弟工作区中的业务仓，业务仓通过轻量 `AGENTS.md` 指回控制面。

推荐本地布局：

```text
$HOME/
├── sfa-ai-harness/                  # 控制面仓
└── codex/sfa-projects/
    ├── sfa-sales-management/        # Java 后端仓
    ├── sfa-backend/                 # Java 后端仓
    ├── mapSystem/                   # Vue2 管理后台仓
    └── sign-up/                     # Vue2 H5 / 移动端仓
```

控制面中的 change 文件使用明确的 repo path：

```yaml
repos:
  backend_sales_management: $SFA_REPO_BACKEND_SALES_MANAGEMENT
  backend_sfa_backend: $SFA_REPO_BACKEND_SFA_BACKEND
  frontend_admin: $SFA_REPO_FRONTEND_MAP_SYSTEM
  frontend_h5: $SFA_REPO_FRONTEND_SIGN_UP
control_plane: $SFA_HARNESS_ROOT
```

业务仓只新增轻量 `AGENTS.md`，内容包括：

```markdown
# AGENTS.md

This repo is governed by `$SFA_HARNESS_ROOT`.

Read first:
- `$SFA_HARNESS_ROOT/AGENTS.md`
- active change spec under `$SFA_HARNESS_ROOT/changes/<change-id>/spec.md`

Repo commands:
- Compile/test/lint commands for this repo

Protected paths:
- production config
- deployment files
- DB migration unless explicitly allowed by spec
```

这样做的原因：

- 不破坏现有业务仓边界，避免把控制面变成伪 monorepo。
- 本地 Codex / Cursor 都能直接读绝对路径或相对路径，试点阶段摩擦最低。
- 后续如果 Codeup raw URL 稳定，再把业务仓 stub 中的本地路径替换成 raw URL。
- 如果团队需要离线或固定版本，再评估 git submodule；Phase 0-2 不先引入 submodule 成本。

### 2.2 实际仓库扫描结果

| 仓库 | 类型判断 | 技术标识 | 当前分支 | Codeup 远端 | 试点角色建议 |
| --- | --- | --- | --- | --- | --- |
| `$SFA_REPO_BACKEND_SALES_MANAGEMENT` | 后端 | Maven 多模块；Java 8；Spring Boot 2.2.5；模块含 `interfaces` / `application` / `domain` / `infrastructure` / `api`；已有 `openspec` 和 `AGENTS.md` | `master` | `want_sfa/sfa-sales-management.git` | 优先作为后端试点仓，层次更清晰 |
| `$SFA_REPO_BACKEND_SFA_BACKEND` | 后端 | Maven 多模块；Java 8；Spring Boot 2.2.5；模块含 `api` / `webapi` / `service` / `openapi`；已有 `openspec` | `master` | `want_sfa/sfa-backend.git` | 作为第二后端仓，适合跨服务或 downstream 依赖场景 |
| `$SFA_REPO_FRONTEND_MAP_SYSTEM` | 前端 | Vue 2.6.10；Vue CLI 3；Element UI；`src/views` 很大；脚本含 `dev` / `build:test` / `build:stage` / `build:prod` / `lint` / `test:unit` | `master` | `want-ceo/H5/mapSystem.git` | 优先作为 Vue2 管理后台试点仓 |
| `$SFA_REPO_FRONTEND_SIGN_UP` | 前端 | Vue 2.6.x；Vue CLI 4；Vant / Mint UI / Weixin JS SDK；`src/views/visit` | `master` | `want-sfa/sign-up.git` | 作为 H5 / 移动端仓，暂不作为首个后台 CRUD 试点 |

四个仓先全部写入控制面初始 registry：

```yaml
repo_registry:
  backend:
    sfa-sales-management:
      path: $SFA_REPO_BACKEND_SALES_MANAGEMENT
      role: sales-management-domain-service
      build_tool: maven
      primary_for_pilot: true
    sfa-backend:
      path: $SFA_REPO_BACKEND_SFA_BACKEND
      role: legacy-sfa-backend-service
      build_tool: maven
      primary_for_pilot: false
  frontend:
    mapSystem:
      path: $SFA_REPO_FRONTEND_MAP_SYSTEM
      role: vue2-admin-console
      build_tool: npm-vue-cli
      primary_for_pilot: true
    sign-up:
      path: $SFA_REPO_FRONTEND_SIGN_UP
      role: vue2-h5-mobile
      build_tool: npm-vue-cli
      primary_for_pilot: false

first_pilot_repos:
  frontend: $SFA_REPO_FRONTEND_MAP_SYSTEM
  backend: $SFA_REPO_BACKEND_SALES_MANAGEMENT
```

原因：

- `mapSystem` 是 Vue2 + Element UI 管理后台，更符合“1 个 Vue2 页面 + 1-2 个 Java 接口”的 CRUD 试点。
- `sfa-sales-management` 已经有分层模块和项目级 `AGENTS.md`，更适合验证控制面 stub、OpenSpec、allowed paths、Reviewer。
- `sfa-backend` 和 `sign-up` 不是首个 CRUD 主线，但必须进入 registry 和 baseline，避免控制面后续只适配一个前后端组合。
- 首个试点不建议同时改两个后端仓或两个前端仓；它们先作为依赖/对照仓参与影响分析和知识库盘点。

---

## 3. 当前项目目标目录

Phase 0-2 后，当前项目应形成下面结构。第一月只要求标注 `MVP` 的部分完整可用。`<pilot-change-id>`、`<repo>`、`<api>` 这类变量必须在 Week 1 D2 选定真实试点后替换成实际名称，不能原样进入执行产物。

```text
sfa-ai-harness/
├── AGENTS.md                         # MVP: 控制面入口，100 行以内
├── README.md                         # MVP: 人类说明，讲清怎么用
├── docs/
│   ├── README.md                     # MVP: 知识库索引
│   ├── baseline/                     # MVP: 试点前后端仓现状盘点
│   ├── architecture/                 # MVP: 试点业务域局部地图
│   ├── contracts/                    # MVP: 跨仓 API 契约
│   ├── decision-log/                 # MVP: 试点选择、规则取舍、复盘
│   ├── samples/                      # MVP: 可模仿样板索引
│   ├── data-models/                  # Phase 3: 表、Redis、MQ
│   └── ops/                          # Phase 3: Nacos、XXL-JOB、错误码
├── templates/
│   ├── spec-tier-s.md                # MVP
│   ├── spec-tier-m.md                # MVP
│   ├── spec-tier-l.md                # MVP
│   ├── plan-tier-m.md                # MVP
│   └── pre-pr-review.md              # MVP
├── rules/
│   ├── backend-java.mdc              # MVP
│   ├── frontend-vue2.mdc             # MVP
│   ├── mybatis-xml.mdc               # MVP
│   ├── sql-ddl.mdc                   # MVP
│   └── miniapp.mdc                   # Phase 3
├── skills/
│   ├── reviewer/SKILL.md             # MVP
│   └── explorer/SKILL.md             # MVP
├── scripts/
│   ├── confidence-gate.sh            # MVP
│   ├── allowed-paths.sh              # MVP
│   ├── mvn-targeted-test.sh          # MVP
│   ├── frontend-lint-build.sh        # MVP
│   ├── harness-self-audit.sh         # MVP
│   ├── lane-decision.sh              # Phase 3
│   └── feishu-to-md-sync.sh          # Phase 3
├── hooks/
│   └── post-tool-use.sh              # MVP: 可选自动触发，失败时退化为手工脚本
├── lanes/
│   ├── fullstack-crud.md             # MVP
│   ├── bugfix-fast.md                # Phase 3
│   └── backend-small-feature.md      # Phase 3
├── evals/
│   ├── datasets/                     # MVP: 1 条 golden scenario
│   └── results/                      # MVP: 试点运行结果
└── changes/
    └── <pilot-change-id>/
        ├── spec.md                   # MVP
        ├── plan.md                   # MVP
        ├── evidence.md               # MVP
        ├── review.md                 # MVP
        ├── pre-pr.md                 # MVP
        └── retro.md                  # MVP
```

---

## 4. 分阶段实施计划

### Phase 0：控制面骨架与试点选择（Week 1）

**目标**：当前项目先成为可被 AI 和人使用的控制面；不写业务代码。

| Day | 任务 | 产物 | 验收 |
| --- | --- | --- | --- |
| D1 | 创建控制面基础目录 | 上述目录 skeleton | 所有 MVP 目录存在 |
| D1 | 写 `AGENTS.md` 第一版 | `AGENTS.md` | 100 行以内；只做入口索引和硬规则 |
| D1 | 写人类入口说明 | `README.md` | 说明控制面、试点流程、怎么接业务仓 |
| D2 | 选择第一个真实试点 | `docs/decision-log/YYYY-MM-DD-pilot-selection.md` | 写清 IN / OUT / 风险 / 选择理由 |
| D2 | 建四仓 registry | `docs/architecture/repo-registry.md` | 四个仓的 path、类型、远端、分支、命令、试点角色齐全 |
| D2 | 盘点两个试点主仓 | `docs/baseline/mapSystem.md`、`docs/baseline/sfa-sales-management.md` | 命令、框架、受保护路径、痛点、验证命令齐全 |
| D2 | 轻量盘点两个非主仓 | `docs/baseline/sign-up.md`、`docs/baseline/sfa-backend.md` | 至少记录命令、模块结构、保护路径、与试点关系 |
| D3 | 写试点 spec V1 | `changes/<id>/spec.md` | `[FACT]` / `[ASSUMP]` / `[QUESTION]` 标齐 |
| D3 | 你回答 Top Decisions | `changes/<id>/spec.md` V2 | Open Questions 为 0 或明确非阻塞 |
| D4 | 写跨仓契约 Markdown | `docs/contracts/<api>.md` | 前后端字段、错误码、空态、分页都明确 |
| D5 | Week 1 复盘 | `docs/decision-log/YYYY-MM-DD-w1-retro.md` | 记录卡点、下周优先项、是否继续 |

**Phase 0 完成标准**：

- `AGENTS.md` 存在且短。
- 试点 change 有 spec V2。
- 两个业务仓 baseline 完成。
- 至少 1 个 contract 文档可作为前后端 mock 来源。
- 当前项目已经能回答“AI 开始前该读什么、不能改什么、怎么验证”。

### Phase 1：最小控制包（Week 2）

**目标**：把规则从“说明”变成可重复使用的模板、规则和脚本。

| Day | 任务 | 产物 | 验收 |
| --- | --- | --- | --- |
| D1 | 写 Tier S/M/L spec 模板 | `templates/spec-tier-*.md` | S/M <= 200 行，L <= 500 行 |
| D1 | 写 Tier M plan 模板 | `templates/plan-tier-m.md` | 包含 allowed paths、验证命令、回滚 |
| D1 | 写 Pre-PR 自审模板 | `templates/pre-pr-review.md` | 1 页左右，能直接复制到 change |
| D2 | 写 Cursor rules 四件套 | `rules/backend-java.mdc` 等 | 每个 <= 150 行；有 globs；单一职责 |
| D2 | 写业务仓 stub 模板 | `templates/business-repo-agents-stub.md` | 30 行左右；指向控制面 |
| D3 | 写 `confidence-gate.sh` | `scripts/confidence-gate.sh` | 能发现未标标签、未解决 QUESTION |
| D3 | 写 `allowed-paths.sh` | `scripts/allowed-paths.sh` | 能检查 diff 是否越过 spec allowed paths |
| D3 | 写 Java / 前端验证脚本 | `scripts/mvn-targeted-test.sh`、`scripts/frontend-lint-build.sh` | 缺命令时给出清晰失败信息 |
| D4 | 写 Explorer skill | `skills/explorer/SKILL.md` | 只读；输出 FACTS 和证据路径 |
| D4 | 写 Reviewer skill | `skills/reviewer/SKILL.md` | 只读；审 FACTS、ASSUMP 泄漏、越界、隐性功能、验证缺口 |
| D4 | 验证 Codex / Cursor 加载方式 | `docs/decision-log/YYYY-MM-DD-tool-loading-check.md` | 记录能用、不能用、退化方式 |
| D5 | 写第一条 golden scenario | `evals/datasets/<id>.yaml` | 包含 prompt、allowed paths、required checks、grader |
| D5 | Week 2 复盘 | `docs/decision-log/YYYY-MM-DD-w2-retro.md` | 明确哪些自动化不能用，脚本如何手工跑 |

**Phase 1 完成标准**：

- 3 个 spec 模板、1 个 plan 模板、1 个 Pre-PR 模板可用。
- 4 个 rules 文件可镜像到试点仓。
- 4 个核心 scripts 可独立运行，即使 hooks 不可用也能手工触发。
- Reviewer / Explorer 都是 read-only 工作流。
- golden scenario 有结构，允许暂时不全自动运行。

### Phase 2：真实试点闭环（Week 3-4）

**目标**：让一个真实需求在 harness 内完整走完。

| 时间 | 任务 | 产物 | 验收 |
| --- | --- | --- | --- |
| W3-D1 | 用 spec V2 生成 plan | `changes/<id>/plan.md` | allowed paths、验证命令、回滚、人工拍板点齐全 |
| W3-D1 | 计划评审 | `docs/decision-log/YYYY-MM-DD-plan-review.md` | 你确认后才进入实现 |
| W3-D2 | 后端实现 | 业务仓后端分支 / commit + `evidence.md` | compile + targeted test + allowed-paths 通过 |
| W3-D3 | 前端实现 | 业务仓前端分支 / commit + `evidence.md` | lint + build/test + contract 映射通过 |
| W3-D4 | 联调前 contract check | `changes/<id>/evidence.md` | 前后端字段、错误码、空态无漂移 |
| W3-D4 | Reviewer 审查 | `changes/<id>/review.md` | HIGH = 0；MEDIUM 由你判断是否修 |
| W3-D5 | 运行 golden scenario | `evals/results/<id>-w3.md` | 记录真实通过/失败，不粉饰 |
| W4-D1 | Pre-PR 自审 | `changes/<id>/pre-pr.md` | 所有 checklist 有证据 |
| W4-D2 | 提业务仓 PR | PR 描述引用 spec、plan、evidence、review | 人类 review 可追溯 |
| W4-D3 | SIT / 测试环境 smoke | SIT 记录 | 至少覆盖 happy path、空态、异常态、回滚 |
| W4-D4 | 完整 retro | `changes/<id>/retro.md` | 数据化评估本次 harness 是否减负 |
| W4-D5 | 规则取舍决策 | `docs/decision-log/YYYY-MM-DD-rule-decisions.md` | 保留、删除、重写、延后都有理由 |

**Phase 2 完成标准**：

- 一个真实全栈试点从 spec 到 SIT 闭环完成。
- 0 个未确认 `[ASSUMP]` / `[QUESTION]` 进入实现。
- 0 个 allowed paths 越界。
- Reviewer 至少给出有效风险或证明其无效；不能只看“通过”。
- retro 说清：哪些规则真正挡住问题，哪些只是负担。

### Phase 3：推广前加固（Month 2）

**目标**：在不扩大混乱的前提下，把试点经验抽成可复制 lane。

| 工作包 | 任务 | 产物 | 验收 |
| --- | --- | --- | --- |
| Lane 固化 | 把试点经验整理成 `lanes/fullstack-crud.md` | Fullstack CRUD lane | 第二个人能按 lane 复跑 |
| 知识库补强 | 补 `system-map`、`service-catalog`、`samples` | `docs/architecture/*`、`docs/samples/*` | 不再依赖口头解释找样板 |
| Sensor 加固 | 增加 contract snapshot、ArchUnit 或简单依赖扫描 | `scripts/check-contracts.sh` 或业务仓测试 | 能挡住至少一个真实越界风险 |
| Codeup 验证 | 查 branch protection、webhook、流水线能力 | `docs/decision-log/YYYY-MM-DD-codeup-ci-check.md` | 决定 A/B/C 同步方案 |
| 人员试跑 | 让 1 位团队成员跑 1 个低风险任务 | 第二条 change 记录 | 不靠你口头指导也能完成主要步骤 |

**Phase 3 不追求**：自动合并、无人值守、复杂业务 lane。

### Phase 4：低风险 lane 自动化（Month 3）

**目标**：让某一类低风险任务进入 3-4 级自动化。

候选 lane：

1. 文档 / contract-only 更新。
2. Tier S bugfix。
3. 后台列表页字段展示类小改。
4. 测试补齐 / 样板补齐。

进入 4 级的硬条件：

- 同类 lane 连续 5 次无 SIT escape。
- Reviewer HIGH = 0，且人工抽检 alignment >= 80%。
- Computational sensors 稳定可跑。
- 回滚路径明确。
- 不触碰 DB migration、生产配置、权限、财务、订单、状态机。

### Phase 5：团队化治理（Month 4+）

**目标**：把 harness 变成团队工程资产，而不是个人脚本集合。

| 方向 | 动作 | 成功标志 |
| --- | --- | --- |
| Owner 机制 | 设 2-3 个控制面 maintainer | 规则变更有人 review |
| 规则生命周期 | 每两周运行 `harness-self-audit.sh` | 每次至少删除或降级 1 条无用规则 |
| 复盘机制 | 每个 lane 保留 `retro.md` | 同类问题不重复出现 |
| 文档同步 | 飞书核心文档进入 Markdown 镜像或手工摘录 | AI 可稳定找到事实源 |
| 工具适配 | Codex / Cursor / Codeup 的差异写入 docs | 不靠个人记忆解释工具差异 |

---

## 5. 多仓业务仓接入标准

每个业务仓只做最小接入，不把控制面复制进去。

### 5.1 业务仓必须新增或确认

| 文件 | 内容 | 行数目标 |
| --- | --- | --- |
| `AGENTS.md` | 指向控制面、当前仓命令、保护路径、本仓例外 | <= 30 行 |
| `.cursor/rules/*.mdc` | 从控制面复制或镜像对应规则 | 单文件 <= 150 行 |
| `.codex/config.toml` 或个人配置说明 | 标明保护路径和推荐命令 | 不强求首月落地 |
| PR checklist | 引用控制面 Pre-PR 模板 | 1 页 |

### 5.2 业务仓禁止在 Phase 0-2 做的事

- 不把完整控制面 docs 复制进业务仓。
- 不在业务仓写第二套互相冲突的 harness 规则。
- 不把未验证的 hooks 作为唯一门禁。
- 不让 agent 直接改 prod 配置、Nacos 线上配置、部署脚本、DB migration。

---

## 6. Sensors 分层

### 6.1 Phase 1 必须实现的确定性 sensors

| Sensor | 脚本 | 检查内容 | 失败处理 |
| --- | --- | --- | --- |
| Confidence Gate | `scripts/confidence-gate.sh` | spec 标签、未解决问题、ASSUMP 泄漏风险 | 阻断实现或 Pre-PR |
| Allowed Paths | `scripts/allowed-paths.sh` | diff 是否只在 plan 允许路径内 | 越界必须人工确认 |
| Java Targeted Test | `scripts/mvn-targeted-test.sh` | Maven compile / targeted test | 输出模块和建议命令 |
| Frontend Lint Build | `scripts/frontend-lint-build.sh` | Vue2 lint / build / unit smoke | 输出缺失脚本或失败摘要 |

### 6.2 Phase 2-3 再补的 sensors

| Sensor | 触发条件 | 原因 |
| --- | --- | --- |
| Contract snapshot | 接口字段变更 | 防止前后端字段漂移 |
| ArchUnit / 依赖扫描 | Java 仓稳定后 | 防 Controller 直连 Mapper 等架构漂移 |
| ESLint import boundary | Vue2 仓可统一 lint 后 | 防页面绕过 API SDK |
| Golden scenario eval | lane 稳定后 | 评估 agent 是否按流程完成 |
| Reviewer subagent alignment | 每周抽样 | 判断 reviewer 是否可信 |

---

## 7. 成功指标

### 7.1 Week 1 必须量 baseline

| 指标 | 量法 |
| --- | --- |
| 试点类似需求历史耗时 | 找最近 3-5 个相近需求估算 |
| 前后端字段不一致次数 | 联调 / SIT / 线上问题回忆或记录 |
| AI 越界改动次数 | 最近两周个人使用 AI 的问题记录 |
| 需求确认次数 | 最近需求中反复问产品/后端/前端的次数 |
| 当前 harness 负担感 | 1-5 分主观评分，但要写原因 |

### 7.2 一个月目标

| 指标 | 目标 |
| --- | --- |
| 试点总耗时 | <= baseline 的 70%，如果未达到要解释原因 |
| 字段不一致 | 0 |
| 越界改动 | 0 |
| 未确认推断进入实现 | 0 |
| Computational sensors 可独立运行 | 100% |
| Reviewer 有效性 | 至少发现 1 个真实风险，或 retro 证明其暂时无价值 |
| 控制面核心文档 | >= 5 份 |
| 团队可复用性 | 至少 1 个业务仓 stub 合入或准备合入 |

### 7.3 三个月目标

| 指标 | 目标 |
| --- | --- |
| Fullstack CRUD lane | 可由第二个人复跑 |
| Bugfix Fast lane | 达到 3 级受边界自动驾驶 |
| Golden scenarios | >= 5 条 |
| docs 覆盖核心资产 | system-map、service-catalog、contracts、samples、error-codes 至少 5 类 |
| Reviewer alignment | >= 80% |

---

## 8. 风险与缓解

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| Cursor hooks 能力不稳定 | 自动触发 sensor 失败 | 所有 sensor 必须能手工脚本运行 |
| Codex 桌面与 CLI 能力不同 | skills/subagents 行为不一致 | Week 2 单独写 tool-loading check |
| Codeup raw URL 不稳定 | 业务仓无法引用控制面 | 先本地相对路径，必要时改 submodule |
| 试点需求选复杂了 | 一个月闭环失败 | Week 1 D2 严控：不动复杂 DB / 状态机 / 权限 |
| 文档太重团队不用 | harness 变负担 | AGENTS 短、模板短，每两周删规则 |
| AI 伪装 `[FACT]` | 置信度门失效 | Reviewer 反查来源；人工抽检 5% |
| Reviewer 只输出空泛建议 | inferential sensor 无效 | 要求证据路径；无证据则标为低价值并改 prompt |
| CI 接入拖慢 | 试点延迟 | Phase 0-2 不依赖 CI，脚本先跑通 |

---

## 9. 当前项目下一步执行清单

这是从“计划”进入“搭建”的最小执行顺序。

1. 新增目录 skeleton。
2. 写根 `AGENTS.md`，控制 100 行以内。
3. 写 `README.md`，说明控制面怎么用。
4. 写 `templates/spec-tier-m.md` 和 `templates/pre-pr-review.md`。
5. 写 `docs/decision-log/YYYY-MM-DD-pilot-selection.md`，等待你确定试点。
6. 选定试点后，补两个业务仓 baseline。
7. 写试点 `changes/<id>/spec.md`，先暴露问题，再由你拍板。
8. 写最小 scripts：`confidence-gate.sh`、`allowed-paths.sh`。
9. 写 Reviewer / Explorer skill。
10. 启动真实试点闭环。

---

## 10. 判定是否可以推广的门槛

一个月后，只有满足下面条件才进入 Phase 3 推广：

- 试点真实完成，而不是只完成文档。
- retro 里能列出至少 3 个 harness 带来的实际收益或暴露的问题。
- 规则清单没有继续膨胀，至少删掉或降级 1 条无用规则。
- 业务仓开发者能理解 stub `AGENTS.md`，不需要读完整控制面。
- 你能回答：下一个 lane 复制哪些资产、丢弃哪些资产、为什么。

如果不满足，不算失败，结论应是继续缩小范围：只保留 spec 模板、allowed paths、contract 和 reviewer，暂停 rules / hooks / eval 扩展。
