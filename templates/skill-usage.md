# Harness Skill Usage：<change-id>

> 记录本次需求实际读取和执行的 harness skill。RZ 角色人设在 `subagents/<role>_agent.md`；本表仍写 `skills/*/SKILL.md` 路径，供 `gates/skill-usage-gate.sh` 检查。外部 superpowers skill 不能替代本记录。

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

> RZ 未引入 `skills/third-party/` 与 ECC。本表默认全部 `N/A`，并写原因。不得用外部 lens 替代上表 harness skill。

| Lens | Status | Evidence / Output | N/A reason |
| --- | --- | --- | --- |
| 外部 Codex / Brooks / ECC | N/A | — | RZ 未引入 |

## 结论

- [ ] 命中场景的 skill 均为 `USED`，或已写明确 `N/A reason`。
- [ ] 没有用外部 superpowers skill 替代 harness skill。
- [ ] 如使用外部 lens，已确认没有启用 auto-fix / real action。
- [ ] Reviewer 已检查本文件。
