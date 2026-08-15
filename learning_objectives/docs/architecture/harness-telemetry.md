# Harness Telemetry

> Phase 4B control-plane telemetry design. This document defines what may be recorded, what must be rejected, and what may enter version control.

## Goals

- Record enough control effectiveness data to support later gate migration, softening, or retirement.
- Keep raw events local and ignored.
- Keep versioned summaries aggregate-only and reviewable.
- Preserve existing hard gates, hooks, `skill-usage-gate.sh`, and business repo behavior.

## Storage Boundary

| Layer | Path | Versioned? | Contents |
| --- | --- | --- | --- |
| Raw event scratch | `.harness/telemetry/events.jsonl` | no | allowlisted JSONL events only |
| Test fixtures | temporary directories from `mktemp -d` | no | synthetic event rows |
| Reviewable summaries | `changes/<change-id>/evidence.md` or `docs/decision-log/audit/*.md` | yes | aggregate counts and conclusions only |

## Event Types

| Event type | Required fields | Optional fields |
| --- | --- | --- |
| `gate_run` | `change_id`, `gate_id`, `risk_tier`, `result`, `source_ref` | `block_code`, `timestamp` |
| `gate_effectiveness_review` | `gate_id`, `true_catch`, `false_positive`, `manual_override`, `duplicate_signal`, `replacement_protection`, `reviewer`, `source_ref` | `timestamp` |
| `skill_route_event` | `change_id`, `skill_id`, `trigger_reason`, `outcome`, `source_ref` | `failure_reason`, `timestamp` |
| `reviewer_event` | `change_id`, `review_type`, `high_risk_count`, `medium_risk_count`, `decision`, `source_ref` | `timestamp` |
| `model_route_event` | `change_id`, `role`, `model_tier`, `turn_count`, `retry_count`, `failure_count`, `review_value`, `source_ref` | `timestamp` |
| `agent_dispatch_event` | `change_id`, `agent_id`, `agent_role`, `dispatch_stage`, `permission`, `result`, `source_ref` | `timestamp` |
| `verification_run_event` | `change_id`, `verification_runner`, `result`, `pass_count`, `fail_count`, `skip_count`, `dry_run`, `source_ref` | `verification_id`, `failure_reason`, `timestamp` |
| `human_confirmation_event` | `change_id`, `confirmation_item`, `decision`, `source_ref` | `timestamp` |
| `rework_cycle_event` | `change_id`, `cycle_reason`, `outcome`, `source_ref` | `timestamp` |
| `eval_trial_event` | `change_id`, `eval_id`, `scenario_id`, `trial_id`, `result`, `source_ref` | `failure_reason`, `timestamp` |
| `eval_suite_event` | `change_id`, `suite_id`, `result`, `decision`, `suite_total`, `suite_passed`, `suite_failed`, `source_ref` | `business_golden_total`, `business_golden_matched`, `business_golden_promoted`, `replay_fixture_total`, `replay_fixture_matched`, `pass_power_k`, `timestamp` |

`eval_trial_event.failure_reason` is limited to a short single-line safe label
such as `none` or `AGENT_EXITED`. It must not contain prose, raw prompts,
transcripts, command output, or multiline text.

## Rejection Rules

`scripts/harness-telemetry-record.sh` must fail closed when:

- The event type is unknown.
- A provided field is not allowlisted for that event type.
- A required field is missing.
- Any value contains obvious credential, cookie, authorization, private key, or raw SQL-result markers.

## Summary Rules

`scripts/harness-weekly-audit-summary.sh` may output:

- total event count
- count by event type
- count by result / outcome / decision
- count by gate id
- count by skill id
- reviewer decision counts
- count by model route role and model tier
- count by agent id and dispatch stage
- count by verification runner
- count by confirmation item and rework reason
- count by eval id and scenario id
- eval suite run counts by `suite_id`, including passed / failed run counts and latest decision

By default it excludes files under a `rehearsal/` directory so weekly audit
counts match the real-data default used by readiness. Use
`--include-rehearsal` only when validating the rehearsal pipeline.

It must not output raw prompt text, raw logs, private Feishu body text, command output, credentials, cookies, customer data, or DB query results.

## Readiness Rules

`scripts/harness-telemetry-readiness.sh` may output only aggregate readiness counts:

- `SKILL_USAGE_MIGRATION_READY`
- `MODEL_ROUTING_READY`
- `DISTINCT_CHANGES`
- `DISTINCT_WEEKS`
- event counts by type

It must not migrate `skill-usage-gate.sh`, route models automatically, or output `source_ref` values.

## Rollback

- Delete `.harness/telemetry/` to remove raw events.
- Remove any generated weekly summary if it was created from invalid inputs.
- No business repo rollback is required because Phase 4B does not touch business repositories.
