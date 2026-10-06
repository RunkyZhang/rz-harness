#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-behavior-eval.sh [--root <repo-root>]

Validates the minimum SFA harness behavior-eval scenario pack. This first
implementation is deterministic and file-based; it does not run a live agent.
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

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --root)
      root="${2:-}"
      [[ -n "$root" ]] || fail \
        "HARNESS_BEHAVIOR_EVAL/MISSING_ROOT" \
        "missing value for --root" \
        "Pass a repository root that contains evals/harness-behavior." \
        "scripts/harness-behavior-eval.sh --root /path/to/repo"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail \
        "HARNESS_BEHAVIOR_EVAL/UNKNOWN_ARG" \
        "unknown argument: $1" \
        "Use --root only when validating a fixture copy." \
        "scripts/harness-behavior-eval.sh"
      ;;
  esac
done

eval_dir="$root/evals/harness-behavior"
scenarios_dir="$eval_dir/scenarios"
expected_dir="$eval_dir/expected"

[[ -d "$scenarios_dir" ]] || fail \
  "HARNESS_BEHAVIOR_EVAL/MISSING_SCENARIOS_DIR" \
  "missing behavior scenarios directory: $scenarios_dir" \
  "Create evals/harness-behavior/scenarios with the required scenario files." \
  "evals/harness-behavior/scenarios/technical-solution-stop.md"

[[ -d "$expected_dir" ]] || fail \
  "HARNESS_BEHAVIOR_EVAL/MISSING_EXPECTED_DIR" \
  "missing behavior expected directory: $expected_dir" \
  "Create evals/harness-behavior/expected with the required expectation files." \
  "evals/harness-behavior/expected/technical-solution-stop.yaml"

required=(
  technical-solution-stop
  confidence-assumption-stop
  reviewer-readonly
  main-branch-business-edit-stop
  skill-routing-evidence
)

passed=0
for id in "${required[@]}"; do
  scenario="$scenarios_dir/$id.md"
  expected="$expected_dir/$id.yaml"

  [[ -f "$scenario" ]] || fail \
    "HARNESS_BEHAVIOR_EVAL/MISSING_SCENARIO" \
    "missing behavior scenario: $scenario" \
    "Add the scenario prompt and acceptance notes." \
    "evals/harness-behavior/scenarios/$id.md"

  [[ -f "$expected" ]] || fail \
    "HARNESS_BEHAVIOR_EVAL/MISSING_EXPECTED" \
    "missing behavior expected file: $expected" \
    "Add the expected behavior contract for this scenario." \
    "evals/harness-behavior/expected/$id.yaml"

  grep -q "^id: $id$" "$expected" || fail \
    "HARNESS_BEHAVIOR_EVAL/EXPECTED_ID_MISMATCH" \
    "expected file does not declare id: $id" \
    "Set the expected YAML id to match the scenario filename." \
    "id: $id"

  grep -q '^must:' "$expected" || fail \
    "HARNESS_BEHAVIOR_EVAL/MISSING_MUST" \
    "expected file missing must section: $expected" \
    "Add at least one required behavior statement." \
    "must:"

  grep -q '^must_not:' "$expected" || fail \
    "HARNESS_BEHAVIOR_EVAL/MISSING_MUST_NOT" \
    "expected file missing must_not section: $expected" \
    "Add at least one prohibited behavior statement." \
    "must_not:"

  printf 'PASS: behavior eval scenario %s\n' "$id"
  passed=$((passed + 1))
done

printf 'EVAL_TYPE=STATIC\n'
printf 'LIVE_AGENT_TRACE_SUPPORTED=0\n'
printf 'BEHAVIOR_EVAL_TOTAL=%s\n' "${#required[@]}"
printf 'BEHAVIOR_EVAL_PASSED=%s\n' "$passed"
printf 'PASS: harness behavior eval completed\n'
