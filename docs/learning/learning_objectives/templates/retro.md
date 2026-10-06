# Retro：<change-id>

> 用途：在高风险或中大型 change closeout 时，把返工、用户纠正、gate 触发、
> Reviewer 结论和知识沉淀变成可复核数据。Tier S 小修可以不单独创建本文件，
> 只在 `harness-status.md` / `evidence.md` 写轻量 closeout metrics。

```yaml
change_id: <change-id>
retro_status: PENDING
retro_required: yes
change_tier: M
risk_trigger_status: PENDING
total_rework_count: 0
gate_trigger_count: 0
gate_false_positive_count: 0
reviewer_high_risk_count: 0
user_correction_count: 0
instinct_candidate_count: 0
knowledge_updates_status: PENDING
```

`retro_required` 可选值：`yes` / `no`。
`retro_status` 可选值：`PENDING` / `READY` / `BLOCKED`。
`knowledge_updates_status` 可选值：`READY` / `N/A`。

## 触发条件

| Trigger | Applies? | Evidence |
| --- | --- | --- |
| Tier M/L | `<yes/no>` | `harness-status.md artifact_profile` |
| Cross-repo | `<yes/no>` | `plan.md / workstream dispatch` |
| Incident / rework | `<yes/no>` | `evidence.md / user correction` |
| High risk | `<yes/no>` | `review.md / ai-test-report.md` |

## 关键指标

| Metric | Value | Evidence |
| --- | --- | --- |
| total_rework_count | `<number>` | `<evidence section>` |
| gate_trigger_count | `<number>` | `<gate output / telemetry summary>` |
| gate_false_positive_count | `<number>` | `<gate output / user correction>` |
| reviewer_high_risk_count | `<number>` | `review.md` |
| user_correction_count | `<number>` | `evidence.md / chat summary` |
| instinct_candidate_count | `<number>` | `规则升级 / 不升级决策` |

## 用户纠正与返工

| ID | Source | Correction / Rework | Cause | Follow-up | Status |
| --- | --- | --- | --- | --- | --- |
| UC-001 | `<user/reviewer/test>` | `<纠正或返工内容>` | `<原因>` | `<后续动作>` | `CLOSED / N/A` |

## Gate 触发与误报

| Gate | Trigger count | False positive count | Action | Status |
| --- | --- | --- | --- | --- |
| `<gate script>` | `<number>` | `<number>` | `keep / tune / retire-candidate / N/A` | `READY / N/A` |

## 规则升级 / 不升级决策

| ID | Candidate | Source | Decision | Reason | Status |
| --- | --- | --- | --- | --- | --- |
| IC-001 | `<candidate rule / gate / skill update>` | `<UC/Gate/Reviewer>` | `promote / reject / defer` | `<原因>` | `READY / N/A` |

## 知识沉淀

| Target | Action | Status |
| --- | --- | --- |
| `<docs/pitfalls or docs/decision-log or template/rule>` | `<新增/更新/N/A>` | `READY / N/A` |
