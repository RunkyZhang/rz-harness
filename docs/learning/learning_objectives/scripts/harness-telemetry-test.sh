#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local file="$1" pattern="$2" label="$3"
  grep -qF "$pattern" "$file" || fail "$label"
}

assert_not_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -qF "$pattern" "$file"; then
    fail "$label"
  fi
}

telemetry_dir="$tmpdir/telemetry"

"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type gate_run \
  --change-id harness-evolution-architecture \
  --gate-id confidence-gate \
  --risk-tier L3 \
  --result PASS \
  --source-ref changes/harness-evolution-architecture/evidence.md

events_file="$telemetry_dir/events.jsonl"
[[ -f "$events_file" ]] || fail "events file was not created"
assert_contains "$events_file" '"event_type":"gate_run"' "gate_run event missing"
assert_contains "$events_file" '"gate_id":"confidence-gate"' "gate_id missing"
assert_contains "$events_file" '"timestamp":"' "timestamp missing"
printf 'PASS: allowed telemetry event is recorded\n'

if "$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type gate_run \
  --change-id harness-evolution-architecture \
  --gate-id confidence-gate \
  --risk-tier L3 \
  --result PASS \
  --source-ref changes/harness-evolution-architecture/evidence.md \
  --raw-prompt "must not be accepted" >/tmp/sfa-telemetry-unknown.out 2>&1; then
  fail "unknown telemetry field was accepted"
fi
assert_contains /tmp/sfa-telemetry-unknown.out 'TELEMETRY/UNKNOWN_FIELD' "unknown field error code missing"
rm -f /tmp/sfa-telemetry-unknown.out
printf 'PASS: unknown telemetry field is rejected\n'

blocked_marker="$("printf" '%s=%s' 'pass''word' 'fixture')"
before_count="$(wc -l <"$events_file" | tr -d ' ')"
if "$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type skill_route_event \
  --change-id harness-evolution-architecture \
  --skill-id lark-doc \
  --trigger-reason "$blocked_marker" \
  --outcome USED \
  --source-ref changes/harness-evolution-architecture/evidence.md >/tmp/sfa-telemetry-sensitive.out 2>&1; then
  fail "sensitive telemetry value was accepted"
fi
assert_contains /tmp/sfa-telemetry-sensitive.out 'TELEMETRY/SENSITIVE_VALUE' "sensitive value error code missing"
after_count="$(wc -l <"$events_file" | tr -d ' ')"
[[ "$before_count" == "$after_count" ]] || fail "sensitive rejection wrote a row"
rm -f /tmp/sfa-telemetry-sensitive.out
printf 'PASS: sensitive telemetry value is rejected without writing\n'

"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type eval_trial_event \
  --change-id harness-replay-eval-foundation \
  --eval-id harness-behavior-replay \
  --scenario-id technical-solution-stop \
  --trial-id positive-stop-no-edit \
  --result PASS \
  --failure-reason none \
  --source-ref evals/harness-behavior/replay/technical-solution-stop/positive-stop-no-edit/metadata.env

assert_contains "$events_file" '"event_type":"eval_trial_event"' "eval trial event missing"
assert_contains "$events_file" '"eval_id":"harness-behavior-replay"' "eval id missing"
assert_contains "$events_file" '"scenario_id":"technical-solution-stop"' "scenario id missing"
printf 'PASS: eval_trial_event is allowlisted and recorded\n'

if "$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type eval_trial_event \
  --change-id harness-replay-eval-foundation \
  --eval-id harness-behavior-replay \
  --scenario-id technical-solution-stop \
  --trial-id unsafe-failure \
  --result FAIL \
  --failure-reason "raw transcript pasted here" \
  --source-ref evals/harness-behavior/replay/technical-solution-stop/negative-false-done/metadata.env >/tmp/sfa-telemetry-eval-reason.out 2>&1; then
  fail "free-text eval trial failure reason was accepted"
fi
assert_contains /tmp/sfa-telemetry-eval-reason.out 'TELEMETRY/UNSAFE_FAILURE_REASON' "unsafe eval failure reason error code missing"
rm -f /tmp/sfa-telemetry-eval-reason.out
printf 'PASS: eval_trial_event failure reason is a safe label\n'

if "$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type eval_trial_event \
  --change-id harness-replay-eval-foundation \
  --eval-id harness-behavior-replay \
  --scenario-id technical-solution-stop \
  --trial-id multiline-failure \
  --result FAIL \
  --failure-reason $'AGENT_EXITED\nraw output line' \
  --source-ref evals/harness-behavior/replay/technical-solution-stop/negative-false-done/metadata.env >/tmp/sfa-telemetry-multiline.out 2>&1; then
  fail "multiline telemetry value was accepted"
fi
assert_contains /tmp/sfa-telemetry-multiline.out 'TELEMETRY/MULTILINE_VALUE' "multiline value error code missing"
rm -f /tmp/sfa-telemetry-multiline.out
printf 'PASS: multiline telemetry values are rejected\n'

"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type eval_suite_event \
  --change-id harness-replay-eval-foundation \
  --suite-id harness-eval-suite \
  --result PASS \
  --decision PASS_EVAL_SUITE \
  --suite-total 12 \
  --suite-passed 12 \
  --suite-failed 0 \
  --business-golden-total 6 \
  --business-golden-matched 6 \
  --business-golden-promoted 3 \
  --replay-fixture-total 8 \
  --replay-fixture-matched 8 \
  --pass-power-k 1 \
  --source-ref changes/harness-replay-eval-foundation/evidence.md

assert_contains "$events_file" '"event_type":"eval_suite_event"' "eval suite event missing"
assert_contains "$events_file" '"suite_id":"harness-eval-suite"' "eval suite id missing"
assert_contains "$events_file" '"suite_passed":"12"' "eval suite passed count missing"
printf 'PASS: eval_suite_event is allowlisted and recorded\n'

"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type skill_route_event \
  --change-id harness-evolution-architecture \
  --skill-id lark-doc \
  --trigger-reason feishu-doc-update \
  --outcome USED \
  --source-ref changes/harness-evolution-architecture/evidence.md

"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type reviewer_event \
  --change-id harness-evolution-architecture \
  --review-type read-only \
  --high-risk-count 0 \
  --medium-risk-count 1 \
  --decision PASS \
  --source-ref changes/harness-evolution-architecture/review.md

"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type agent_dispatch_event \
  --change-id harness-evolution-architecture \
  --agent-id sfa-test-agent \
  --agent-role verification \
  --dispatch-stage pre-test-release \
  --permission read_only \
  --result PASS \
  --source-ref changes/harness-evolution-architecture/agent-dispatch-plan.md

"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type verification_run_event \
  --change-id harness-evolution-architecture \
  --verification-id VM-001 \
  --verification-runner shell \
  --result PASS \
  --pass-count 1 \
  --fail-count 0 \
  --skip-count 0 \
  --dry-run false \
  --source-ref changes/harness-evolution-architecture/verification-run-report.md

"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type human_confirmation_event \
  --change-id harness-evolution-architecture \
  --confirmation-item technical_solution \
  --decision CONFIRMED \
  --source-ref changes/harness-evolution-architecture/technical-solution.md

"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type rework_cycle_event \
  --change-id harness-evolution-architecture \
  --cycle-reason reviewer_feedback \
  --outcome FIXED \
  --source-ref changes/harness-evolution-architecture/review.md

mkdir -p "$telemetry_dir/rehearsal"
"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir/rehearsal" \
  --event-type gate_run \
  --change-id rehearsal-change \
  --gate-id rehearsal-gate \
  --risk-tier L3 \
  --result PASS \
  --source-ref changes/rehearsal-change/evidence.md

summary="$tmpdir/summary.md"
"$root/scripts/harness-weekly-audit-summary.sh" \
  --telemetry-dir "$telemetry_dir" \
  --week 2026-W26 >"$summary"

assert_contains "$summary" '# Harness Weekly Audit Summary' "summary title missing"
assert_contains "$summary" '| gate_run | 1 |' "event type aggregate missing"
assert_contains "$summary" '| eval_trial_event | 1 |' "eval trial event aggregate missing"
assert_contains "$summary" '| eval_suite_event | 1 |' "eval suite event aggregate missing"
assert_contains "$summary" '| skill_route_event | 1 |' "skill event aggregate missing"
assert_contains "$summary" '| reviewer_event | 1 |' "reviewer event aggregate missing"
assert_contains "$summary" '| agent_dispatch_event | 1 |' "agent dispatch event aggregate missing"
assert_contains "$summary" '| verification_run_event | 1 |' "verification run event aggregate missing"
assert_contains "$summary" '| human_confirmation_event | 1 |' "human confirmation event aggregate missing"
assert_contains "$summary" '| rework_cycle_event | 1 |' "rework cycle event aggregate missing"
assert_contains "$summary" '| confidence-gate | 1 |' "gate aggregate missing"
assert_contains "$summary" '| lark-doc | 1 |' "skill aggregate missing"
assert_contains "$summary" '| sfa-test-agent | 1 |' "agent aggregate missing"
assert_contains "$summary" '| pre-test-release | 1 |' "dispatch stage aggregate missing"
assert_contains "$summary" '| shell | 1 |' "verification runner aggregate missing"
assert_contains "$summary" '| harness-behavior-replay | 1 |' "eval id aggregate missing"
assert_contains "$summary" '| technical-solution-stop | 1 |' "scenario id aggregate missing"
assert_contains "$summary" '| harness-eval-suite | 1 | 1 | 0 | PASS_EVAL_SUITE |' "eval suite trend aggregate missing"
assert_contains "$summary" '| technical_solution | 1 |' "confirmation item aggregate missing"
assert_contains "$summary" '| reviewer_feedback | 1 |' "rework reason aggregate missing"
assert_not_contains "$summary" 'rehearsal-gate' "weekly summary should exclude rehearsal telemetry by default"
assert_not_contains "$summary" "$blocked_marker" "summary leaked blocked marker fixture"
printf 'PASS: weekly audit summary is aggregate-only\n'

included_summary="$tmpdir/included-summary.md"
"$root/scripts/harness-weekly-audit-summary.sh" \
  --telemetry-dir "$telemetry_dir" \
  --week 2026-W26 \
  --include-rehearsal >"$included_summary"
assert_contains "$included_summary" '| gate_run | 2 |' "explicit rehearsal include should count rehearsal gate events"
assert_contains "$included_summary" '| rehearsal-gate | 1 |' "explicit rehearsal include should include rehearsal gate aggregate"
printf 'PASS: weekly audit summary can explicitly include rehearsal telemetry\n'

git -C "$root" check-ignore -q .harness/telemetry/sample.jsonl || fail ".harness/telemetry is not git-ignored"
printf 'PASS: raw telemetry default path is git-ignored\n'

empty_dir="$tmpdir/empty"
mkdir -p "$empty_dir"
"$root/scripts/harness-weekly-audit-summary.sh" --telemetry-dir "$empty_dir" --week 2026-W26 >"$tmpdir/empty-summary.md"
assert_contains "$tmpdir/empty-summary.md" '| total_events | 0 |' "empty telemetry summary missing zero count"
printf 'PASS: empty telemetry directory produces zero summary\n'

printf 'PASS: harness telemetry test passed\n'
