#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-weekly-audit-summary.sh [--telemetry-dir <dir>] [--week <YYYY-WW>] [--include-rehearsal]

Reads local allowlisted telemetry JSONL and prints an aggregate-only Markdown
summary. It does not print source_ref, raw prompt, raw logs, or raw command
output. Files under a rehearsal/ directory are excluded by default.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  printf 'CODE: %s\n' "$2" >&2
  printf 'FIX: %s\n' "$3" >&2
  printf 'SAMPLE: %s\n' "$4" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
telemetry_dir="$root/.harness/telemetry"
week="$(date -u '+%Y-W%V')"
include_rehearsal=0

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --telemetry-dir)
      telemetry_dir="${2:-}"
      [[ -n "$telemetry_dir" ]] || fail "missing value for --telemetry-dir" "WEEKLY_AUDIT/MISSING_VALUE" "Pass a directory path." "--telemetry-dir .harness/telemetry"
      shift 2
      ;;
    --week)
      week="${2:-}"
      [[ -n "$week" ]] || fail "missing value for --week" "WEEKLY_AUDIT/MISSING_VALUE" "Pass a week label." "--week 2026-W26"
      shift 2
      ;;
    --include-rehearsal)
      include_rehearsal=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1" "WEEKLY_AUDIT/UNKNOWN_ARG" "Use --telemetry-dir, --week, or --include-rehearsal." "scripts/harness-weekly-audit-summary.sh --help"
      ;;
  esac
done

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
events="$tmpdir/events.jsonl"
: >"$events"

if [[ -d "$telemetry_dir" ]]; then
  find "$telemetry_dir" -type f -name '*.jsonl' -print | sort | while IFS= read -r file; do
    if [[ "$include_rehearsal" -ne 1 && "$file" == */rehearsal/* ]]; then
      continue
    fi
    cat "$file"
  done >"$events"
fi

total="$(wc -l <"$events" | tr -d ' ')"

extract_field() {
  local key="$1"
  sed -n "s/.*\"$key\":\"\\([^\"]*\\)\".*/\\1/p" "$events" | sed '/^$/d'
}

print_counts() {
  local title="$1" key="$2"
  printf '\n## %s\n\n' "$title"
  printf '| %s | count |\n' "$key"
  printf '| --- | --- |\n'
  if [[ "$total" -eq 0 ]]; then
    printf '| none | 0 |\n'
    return 0
  fi
  extract_field "$key" | sort | uniq -c | awk '{ count=$1; $1=""; sub(/^ /, ""); printf "| %s | %s |\n", $0, count }'
}

print_eval_suites() {
  printf '\n## Eval Suites\n\n'
  printf '| suite_id | runs | passed_runs | failed_runs | latest_decision |\n'
  printf '| --- | --- | --- | --- | --- |\n'
  if [[ "$total" -eq 0 ]] || ! grep -q '"event_type":"eval_suite_event"' "$events"; then
    printf '| none | 0 | 0 | 0 | none |\n'
    return 0
  fi

  awk '
    function field(line, key, parts, value_parts, count) {
      count = split(line, parts, "\"" key "\":\"")
      if (count < 2) {
        return ""
      }
      split(parts[2], value_parts, "\"")
      return value_parts[1]
    }
    /"event_type":"eval_suite_event"/ {
      suite = field($0, "suite_id")
      if (suite == "") {
        suite = "unknown"
      }
      result = field($0, "result")
      decision = field($0, "decision")
      runs[suite] += 1
      if (result == "PASS") {
        passed[suite] += 1
      } else if (result == "FAIL") {
        failed[suite] += 1
      }
      latest[suite] = decision
    }
    END {
      for (suite in runs) {
        printf "%s\t%s\t%s\t%s\t%s\n", suite, runs[suite], passed[suite] + 0, failed[suite] + 0, latest[suite]
      }
    }
  ' "$events" | sort | while IFS=$'\t' read -r suite runs passed_runs failed_runs latest_decision; do
    printf '| %s | %s | %s | %s | %s |\n' "$suite" "$runs" "$passed_runs" "$failed_runs" "$latest_decision"
  done
}

cat <<EOF
# Harness Weekly Audit Summary

| item | value |
| --- | --- |
| week | $week |
| telemetry_dir | local ignored scratch |
| total_events | $total |

EOF

print_counts "Event Types" event_type
print_counts "Results" result
print_counts "Outcomes" outcome
print_counts "Reviewer Decisions" decision
print_counts "Gate Runs" gate_id
print_counts "Skill Routes" skill_id
print_counts "Model Route Roles" role
print_counts "Model Route Tiers" model_tier
print_counts "Agent Dispatches" agent_id
print_counts "Dispatch Stages" dispatch_stage
print_counts "Verification Runners" verification_runner
print_counts "Confirmation Items" confirmation_item
print_counts "Rework Reasons" cycle_reason
print_counts "Eval IDs" eval_id
print_counts "Eval Scenarios" scenario_id
print_eval_suites

cat <<'EOF'

## Notes

- This summary is aggregate-only.
- Raw telemetry remains local and ignored under `.harness/telemetry/`.
- Do not paste raw prompts, command output, credentials, cookies, customer data, or DB query results into this summary.
EOF
