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

rehearsal_script="$root/scripts/harness-telemetry-rehearsal.sh"
readiness_script="$root/scripts/harness-telemetry-readiness.sh"
readiness_doc="$root/docs/architecture/harness-telemetry-readiness.md"

[[ -x "$rehearsal_script" ]] || fail "telemetry rehearsal script is missing or not executable"
assert_contains "$readiness_doc" 'rehearsal telemetry' "readiness doc must define rehearsal telemetry"
assert_contains "$root/docs/README.md" 'harness-telemetry-rehearsal.sh' "docs index must reference rehearsal script"
assert_contains "$root/docs/README.md" 'harness-telemetry-rehearsal-test.sh' "docs index must reference rehearsal test"

telemetry_root="$tmpdir/telemetry"
rehearsal_dir="$telemetry_root/rehearsal"
rehearsal_output="$tmpdir/rehearsal.out"
"$rehearsal_script" --telemetry-dir "$rehearsal_dir" --changes 5 --week 2026-W26 >"$rehearsal_output"

events_file="$rehearsal_dir/events.jsonl"
[[ -f "$events_file" ]] || fail "rehearsal did not create events.jsonl"
assert_contains "$events_file" '"change_id":"rehearsal-change-1"' "rehearsal change id missing"
assert_contains "$events_file" '"event_type":"skill_route_event"' "rehearsal skill events missing"
assert_contains "$events_file" '"event_type":"model_route_event"' "rehearsal model events missing"
assert_contains "$events_file" '"event_type":"reviewer_event"' "rehearsal reviewer events missing"
assert_contains "$events_file" '"event_type":"gate_run"' "rehearsal gate events missing"
assert_contains "$rehearsal_output" 'SIMULATION_SCOPE=REHEARSAL_ONLY' "rehearsal output must mark rehearsal-only scope"
assert_contains "$rehearsal_output" 'DECISION=READY_FOR_REVIEW' "rehearsal should prove ready path under explicit include"
assert_not_contains "$rehearsal_output" 'source_ref' "rehearsal output must stay aggregate-only"
printf 'PASS: rehearsal generates representative telemetry and aggregate output\n'

real_readiness="$tmpdir/real-readiness.out"
"$readiness_script" --telemetry-dir "$telemetry_root" >"$real_readiness"
assert_contains "$real_readiness" 'TOTAL_EVENTS=0' "default readiness must exclude rehearsal telemetry"
assert_contains "$real_readiness" 'DECISION=WAIT_DATA_WINDOW' "default readiness must not pass from rehearsal telemetry"
printf 'PASS: default readiness excludes rehearsal telemetry\n'

included_readiness="$tmpdir/included-readiness.out"
"$readiness_script" --telemetry-dir "$telemetry_root" --include-rehearsal >"$included_readiness"
assert_contains "$included_readiness" 'SKILL_USAGE_MIGRATION_READY=1' "explicit rehearsal include should satisfy skill usage readiness"
assert_contains "$included_readiness" 'MODEL_ROUTING_READY=1' "explicit rehearsal include should satisfy model routing readiness"
assert_contains "$included_readiness" 'DECISION=READY_FOR_REVIEW' "explicit rehearsal include should prove ready path"
assert_not_contains "$included_readiness" 'changes/rehearsal-change-1/evidence.md' "readiness output leaked source_ref"
printf 'PASS: explicit include can exercise ready path\n'

summary="$tmpdir/summary.md"
"$root/scripts/harness-weekly-audit-summary.sh" --telemetry-dir "$rehearsal_dir" --week 2026-W26 --include-rehearsal >"$summary"
assert_contains "$summary" '| total_events | 20 |' "weekly summary should count rehearsal events"
assert_contains "$summary" 'Model Route Roles' "weekly summary should include model route role aggregation"
assert_not_contains "$summary" 'changes/rehearsal-change-1/evidence.md' "weekly summary leaked source_ref"
printf 'PASS: weekly summary works with rehearsal data\n'

printf 'PASS: harness telemetry rehearsal test passed\n'
