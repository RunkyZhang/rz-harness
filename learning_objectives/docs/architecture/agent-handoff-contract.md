# Agent Handoff Contract

> Phase 5A contract for SFA harness agent handoff and reviewer packages. This is a control-plane contract only; it does not authorize business repo edits, hook runtime changes, or `skill-usage-gate.sh` changes.

## 1. 适用范围

本契约适用于多 Agent、长上下文、跨任务 implementation、Test Agent 复验和 Reviewer Agent 审查的文件交接。目标是让任务 brief、实现报告、review package 和 progress ledger 成为可恢复、可复核的证据，而不是把长任务和 diff 反复粘贴在对话里。

Phase 5A 只固化 handoff 文件形状和 reviewer contract：

- 不修改 business repo。
- 不修改 hook adapters。
- 不修改 `scripts/skill-usage-gate.sh`。
- 不删除最终 `Reviewer Agent` 和 `reviewer-gate.sh`。
- 不要求每个普通小任务都派发 subagent；只有多 Agent、长上下文或高风险 review 时使用。

## 2. 文件契约

所有临时 handoff 文件放在 `.harness/agent-work/<change-id>/`。该目录必须自忽略；进入 Git 的只应是 `changes/<change-id>/evidence.md`、`test-agent-verification.md`、`review.md` 等摘要。

| File | Producer | Consumer | Required content | Versioned |
| --- | --- | --- | --- | --- |
| `progress-ledger.md` | `scripts/agent-workspace.sh` / Orchestrator | Orchestrator after compaction | `Task`, `Status`, `Owner`, `Task brief`, `Implementer report`, `Review package`, `Review verdict`, `Test / evidence`, `Notes` | NO |
| `task-<N>-brief.md` | `scripts/agent-task-brief.sh` | Implementer Agent / Reviewer Agent | `change_id`, `task_number`, `source_plan`, `source_repo`, one extracted task only | NO |
| `task-<N>-implementer-report.md` | Implementer Agent | Orchestrator / task Reviewer | status, changed files, tests run, evidence path, concerns, open blockers | NO |
| `review-<scope>-<base>..<head>.diff` | `scripts/agent-review-package.sh` | task Reviewer / final Reviewer | `review_scope`, `reviewer_independence`, `required_verdicts`, commits, file stat, full diff | NO |

Allowed `review_scope` values:

- `task`: review a single task or small task group.
- `whole-branch`: final whole-branch or whole-change review package.

## 3. Status Contract

Implementer report status values:

| Status | Meaning | Orchestrator action |
| --- | --- | --- |
| `DONE` | Task implemented and verified against task brief. | Generate review package and dispatch read-only review. |
| `DONE_WITH_CONCERNS` | Task implemented but concerns remain. | Read concerns, decide whether review can proceed, record risk. |
| `NEEDS_CONTEXT` | Implementer needs missing facts or files. | Provide bounded context or split task. |
| `BLOCKED` | Implementer cannot proceed safely. | Record blocker and stop only if Orchestrator cannot resolve within confirmed scope. |

Progress ledger `Status` values:

- `PLANNED`
- `IN_PROGRESS`
- `REVIEWING`
- `FIXING`
- `COMPLETE`
- `BLOCKED`
- `N/A`

## 4. Reviewer Contract

Reviewers are read-only. A review package must declare:

- `reviewer_independence: READ_ONLY`
- `required_verdicts: spec_compliance, code_quality`

The Reviewer must produce both verdicts:

| Verdict | PASS condition |
| --- | --- |
| `spec_compliance` | The diff implements the task brief and confirmed solution, with no unapproved scope. |
| `code_quality` | The implementation is maintainable, tested, and does not introduce avoidable risk. |

Reviewer prompts must not pre-judge findings. The following wording is forbidden unless it quotes a confirmed user exception with evidence path:

- "do not flag"
- "不要报"
- "ignore this"
- "最多 Minor"
- "按计划如此所以不算问题"

Any Critical / HIGH or Important / MEDIUM finding must be fixed or explicitly recorded before the task is marked `COMPLETE`.

## 5. Ledger Rules

The ledger is the recovery source after context compaction. For every dispatched task, Orchestrator records one row:

| Field | Rule |
| --- | --- |
| `Task` | Use task number and short title from `task-<N>-brief.md`. |
| `Status` | Use the controlled values in this contract. |
| `Owner` | Use role, not personal name: `Orchestrator`, `Backend Agent`, `Frontend Agent`, `Test Agent`, `Reviewer Agent`. |
| `Task brief` | Path to `task-<N>-brief.md`. |
| `Implementer report` | Path to `task-<N>-implementer-report.md`, or `N/A: reason`. |
| `Review package` | Path to `review-<scope>-<base>..<head>.diff`, or `N/A: reason`. |
| `Review verdict` | `PASS`, `ISSUES_FOUND`, `BLOCKED`, or `N/A: reason`. |
| `Test / evidence` | Path to evidence summary or command result. |
| `Notes` | Only sanitized summary. No secrets, tokens, cookies, DB passwords, raw private prompts, or customer data. |

## 6. Verification

Minimum local verification after changing this contract or the handoff scripts:

```bash
bash scripts/agent-handoff-workflow-test.sh
```

For this harness evolution change, Phase 5A also requires:

- `scripts/technical-solution-gate.sh changes/harness-evolution-architecture`
- `scripts/ai-test-plan-gate.sh changes/harness-evolution-architecture`
- `scripts/verification-map-gate.sh changes/harness-evolution-architecture`
- Feishu child doc outline and keyword fetch after publishing.

## 7. 来源归因

| Source | Usage |
| --- | --- |
| `[SP-SOURCE]` `subagent-driven-development` | Adopts task brief, implementer report, review package, durable ledger, task review, and final review principles. |
| `[SP-SOURCE]` `task-reviewer-prompt` | Adopts read-only reviewer and dual verdicts: `spec_compliance`, `code_quality`. |
| `[ECC-SOURCE]` worktree orchestration | Adapts file handoff and status ledger ideas without adopting tmux as SFA default. |
| `[LOCAL-FACT]` existing SFA scripts | Uses `agent-workspace.sh`, `agent-task-brief.sh`, `agent-review-package.sh`, `agent-handoff-workflow-test.sh`, `Reviewer Agent`, and `reviewer-gate.sh`. |
| `[AI-INFERENCE]` SFA-specific constraints | Keeps Orchestrator-only control-plane writes, Chinese review docs, Feishu evidence, Test Agent, Reviewer Agent, and business repo safety boundaries. |
