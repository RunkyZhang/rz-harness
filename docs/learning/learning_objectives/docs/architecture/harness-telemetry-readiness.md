# Harness Telemetry Readiness

> Phase 5E contract for deciding whether telemetry has enough real data to review `skill-usage-gate.sh` migration or model routing cost controls. This is a no-fail readiness report; it does not migrate gates or route models.

```yaml
contract_status: DOCS_AND_READINESS_SCRIPT
runtime_changes_allowed: false
gate_changes_allowed: false
default_min_weeks: 4
default_min_real_changes: 5
owner: Orchestrator
last_verified: 2026-06-26
```

## 1. Purpose

Phase 4B introduced sanitized telemetry events, but the harness still needs a clear stop point before changing `skill-usage-gate.sh` or adding model routing controls.

This contract makes the data window explicit:

- `skill-usage-gate.sh` migration review needs 4 weeks or 5 real changes with skill route evidence.
- model routing review needs enough role/model telemetry to compare turn count, retries, failures, and review value.
- readiness is a report, not an implementation permission.
- rehearsal telemetry may prove the pipeline before real usage, but it is not real evidence for gate migration or model routing.

## 2. Inputs

`scripts/harness-telemetry-readiness.sh` reads ignored local JSONL from `.harness/telemetry/` or a supplied temporary directory.

By default it excludes files under a `rehearsal/` directory. Pass `--include-rehearsal` only when validating the rehearsal pipeline itself.

Allowed input event types:

| Event | Used for |
| --- | --- |
| `skill_route_event` | Measures whether skill usage can be audited from events instead of manual table rows. |
| `model_route_event` | Measures whether model routing has enough role/model outcome data. |
| `gate_run` | Context only; does not prove migration readiness alone. |
| `reviewer_event` | Context only; helps later compare review value and failure patterns. |

## 3. `model_route_event`

Phase 5E adds one manual telemetry event type:

| Required field | Meaning |
| --- | --- |
| `change_id` | Source change id. |
| `role` | Agent role, such as `orchestrator`, `reviewer`, `test-agent`, or `worker`. |
| `model_tier` | Sanitized tier label, such as `fast`, `standard`, or `frontier`; do not record provider secrets. |
| `turn_count` | Number of turns used by that role for the scoped work. |
| `retry_count` | Number of retries caused by failed checks or unclear output. |
| `failure_count` | Number of failed outcomes attributable to this route. |
| `review_value` | One of `none`, `low`, `medium`, `high`; reviewed value of this route. |
| `source_ref` | Local evidence reference. |

`model_route_event` must not include raw prompts, raw model output, token strings, cookies, account ids, customer data, or private Feishu body text.

## 4. Readiness Outputs

The script prints machine-readable lines:

| Output | Meaning |
| --- | --- |
| `TOTAL_EVENTS` | Count of JSONL rows read. |
| `DISTINCT_CHANGES` | Count of distinct `change_id` values across useful events. |
| `DISTINCT_WEEKS` | Count of ISO weeks represented by event timestamps. |
| `SKILL_ROUTE_EVENTS` | Count of `skill_route_event` rows. |
| `MODEL_ROUTE_EVENTS` | Count of `model_route_event` rows. |
| `SKILL_USAGE_MIGRATION_READY` | `1` only when the skill data window meets the threshold. |
| `MODEL_ROUTING_READY` | `1` only when model route events meet the threshold. |
| `DECISION` | `READY_FOR_REVIEW` or `WAIT_DATA_WINDOW`. |

Readiness means "safe to write a migration or routing review proposal", not "safe to implement migration".

## 5. Thresholds

Default thresholds:

- `--min-changes 5`
- `--min-weeks 4`
- `--min-model-events 5`

`SKILL_USAGE_MIGRATION_READY=1` when either:

- at least 5 real changes have `skill_route_event`, or
- at least 4 weeks contain `skill_route_event`.

`MODEL_ROUTING_READY=1` when:

- at least 5 `model_route_event` rows exist, and
- at least 2 distinct roles are represented.

## 6. Stop Points

Phase 5E does not allow:

- modifying `scripts/skill-usage-gate.sh`
- softening existing hard gates
- editing hook runtime files
- adding automatic model routing
- writing raw prompts or model output
- touching business repositories

If readiness passes, the next step is a separate technical solution comparing keep / soften / retire for `skill-usage-gate.sh`, or a separate model routing budget proposal.

## 7. Rehearsal Mode

`scripts/harness-telemetry-rehearsal.sh` generates representative, sanitized rehearsal telemetry into `.harness/telemetry/rehearsal/` by default. It then runs:

- `scripts/harness-telemetry-readiness.sh --include-rehearsal`
- `scripts/harness-weekly-audit-summary.sh --include-rehearsal`

This mode exists so the Orchestrator can self-close the local pipeline before a human runs a real change. It must print `SIMULATION_SCOPE=REHEARSAL_ONLY`, and normal readiness must still return `WAIT_DATA_WINDOW` when only rehearsal data exists.

Rehearsal output may be used to verify wiring, aggregation, and stop points. It must not be used as real telemetry evidence for:

- migrating `skill-usage-gate.sh`
- adding automatic model routing
- changing hook runtime
- writing project/global memory
- claiming real multi-change adoption

## 8. Source Attribution

| Source | Usage |
| --- | --- |
| `[LOCAL-FACT]` Phase 4B telemetry | Reuses existing sanitized JSONL boundary and ignored raw storage. |
| `[LOCAL-FACT]` remaining issues matrix | Uses the recorded 4 weeks or 5 real changes prerequisite for `skill-usage-gate.sh` migration. |
| `[ECC-SOURCE]` skills health and execution tracking | Adapts data-window and health trend ideas without copying ECC runtime. |
| `[SP-SOURCE]` evidence-before-completion | Requires data before changing process gates or model routing. |
| `[AI-INFERENCE]` model routing fields | Adds role/model/turn/retry/failure/review-value fields as SFA-specific cost-control inputs. |

## 9. Verification

```bash
bash scripts/harness-telemetry-readiness-test.sh
scripts/harness-telemetry-rehearsal.sh
scripts/harness-telemetry-readiness.sh
scripts/harness-telemetry-readiness.sh --telemetry-dir .harness/telemetry
```
