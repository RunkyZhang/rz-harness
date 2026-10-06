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

readiness_doc="$root/docs/architecture/harness-telemetry-readiness.md"
readiness_script="$root/scripts/harness-telemetry-readiness.sh"

[[ -f "$readiness_doc" ]] || fail "telemetry readiness contract is missing"
[[ -x "$readiness_script" ]] || fail "telemetry readiness script is missing or not executable"
assert_contains "$root/docs/architecture/harness-telemetry.md" 'model_route_event' "telemetry doc must define model_route_event"
assert_contains "$readiness_doc" 'SKILL_USAGE_MIGRATION_READY' "readiness doc must define skill usage readiness output"
assert_contains "$readiness_doc" 'MODEL_ROUTING_READY' "readiness doc must define model routing readiness output"
assert_contains "$readiness_doc" '4 weeks' "readiness doc must mention four-week window"
assert_contains "$readiness_doc" '5 real changes' "readiness doc must mention five real changes"
assert_contains "$root/docs/README.md" 'harness-telemetry-readiness.md' "docs index must reference readiness doc"
assert_contains "$root/docs/README.md" 'harness-telemetry-readiness.sh' "docs index must reference readiness script"
assert_contains "$root/docs/README.md" 'harness-telemetry-readiness-test.sh' "docs index must reference readiness test"

telemetry_dir="$tmpdir/telemetry"

"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type model_route_event \
  --change-id change-1 \
  --role orchestrator \
  --model-tier standard \
  --turn-count 12 \
  --retry-count 1 \
  --failure-count 0 \
  --review-value medium \
  --source-ref changes/change-1/evidence.md \
  --timestamp 2026-06-01T00:00:00Z

events_file="$telemetry_dir/events.jsonl"
assert_contains "$events_file" '"event_type":"model_route_event"' "model_route_event was not recorded"
assert_contains "$events_file" '"model_tier":"standard"' "model tier missing from telemetry event"
printf 'PASS: model_route_event is allowlisted and recorded\n'

"$root/scripts/harness-telemetry-record.sh" \
  --telemetry-dir "$telemetry_dir" \
  --event-type skill_route_event \
  --change-id change-1 \
  --skill-id lark-doc \
  --trigger-reason feishu-doc-update \
  --outcome USED \
  --source-ref changes/change-1/evidence.md \
  --timestamp 2026-06-01T00:00:00Z

not_ready="$tmpdir/not-ready.md"
"$readiness_script" --telemetry-dir "$telemetry_dir" --min-changes 5 --min-weeks 4 --min-model-events 5 >"$not_ready"
assert_contains "$not_ready" 'SKILL_USAGE_MIGRATION_READY=0' "single change should not be skill migration ready"
assert_contains "$not_ready" 'MODEL_ROUTING_READY=0' "single model event should not be model routing ready"
assert_contains "$not_ready" 'DECISION=WAIT_DATA_WINDOW' "not-ready decision missing"
assert_not_contains "$not_ready" 'changes/change-1/evidence.md' "readiness output leaked source_ref"
printf 'PASS: readiness remains blocked with insufficient data\n'

for index in 2 3 4 5; do
  "$root/scripts/harness-telemetry-record.sh" \
    --telemetry-dir "$telemetry_dir" \
    --event-type skill_route_event \
    --change-id "change-$index" \
    --skill-id lark-doc \
    --trigger-reason feishu-doc-update \
    --outcome USED \
    --source-ref "changes/change-$index/evidence.md" \
    --timestamp "2026-06-0${index}T00:00:00Z" >/dev/null

  "$root/scripts/harness-telemetry-record.sh" \
    --telemetry-dir "$telemetry_dir" \
    --event-type model_route_event \
    --change-id "change-$index" \
    --role reviewer \
    --model-tier standard \
    --turn-count 8 \
    --retry-count 0 \
    --failure-count 0 \
    --review-value high \
    --source-ref "changes/change-$index/evidence.md" \
    --timestamp "2026-06-0${index}T00:00:00Z" >/dev/null
done

ready="$tmpdir/ready.md"
"$readiness_script" --telemetry-dir "$telemetry_dir" --min-changes 5 --min-weeks 4 --min-model-events 5 >"$ready"
assert_contains "$ready" 'DISTINCT_CHANGES=5' "readiness should count distinct changes"
assert_contains "$ready" 'SKILL_ROUTE_EVENTS=5' "readiness should count skill route events"
assert_contains "$ready" 'MODEL_ROUTE_EVENTS=5' "readiness should count model route events"
assert_contains "$ready" 'SKILL_USAGE_MIGRATION_READY=1' "five changes should satisfy skill usage data window"
assert_contains "$ready" 'MODEL_ROUTING_READY=1' "five model events should satisfy model routing data window"
assert_contains "$ready" 'DECISION=READY_FOR_REVIEW' "ready decision missing"
printf 'PASS: readiness passes when data window thresholds are met\n'

empty_dir="$tmpdir/empty"
mkdir -p "$empty_dir"
empty="$tmpdir/empty.md"
"$readiness_script" --telemetry-dir "$empty_dir" >"$empty"
assert_contains "$empty" 'TOTAL_EVENTS=0' "empty readiness should report zero events"
assert_contains "$empty" 'SKILL_USAGE_MIGRATION_READY=0' "empty readiness should not pass skill migration"
assert_contains "$empty" 'MODEL_ROUTING_READY=0' "empty readiness should not pass model routing"
printf 'PASS: empty telemetry is not ready\n'

printf 'PASS: harness telemetry readiness test passed\n'
