#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-telemetry-record.sh --event-type <type> [fields...] [--telemetry-dir <dir>]

Records an allowlisted, local-only harness telemetry event. The default output
path is .harness/telemetry/events.jsonl, which is ignored by git.
USAGE
}

fail() {
  local code="$1" message="$2" fix="$3" sample="$4"
  printf 'FAIL: %s\n' "$message" >&2
  printf 'CODE: %s\n' "$code" >&2
  printf 'FIX: %s\n' "$fix" >&2
  printf 'SAMPLE: %s\n' "$sample" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
telemetry_dir="${SFA_HARNESS_TELEMETRY_DIR:-$root/.harness/telemetry}"
event_type=""
timestamp=""
change_id=""
gate_id=""
risk_tier=""
result=""
block_code=""
source_ref=""
true_catch=""
false_positive=""
manual_override=""
duplicate_signal=""
replacement_protection=""
reviewer=""
skill_id=""
trigger_reason=""
outcome=""
failure_reason=""
review_type=""
high_risk_count=""
medium_risk_count=""
decision=""
role=""
model_tier=""
turn_count=""
retry_count=""
failure_count=""
review_value=""
agent_id=""
agent_role=""
dispatch_stage=""
permission=""
verification_id=""
verification_runner=""
pass_count=""
fail_count=""
skip_count=""
dry_run=""
confirmation_item=""
cycle_reason=""
eval_id=""
scenario_id=""
trial_id=""
suite_id=""
suite_total=""
suite_passed=""
suite_failed=""
business_golden_total=""
business_golden_matched=""
business_golden_promoted=""
replay_fixture_total=""
replay_fixture_matched=""
pass_power_k=""

set_field() {
  local key="$1" value="$2"
  case "$key" in
    event_type) event_type="$value" ;;
    timestamp) timestamp="$value" ;;
    change_id) change_id="$value" ;;
    gate_id) gate_id="$value" ;;
    risk_tier) risk_tier="$value" ;;
    result) result="$value" ;;
    block_code) block_code="$value" ;;
    source_ref) source_ref="$value" ;;
    true_catch) true_catch="$value" ;;
    false_positive) false_positive="$value" ;;
    manual_override) manual_override="$value" ;;
    duplicate_signal) duplicate_signal="$value" ;;
    replacement_protection) replacement_protection="$value" ;;
    reviewer) reviewer="$value" ;;
    skill_id) skill_id="$value" ;;
    trigger_reason) trigger_reason="$value" ;;
    outcome) outcome="$value" ;;
    failure_reason) failure_reason="$value" ;;
    review_type) review_type="$value" ;;
    high_risk_count) high_risk_count="$value" ;;
    medium_risk_count) medium_risk_count="$value" ;;
    decision) decision="$value" ;;
    role) role="$value" ;;
    model_tier) model_tier="$value" ;;
    turn_count) turn_count="$value" ;;
    retry_count) retry_count="$value" ;;
    failure_count) failure_count="$value" ;;
    review_value) review_value="$value" ;;
    agent_id) agent_id="$value" ;;
    agent_role) agent_role="$value" ;;
    dispatch_stage) dispatch_stage="$value" ;;
    permission) permission="$value" ;;
    verification_id) verification_id="$value" ;;
    verification_runner) verification_runner="$value" ;;
    pass_count) pass_count="$value" ;;
    fail_count) fail_count="$value" ;;
    skip_count) skip_count="$value" ;;
    dry_run) dry_run="$value" ;;
    confirmation_item) confirmation_item="$value" ;;
    cycle_reason) cycle_reason="$value" ;;
    eval_id) eval_id="$value" ;;
    scenario_id) scenario_id="$value" ;;
    trial_id) trial_id="$value" ;;
    suite_id) suite_id="$value" ;;
    suite_total) suite_total="$value" ;;
    suite_passed) suite_passed="$value" ;;
    suite_failed) suite_failed="$value" ;;
    business_golden_total) business_golden_total="$value" ;;
    business_golden_matched) business_golden_matched="$value" ;;
    business_golden_promoted) business_golden_promoted="$value" ;;
    replay_fixture_total) replay_fixture_total="$value" ;;
    replay_fixture_matched) replay_fixture_matched="$value" ;;
    pass_power_k) pass_power_k="$value" ;;
    *)
      fail \
        "TELEMETRY/UNKNOWN_FIELD" \
        "unknown telemetry field: $key" \
        "Use only the event fields documented in docs/architecture/harness-telemetry.md." \
        "scripts/harness-telemetry-record.sh --event-type gate_run --change-id demo --gate-id confidence-gate --risk-tier L3 --result PASS --source-ref changes/demo/evidence.md"
      ;;
  esac
}

flag_to_key() {
  printf '%s' "${1#--}" | tr '-' '_'
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --telemetry-dir)
      telemetry_dir="${2:-}"
      [[ -n "$telemetry_dir" ]] || fail "TELEMETRY/MISSING_VALUE" "missing value for --telemetry-dir" "Pass a directory path." "--telemetry-dir .harness/telemetry"
      shift 2
      ;;
    --*)
      key="$(flag_to_key "$1")"
      value="${2:-}"
      [[ -n "$value" ]] || fail "TELEMETRY/MISSING_VALUE" "missing value for $1" "Pass a non-empty value." "$1 value"
      set_field "$key" "$value"
      shift 2
      ;;
    *)
      fail "TELEMETRY/UNKNOWN_ARG" "unknown argument: $1" "Use --field value pairs only." "scripts/harness-telemetry-record.sh --help"
      ;;
  esac
done

[[ -n "$event_type" ]] || fail "TELEMETRY/MISSING_EVENT_TYPE" "missing --event-type" "Pass one supported event type." "--event-type gate_run"

is_allowed_for_event() {
  local key="$1"
  case "$event_type:$key" in
    gate_run:event_type|gate_run:timestamp|gate_run:change_id|gate_run:gate_id|gate_run:risk_tier|gate_run:result|gate_run:block_code|gate_run:source_ref) return 0 ;;
    gate_effectiveness_review:event_type|gate_effectiveness_review:timestamp|gate_effectiveness_review:gate_id|gate_effectiveness_review:true_catch|gate_effectiveness_review:false_positive|gate_effectiveness_review:manual_override|gate_effectiveness_review:duplicate_signal|gate_effectiveness_review:replacement_protection|gate_effectiveness_review:reviewer|gate_effectiveness_review:source_ref) return 0 ;;
    skill_route_event:event_type|skill_route_event:timestamp|skill_route_event:change_id|skill_route_event:skill_id|skill_route_event:trigger_reason|skill_route_event:outcome|skill_route_event:failure_reason|skill_route_event:source_ref) return 0 ;;
    reviewer_event:event_type|reviewer_event:timestamp|reviewer_event:change_id|reviewer_event:review_type|reviewer_event:high_risk_count|reviewer_event:medium_risk_count|reviewer_event:decision|reviewer_event:source_ref) return 0 ;;
    model_route_event:event_type|model_route_event:timestamp|model_route_event:change_id|model_route_event:role|model_route_event:model_tier|model_route_event:turn_count|model_route_event:retry_count|model_route_event:failure_count|model_route_event:review_value|model_route_event:source_ref) return 0 ;;
    agent_dispatch_event:event_type|agent_dispatch_event:timestamp|agent_dispatch_event:change_id|agent_dispatch_event:agent_id|agent_dispatch_event:agent_role|agent_dispatch_event:dispatch_stage|agent_dispatch_event:permission|agent_dispatch_event:result|agent_dispatch_event:source_ref) return 0 ;;
    verification_run_event:event_type|verification_run_event:timestamp|verification_run_event:change_id|verification_run_event:verification_id|verification_run_event:verification_runner|verification_run_event:result|verification_run_event:pass_count|verification_run_event:fail_count|verification_run_event:skip_count|verification_run_event:dry_run|verification_run_event:failure_reason|verification_run_event:source_ref) return 0 ;;
    human_confirmation_event:event_type|human_confirmation_event:timestamp|human_confirmation_event:change_id|human_confirmation_event:confirmation_item|human_confirmation_event:decision|human_confirmation_event:source_ref) return 0 ;;
    rework_cycle_event:event_type|rework_cycle_event:timestamp|rework_cycle_event:change_id|rework_cycle_event:cycle_reason|rework_cycle_event:outcome|rework_cycle_event:source_ref) return 0 ;;
    eval_trial_event:event_type|eval_trial_event:timestamp|eval_trial_event:change_id|eval_trial_event:eval_id|eval_trial_event:scenario_id|eval_trial_event:trial_id|eval_trial_event:result|eval_trial_event:failure_reason|eval_trial_event:source_ref) return 0 ;;
    eval_suite_event:event_type|eval_suite_event:timestamp|eval_suite_event:change_id|eval_suite_event:suite_id|eval_suite_event:result|eval_suite_event:decision|eval_suite_event:suite_total|eval_suite_event:suite_passed|eval_suite_event:suite_failed|eval_suite_event:business_golden_total|eval_suite_event:business_golden_matched|eval_suite_event:business_golden_promoted|eval_suite_event:replay_fixture_total|eval_suite_event:replay_fixture_matched|eval_suite_event:pass_power_k|eval_suite_event:source_ref) return 0 ;;
  esac
  return 1
}

case "$event_type" in
  gate_run|gate_effectiveness_review|skill_route_event|reviewer_event|model_route_event|agent_dispatch_event|verification_run_event|human_confirmation_event|rework_cycle_event|eval_trial_event|eval_suite_event) ;;
  *)
    fail "TELEMETRY/UNKNOWN_EVENT_TYPE" "unknown telemetry event type: $event_type" "Use a supported event type." "gate_run"
    ;;
esac

for key in timestamp change_id gate_id risk_tier result block_code source_ref true_catch false_positive manual_override duplicate_signal replacement_protection reviewer skill_id trigger_reason outcome failure_reason review_type high_risk_count medium_risk_count decision role model_tier turn_count retry_count failure_count review_value agent_id agent_role dispatch_stage permission verification_id verification_runner pass_count fail_count skip_count dry_run confirmation_item cycle_reason eval_id scenario_id trial_id suite_id suite_total suite_passed suite_failed business_golden_total business_golden_matched business_golden_promoted replay_fixture_total replay_fixture_matched pass_power_k; do
  value="$(eval "printf '%s' \"\${$key}\"")"
  if [[ -n "$value" ]] && ! is_allowed_for_event "$key"; then
    fail "TELEMETRY/FIELD_NOT_ALLOWED" "field $key is not allowed for $event_type" "Remove the field or choose the correct event type." "$event_type"
  fi
done

check_single_line() {
  local key="$1" value="$2"
  [[ -z "$value" ]] && return 0
  if [[ "$value" == *$'\n'* || "$value" == *$'\r'* ]]; then
    fail \
      "TELEMETRY/MULTILINE_VALUE" \
      "telemetry field $key must be a single-line safe label" \
      "Record only stable ids, counts, source references, or sanitized labels." \
      "failure_reason=AGENT_EXITED"
  fi
}

for key in event_type timestamp change_id gate_id risk_tier result block_code source_ref true_catch false_positive manual_override duplicate_signal replacement_protection reviewer skill_id trigger_reason outcome failure_reason review_type high_risk_count medium_risk_count decision role model_tier turn_count retry_count failure_count review_value agent_id agent_role dispatch_stage permission verification_id verification_runner pass_count fail_count skip_count dry_run confirmation_item cycle_reason eval_id scenario_id trial_id suite_id suite_total suite_passed suite_failed business_golden_total business_golden_matched business_golden_promoted replay_fixture_total replay_fixture_matched pass_power_k; do
  value="$(eval "printf '%s' \"\${$key}\"")"
  check_single_line "$key" "$value"
done

require_field() {
  local key="$1"
  local value
  value="$(eval "printf '%s' \"\${$key}\"")"
  [[ -n "$value" ]] || fail "TELEMETRY/MISSING_REQUIRED_FIELD" "missing required field: $key" "Add the required field for $event_type." "$key"
}

case "$event_type" in
  gate_run)
    require_field change_id
    require_field gate_id
    require_field risk_tier
    require_field result
    require_field source_ref
    ;;
  gate_effectiveness_review)
    require_field gate_id
    require_field true_catch
    require_field false_positive
    require_field manual_override
    require_field duplicate_signal
    require_field replacement_protection
    require_field reviewer
    require_field source_ref
    ;;
  skill_route_event)
    require_field change_id
    require_field skill_id
    require_field trigger_reason
    require_field outcome
    require_field source_ref
    ;;
  reviewer_event)
    require_field change_id
    require_field review_type
    require_field high_risk_count
    require_field medium_risk_count
    require_field decision
    require_field source_ref
    ;;
  model_route_event)
    require_field change_id
    require_field role
    require_field model_tier
    require_field turn_count
    require_field retry_count
    require_field failure_count
    require_field review_value
    require_field source_ref
    ;;
  agent_dispatch_event)
    require_field change_id
    require_field agent_id
    require_field agent_role
    require_field dispatch_stage
    require_field permission
    require_field result
    require_field source_ref
    ;;
  verification_run_event)
    require_field change_id
    require_field verification_runner
    require_field result
    require_field pass_count
    require_field fail_count
    require_field skip_count
    require_field dry_run
    require_field source_ref
    ;;
  human_confirmation_event)
    require_field change_id
    require_field confirmation_item
    require_field decision
    require_field source_ref
    ;;
  rework_cycle_event)
    require_field change_id
    require_field cycle_reason
    require_field outcome
    require_field source_ref
    ;;
  eval_trial_event)
    require_field change_id
    require_field eval_id
    require_field scenario_id
    require_field trial_id
    require_field result
    require_field source_ref
    ;;
  eval_suite_event)
    require_field change_id
    require_field suite_id
    require_field result
    require_field decision
    require_field suite_total
    require_field suite_passed
    require_field suite_failed
    require_field source_ref
    ;;
esac

if [[ "$event_type" == "eval_trial_event" && -n "$failure_reason" ]]; then
  if [[ ${#failure_reason} -gt 80 || ! "$failure_reason" =~ ^[A-Za-z0-9_.:/-]+$ ]]; then
    fail \
      "TELEMETRY/UNSAFE_FAILURE_REASON" \
      "eval_trial_event failure_reason must be a short safe label" \
      "Use a stable code, not raw prompt, transcript, command output, or prose." \
      "failure_reason=AGENT_EXITED"
  fi
fi

if [[ -z "$timestamp" ]]; then
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
fi

check_sensitive() {
  local key="$1" value="$2"
  [[ -z "$value" ]] && return 0
  if printf '%s' "$value" | LC_ALL=C grep -Eiq '(password|passwd|pwd[[:space:]]*=|token[[:space:]]*=|cookie|authorization|access[_-]?token|refresh[_-]?token|db[_-]?password|secret[[:space:]]*=|private[_-]?key|BEGIN[[:space:]]+(RSA|OPENSSH|PRIVATE)|select[[:space:]].*from[[:space:]])'; then
    fail \
      "TELEMETRY/SENSITIVE_VALUE" \
      "telemetry field $key appears to contain sensitive or raw data" \
      "Record only stable ids, counts, source references, or sanitized labels." \
      "source_ref=changes/<change-id>/evidence.md"
  fi
}

for key in event_type timestamp change_id gate_id risk_tier result block_code source_ref true_catch false_positive manual_override duplicate_signal replacement_protection reviewer skill_id trigger_reason outcome failure_reason review_type high_risk_count medium_risk_count decision role model_tier turn_count retry_count failure_count review_value agent_id agent_role dispatch_stage permission verification_id verification_runner pass_count fail_count skip_count dry_run confirmation_item cycle_reason eval_id scenario_id trial_id suite_id suite_total suite_passed suite_failed business_golden_total business_golden_matched business_golden_promoted replay_fixture_total replay_fixture_matched pass_power_k; do
  value="$(eval "printf '%s' \"\${$key}\"")"
  check_sensitive "$key" "$value"
done

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

json_line="{\"event_type\":\"$(json_escape "$event_type")\",\"timestamp\":\"$(json_escape "$timestamp")\""
append_json_field() {
  local key="$1" value="$2"
  if [[ -n "$value" ]]; then
    json_line="$json_line,\"$key\":\"$(json_escape "$value")\""
  fi
}

append_json_field change_id "$change_id"
append_json_field gate_id "$gate_id"
append_json_field risk_tier "$risk_tier"
append_json_field result "$result"
append_json_field block_code "$block_code"
append_json_field source_ref "$source_ref"
append_json_field true_catch "$true_catch"
append_json_field false_positive "$false_positive"
append_json_field manual_override "$manual_override"
append_json_field duplicate_signal "$duplicate_signal"
append_json_field replacement_protection "$replacement_protection"
append_json_field reviewer "$reviewer"
append_json_field skill_id "$skill_id"
append_json_field trigger_reason "$trigger_reason"
append_json_field outcome "$outcome"
append_json_field failure_reason "$failure_reason"
append_json_field review_type "$review_type"
append_json_field high_risk_count "$high_risk_count"
append_json_field medium_risk_count "$medium_risk_count"
append_json_field decision "$decision"
append_json_field role "$role"
append_json_field model_tier "$model_tier"
append_json_field turn_count "$turn_count"
append_json_field retry_count "$retry_count"
append_json_field failure_count "$failure_count"
append_json_field review_value "$review_value"
append_json_field agent_id "$agent_id"
append_json_field agent_role "$agent_role"
append_json_field dispatch_stage "$dispatch_stage"
append_json_field permission "$permission"
append_json_field verification_id "$verification_id"
append_json_field verification_runner "$verification_runner"
append_json_field pass_count "$pass_count"
append_json_field fail_count "$fail_count"
append_json_field skip_count "$skip_count"
append_json_field dry_run "$dry_run"
append_json_field confirmation_item "$confirmation_item"
append_json_field cycle_reason "$cycle_reason"
append_json_field eval_id "$eval_id"
append_json_field scenario_id "$scenario_id"
append_json_field trial_id "$trial_id"
append_json_field suite_id "$suite_id"
append_json_field suite_total "$suite_total"
append_json_field suite_passed "$suite_passed"
append_json_field suite_failed "$suite_failed"
append_json_field business_golden_total "$business_golden_total"
append_json_field business_golden_matched "$business_golden_matched"
append_json_field business_golden_promoted "$business_golden_promoted"
append_json_field replay_fixture_total "$replay_fixture_total"
append_json_field replay_fixture_matched "$replay_fixture_matched"
append_json_field pass_power_k "$pass_power_k"
json_line="$json_line}"

umask 077
mkdir -p "$telemetry_dir"
printf '%s\n' "$json_line" >>"$telemetry_dir/events.jsonl"
printf 'PASS: telemetry event recorded type=%s path=%s\n' "$event_type" "$telemetry_dir/events.jsonl"
