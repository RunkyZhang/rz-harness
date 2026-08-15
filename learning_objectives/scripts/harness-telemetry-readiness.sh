#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-telemetry-readiness.sh [--telemetry-dir <dir>] [--min-changes <n>] [--min-weeks <n>] [--min-model-events <n>] [--include-rehearsal]

Reads sanitized local telemetry JSONL and reports whether enough data exists
to review skill-usage migration or model-routing controls. This script never
changes gates, hooks, model routing, or memory.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  printf 'CODE: %s\n' "$2" >&2
  printf 'FIX: %s\n' "$3" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
telemetry_dir="$root/.harness/telemetry"
min_changes=5
min_weeks=4
min_model_events=5
include_rehearsal=0

positive_int() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --telemetry-dir)
      telemetry_dir="${2:-}"
      [[ -n "$telemetry_dir" ]] || fail "missing value for --telemetry-dir" "READINESS/MISSING_VALUE" "Pass a directory path."
      shift 2
      ;;
    --min-changes)
      min_changes="${2:-}"
      positive_int "$min_changes" || fail "invalid --min-changes: $min_changes" "READINESS/INVALID_THRESHOLD" "Pass a positive integer."
      shift 2
      ;;
    --min-weeks)
      min_weeks="${2:-}"
      positive_int "$min_weeks" || fail "invalid --min-weeks: $min_weeks" "READINESS/INVALID_THRESHOLD" "Pass a positive integer."
      shift 2
      ;;
    --min-model-events)
      min_model_events="${2:-}"
      positive_int "$min_model_events" || fail "invalid --min-model-events: $min_model_events" "READINESS/INVALID_THRESHOLD" "Pass a positive integer."
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
      fail "unknown argument: $1" "READINESS/UNKNOWN_ARG" "Use --telemetry-dir, --min-changes, --min-weeks, --min-model-events, or --include-rehearsal."
      ;;
  esac
done

command -v node >/dev/null 2>&1 || fail "node is required for readiness analysis" "READINESS/NODE_MISSING" "Install Node.js or use the workspace bundled runtime."

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

node - "$events" "$min_changes" "$min_weeks" "$min_model_events" <<'NODE'
const fs = require('fs');

const file = process.argv[2];
const minChanges = Number(process.argv[3]);
const minWeeks = Number(process.argv[4]);
const minModelEvents = Number(process.argv[5]);
const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/).filter((line) => line.trim().length > 0);

const usefulChangeIds = new Set();
const skillChangeIds = new Set();
const skillWeeks = new Set();
const allWeeks = new Set();
const modelRoles = new Set();
const counts = {
  total: 0,
  skillRoute: 0,
  modelRoute: 0,
  gateRun: 0,
  reviewer: 0,
};

function isoWeek(timestamp) {
  if (!timestamp) return '';
  const date = new Date(timestamp);
  if (Number.isNaN(date.getTime())) return '';
  const utc = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = utc.getUTCDay() || 7;
  utc.setUTCDate(utc.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(utc.getUTCFullYear(), 0, 1));
  const week = Math.ceil((((utc - yearStart) / 86400000) + 1) / 7);
  return `${utc.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
}

for (let i = 0; i < lines.length; i += 1) {
  let row;
  try {
    row = JSON.parse(lines[i]);
  } catch (error) {
    console.error(`FAIL: invalid JSON at line ${i + 1}: ${error.message}`);
    console.error('CODE: READINESS/INVALID_JSON');
    console.error('FIX: Keep telemetry as one JSON object per line.');
    process.exit(1);
  }
  counts.total += 1;
  if (row.change_id) usefulChangeIds.add(String(row.change_id));
  const week = isoWeek(row.timestamp);
  if (week) allWeeks.add(week);

  switch (row.event_type) {
    case 'skill_route_event':
      counts.skillRoute += 1;
      if (row.change_id) skillChangeIds.add(String(row.change_id));
      if (week) skillWeeks.add(week);
      break;
    case 'model_route_event':
      counts.modelRoute += 1;
      if (row.role) modelRoles.add(String(row.role));
      break;
    case 'gate_run':
      counts.gateRun += 1;
      break;
    case 'reviewer_event':
      counts.reviewer += 1;
      break;
    default:
      break;
  }
}

const skillReady = skillChangeIds.size >= minChanges || skillWeeks.size >= minWeeks;
const modelReady = counts.modelRoute >= minModelEvents && modelRoles.size >= 2;
const decision = skillReady && modelReady ? 'READY_FOR_REVIEW' : 'WAIT_DATA_WINDOW';

console.log('# Harness Telemetry Readiness');
console.log(`TOTAL_EVENTS=${counts.total}`);
console.log(`DISTINCT_CHANGES=${usefulChangeIds.size}`);
console.log(`DISTINCT_WEEKS=${allWeeks.size}`);
console.log(`SKILL_ROUTE_EVENTS=${counts.skillRoute}`);
console.log(`SKILL_ROUTE_DISTINCT_CHANGES=${skillChangeIds.size}`);
console.log(`SKILL_ROUTE_DISTINCT_WEEKS=${skillWeeks.size}`);
console.log(`MODEL_ROUTE_EVENTS=${counts.modelRoute}`);
console.log(`MODEL_ROUTE_DISTINCT_ROLES=${modelRoles.size}`);
console.log(`GATE_RUN_EVENTS=${counts.gateRun}`);
console.log(`REVIEWER_EVENTS=${counts.reviewer}`);
console.log(`MIN_CHANGES=${minChanges}`);
console.log(`MIN_WEEKS=${minWeeks}`);
console.log(`MIN_MODEL_EVENTS=${minModelEvents}`);
console.log(`SKILL_USAGE_MIGRATION_READY=${skillReady ? 1 : 0}`);
console.log(`MODEL_ROUTING_READY=${modelReady ? 1 : 0}`);
console.log(`DECISION=${decision}`);
console.log('NOTE=Readiness is permission to write a review proposal, not permission to migrate gates or route models.');
NODE
