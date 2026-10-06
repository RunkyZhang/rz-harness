#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-behavior-reliability.sh [--runs N] [--mode safety|exploratory] [--eval-command CMD]

Runs a behavior eval command repeatedly and reports both pass@k and pass^k.
Default command: scripts/harness-behavior-eval.sh
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
runs=3
mode="safety"
eval_command="scripts/harness-behavior-eval.sh"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --runs)
      runs="${2:-}"
      [[ -n "$runs" ]] || fail \
        "HARNESS_BEHAVIOR_RELIABILITY/MISSING_RUNS" \
        "missing value for --runs" \
        "Pass a positive integer." \
        "scripts/harness-behavior-reliability.sh --runs 3"
      shift 2
      ;;
    --mode)
      mode="${2:-}"
      [[ -n "$mode" ]] || fail \
        "HARNESS_BEHAVIOR_RELIABILITY/MISSING_MODE" \
        "missing value for --mode" \
        "Use safety or exploratory." \
        "scripts/harness-behavior-reliability.sh --mode safety"
      shift 2
      ;;
    --eval-command)
      eval_command="${2:-}"
      [[ -n "$eval_command" ]] || fail \
        "HARNESS_BEHAVIOR_RELIABILITY/MISSING_EVAL_COMMAND" \
        "missing value for --eval-command" \
        "Pass a shell command that exits 0 on eval pass." \
        "scripts/harness-behavior-reliability.sh --eval-command 'scripts/harness-behavior-eval.sh'"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail \
        "HARNESS_BEHAVIOR_RELIABILITY/UNKNOWN_ARG" \
        "unknown argument: $1" \
        "Use --runs, --mode, and --eval-command." \
        "scripts/harness-behavior-reliability.sh --runs 3 --mode safety"
      ;;
  esac
done

if ! [[ "$runs" =~ ^[0-9]+$ ]] || [[ "$runs" -lt 1 ]]; then
  fail \
    "HARNESS_BEHAVIOR_RELIABILITY/INVALID_RUNS" \
    "runs must be a positive integer" \
    "Use --runs with a value greater than zero." \
    "scripts/harness-behavior-reliability.sh --runs 3"
fi

case "$mode" in
  safety|exploratory)
    ;;
  *)
    fail \
      "HARNESS_BEHAVIOR_RELIABILITY/INVALID_MODE" \
      "mode must be safety or exploratory" \
      "Choose safety for high-risk rules and exploratory for candidate generation." \
      "scripts/harness-behavior-reliability.sh --mode safety"
    ;;
esac

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

successes=0
failures=0

printf '# Harness Behavior Reliability\n'
printf 'MODE=%s\n' "$mode"
printf 'EVAL_COMMAND=%s\n' "$eval_command"

for ((i = 1; i <= runs; i++)); do
  run_out="$tmpdir/run-$i.out"
  run_err="$tmpdir/run-$i.err"
  if (cd "$root" && bash -c "$eval_command") >"$run_out" 2>"$run_err"; then
    successes=$((successes + 1))
    printf 'RUN_%s=PASS\n' "$i"
  else
    failures=$((failures + 1))
    printf 'RUN_%s=FAIL\n' "$i"
  fi
done

pass_at_k=0
pass_power_k=0
if [[ "$successes" -gt 0 ]]; then
  pass_at_k=1
fi
if [[ "$successes" -eq "$runs" ]]; then
  pass_power_k=1
fi

printf 'HARNESS_BEHAVIOR_RELIABILITY_RUNS=%s\n' "$runs"
printf 'HARNESS_BEHAVIOR_RELIABILITY_SUCCESSES=%s\n' "$successes"
printf 'HARNESS_BEHAVIOR_RELIABILITY_FAILURES=%s\n' "$failures"
printf 'PASS_AT_K=%s\n' "$pass_at_k"
printf 'PASS_POWER_K=%s\n' "$pass_power_k"

if [[ "$pass_at_k" -eq 0 ]]; then
  printf 'DECISION=FAIL_NO_PASSING_RUNS\n'
  fail \
    "HARNESS_BEHAVIOR_RELIABILITY/NO_PASSING_RUNS" \
    "no behavior eval run passed" \
    "Fix the eval command or scenario pack before using reliability results." \
    "PASS_AT_K=0"
fi

if [[ "$mode" == "safety" ]]; then
  if [[ "$pass_power_k" -eq 1 ]]; then
    printf 'DECISION=PASS_SAFETY_STABLE\n'
    printf 'PASS: harness behavior reliability completed\n'
    exit 0
  fi
  printf 'DECISION=FAIL_SAFETY_NOT_STABLE\n'
  fail \
    "HARNESS_BEHAVIOR_RELIABILITY/SAFETY_NOT_STABLE" \
    "safety mode requires all runs to pass" \
    "Investigate flaky behavior or lower the claim to exploratory evidence." \
    "PASS_POWER_K=0"
fi

if [[ "$pass_power_k" -eq 1 ]]; then
  printf 'DECISION=PASS_EXPLORATORY_STABLE\n'
else
  printf 'DECISION=PASS_EXPLORATORY_UNSTABLE\n'
fi
printf 'PASS: harness behavior reliability completed\n'
