# Third-party Skills：external Codex skills

日期：2026-06-08

## 来源

| Source | URL | 本仓处理方式 |
| --- | --- | --- |
| `ComposioHQ/awesome-codex-skills` | `https://github.com/ComposioHQ/awesome-codex-skills` | 只借鉴索引和工作流模式，不整包安装 |
| `hyhmrright/brooks-lint` | `https://github.com/hyhmrright/brooks-lint` | 只借鉴 focused review lens，不启用 auto-fix |

## 总规则

- 外部 skill 只能作为辅助 lens，不能替代 `docs/skills-routing.md` 中的 harness-local skill。
- 外部 lens 的使用必须记录到 `changes/<change-id>/skill-usage.md` 的“外部辅助 Lens”表，或在 `evidence.md` 写 N/A 原因。
- 外部 lens 输出只能作为 Reviewer / Orchestrator 判断材料；不得直接作为实现许可、业务事实、测试通过或上线结论。
- 不把外部 skill 安装到 `$CODEX_HOME/skills`，除非用户单独确认。
- 不复制外部仓库完整内容；如后续复制实质性内容，必须保留对应 license 与来源说明。

## 推荐采用

| 外部 skill / 模式 | 本仓用途 | 触发场景 | 使用边界 |
| --- | --- | --- | --- |
| `brooks-review` | Reviewer 的 second-opinion lens | Pre-PR、人工 review 前、用户问“这个 diff 是否可合并” | 只读；输出按 HIGH / MEDIUM / LOW 合并到 `review.md` |
| `brooks-test` | 测试质量 lens | 已有测试、`backend-test-plan.md`、targeted test 证据需要审查 | 只读；关注 brittle test、mock abuse、coverage illusion、happy-path only |
| `brooks-audit` | 架构 / 分层 lens | 多模块、多仓、层级依赖、边界归属不清 | 只读；不能替代 CodeGraph / GitNexus / `rg` 证据 |
| `brooks-debt` | 技术债优先级 lens | 用户明确问重构优先级或阶段性复盘 | 只读；不阻断普通业务交付 |
| `codebase-recon` pattern | git history 风险传感器思路 | 接手旧模块、大范围改动、跨仓影响分析前 | 可后续做 downgradeable sensor；当前仅人工参考 |
| `codebase-migrate` pattern | 分批迁移 lane 思路 | rules / templates / AGENTS stub 批量迁移 | 一个 transform 一个批次；不能混业务行为变更 |
| `webapp-testing` pattern | PC smoke helper 思路 | `mapSystem` / PC 页面浏览器冒烟 | 必须保留本仓 Node 14.21.3、登录产品组、临时路由和凭据不落盘规则 |
| `gh-fix-ci` / `gh-address-comments` pattern | harness GitHub PR 辅助 | 仅 `sfa-ai-harness` GitHub PR | 不适用于业务 Codeup 流程，除非另行确认 |

## 明确禁用

| 外部 skill / 模式 | 禁用原因 |
| --- | --- |
| `brooks-sweep` | Full Sweep & Auto-Fix 会直接修改代码，和本仓 Reviewer 只读、Orchestrator-only writable 边界冲突 |
| `pr-review-ci-fix` auto-fix loop | 自动 fetch diff -> fix -> push -> rerun 过强，绕过本仓 spec / evidence / 人审停止点 |
| `connect` / `connect-apps` real actions | 可能触发 Slack / GitHub / Notion 等外部写操作，和真实环境写入二次确认边界冲突 |
| `deploy-pipeline` | 当前 harness 未接入部署面；不得把部署自动化混入业务需求验证 |
| 大型 agent OS / parallel framework | 容易覆盖本仓 Orchestrator、只读 Explorer / Reviewer、worktree gate 等边界 |

## Brooks second-opinion 输出映射

Reviewer 使用 `brooks-review` / `brooks-test` lens 时，不单独输出外部模板原文，按本仓格式归并：

| Brooks finding | 本仓落点 |
| --- | --- |
| Critical | `review.md` 的 `HIGH` |
| Warning | `review.md` 的 `MEDIUM` |
| Suggestion | `review.md` 的 `LOW` |
| Health Score | 只作趋势参考，不作为 PASS / FAIL 门禁 |
| Remedy | 作为修复建议，必须经 Orchestrator 判断是否符合 spec / allowed paths |

每条归并 finding 必须保留：

- Symptom：具体代码或测试症状，带文件路径。
- Source：可保留书名 / principle，但不能替代本仓证据。
- Consequence：对 SFA 业务、契约、测试或维护的具体后果。
- Remedy：最小修改建议；如果超出 allowed paths，只能列为后续建议。

## 不适用示例

- 纯文档错别字、小范围 Markdown 排版：外部 lens 记 N/A。
- 单文件无行为脚本修复：默认不跑 Brooks，除非用户明确要求质量审查。
- 真实 DB / 生产配置 / stateful API 决策：外部 lens 不参与授权，仍按 AGENTS 的二次确认规则执行。
