#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-eval-suite.sh [--root <repo-root>] [--check <name:command> ...] [--record-telemetry] [--telemetry-dir <dir>]

Runs the harness eval suite and prints a compact summary. Default checks cover
replay fixtures, live sandbox tests, live Codex wrapper tests, business golden
evals, candidate intake, behavior eval reliability, telemetry, registry, and
hygiene. Telemetry recording is opt-in and writes one aggregate suite event.
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

script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
root="$script_root"
custom_checks=()
record_telemetry=0
telemetry_dir=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --root)
      root="${2:-}"
      [[ -n "$root" ]] || fail \
        "HARNESS_EVAL_SUITE/MISSING_ROOT" \
        "missing value for --root" \
        "Pass a repository root." \
        "scripts/harness-eval-suite.sh --root /path/to/repo"
      shift 2
      ;;
    --check)
      check_value="${2:-}"
      [[ -n "$check_value" ]] || fail \
        "HARNESS_EVAL_SUITE/MISSING_CHECK" \
        "missing value for --check" \
        "Pass a check as name:command." \
        "scripts/harness-eval-suite.sh --check smoke:scripts/smoke.sh"
      custom_checks+=("$check_value")
      shift 2
      ;;
    --record-telemetry)
      record_telemetry=1
      shift
      ;;
    --telemetry-dir)
      telemetry_dir="${2:-}"
      [[ -n "$telemetry_dir" ]] || fail \
        "HARNESS_EVAL_SUITE/MISSING_TELEMETRY_DIR" \
        "missing value for --telemetry-dir" \
        "Pass a directory for local ignored telemetry output." \
        "scripts/harness-eval-suite.sh --record-telemetry --telemetry-dir .harness/telemetry"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail \
        "HARNESS_EVAL_SUITE/UNKNOWN_ARG" \
        "unknown argument: $1" \
        "Use --root, --check, --record-telemetry, and --telemetry-dir." \
        "scripts/harness-eval-suite.sh"
      ;;
  esac
done

[[ -d "$root" ]] || fail \
  "HARNESS_EVAL_SUITE/ROOT_NOT_FOUND" \
  "root directory not found: $root" \
  "Pass an existing harness repository root." \
  "scripts/harness-eval-suite.sh --root /path/to/repo"

check_names=()
check_commands=()

add_check() {
  check_names+=("$1")
  check_commands+=("$2")
}

if [[ "${#custom_checks[@]}" -gt 0 ]]; then
  for check in "${custom_checks[@]}"; do
    if [[ "$check" != *:* ]]; then
      fail \
        "HARNESS_EVAL_SUITE/INVALID_CHECK" \
        "invalid check format: $check" \
        "Use name:command so suite output remains attributable." \
        "smoke:scripts/smoke.sh"
    fi
    add_check "${check%%:*}" "${check#*:}"
  done
else
  add_check replay "scripts/harness-replay-fixture-eval.sh"
  add_check live_sandbox "bash scripts/harness-live-sandbox-eval-test.sh"
  add_check live_codex "bash scripts/harness-live-codex-trial-test.sh"
  add_check business_golden "scripts/harness-business-golden-eval.sh"
  add_check business_candidate "scripts/harness-business-golden-candidate-gate.sh"
  add_check business_candidate_intake "bash scripts/harness-business-golden-candidate-intake-test.sh"
  add_check business_candidate_report "bash scripts/harness-business-golden-candidate-report-test.sh"
  add_check behavior "scripts/harness-behavior-eval.sh"
  add_check reliability "scripts/harness-behavior-reliability.sh --runs 3 --mode safety --eval-command 'scripts/harness-behavior-eval.sh'"
  add_check telemetry "bash scripts/harness-telemetry-test.sh"
  add_check registry "scripts/harness-control-audit.sh --check registry"
  add_check hygiene "scripts/no-personal-paths.sh docs/README.md docs/architecture/gate-registry.md docs/architecture/harness-telemetry.md docs/architecture/harness-replay-fixture-eval.md docs/architecture/harness-business-golden-eval.md docs/architecture/harness-eval-suite.md scripts/harness-telemetry-record.sh scripts/harness-telemetry-test.sh scripts/harness-weekly-audit-summary.sh scripts/harness-replay-fixture-eval.sh scripts/harness-replay-fixture-eval-test.sh scripts/harness-live-sandbox-eval.sh scripts/harness-live-sandbox-eval-test.sh scripts/harness-live-codex-trial.sh scripts/harness-live-codex-trial-test.sh scripts/harness-business-golden-eval.sh scripts/harness-business-golden-eval-test.sh scripts/harness-business-golden-candidate-gate.sh scripts/harness-business-golden-candidate-gate-test.sh scripts/harness-business-golden-candidate-intake.sh scripts/harness-business-golden-candidate-intake-test.sh scripts/harness-business-golden-candidate-report.sh scripts/harness-business-golden-candidate-report-test.sh scripts/harness-eval-suite.sh scripts/harness-eval-suite-test.sh scripts/harness-eval-weekly-run.sh scripts/harness-eval-weekly-run-test.sh scripts/harness-eval-trend-readiness.sh scripts/harness-eval-trend-readiness-test.sh scripts/test-fixtures evals/harness-behavior/replay evals/business-golden changes/harness-replay-eval-foundation"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

passed=0
failed=0

printf '# Harness Eval Suite\n'

for i in "${!check_names[@]}"; do
  name="${check_names[$i]}"
  command="${check_commands[$i]}"
  out="$tmpdir/$name.out"
  err="$tmpdir/$name.err"
  if (cd "$root" && bash -c "$command") >"$out" 2>"$err"; then
    passed=$((passed + 1))
    printf 'CHECK %s=PASS\n' "$name"
  else
    failed=$((failed + 1))
    printf 'CHECK %s=FAIL\n' "$name"
    printf '%s\n' "--- $name stdout ---" >&2
    sed -n '1,120p' "$out" >&2 || true
    printf '%s\n' "--- $name stderr ---" >&2
    sed -n '1,120p' "$err" >&2 || true
  fi
done

metric_value() {
  local key="$1"
  local value
  value="$(grep -h "^${key}=" "$tmpdir"/*.out 2>/dev/null | tail -n 1 || true)"
  if [[ -n "$value" ]]; then
    printf '%s' "${value#*=}"
  fi
}

print_metric() {
  local key="$1" value
  value="$(metric_value "$key")"
  if [[ -n "$value" ]]; then
    printf '%s=%s\n' "$key" "$value"
  fi
}

replay_fixture_total="$(metric_value REPLAY_FIXTURE_TOTAL)"
replay_fixture_matched="$(metric_value REPLAY_FIXTURE_MATCHED)"
business_golden_total="$(metric_value BUSINESS_GOLDEN_TOTAL)"
business_golden_matched="$(metric_value BUSINESS_GOLDEN_MATCHED)"
business_golden_promoted="$(metric_value BUSINESS_GOLDEN_PROMOTED)"
pass_power_k="$(metric_value PASS_POWER_K)"

record_eval_suite_event() {
  local event_result="$1" event_decision="$2"
  [[ "$record_telemetry" -eq 1 ]] || return 0

  local cmd=("$script_root/scripts/harness-telemetry-record.sh")
  if [[ -n "$telemetry_dir" ]]; then
    cmd+=(--telemetry-dir "$telemetry_dir")
  fi

  cmd+=(
    --event-type eval_suite_event
    --change-id harness-replay-eval-foundation
    --suite-id harness-eval-suite
    --result "$event_result"
    --decision "$event_decision"
    --suite-total "${#check_names[@]}"
    --suite-passed "$passed"
    --suite-failed "$failed"
    --source-ref changes/harness-replay-eval-foundation/evidence.md
  )

  [[ -n "$business_golden_total" ]] && cmd+=(--business-golden-total "$business_golden_total")
  [[ -n "$business_golden_matched" ]] && cmd+=(--business-golden-matched "$business_golden_matched")
  [[ -n "$business_golden_promoted" ]] && cmd+=(--business-golden-promoted "$business_golden_promoted")
  [[ -n "$replay_fixture_total" ]] && cmd+=(--replay-fixture-total "$replay_fixture_total")
  [[ -n "$replay_fixture_matched" ]] && cmd+=(--replay-fixture-matched "$replay_fixture_matched")
  [[ -n "$pass_power_k" ]] && cmd+=(--pass-power-k "$pass_power_k")

  "${cmd[@]}" >/dev/null
}

printf 'EVAL_TYPE=HARNESS_EVAL_SUITE\n'
printf 'EVAL_SUITE_TOTAL=%s\n' "${#check_names[@]}"
printf 'EVAL_SUITE_PASSED=%s\n' "$passed"
printf 'EVAL_SUITE_FAILED=%s\n' "$failed"

for key in \
  REPLAY_FIXTURE_TOTAL \
  REPLAY_FIXTURE_MATCHED \
  BUSINESS_GOLDEN_TOTAL \
  BUSINESS_GOLDEN_MATCHED \
  BUSINESS_GOLDEN_CANDIDATE_TOTAL \
  BUSINESS_GOLDEN_PROMOTED \
  BEHAVIOR_EVAL_TOTAL \
  BEHAVIOR_EVAL_PASSED \
  PASS_AT_K \
  PASS_POWER_K \
  REGISTRY_MISSING_GATES \
  REGISTRY_EXTRA_GATES; do
  print_metric "$key"
done

if [[ "$failed" -gt 0 ]]; then
  printf 'DECISION=FAIL_EVAL_SUITE\n'
  record_eval_suite_event FAIL FAIL_EVAL_SUITE
  fail \
    "HARNESS_EVAL_SUITE/CHECK_FAILED" \
    "one or more eval suite checks failed" \
    "Inspect the failed CHECK output, fix the underlying eval or artifact, then rerun the suite." \
    "CHECK replay=PASS"
fi

printf 'DECISION=PASS_EVAL_SUITE\n'
record_eval_suite_event PASS PASS_EVAL_SUITE
printf 'PASS: harness eval suite completed\n'
