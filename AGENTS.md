# AGENTS.md (rz-ai-harness)

本仓库是 RZ AI Harness **控制面**：规矩、模版、gate、子 Agent 人设、变更包工作目录。业务代码在各自 git 仓里，用磁盘路径引用，不要把业务仓 clone 或拷进本目录。

## 控制面（control plane）
控制面 = 本仓库 `rz-harness`，harness 的载体。目录 / 内容分两类：
- **配置类**：要按本机环境和使用的 runtime（Cursor / Codex / OpenCode）做本地化填写。包括运行时参数，Git 仓库， Hook 机制
- **静态类**：装好即用，内置能力，功能不按环境改。包括语言政策，模版文件，工具&脚本，子 Agent，知识与规则

### 运行时参数
- 本机配置：路径 `config/runtime_local.sh`，按当前开发环境填写。参数至少包括：业务仓绝对路径、账号/凭据**来源**、数据库连接信息、本地服务地址/代理/端口、本机工具命令等
- 明文密码、token、cookie 等只放在 `config/runtime_local.sh` 或系统钥匙串。以上禁止写入 spec、evidence、状态卡或任何会进 git 仓库的文件

### 语言政策
- 给人工 review / 用户确认的文档默认使用简体中文
- 代码标识、命令、API 路径、字段名、错误码、YAML key、日志 key 和引用这些原文保持原样不要翻译为英文

### Git仓库
先读 `git-registry.md`。当前仓库：
- 后端代码：`sfa-sales-management`、`sfa-backend`、`sfa-root`、`sfa-base`、`arch-open`、`arch-event`、`sfa-common-sdk`
- Web端代码：`mapSystem`
- App端代码：`sign-up`、`sfa-ios`、`sfa-android`

### Baseline
> 仓说明书在 `baselines/` 目录下。**不要一次读完全部。** 只读本次变更涉及的仓。

- 主 Agent 在写该仓 `allowed_paths`、选样板、第一次改业务代码之前读取对应文件。Explorer 下钻业务仓前先读。Backend / Frontend / Mobile 实现前必读。Reviewer 审查该仓 diff 时对照其中的分层、样板和受保护路径。
- `mapSystem` 额外遵守 `baselines/frontend-map-system.md` 的 Node 版本、登录和临时路由约定。

### 模版文件
> 全部模板文件保存在目录 `templates/`，用来生成 change 变更包所需文件。`templates/template_directory.md` 为字典目录（每个 template 作用是什么、用在哪段流程、拷到变更包后叫什么）。

### 工具&脚本
> - 门禁脚本在 `gates/`。（见「gate（门禁）」）
> - 脚本工本在 `scripts/`。快速定位见 `scripts/script_directory.md`
> - skill工具在 `skills/`。快速定位和使用规则见 `skills/skill_directory.md`

### 子 Agent
> 角色人设。（见「子 Agent」）

### 知识与规则
> 知识库在 `docs/`。用来给人看的文档。全量说明（含流程图）见 `docs/readme.html`。执行仍以本文件为准
> 规则库在 `rules/`。用来给 LLM 生成代码时做参考

### Hook 机制
> - 大多数 runtime（Cursor / Codex / OpenCode）都有自己的 hook 机制。用户可以自定义“当某事件发生时，让 runtime 执行某个脚本”。和 LLM 的 `tool_call` 不同，hook 是 runtime 的功能，不依赖 LLM 决策
> - **触发方式**上，hook 是“推式”（runtime 在事件点一定会执行），比“拉式”（靠人 / agent 记得跑 gate）更可靠。重要 gate 挂到 hook 上自动执行，可降低漏执行风险。（注意：gate 是“检查内容”，hook 是“触发时机”，二者不是比谁靠谱的同类）
> - 不同 runtime 的 hook 设置方式不同，选定 runtime 后要按 `hooks/hook_setup.md` 接线。`hooks/hook_adapter.sh` 只做路由（转发到 `hooks/harness-sensor-runner.sh`）；检查逻辑在 runner 里（危险命令 / code-start 瘦身 / 有 `RZ_CHANGE_SPEC` 时跑 `gates/allowed-paths.sh`）

流程：
```text
        runtime 事件点
           │ 触发
           ▼
        各 runtime 接线（见 hooks/hook_setup.md）
           Cursor: .cursor/hooks.json    
           Codex: .codex/hooks.json
           OpenCode: 按 hooks/hook_setup.md 本机建 plugin（spawn 同一脚本）
           │ 调用
           ▼
           hooks/hook_adapter.sh（只路由）
           │
           ▼
        hooks/harness-sensor-runner.sh（做事）
           ├─ pre  事件：能硬停（拦 commit / 危险命令）
           └─ post 事件：只能警告、拦下一步，不能撤销
```
目前 hook 会执行的检查在 `hooks/harness-sensor-runner.sh`。检查内容包括危险 shell（`rm -rf`、`git push --force` 等）和不符合规则的 git 命令。


## 领域名词
### harness / runtime
| 词 | 是什么 | 负责什么                                      |
|---|---|-------------------------------------------|
| **runtime** | 真正跑起来的 agent 程序（Cursor / Codex / OpenCode） | 提供 agent 循环、读文件、跑 shell、权限、沙箱——**能跑**     |
| **harness** | 套在 runtime 外面的工程系统（规则 + 工件 + 检查 + 流程） | 让 agent **在边界里跑**：改哪些文件、什么时候必须停、宣称完成拿什么证明 |

### 档位
> 这次需求使用哪个档位分级，使用不同档位流程上会有不同的步骤。不一定代表需求大小，而是改动范围、风险和环境依赖。功能点少也可能是 L（例如改权限、动真实库）；页面很多也可能是 S（单仓低风险小修）。

| 档 | 典型长什么样 | 流程上多什么                                  |
|---|---|-----------------------------------------|
| S | 单仓小修、文档、低风险脚本 | 只要 spec / 状态卡 / 证据                      |
| M | 普通全栈或多文件业务，大约 1～2 个 API | 包括 S 档内容，再加强制方案、契约、测试方案、Tester、Reviewer |
| L | 跨仓、高风险、强依赖真实环境、发布前风险高 | 包括 M 档内容，再加环境就绪、测试报告、决策记录               |

### 需求理解（FACT/ASSUMP/QUESTION）
> 主 Agent 把「PRD 写了的 / 代码里已有的 / 用户说的 / 模型猜的」拆开，写进 `changes/<change-id>/spec.md`。聊天不是事实源。没出处的业务规则、字段、状态、权限、错误码、默认值、回滚规则不是事实。

| 标签 | 是什么 | 限制                                                             |
|---|---|----------------------------------------------------------------|
| `[FACT]` | 有出处：PRD、用户确认、现有代码、已冻契约、线上已有行为 | 只有这类可以进实现                                                      |
| `[ASSUMP]` | 模型推断、尚未确认 | 不阻塞开工，但这条不得作为实现依据；一旦渗进实现文件，`gates/assumption-leak-gate.sh` 会检查出 FAIL |
| `[QUESTION]` | 必须用户决定，Agent 不能代选 | 阻塞项未清，不得写业务代码                                                  |

注意：拿不准时写成 `[QUESTION]`，不要先标成 `[FACT]`。

**谁写：** 
- 主 Agent 理解需求文档、定义全部三标签、写入 `spec.md`。
- Explorer （可选）只读、不改文件；主 Agent 对业务仓现状吃不准时才派，Explorer 在对话里按三标签供料（含证据路径）
- 主 Agent 会根据 Explorer 查证的信息决定采纳与否再落 `spec.md`
- 用户答阻塞 `[QUESTION]`、确认或推翻 `[ASSUMP]`；答完后由主 Agent 改标签

**何时：** 建包时 scaffold 拷模板，文件里已有占位标签，不是已经问过用户。需求理解阶段（停止点 1）填写实质内容，然后停下来问用户。用户答完，主 Agent **原地**把该行改成带来源的 `[FACT]`（`[QUESTION]` 和已确认的 `[ASSUMP]` 都这样处理，不能留下 `[QUESTION]` 再另写一行 FACT），再跑 `gates/confidence-gate.sh`。口头「ok」不算过。

**写法：** 
- 三种标签都必须出现。没有假设写 `[ASSUMP] None.`。
- 不影响本次实现的 `[QUESTION]` 放到 `non_blocking_questions:` 下，默认不拦开工；
- 吃不准是否阻塞就放正文当阻塞项
- 其他模板（契约、技术方案）里的 `[QUESTION]` 只是空格占位，`gates/confidence-gate.sh` 不扫那些文件
- 要拿某条 `[ASSUMP]` 去写代码，必须先确认成 `[FACT]` 才能进行代码实现

| Gate | 查哪                                   | 过不了意味着                                                |
|---|--------------------------------------|-------------------------------------------------------|
| `gates/confidence-gate.sh` | 扫描 `spec.md`：阻塞 `[QUESTION]` 是否还在；`lane` 是否为唯一合法值，且与 `status-card.md` 的 `Lane` 一致 | 问题没答完，或 lane 仍是 `TODO` / 与状态卡不一致，不能开工。**不会**因为 `spec.md` 里还留着未确认 `[ASSUMP]` 就不开工 |
| `gates/assumption-leak-gate.sh` | 检查实现文件里有没有 `[ASSUMP]` 字面标签，以及 spec 中假设的标识符有没有漏进实现代码   | 假设漏进实现                                                |


## 运行机制：Guides 与 Sensors
> harness 会**围住** agent：行动前喂资料（Guides），行动后压检查（Sensors）

### 一张图：两层控制怎么围住 agent 让其循环执行，判断
```text
        Guides（AGENTS / templates / baselines / subagents 人设 / lane）
                    ↓ 行动前喂进去
              agent 干活（act）
                    ↓ 产出 / 动作
        Sensors（gates / 编译 / lint / 测试 / Reviewer）
                    ↓ FAIL → 把 FIX 压回 agent，重做
                    ↓ PASS → 继续
```

- Guides 会失败（模型可能不读、读了也可能违反），所以必须有 Sensors 兜底。
- 需要人拍板的节点见「停止点」——本质是 loop 暂停、把控制权交回给人的时刻。

### Guides：行动前的引导（不自动拦）
> 喂给 agent 读的说明，靠“读”起作用，**本身不 PASS/FAIL、不拦截**：`AGENTS.md`、`templates/`、`baselines/`、`subagents/` 人设、`lanes/`。

### Sensors：行动后的检查（会拦）
> agent 动作后压回来的检查，判定失败就是反向压力，逼它重做：

| 层 | 例子 | 怎么判 |
|---|---|---|
| **确定性（Computational）** | `gates/*.sh`（gate）、编译、lint、测试、扫描 | 脚本 / 工具，可重复、可机判 |
| **推断性（Inferential）** | Reviewer 审查 | 模型 / 人判断 |

设计时先问：这条约束能不能用脚本判？能 → 写成 gate；不能（代码好不好、架构漂不漂）→ 交 Reviewer。另外 gate 本身是**拉式**的：要有人 / agent 去跑它，自动跑要靠 hook。

### gate（门禁）
> gate 是 Sensors 里最“确定性”的一类：只做能**算清**的判断（文件是否存在、字段是否填了、路径是否在白名单），写成脚本、放 `gates/`

检查变更包产出物或流程状态、输出 PASS/FAIL 的可执行脚本。主 Agent / hook 根据 exit code 判断流程继续或阻断。gate 只裁决不干活。

- 位置：`gates/` 目录；`gates/gate_directory.md` 为字典目录（每个 gate 检查什么、何时跑、前置依赖）
- 实现：bash 脚本，当前均为 `*.sh`
- exit code 约定：`0` = PASS 可继续；非 `0` = FAIL 阻断
- FAIL 诊断输出 `FAIL / CODE / FIX / SAMPLE` 四要素（问题、错误码、怎么修、参考模板）
- gate 检查的对象是 `changes/<change-id>/` 下的产物（spec、evidence、状态卡等）；命令证据记录在 evidence.md，不由 gate 承载
- **fail-closed**：判定不了时默认 **FAIL**——文件缺失、字段没填、条件无法判定都不算通过；不许“找不到就跳过/放行”（反向的 fail-open 是明确禁止的）

### 停止点
停止点和流程节点并不一一对应。流程中需要确认的点。停止点分两类：
- **用户拍板类**：必须等用户在对话里确认才能进入下一阶段。口头确认后由**主 Agent**把确认状态写入对应文件，再跑 gate；用户不用自己改 YAML。
- **自动关卡 / 独立角色类**：gate 或 Tester / Reviewer 放行。用户不逐项参与；`BLOCKED` 或 HIGH 才升级给用户。

`status-card.md` 只镜像进度，不是拍板原文。`BLOCKED` 是合法停、升级给用户，不是放行。gate 脚本在 `gates/`；状态卡收集脚本在 `changes/status-card.sh`（只读，不裁决）。

用户平时节奏：**答 QUESTION（1）→ 确认方案（2）→ 确认测试方案（3）→（条件）确认 UI（6）→ 确认测试报告（8）→ 人工 review**。4 / 5 / 7 / 9 平时无需介入。

编号与阶段顺序不一一对应：环境材料（4）可提前准备，强制时点在真实 E2E 前；code-start（5）先于 E2E；验收阶段可同时挂 7 / 8 / 9。契约冻结不是这 9 个里的编号项，未冻不得实现。DB 真实写入二次确认挂在实现阶段内，仍由用户拍板。pre-merge 卫生扫描是检查项，不是决策停止点。

| # | 停止点 | 类型 | 谁写产物                                                                                               | 用户要干嘛 | 谁检查 | 怎样算过 |
|---|---|---|----------------------------------------------------------------------------------------------------|---|---|---|
| 1 | Spec 三标签 | 拍板 + gate | 主 Agent 写 `spec.md`；Explorer 只读供料。用户答完后，主 Agent 把该项改成带来源的 `[FACT]` | 答阻塞 `[QUESTION]`、确认 `[ASSUMP]` | `confidence-gate.sh` | 阻塞项已清，且 `lane` 为唯一合法值并与状态卡一致；未清不得进实现 |
| 2 | 技术方案（仅 M/L） | 拍板 + gate | 主 Agent 写 `technical-solution.md`（全栈）。用户拍板后，主 Agent 改文首 YAML：`confirmation_status: CONFIRMED`、`confirmed_by` / `confirmed_at`、`allowed_next_stage` 非 `none` | 审方案，在对话里确认或要求改 | `technical-solution-gate.sh` | 文件已 `CONFIRMED`；未过不得写业务代码。**S 本停止点 N/A** |
| 3 | AI 测试方案（仅 M/L） | 拍板 + gate | Test Strategy 写 `ai-test-plan.md`。用户拍板后，主 Agent 写成 `test_plan_status: CONFIRMED` | 审测试方案，在对话里确认或要求改 | `ai-test-plan-gate.sh` | 已 `CONFIRMED`；未过不得实现。**S 本停止点 N/A** |
| 4 | 环境就绪 | 自动关卡（仅真 E2E） | 主 Agent 写 `environment-readiness.md`；账号只写来源                                                        | 自动点，无需用户参与 | `environment-readiness-gate.sh` | `environment_status: READY`；真 E2E 前必须 READY |
| 5 | Code start | 自动关卡 | 主 Agent 从业务仓远程主干 `origin/master`（或 `origin/main`）拉 `harness/<id>`；`allowed_paths` 写在 spec；脏仓先写 `dirty-worktree-ledger.md` | 自动点，无需用户参与 | **S：** `confidence-gate.sh`、`assumption-leak-gate.sh`、`allowed-paths.sh`。**M/L 再加** `business-code-start-gate.sh`。脏仓再加 `business-dirty-worktree-gate.sh` | 开工门禁通过（S 三重 / M/L 四重，见「强制工作流」②）；未过不得改业务文件 |
| 6 | 复杂 UI 确认 | 拍板（条件触发） | 主 Agent 写 `ui-confirmation.md`。用户拍板后，主 Agent 把判定表写成 `Status: CONFIRMED`，并在人工确认表加一行 Decision=`CONFIRMED` | 看可运行页面，在对话里确认。PC smoke 不能替代 | `ui-confirmation-gate.sh`；规则缺口走 `ui-rule-gate.sh` | 已 `CONFIRMED`；未确认不得声称 UI 通过 |
| 7 | Tester 验收（仅 M/L） | 独立角色 | Tester 写 `test-agent-verification.md`。主 Agent 只修代码、补证据，不得代裁、不得自称 `GOAL_ACHIEVED`                   | 自动点，无需用户参与 | `test-agent-verification-gate.sh` | 仅 `GOAL_ACHIEVED` 才放行。`BLOCKED` 是停不是过。此后改代码必须重跑。**S 可 `N/A`** |
| 8 | AI 测试报告 | 拍板 + gate（L 强制；M 提测/预发时要） | 主 Agent 写 `ai-test-report.md`。用户拍板后，主 Agent 改「人工确认」YAML：`confirmation_status: CONFIRMED`；进预发还要 `recommendation: 允许进入预发` | 审报告、残余风险、是否进预发，在对话里确认 | `ai-test-report-gate.sh` | 已人工 `CONFIRMED`；未确认不得进测试/预发 |
| 9 | Reviewer 过门 | 独立角色（M/L 强制；S 建议） | Reviewer 写 `review.md`。主 Agent 不得代裁                                                                | 自动点，无需用户参与 | `reviewer-gate.sh` | `high_risk_count: 0`。代码又变则审查过期，按需重跑 Tester 再重跑 Reviewer |

## 变更包（change）
> 一次需求开始会创建目录 `changes/<change-id>/` ，相当于这次需求的本机工作目录。**整包不提交 git**（`.gitignore` 为 `/changes/*/`）。`changes/` 根下的 `change-scaffold.sh`、`status-card.sh`、`change-whitelist-spec.md` 是控制面，要进 git。

### 脚本
执行 `changes/change-scaffold.sh --tier S|M|L <change-id>` 。脚本会：
- 新建目录 `changes/<change-id>/`
- 预建 `changes/<change-id>/artifacts/` 子目录，作为大文件（截图 / 录屏 / trace / 长日志）的统一落点
- 按档位（S/M/L）把所需 md 从 `templates/` 原样 copy 到变更包目录
- 当场拼一个空表 `evidence.md`
- M/L 同时拷 `templates/agent-dispatch-plan.md` 空壳（不调标本 `agent-dispatch-plan.sh`）

### 白名单策略
白名单策略（控制能出现的文件）会判断 `changes/<change-id>/` 目录中是否产生不应该出现的文件
- 通过 `changes/change-whitelist-spec.md` 定义可以出现哪些文件
- 通过 `gates/change-artifacts-gate.sh` 检查是否出现没在白名单中的文件
- 大文件（截图、录屏、trace、长日志）放 `changes/<change-id>/artifacts/`，不要摊在包根、也不要放到仓库根的 `artifacts/`

### 状态卡（`status-card.md`）
> 给人看的**单一流程入口**：这次需求走到哪、下一步是什么、卡在哪、要不要你拍板、子 Agent 在干什么。

#### 作用
> 把各产物上的真实状态抄成一张卡。方案是否 `CONFIRMED`、环境是否 `READY`、Tester 是否 `GOAL_ACHIEVED`，原文在各自 md 里。状态卡只镜像，不拍板。用户口头确认后，主 Agent 先改对应产物，再改状态卡，再跑对应 gate。不要只改状态卡就宣称过门。无单独「状态卡 gate」；它不 PASS/FAIL、不拦截。`BLOCKED` 写在卡上是合法停、升级给你，不是放行。

#### 初始文件
> 建包即有，S/M/L 都要。`changes/change-scaffold.sh` 拷 `templates/status-card.md` 到 `changes/<change-id>/status-card.md`，并在文首写入 `artifact_profile` 和 `artifact_schema_version: 1`。`gates/change-artifacts-gate.sh` 靠这两行识别档位。手工建包也要写这两行。

#### 触发时机
主 Agent 在下列事件刷新状态卡，不必等你开口：

- 你问「现在到哪了」「下一步是什么」或同类问题
- 阶段切换
- 阻塞出现或解除
- 人工确认前后（方案、测试方案、复杂 UI、测试报告）
- Tester / Reviewer 返回
- 审查之后又改了业务代码，先前结论失效
- 进入预发前
- 派发 / 完成 / 阻塞子 Agent（还要改 Agent Roster）

不是契约之后才出现的单独阶段，也不是收口时才写的总结。

#### 动作
- 跑 `changes/status-card.sh changes/<change-id>` 脚本，脚本只收集当前变更包（`changes/<change-id>`）状态信息给主 Agent；
- 主 Agent 根据脚本收集的状态信息，并聚合其他信息更新 `status-card.md`（不要覆盖 Agent Roster）。

#### 其他规则
- 只**主 Agent**写状态卡。子 Agent 不得改；
- 当前阶段取值：`需求理解 / 方案确认 / 允许开工 / 实现中 / AI测试待确认 / 预发待发布 / 已收口`；
- 脚本自动推断上限是 `允许开工`；`实现中` 和 `已收口` 读不到业务仓和收口状态，由主 Agent 在实现开始、收口时手动置位；
- scaffold 只给空壳。主 Agent 建包后立刻写入当前阶段（通常 `需求理解`）、下一步、是否允许进入下一阶段、当前阻塞、需要人工确认。Agent Roster 从主 Agent 那一行开始填。禁止写入 token、cookie、DB password。

### 证据（`evidence.md`）
> 可复查的**命令痕迹**：证明“真的跑过、结果如何”，不是口头「测过了」。宣称跑过编译、lint、gate、冒烟或重启，本轮就要在这里留下命令和结果摘要。

#### 作用
> 把每一步关键命令和结果落盘，成为可复查的本机事实源（变更包不进 git）。Agent 的自我汇报不是证据；宣称完成必须能在这里找到本轮命令输出。它不是验收裁决（裁决由 Tester 写在 `test-agent-verification.md`），也不是 gate（无单独 evidence gate）。

#### 初始文件
> 建包即有，S/M/L 都要。路径 `changes/<change-id>/evidence.md`。**没有** `templates/` md；`changes/change-scaffold.sh` **当场生成**空表，首行是建包记录 `Scaffold … PASS`。表头：`Check | Command / Source | Result | Summary`；`Result` 取 `PASS` / `FAIL` / `BLOCKED` / `N/A`。

#### 触发时机
主 Agent 每跑一条关键命令就**追加**，不必等收口：
- 编译、lint、gate、冒烟、重启、扫描执行后
- 命中场景但未做的检查，写 `N/A` 和原因

不要覆盖整表，不要等收口再补。

#### 动作
1. 每条关键命令执行后，把 `Check / Command / Result / Summary` 追加进 `evidence.md`；
2. 长输出只留关键摘要和 `changes/<change-id>/artifacts/` 路径，不整段贴；
3. 注释/日志扫描的 warning 也可记这里，交 Reviewer 判断。

#### 其他规则
- 只**主 Agent**写；Tester 的复测结论写在 `test-agent-verification.md`，主 Agent 不得代裁 `GOAL_ACHIEVED`；
- **禁止写入** token、cookie、DB password、客户资料、未脱敏 SQL 结果、原始私密 prompt。明文机密只放 `config/runtime_local.sh` 或系统钥匙串。长日志、截图、录屏、trace 放 `changes/<change-id>/artifacts/` 或外部存储，evidence 只记路径和结论；
- `gates/reviewer-gate.sh` 要求 `review.md` 引用 `evidence.md`，否则 Reviewer 关卡 FAIL——evidence 不是“有空才看”；
- 与证据家族其他文件区分：`test-agent-verification.md`（Tester 裁决）、`verification-run-report.md`（verification-map 执行报告，脚本生成）、`codegraph-evidence.md`（结构影响线索）、`pc-e2e-smoke-report.md`（冒烟摘要）；

### 文件列表
| # | 文件                                                | 从哪创建                                                                                                 | 何时出现 | 作用 | 谁写 | 谁检查 | 怎样算过 / 备注 |
|---|---------------------------------------------------|------------------------------------------------------------------------------------------------------|---|---|---|---|---|
| 1 | `spec.md`                                         | 拷 `templates/spec-tier-s.md` / `spec-tier-m.md` / `spec-tier-l.md`（scaffold）                         | 建包即有；需求理解时填。S/M/L 都要 | 目标、范围内外、三标签、`lane`、`allowed_paths` | 主 Agent；Explorer 只读供料 | `confidence-gate.sh` | 阻塞 `[QUESTION]` 已清、`[ASSUMP]` 已确认并写成带来源的 `[FACT]` |
| 2 | `status-card.md`                                   | 拷 `templates/status-card.md`；文首加 `artifact_profile` + `artifact_schema_version: 1`（scaffold 会写；手工建包也要写） | 建包即有；此后贯穿更新。S/M/L 都要 | 给人看的阶段、阻塞、下一步、`Lane`、Agent Roster | 主 Agent 跑 `changes/status-card.sh` 后写入 | 无单独「状态卡 gate」。marker 由 `gates/change-artifacts-gate.sh` 读 | 摘要不是拍板原文；脚本不覆盖 Roster |
| 3 | `evidence.md`                                     | scaffold **当场生成空表**，无模板 md                                                                           | 建包即有；每跑命令就追加。S/M/L 都要 | 命令、结果摘要、阻塞。禁止密码/token | 主 Agent | 无单独过门；Reviewer 会看 | 只记摘要 |
| 4 | `requirement-intake.md`                           | 条件命中时主 Agent 拷 `templates/requirement-intake.md`；scaffold / gate 都不创建                                | 条件：M/L 要结构化收需求时 | 把 PRD 收成结构化入口 | 主 Agent | `gates/requirement-intake-gate.sh` | 可无 |
| 5 | `contract.md`                                     | 拷 `templates/api-contract.md` → 变更包内 `contract.md`（M/L scaffold 或手工拷）。RZ **只用这一条路径** | **空壳：** M/L 建包即有。**填写：** 契约冻结时 | 冻结 endpoint、字段、错误码、分页、空态 | 主 Agent；前端只读这份 | `contract-delta-gate.sh`（有增量时） | 未冻不得实现。不用 `docs/contracts/<id>-api.md` |
| 6 | `technical-solution.md`                           | 拷 `templates/technical-solution.md`（M/L scaffold）                                                    | **空壳：** M/L 建包即有。**填写 / 确认：** 方案阶段 | 全栈技术方案 | 主 Agent | `technical-solution-gate.sh` | 用户对话确认后，主 Agent 写 `confirmation_status: CONFIRMED`（含 `confirmed_by` / `confirmed_at`，`allowed_next_stage` 非 `none`） |
| 7 | `plan.md`                                         | 拷 `templates/plan-tier-m.md`（M/L scaffold）                                                           | **空壳：** M/L 建包即有。**填写：** 方案后、开工前 | 实现步骤、验证、回滚 | 主 Agent | 无单独过门；勿与状态卡两套打架 | v1 可把步骤写进状态卡 |
| 8 | `verification-map.md`                             | 拷 `templates/verification-map.md`（M/L scaffold）                                                      | **空壳：** M/L 建包即有。**填写：** 同 plan | 每条约束怎么验（命令 / 人确认 / N/A） | 主 Agent | `verification-map-gate.sh` | 可与测试方案合并，标本是分开的 |
| 9 | `skill-usage.md`                                  | 拷 `templates/skill-usage.md`（M/L scaffold）                                                           | **空壳：** M/L 建包即有。**填写：** 用到 skill 时；标本 M 强制 | 按 `skills/skill_directory.md` 记录用过哪些 skill 或 N/A | 主 Agent | `skill-usage-gate.sh` | 未用写 N/A |
| 10 | `agent-dispatch-plan.md`                          | 拷 `templates/agent-dispatch-plan.md`（M/L scaffold）。RZ 不调标本 `agent-dispatch-plan.sh` / registry | **空壳：** M/L 建包即有。**填写：** 派子 Agent 前 | 准备派哪些子 Agent | 主 Agent | 标本另有 `agent-dispatch-plan-gate.sh`，**RZ 未拷**；派前对照 `subagents/dispatch_subagent.md` | 不派实现 Agent 也可写 N/A |
| 11 | `capability-spec.md` / `behavior-spec.md`         | **无模板**，按 AGENTS 自建                                                                                  | 条件：复杂状态机 / 权限 / 跨端 | 行为或能力边界 | 主 Agent | 在 `verification-map.md` 映射 | 普通 CRUD 写 N/A |
| 12 | `ai-test-plan.md`                                 | 拷 `templates/ai-test-plan.md`（M/L scaffold 空壳）                                                       | **空壳：** M/L 建包即有。**填写 / 确认：** 方案确认后、实现前 | AI 测试方案 | **Test Strategy** 填内容；主 Agent 不得代写。用户确认后主 Agent 写 `test_plan_status: CONFIRMED` | `ai-test-plan-gate.sh` | 未确认不得实现 |
| 13 | `backend-test-plan.md`                            | 条件命中时主 Agent 拷 `templates/backend-test-plan.md`；scaffold / gate 都不创建                                 | 条件：Java 行为变更 | 后端测什么；仅编译不够 | 主 Agent | 实现前必须有此文件或明确 N/A | 无行为变更则 N/A |
| 14 | `environment-readiness.md`                        | 拷 `templates/environment-readiness.md`（L scaffold；M 命中再拷）                                            | **空壳：** L 建包即有。**填写：** 真 E2E 前（可提前）。M 非 E2E 可不建 | 环境、拓扑、账号**来源**、写库边界 | 主 Agent | `environment-readiness-gate.sh` | `environment_status: READY`。不查 CONFIRMED，不探活 |
| 15 | `dirty-worktree-ledger.md`                        | 条件命中时主 Agent 拷 `templates/dirty-worktree-ledger.md`；scaffold / gate 都不创建                             | 条件：业务仓已有未提交改动 | 脏 diff 归属，避免覆盖用户工作 | 主 Agent | `business-dirty-worktree-gate.sh` | 无脏仓则不建 |
| 16 | `agent-candidate-confirmation.md`                 | 条件命中时主 Agent 拷 `templates/agent-candidate-confirmation.md`；scaffold / gate 都不创建                      | 条件：派 Backend / Frontend / Mobile | 允许候选实现 Agent | 主 Agent（用户确认后回写） | 派发前检查 | 不派则不建 |
| 17 | 业务仓分支 `harness/<change-id>`                       | **git**：从业务仓远程主干 `origin/master`（或 `origin/main`）拉，不是 md                                                                | 第一次改该仓业务文件前 | 实现落点，不是变更包内文件 | 主 Agent | S：`confidence-gate` / `assumption-leak-gate` / `allowed-paths`。M/L 再加 `business-code-start-gate.sh`。脏仓再加 `business-dirty-worktree-gate.sh` | 停在主干则不得改业务文件。`business-code-start-gate` **仅 M/L** |
| 18 | `ui-rule-checklist.md`                            | 条件命中时主 Agent 拷 `templates/ui-rule-checklist.md`；scaffold / gate 都不创建                                 | 条件：PRD UI / 交互编码 | UI 规范逐项、缺口 | 主 Agent | `ui-rule-gate.sh` | 规则缺口未确认不得实现 |
| 19 | `ui-confirmation.md`                              | 条件命中时主 Agent 拷 `templates/ui-confirmation.md`；scaffold / gate 都不创建                                   | 条件：复杂 UI | 可运行页 / 截图后的确认记录 | 主 Agent；用户看页面后主 Agent 写 `Status: CONFIRMED` | `gates/ui-confirmation-gate.sh` | PC smoke 不能替代 |
| 20 | `data-model.md` / `data-model-sql.md`             | SQL：条件命中时主 Agent 拷 `templates/data-model-sql.md`。**`data-model.md` 无模板**，对照方案自建。scaffold / gate 都不创建 | 条件：改 DB | ER、字段来源、可执行 SQL | 主 Agent | 无单独过门；真实库写要用户二次确认 | 高危 SQL 禁止 |
| 21 | `contract-delta.md`                               | 条件命中时主 Agent 拷 `templates/contract-delta.md`；scaffold / gate 都不创建                                    | 条件：实现中契约有增量 | 契约变更说明 | 主 Agent | `contract-delta-gate.sh` | 无增量不建 |
| 22 | `local-routing.yml`                               | `scripts/generate-local-routing.sh` 生成；也可参考 `templates/local-routing.yml` 手写 | 条件：本地前后端联调 | 前端打哪套后端 / 代理 | 主 Agent | `gates/local-routing-gate.sh` | 不要长期手写堆积 route |
| 23 | `pc-e2e-smoke-plan.md` / `pc-e2e-smoke-report.md` | 条件命中时主 Agent 拷 `templates/pc-e2e-smoke-plan.md`、`pc-e2e-smoke-report.md`；scaffold / gate 都不创建        | 条件：PC 真浏览器冒烟 | 冒烟计划与结果 | 主 Agent | 无专用 RZ gate；真 E2E 须先过已有的 `environment-readiness-gate.sh` | 报告只留摘要 |
| 24 | `miniapp-local-env.md`                            | 条件命中时主 Agent 拷 `templates/miniapp-local-env.md`；scaffold / gate 都不创建                                 | 条件：改小程序本地环境 | 小程序本地运行约定 | 主 Agent | `gates/miniapp-local-env-gate.sh` | 未改小程序不建 |
| 25 | `temporary-state-ledger.md`                       | 条件命中时主 Agent 拷 `templates/temporary-state-ledger.md`；scaffold / gate 都不创建                            | 条件：本地服务、测试数据、debug 开关 | 临时状态清理台账 | 主 Agent | `gates/temporary-state-ledger-gate.sh` | 避免遗留 |
| 26 | `codegraph-evidence.md`                           | 条件命中时主 Agent 拷 `templates/codegraph-evidence.md`；scaffold / gate 都不创建                                | 条件：改公共 API / 权限等；可选 | 结构影响线索 | 主 Agent | 可选，不是关卡 | 未命中不是无影响证明 |
| 27 | `verification-run-report.md`                      | `scripts/verification-run.sh` 生成 | 进入 Tester / Reviewer 前（map 有可执行行时） | verification-map 跑完的报告 | 主 Agent | 有可执行行则必须有报告文件 | 无可执行行则 N/A |
| 28 | `test-agent-verification.md`                      | 拷 `templates/test-agent-verification.md`（M/L scaffold 空壳）                                            | **空壳：** M/L 建包即有。**填写：** 实现后验收，**只能 Tester 填** | 对照已确认测试方案的独立验收 | **Tester**。主 Agent 修代码、补 evidence，不得代裁 | `test-agent-verification-gate.sh` | 仅 `GOAL_ACHIEVED` 放行；`BLOCKED` 是停。改代码后必须重跑 |
| 29 | `ai-test-report.md`                               | 拷 `templates/ai-test-report.md`（L scaffold；M 提测再拷）                                                   | **空壳：** L 建包即有。**填写 / 确认：** 提测 / 预发前。M 非提测可不建 | 测试结论给人确认 | 主 Agent 汇总；用户确认后写 `confirmation_status: CONFIRMED` | `ai-test-report-gate.sh` | 前置：测试方案已确认 + Tester `GOAL_ACHIEVED`。进预发还要 `recommendation: 允许进入预发` |
| 30 | `review.md`                                       | 拷 `templates/review.md`（M/L scaffold 空壳）                                                             | **空壳：** M/L 建包即有。**填写：** 人审 / PR 前，**只能 Reviewer 填** | 只读审查 | **Reviewer**。主 Agent 不得代裁 | `reviewer-gate.sh` | `high_risk_count: 0`。代码又变则过期，按需重跑 Tester 再重跑 Reviewer |
| 31 | `pre-pr.md`                                       | 合并前主 Agent 拷 `templates/pre-pr-review.md` 存成 `pre-pr.md`；scaffold / gate 都不创建                        | 合并前 | 人审包、残余风险 | 主 Agent | `diff-hygiene-gate.sh`、`temp-hardcode-scan.sh` | 卫生扫描是检查项，不是拍板停止点 |
| 32 | `decisions.md`                                    | 拷 `templates/decisions.md`（L scaffold）                                                               | **空壳：** L 建包即有。**填写：** 过程中有拍板时。S/M 可后补 | 过程决策记录 | 主 Agent | 无单独过门 | L 强制 |
| 33 | `retro.md`                                        | 收口时主 Agent 拷 `templates/retro.md`；scaffold / gate 都不创建                                               | 收口时，可后补 | 复盘 | 主 Agent | 无单独过门 | 变更包不进 git；大文件仍放包内 `artifacts/` |
| 34 | `handoff.md`                                      | **无 `templates/handoff.md`**；按 handoff skill 里的章节自建                                                  | **随时**：换线程、暂停、上下文压缩 | 留给**下一个主 Agent**的交接单 | 主 Agent | 无 gate | 不是 Explorer / Reviewer 之间的信箱 |

## 工作流

### 整体工作流
> - 每阶段的门禁细节见「停止点」与「强制工作流」，产物清单见「变更包 → 文件列表」。
> - 未命中条件的步骤写 `N/A` 和原因后跳过。
> - S 档：契约 / 技术方案 / AI 测试方案 / plan 与 verification-map / Tester / AI 测试报告 默认可写 `N/A` 和原因，但仍须 spec、`allowed_paths`、evidence。
> - 真 E2E 前环境必须 `READY`（停止点 4），材料可提前准备。浏览器冒烟在实现之后，见 E2E Pack。未做真 E2E 时写 `N/A`。
> - 飞书同步、Java `backend-test-plan.md`、Swagger、DB 模型命中才做，见「强制工作流」④。合并前卫生扫描见「受保护行为」。这些都不单列成步。
> - M/L 建包后给用户的第一条回复须包含本次会碰到的**关卡**（见「强制工作流」①）。

1. **定 `change-id`**：用业务含义命名，不要用 `demo` / `tbd` 这类默认名。
2. **选 lane**：按任务类型选定（见「lane工作流」）。有匹配时，步骤菜单用该 lane，本清单用来核对命中的停止点有没有被跳过。无匹配则 `lane: none`，步骤用本清单，再按档位裁剪。
3. **建变更包**：`changes/change-scaffold.sh --tier S|M|L <change-id>`。建包后把 spec 文首 `lane: TODO` 改成唯一值，状态卡 `Lane` 照抄（见「lane工作流」）。状态卡的阶段、下一步、阻塞按「状态卡」写入。
4. **写 spec**：用户确认的写 `[FACT]`、推断写 `[ASSUMP]`、需拍板写 `[QUESTION]`，并写 `allowed_paths`。写完停下来问用户。答完后主 Agent 原地改成带来源的 `[FACT]`，再跑 `gates/confidence-gate.sh`。口头「ok」不算过。阻塞 `[QUESTION]` 未清不得进入第 9 步开工。未确认 `[ASSUMP]` 不挡开工，不得进入第 10 步业务代码。（见「停止点」#1，见「需求理解」；本需求命中哪些强制项见「强制工作流」④）
5. **冻结契约**：`changes/<change-id>/contract.md`。（S / 无 API 可 `N/A`）
6. **技术方案**（M/L）：`technical-solution.md` + 用户确认；命中飞书 PRD 时同步到飞书子文档 + 跑 `gates/technical-solution-feishu-sync-gate.sh`。（见「强制工作流」④，「停止点」#2）
7. **AI 测试方案**（M/L）：独立 Test Strategy 写 `ai-test-plan.md`（见「子 Agent」）。主 Agent 不得代写。用户确认后，主 Agent 写成 `test_plan_status: CONFIRMED`。（见「停止点」#3）
8. **plan 与 verification-map**（M/L）：方案确认后、开工前填写 `plan.md`、`verification-map.md`。S 可 `N/A`。
9. **开工门禁**：从业务仓远程主干 `origin/master`（或 `origin/main`）拉 `harness/<change-id>`；过开工门禁。S 三重 / M/L 四重。（见「强制工作流」②），（见「停止点」#5）
10. **实现 + 记证据**：只改 `allowed_paths` 内文件；命令记入 `changes/<change-id>/evidence.md`。PRD 有界面时，写代码前先写 `ui-rule-checklist.md`，规则缺口停下等用户。（见「停止点」#6）
    - **常规验证**（进入第 11 步前）：编译、定向测试、窄范围 lint（前端 `scripts/frontend-lint-build.sh` 的 `lint-files`，后端 `scripts/mvn-targeted-test.sh`）；`verification-map.md` 有可执行行时跑 `scripts/verification-run.sh`。跑不了写 `BLOCKED` 和原因。已选 lane 时以该 lane 为准。S 档第 11 步为 `N/A` 时，本节验证在第 13 步前完成。
    - **复杂 UI**：页面可运行后写 `ui-confirmation.md`，用户看过再确认。
    - **Optional Pack（命中才跑）**：E2E → 按 `lanes/pc-e2e-smoke.md`（**先过停止点 4：环境 READY**）；Impact / Parallel（CodeGraph/GitNexus、多 Agent worktree）→ RZ 未引入 → `N/A`。
11. **Tester 验收**（M/L）：独立 Tester 对照已确认测试方案，由 Tester 填写 `test-agent-verification.md`。主 Agent 只修代码、补 evidence，不得代填、不得自称 `GOAL_ACHIEVED`。未达到则回到第 10 步改代码再测。`BLOCKED` 升级给用户，不算过。（停止点 7）
12. **AI 测试报告**（提测 / 预发）：`ai-test-report.md` + 用户确认。（停止点 8）
13. **Reviewer 过门**：只读审查，`high_risk_count: 0`。（停止点 9；S 走 `bugfix-fast` 时仍建议 Reviewer）
14. **人工 review / PR / SIT**。
15. **retro 收口**。

### lane工作流
> **lane = 某类任务的默认步骤清单（任务路线）**，放在 `lanes/`。与档位正交：lane 选步骤菜单，tier 选产物厚度。lane **只能选路线，不能豁免「命中的停止点 / 条件关卡」**。

建包后立刻把 spec 文首 `lane: TODO` 改成唯一值（合法值见下方「开工主 lane」+ `none`）。状态卡 `Lane` 只照抄，spec 为准；不一致时先改状态卡再继续。

新会话先读 spec 的 `lane`。是路径就打开该文件，从状态卡「下一步」继续，不从 lane 第 1 步重跑。是 `none` 就用整体工作流。`gates/confidence-gate.sh` 会核对这个值，并要求与状态卡一致；仍是 `TODO` 不能开工。

**开工主 lane**（建包时选一条）：
- 小修 / bugfix → `lanes/bugfix-fast.md`（常配档位 S）
- 低风险全栈 CRUD → `lanes/fullstack-crud.md`（常配档位 M）

**子 lane / Pack**（不是开工三选一；实现之后按触发条件套）：
- PC 冒烟 → `lanes/pc-e2e-smoke.md`（CRUD 命中 E2E Pack 再读）。不改 `lane`，进度写在状态卡「下一步」。

无匹配：不编造新 lane，`lane: none`，走「整体工作流」并按档位裁剪。

### 强制工作流
> - 适用：档位 M/L、跨仓、后端行为、DB、复杂 UI
> - 带 **★** 的是全局规则，S/M/L 都适用。**lane 只能选路线，不能豁免「命中的停止点 / 条件关卡」**
> - 档位裁剪只决定**产物厚度**（S 档可对部分产物写 `N/A`），不改变全局规则。
> - 用户说「开始 / 下一步 / 确认 / ok」只推进到下一个已满足的关卡，不能跳关。

**① 开场（第一条回复）**
- 列出本次会碰到的**关卡**（见「停止点」表，不要手写混合名单）
- 以 `changes/<change-id>/status-card.md` 作为用户可见状态卡。（见「变更包 → 状态卡」）。

**② 开工前（写业务代码前）**
- ★ 读当前变更；`source config/runtime_local.sh`；确认允许的仓库 / 路径。
- ★ 区分 `[FACT]` / `[ASSUMP]` / `[QUESTION]`（见「需求理解」）；未决的假设 / 问题不得进实现；优先用目标仓样板。
- ★ 每个业务仓首次改代码：从 `origin/master`（或 `origin/main`）切 `harness/<change-id>`，记基线分支 + commit，**不在主干改**。
- 开工门禁：
  - **S/M/L 都跑**：`gates/confidence-gate.sh <spec-file>`、`gates/assumption-leak-gate.sh <spec-file> <changed-file...>`、`gates/allowed-paths.sh <spec-file> <changed-file...>`。
  - **M/L 再加**：`gates/business-code-start-gate.sh <change-dir> <changed-file...>`（它校验技术方案 + 开工）。
  - **脏仓再加**：`gates/business-dirty-worktree-gate.sh <repo> [--ledger <ledger>]`。
  - 各脚本参数见 `gates/gate_directory.md`。

**③ 不可豁免**
- 用户口头「ok / 确认」不能跳过**档位需要或条件命中的**关卡（方案、测试方案、环境、Tester、Reviewer 按档位与触发条件才要求；命中飞书 PRD 时含飞书同步）。
- `status-card.md` 持续更新：阶段变化、阻塞出现 / 解除、Tester / Reviewer 返回、验证失效。（见「变更包 → 状态卡 → 触发时机」）
- 代码再变 → 旧结论作废：Tester 验证重跑；Reviewer 产出后代码变 → 审查标过期，重跑 Tester 再重跑 Reviewer。（见「停止点」#7 / #9）
- 主 Agent 可实施 / 修复，但**不得代裁** Tester / Reviewer。
- 派子 Agent：提示词和 Agent Roster 记录可读角色标签。

**④ 强制项**

*M/L 默认必做（见「停止点」#2 / #3）：*
- 全栈 `technical-solution.md` 需 `CONFIRMED`（必须覆盖模板列出的每一块 PRD 面；当前端 / APP / 导出 / 分析 / 跨仓行为在范围内时，仅后端方案无效），并跑 `gates/technical-solution-gate.sh <change-dir>`
- 独立的 Test Strategy 写 `ai-test-plan.md` 需用户确认，并跑 `gates/ai-test-plan-gate.sh <change-dir>`。
- **skill 路由** → 按 `skills/skill_directory.md`；M/L scaffold 必有 `skill-usage.md`（未用写 `N/A`），并跑 `gates/skill-usage-gate.sh changes/<change-id>`。

*命中才做：*
- **行为 / 契约变更** → 实现前需 spec + 契约文档；宣称跑过的检查必须落 `evidence.md`。
- **Java 后端行为变更** → `backend-test-plan.md` 或明确 `N/A`；仅编译不够。
- **Swagger 对外 VO** → **仅当后端仓有活动 `rules/backends/*/manifest.yml` profile 时**：只扫该 profile 配置的响应根、新增对外 `*VO.java` 用 `@ApiModel` + 每字段 `@ApiModelProperty`；配置不追溯既往，不含导出模型与基础设施 DTO；pre-commit 跑 `gates/swagger-model-documentation-gate.sh <change-dir> <changed-file...>`。
- **前端 / UI** → 先判复杂度；PRD UI 需 `ui-rule-checklist.md` + `gates/ui-rule-gate.sh changes/<change-id>`，规则缺口停下等用户；复杂 UI 需 `ui-confirmation.md` + 可运行页面；`mapSystem` 先读 `baselines/frontend-map-system.md`，用 `scripts/frontend-dev-server.sh frontend-map-system 9527`（Node 14.21.3 / 产品组登录 / 临时路由，`HomeIndex` 重定向即失败）。
- **DB 变更** → 带 ER 图的数据模型、可执行 SQL、规范化检查、自包含注释、字段来源。
- **飞书 PRD** → 用 `scripts/technical-solution-feishu-sync.sh` 同步方案到飞书子文档、改后重同步；**同步关卡 `gates/technical-solution-feishu-sync-gate.sh <change-dir>`**（改后不重同步则技术方案关卡不过）；流程图 / ER / 状态图用**白板**不用 Mermaid。
- **复杂行为 / 能力边界** → 写 `capability-spec.md` / `behavior-spec.md`，并在 `verification-map.md` 映射。普通 CRUD 写 `N/A`。

**⑤ 环境与就绪**
- 真实 E2E 前：填 `environment-readiness.md` 并跑 `gates/environment-readiness-gate.sh <change-dir>`（环境 / 系统 / 拓扑 / 账号来源 / 数据 / 写库边界 / 回滚 / 设备 / 阻塞 / **无可复用凭据**）。（见「停止点」#4）
- 本地后端「可验收」只在 `scripts/local-service-lifecycle.sh` 的 HEALTH=UP + check-web-stack 成功后声明（Maven / nohup / 端口单独成功都不算）。

**⑥ 验收与审查**
- **业务代码审查前**：跑 `scripts/code-comment-log-quality.sh`。
- **Tester**：对照已确认的 `ai-test-plan.md` 独立验收，直到 `GOAL_ACHIEVED`；`BLOCKED` 是停不是过；主 Agent 不得自称。（见「停止点」#7）
- **AI 测试报告**：提测 / 预发前 `ai-test-report.md` + `gates/ai-test-report-gate.sh <change-dir>`（需测试方案已确认 + Tester `GOAL_ACHIEVED`）；**进预发还要 `recommendation: 允许进入预发`**。（见「停止点」#8）
- **Reviewer**：只读审查，跑 `gates/reviewer-gate.sh <change-dir>`，`high_risk_count: 0`；必查面见 `gates/reviewer-gate.sh` / `review.md` 模板。（见「停止点」#9）

**⑦ 全局禁令**
- ★ 单一控制面：只用 `changes/<change-id>/`；不建顶层 `openspec/`；旧产物只放 `changes/<id>/legacy-openspec/`。
- ★ 永不记录明文密码 / token / cookie。（见「受保护行为」）
- CodeGraph RZ 未引入（`codegraph-preflight` 等未拷）→ N/A。


## 受保护行为
- 不允许提交代码到 master 或者 main 分支
- 未经 spec 明确许可不要修改：生产配置、密钥、`.env*`、部署清单、DB 迁移、Nacos 生产配置、发布脚本，或 allowed paths 之外的无关模块。
- 真实 SIT/UAT/生产 DB 访问默认只读。真实数据写入、DDL、任务触发的数据变更或会修改的 API 需要目标环境、精确 SQL/API、预期行数、回滚/清理计划，以及明确的第二次用户确认。
- 高危 SQL 全局禁止：`DROP DATABASE`、`DROP TABLE`、`TRUNCATE`、宽范围 `DELETE`、宽范围 `UPDATE`，或没有精确范围的写入。
- 永不在版本化文件、harness 文档、证据或记忆中持久化明文 DB 密码、token 或 cookie。此类机密只放在已忽略的 `config/runtime_local.sh` 或系统钥匙串。
- 合并前，对变更的业务文件运行 `gates/diff-hygiene-gate.sh <repo> [--base <ref>] <files...>` 和 `gates/temp-hardcode-scan.sh <files...>`。

## 子 Agent
> 主 Agent 负责派发和管理子 Agent。创建靠 **runtime 内置工具**（例如：Cursor 为 `Task`）。子 Agent 使用新 session，默认看不到主对话；spec / diff 等必读材料写进派发 prompt 的 `Read inputs`，由子 Agent 读磁盘。

- 目录：`subagents/`
- 派发协议（只给主 Agent）：`subagents/dispatch_subagent.md`
- 角色人设（派发时列入 `Read inputs`）：`subagents/<role>_agent.md`
- 默认只读：**Explorer** / **Reviewer**。方案确认后、写代码前派 **Test Strategy**。实现后、发布前派 **Tester**。**Backend** / **Frontend** / **Mobile** 为候选实现角色，须契约 v0.1、allowed paths 与隔离 worktree 才派发。
- 控制面默认只允许主 Agent 写。主 Agent 可以实施、集成和修复，但不得代替 Reviewer / Tester 的裁决。

现有角色：
- **Explorer**（`subagents/explorer_agent.md`）：方案或实现前只读查证。对主 Agent 输出 `[FACT]` / `[ASSUMP]` / `[QUESTION]` 进行专业的查证。值返回信息给主 Agent 不改 `spec.md` 文件。
- **Reviewer**（`subagents/reviewer_agent.md`）：实现之后、人工 review / PR 之前只读审查。只写 `changes/<change-id>/review.md`；`high_risk_count` 为 0 才建议进人审。
- **Test Strategy**（`subagents/test_strategy_agent.md`）：技术方案确认后、实现前编写 `ai-test-plan.md`，须用户确认；不写业务代码。
- **Tester**（`subagents/tester_agent.md`）：实现后对照已确认测试方案独立验收，维护 `test-agent-verification.md`；不得修业务代码；不得由主 Agent 自称 `GOAL_ACHIEVED`。
- **Backend**（`subagents/backend_agent.md`）：候选。契约与后端测试计划之后，在隔离 worktree 内改后端。
- **Frontend**（`subagents/frontend_agent.md`）：候选。UI 规则与契约之后，在隔离 worktree 内改前端；契约只读。
- **Mobile**（`subagents/mobile_agent.md`）：候选。移动端契约与允许路径之后，在隔离 worktree 内改 iOS/Android。

每个子 Agent 提示词必须以 `Agent Label: <change-id> / <role> / <scope>` 开头，并且必须声明写入范围、禁止路径、要求产出，以及该 Agent 是否只读。子 Agent 最终回复应以 `<role>: <DONE|PASS|BLOCKED|NEEDS_CONTEXT>` 开头；主 Agent 在 `changes/<change-id>/status-card.md` 的 Agent Roster 中记录相同的标签和状态。详细约定见 `subagents/dispatch_subagent.md`。

## 完成定义
仅当 spec/plan/契约与档位 M/L 技术方案一致；没有未解决的假设/问题进入代码；需要时 `ai-test-plan.md` 已确认。
对已执行的 E2E，环境就绪是清楚的；Tester 已确认 `GOAL_ACHIEVED`（或记录 `BLOCKED` 并升级给用户）；Reviewer 产出已通过 `gates/reviewer-gate.sh changes/<change-id>`。
残余风险和回滚已记录。
