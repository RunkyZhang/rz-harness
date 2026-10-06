#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-eval-trend-readiness.sh [--telemetry-dir <dir>] [--suite-id <id>] [--min-runs <n>] [--min-weeks <n>] [--max-failed-runs <n>] [--min-business-golden-total <n>] [--min-replay-fixture-total <n>] [--min-pass-power-k <n>] [--include-rehearsal]

Reads local eval suite telemetry and reports whether the trend window is stable
enough to write a CI trial or gate-adjustment review proposal. It does not
change CI, gates, hooks, model routing, or business repositories.
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
suite_id="harness-eval-suite"
min_runs=4
min_weeks=4
max_failed_runs=0
min_business_golden_total=6
min_replay_fixture_total=8
min_pass_power_k=1
include_rehearsal=0

non_negative_int() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

positive_int() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --telemetry-dir)
      telemetry_dir="${2:-}"
      [[ -n "$telemetry_dir" ]] || fail "missing value for --telemetry-dir" "EVAL_TREND/MISSING_VALUE" "Pass a directory path."
      shift 2
      ;;
    --suite-id)
      suite_id="${2:-}"
      [[ -n "$suite_id" ]] || fail "missing value for --suite-id" "EVAL_TREND/MISSING_VALUE" "Pass a suite id."
      shift 2
      ;;
    --min-runs)
      min_runs="${2:-}"
      positive_int "$min_runs" || fail "invalid --min-runs: $min_runs" "EVAL_TREND/INVALID_THRESHOLD" "Pass a positive integer."
      shift 2
      ;;
    --min-weeks)
      min_weeks="${2:-}"
      positive_int "$min_weeks" || fail "invalid --min-weeks: $min_weeks" "EVAL_TREND/INVALID_THRESHOLD" "Pass a positive integer."
      shift 2
      ;;
    --max-failed-runs)
      max_failed_runs="${2:-}"
      non_negative_int "$max_failed_runs" || fail "invalid --max-failed-runs: $max_failed_runs" "EVAL_TREND/INVALID_THRESHOLD" "Pass a non-negative integer."
      shift 2
      ;;
    --min-business-golden-total)
      min_business_golden_total="${2:-}"
      positive_int "$min_business_golden_total" || fail "invalid --min-business-golden-total: $min_business_golden_total" "EVAL_TREND/INVALID_THRESHOLD" "Pass a positive integer."
      shift 2
      ;;
    --min-replay-fixture-total)
      min_replay_fixture_total="${2:-}"
      positive_int "$min_replay_fixture_total" || fail "invalid --min-replay-fixture-total: $min_replay_fixture_total" "EVAL_TREND/INVALID_THRESHOLD" "Pass a positive integer."
      shift 2
      ;;
    --min-pass-power-k)
      min_pass_power_k="${2:-}"
      positive_int "$min_pass_power_k" || fail "invalid --min-pass-power-k: $min_pass_power_k" "EVAL_TREND/INVALID_THRESHOLD" "Pass a positive integer."
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
      fail "unknown argument: $1" "EVAL_TREND/UNKNOWN_ARG" "Use documented threshold flags only."
      ;;
  esac
done

command -v node >/dev/null 2>&1 || fail "node is required for trend readiness analysis" "EVAL_TREND/NODE_MISSING" "Install Node.js or use the workspace bundled runtime."

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

node - "$events" "$suite_id" "$min_runs" "$min_weeks" "$max_failed_runs" "$min_business_golden_total" "$min_replay_fixture_total" "$min_pass_power_k" <<'NODE'
const fs = require('fs');

const file = process.argv[2];
const targetSuiteId = process.argv[3];
const minRuns = Number(process.argv[4]);
const minWeeks = Number(process.argv[5]);
const maxFailedRuns = Number(process.argv[6]);
const minBusinessGoldenTotal = Number(process.argv[7]);
const minReplayFixtureTotal = Number(process.argv[8]);
const minPassPowerK = Number(process.argv[9]);
const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/).filter((line) => line.trim().length > 0);

const weeks = new Set();
let totalRuns = 0;
let passedRuns = 0;
let failedRuns = 0;
let latest = null;

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

function numeric(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

for (let i = 0; i < lines.length; i += 1) {
  let row;
  try {
    row = JSON.parse(lines[i]);
  } catch (error) {
    console.error(`FAIL: invalid JSON at line ${i + 1}: ${error.message}`);
    console.error('CODE: EVAL_TREND/INVALID_JSON');
    console.error('FIX: Keep telemetry as one JSON object per line.');
    process.exit(1);
  }

  if (row.event_type !== 'eval_suite_event' || row.suite_id !== targetSuiteId) {
    continue;
  }

  totalRuns += 1;
  if (row.result === 'PASS') {
    passedRuns += 1;
  } else if (row.result === 'FAIL') {
    failedRuns += 1;
  }

  const week = isoWeek(row.timestamp);
  if (week) weeks.add(week);

  if (!latest || String(row.timestamp || '') >= String(latest.timestamp || '')) {
    latest = row;
  }
}

const latestDecision = latest?.decision || 'none';
const latestBusinessGoldenTotal = numeric(latest?.business_golden_total);
const latestReplayFixtureTotal = numeric(latest?.replay_fixture_total);
const latestPassPowerK = numeric(latest?.pass_power_k);
const stableWindow = totalRuns >= minRuns && weeks.size >= minWeeks && failedRuns <= maxFailedRuns && latestDecision === 'PASS_EVAL_SUITE';
const baselineReady = latestBusinessGoldenTotal >= minBusinessGoldenTotal && latestReplayFixtureTotal >= minReplayFixtureTotal && latestPassPowerK >= minPassPowerK;
const ciTrialReady = stableWindow && baselineReady;
const gateAdjustmentReviewReady = ciTrialReady;
const decision = gateAdjustmentReviewReady ? 'READY_FOR_EVAL_ADOPTION_REVIEW' : 'WAIT_EVAL_TREND';

console.log('# Harness Eval Trend Readiness');
console.log(`SUITE_ID=${targetSuiteId}`);
console.log(`TOTAL_SUITE_RUNS=${totalRuns}`);
console.log(`DISTINCT_SUITE_WEEKS=${weeks.size}`);
console.log(`PASSED_SUITE_RUNS=${passedRuns}`);
console.log(`FAILED_SUITE_RUNS=${failedRuns}`);
console.log(`LATEST_DECISION=${latestDecision}`);
console.log(`LATEST_BUSINESS_GOLDEN_TOTAL=${latestBusinessGoldenTotal}`);
console.log(`LATEST_REPLAY_FIXTURE_TOTAL=${latestReplayFixtureTotal}`);
console.log(`LATEST_PASS_POWER_K=${latestPassPowerK}`);
console.log(`MIN_RUNS=${minRuns}`);
console.log(`MIN_WEEKS=${minWeeks}`);
console.log(`MAX_FAILED_RUNS=${maxFailedRuns}`);
console.log(`MIN_BUSINESS_GOLDEN_TOTAL=${minBusinessGoldenTotal}`);
console.log(`MIN_REPLAY_FIXTURE_TOTAL=${minReplayFixtureTotal}`);
console.log(`MIN_PASS_POWER_K=${minPassPowerK}`);
console.log(`CI_TRIAL_READY=${ciTrialReady ? 1 : 0}`);
console.log(`GATE_ADJUSTMENT_REVIEW_READY=${gateAdjustmentReviewReady ? 1 : 0}`);
console.log(`DECISION=${decision}`);
console.log('NOTE=Readiness allows writing an adoption review proposal only; it does not change CI, gates, hooks, models, or business repositories.');
NODE
