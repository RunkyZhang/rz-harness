# Hook Lifecycle Contract

> Docs-only contract for SFA harness hook lifecycle support. This file describes what is true today and what a future runtime pilot must prove. It does not authorize hook runtime changes.

```yaml
contract_status: DOCS_ONLY
runtime_changes_allowed: false
max_context_lines: 30
max_context_chars: 2000
owner: Orchestrator
last_verified: 2026-07-02
```

## 1. Purpose

SFA harness has adapter-backed hooks for Codex and Cursor, plus an OpenCode instruction adapter. The current risk is assuming hook lifecycle parity across tools when only part of the lifecycle is wired.

This contract separates three things:

- documented lifecycle intent,
- current adapter wiring,
- future runtime pilot requirements.

Do not modify `.codex/hooks.json`.
Do not modify `.cursor/hooks.json`.
Do not modify `scripts/harness-sensor-runner.sh`.

Those runtime files require a separate technical solution, AI test plan, rollback plan, and Feishu trace.

## 2. Status Labels

| Status | Meaning |
| --- | --- |
| `ADAPTER_WIRED` | The project adapter currently calls the harness runner for this lifecycle event. |
| `RUNNER_ONLY` | `scripts/harness-sensor-runner.sh` has code for this event, but the project adapter is not wired to call it. |
| `DESIGN_ONLY` | The lifecycle event is useful for future design, but no current local runner behavior exists. |
| `NOT_SUPPORTED` | The current adapter surface has no proven support in this repo. |

## 3. Lifecycle Matrix

| Adapter | SessionStart | PreToolUse | PostToolUse | Stop | PreCompact | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| Codex | `RUNNER_ONLY` | `ADAPTER_WIRED` | `ADAPTER_WIRED` | `NOT_SUPPORTED` | `NOT_SUPPORTED` | `.codex/hooks.json`; `scripts/harness-sensor-runner.sh` |
| Cursor | `NOT_SUPPORTED` | `ADAPTER_WIRED` via `beforeShellExecution` | `ADAPTER_WIRED` via `afterFileEdit` | `NOT_SUPPORTED` | `NOT_SUPPORTED` | `.cursor/hooks.json`; `scripts/harness-sensor-runner.sh` |
| OpenCode | `DESIGN_ONLY` | `DESIGN_ONLY` | `DESIGN_ONLY` | `NOT_SUPPORTED` | `NOT_SUPPORTED` | `opencode.json`; `config/opencode.local.json` generated locally |
| Plain runner | `RUNNER_ONLY` | `RUNNER_ONLY` | `RUNNER_ONLY` | `DESIGN_ONLY` | `DESIGN_ONLY` | `scripts/harness-sensor-runner.sh plain ...` |

## 4. Event Contracts

`can_block` is the semantic contract for whether the lifecycle can physically
prevent the risky action from happening:

| can_block | Meaning |
| --- | --- |
| `pre` | The event runs before the risky action and can be used as a hard stop. |
| `post` | The event runs after the risky action; it can warn, stop the next agent step, or block later versioning actions, but it cannot undo the already-written file. |
| `none` | The event is context or bookkeeping only and must not be described as a blocker. |

| Event | can_block | Current SFA behavior | Future pilot rule |
| --- | --- | --- | --- |
| `SessionStart` | `none` | Runner can emit concise context, but Codex / Cursor project adapters do not currently call it. | Only route reminders and stop-point reminders; max 30 lines and 2000 chars. |
| `PreToolUse` | `pre` | Blocks destructive shell commands for wired Codex and Cursor shell events; business repo `git add` / `git commit` / `git push` can be blocked before versioning. | Safety-deny behavior remains hard; process-hygiene blocks must stay narrow and fixture-backed. |
| `PostToolUse` | `post` | Runs changed-file checks and can emit a strong stop signal after edits; it cannot physically undo an edit that already landed. | Keep adapter thin; heavy checks remain in explicit gates, and physical blocking must be paired with a later `pre` event or stage gate. |
| `Stop` | `none` | No wired SFA behavior. | Future use may record sanitized closeout metrics only; no raw prompt persistence. |
| `PreCompact` | `none` | No wired SFA behavior. | Future use may write compact summaries only after a separate privacy review. |

## 5. SessionStart Budget

Future SessionStart content must be short and bounded:

- max_context_lines: 30
- max_context_chars: 2000
- allowed content: active change id, current stop point, skill-routing reminder, protected path warning
- forbidden content: raw prompt, raw Feishu body, token, cookie, DB password, customer data, private transcript

SessionStart must not load long plans, full docs, source diffs, or memory dumps.

## 6. Runtime Pilot Entry Conditions

Runtime pilot remains blocked until all conditions are true:

| Condition | Required evidence |
| --- | --- |
| Technical solution | `changes/harness-evolution-architecture/technical-solution.md` or a later change has a confirmed hook runtime section. |
| AI test plan | `ai-test-plan.md` includes SessionStart / hook payload fixtures and rollback checks. |
| Behavior eval | `harness-behavior-eval.sh` or later runner proves the reminder changes behavior without bypassing hard gates. |
| Privacy boundary | Telemetry and closeout records are sanitized and ignored raw records stay out of Git. |
| Rollback | Exact files and commands for disabling the pilot are recorded before runtime edit. |

## 7. Source Attribution

| Source | Usage |
| --- | --- |
| `[ECC-SOURCE]` `hooks/README.md` | Adapts lifecycle vocabulary and the idea of profile-based hook behavior. |
| `[ECC-SOURCE]` memory persistence docs | Adapts SessionStart / PreCompact separation, but rejects raw transcript persistence. |
| `[SP-SOURCE]` session-start-codex | Uses concise SessionStart reminder as a pattern, with stricter SFA budget. |
| `[LOCAL-FACT]` `.codex/hooks.json` | Confirms Codex project adapter currently wires only `PreToolUse` and `PostToolUse`. |
| `[LOCAL-FACT]` `.cursor/hooks.json` | Confirms Cursor project adapter currently wires only shell-before and edit-after events. |
| `[LOCAL-FACT]` `scripts/harness-sensor-runner.sh` | Confirms runner has `sessionStart`, `PreToolUse`, and `PostToolUse` code paths. |
| `[AI-INFERENCE]` SFA privacy boundary | Keeps hook lifecycle docs-only until telemetry, privacy, and rollback are proven. |

## 8. Verification

```bash
bash scripts/hook-lifecycle-contract-test.sh
scripts/adapter-compliance-gate.sh docs/architecture/adapter-compliance.md
scripts/harness-bootstrap-smoke.sh
```
