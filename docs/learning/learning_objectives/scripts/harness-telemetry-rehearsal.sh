#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-telemetry-rehearsal.sh [--telemetry-dir <dir>] [--changes <n>] [--week <YYYY-WW>]

Generates labeled rehearsal telemetry into an ignored scratch directory and
runs readiness plus weekly summary end-to-end. Rehearsal telemetry is excluded
from normal readiness unless that command is called with --include-rehearsal.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  printf 'CODE: %s\n' "$2" >&2
  printf 'FIX: %s\n' "$3" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
telemetry_dir="$root/.harness/telemetry/rehearsal"
changes=5
week="$(date -u '+%Y-W%V')"

positive_int() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --telemetry-dir)
      telemetry_dir="${2:-}"
      [[ -n "$telemetry_dir" ]] || fail "missing value for --telemetry-dir" "REHEARSAL/MISSING_VALUE" "Pass a directory path."
      shift 2
      ;;
    --changes)
      changes="${2:-}"
      positive_int "$changes" || fail "invalid --changes: $changes" "REHEARSAL/INVALID_CHANGES" "Pass a positive integer."
      shift 2
      ;;
    --week)
      week="${2:-}"
      [[ -n "$week" ]] || fail "missing value for --week" "REHEARSAL/MISSING_VALUE" "Pass a week label."
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1" "REHEARSAL/UNKNOWN_ARG" "Use --telemetry-dir, --changes, or --week."
      ;;
  esac
done

rm -rf "$telemetry_dir"
mkdir -p "$telemetry_dir"

record_event() {
  "$root/scripts/harness-telemetry-record.sh" --telemetry-dir "$telemetry_dir" "$@" >/dev/null
}

for ((index = 1; index <= changes; index += 1)); do
  change_id="rehearsal-change-$index"
  day="$(printf '%02d' "$index")"
  timestamp="2026-06-${day}T00:00:00Z"
  source_ref="changes/$change_id/evidence.md"
  role="orchestrator"
  model_tier="standard"
  review_value="medium"
  if (( index % 2 == 0 )); then
    role="reviewer"
    model_tier="frontier"
    review_value="high"
  fi

  record_event \
    --event-type skill_route_event \
    --change-id "$change_id" \
    --skill-id lark-doc \
    --trigger-reason rehearsal-feishu-doc-update \
    --outcome USED \
    --source-ref "$source_ref" \
    --timestamp "$timestamp"

  record_event \
    --event-type model_route_event \
    --change-id "$change_id" \
    --role "$role" \
    --model-tier "$model_tier" \
    --turn-count "$((6 + index))" \
    --retry-count "$((index % 2))" \
    --failure-count 0 \
    --review-value "$review_value" \
    --source-ref "$source_ref" \
    --timestamp "$timestamp"

  record_event \
    --event-type gate_run \
    --change-id "$change_id" \
    --gate-id technical-solution-gate \
    --risk-tier L3 \
    --result PASS \
    --source-ref "$source_ref" \
    --timestamp "$timestamp"

  record_event \
    --event-type reviewer_event \
    --change-id "$change_id" \
    --review-type final \
    --high-risk-count 0 \
    --medium-risk-count 0 \
    --decision PASS \
    --source-ref "$source_ref" \
    --timestamp "$timestamp"
done

readiness_file="$telemetry_dir/readiness.md"
summary_file="$telemetry_dir/weekly-summary.md"
"$root/scripts/harness-telemetry-readiness.sh" --telemetry-dir "$telemetry_dir" --include-rehearsal >"$readiness_file"
"$root/scripts/harness-weekly-audit-summary.sh" --telemetry-dir "$telemetry_dir" --week "$week" --include-rehearsal >"$summary_file"

cat <<EOF
# Harness Telemetry Rehearsal
SIMULATION_SCOPE=REHEARSAL_ONLY
TELEMETRY_DIR=$telemetry_dir
EVENTS_FILE=$telemetry_dir/events.jsonl
READINESS_FILE=$readiness_file
SUMMARY_FILE=$summary_file
CHANGES=$changes
EOF

cat "$readiness_file"

cat <<'EOF'
NOTE=Rehearsal telemetry is only for end-to-end validation before real usage. It is excluded from normal readiness unless --include-rehearsal is explicitly passed.
EOF
