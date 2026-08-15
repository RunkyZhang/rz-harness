# Harness Skill Usage：<change-id>

> 记录本次需求实际读取和执行的 `sfa-ai-harness/skills/*/SKILL.md`。外部 superpowers skill 不能替代本记录。

## 使用记录

| Phase | Trigger | Skill | Status | Evidence / Output | N/A reason |
| --- | --- | --- | --- | --- | --- |
| Requirement clarification | 复杂需求 / 字段权限状态不清 | `skills/grill/SKILL.md` | TODO / USED / N/A | `spec.md` / `contract.md` |  |
| Evidence discovery | 查业务仓样板 / 调用链 / CodeGraph / rg | `skills/explorer/SKILL.md` | TODO / USED / N/A | `evidence.md` |  |
| Debugging | bug / 失败 / 回归 / 先分析 | `skills/diagnose/SKILL.md` | TODO / USED / N/A | `evidence.md` |  |
| Test planning | 后端行为 / 关键逻辑 / 测试要求 | `skills/tdd/SKILL.md` | TODO / USED / N/A | `backend-test-plan.md` |  |
| Review | Pre-PR / 人工 review 前 | `skills/reviewer/SKILL.md` | TODO / USED / N/A | `review.md` |  |
| Handoff | 长会话 / 暂停 / 切线程 | `skills/handoff/SKILL.md` | TODO / USED / N/A | `handoff.md` |  |

## 外部辅助 Lens

> 外部 lens 只能辅助本仓 skill；不能替代上面的 harness-local skill usage。使用边界见 `skills/third-party/external-codex-skills.md`。

| Lens | Status | Evidence / Output | N/A reason |
| --- | --- | --- | --- |
| `brooks-review` / `brooks-test` / `brooks-audit` / `brooks-debt` | TODO / USED / N/A | `review.md` / `evidence.md` |  |
| `brooks-sweep` | N/A | `review.md` / `evidence.md` | auto-fix 模式默认禁用 |
| `awesome-codex-skills` selected patterns | TODO / USED / N/A | `spec.md` / `evidence.md` |  |
| `ECC sidecar` selected patterns | TODO / USED / N/A | `evidence.md` | ECC optional；未安装时写 N/A reason |

## 结论

- [ ] 命中场景的 skill 均为 `USED`，或已写明确 `N/A reason`。
- [ ] 没有用外部 superpowers skill 替代 harness skill。
- [ ] 如使用外部 lens，已确认没有启用 auto-fix / real action。
- [ ] Reviewer 已检查本文件。
