#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-live-codex-trial.sh --scenario <id> [--runs N] [--mode safety|exploratory] [--codex-bin <path>]

Runs Codex CLI through the Live Sandbox Eval runner and scores repeated trials
with scripts/harness-behavior-reliability.sh.

Current scenarios:
  technical-solution-stop
  reviewer-readonly
  main-branch-business-edit-stop
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
scenario_id=""
runs=1
mode="safety"
codex_bin="codex"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --scenario)
      scenario_id="${2:-}"
      [[ -n "$scenario_id" ]] || fail \
        "HARNESS_LIVE_CODEX_TRIAL/MISSING_SCENARIO" \
        "missing value for --scenario" \
        "Pass a supported scenario id." \
        "scripts/harness-live-codex-trial.sh --scenario technical-solution-stop"
      shift 2
      ;;
    --runs)
      runs="${2:-}"
      [[ -n "$runs" ]] || fail \
        "HARNESS_LIVE_CODEX_TRIAL/MISSING_RUNS" \
        "missing value for --runs" \
        "Pass a positive integer." \
        "scripts/harness-live-codex-trial.sh --scenario technical-solution-stop --runs 3"
      shift 2
      ;;
    --mode)
      mode="${2:-}"
      [[ -n "$mode" ]] || fail \
        "HARNESS_LIVE_CODEX_TRIAL/MISSING_MODE" \
        "missing value for --mode" \
        "Use safety or exploratory." \
        "scripts/harness-live-codex-trial.sh --scenario technical-solution-stop --mode safety"
      shift 2
      ;;
    --codex-bin)
      codex_bin="${2:-}"
      [[ -n "$codex_bin" ]] || fail \
        "HARNESS_LIVE_CODEX_TRIAL/MISSING_CODEX" \
        "missing value for --codex-bin" \
        "Pass a Codex executable path or command name." \
        "--codex-bin codex"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail \
        "HARNESS_LIVE_CODEX_TRIAL/UNKNOWN_ARG" \
        "unknown argument: $1" \
        "Use --scenario, --runs, --mode, or --codex-bin." \
        "scripts/harness-live-codex-trial.sh --scenario technical-solution-stop"
      ;;
  esac
done

[[ -n "$scenario_id" ]] || fail \
  "HARNESS_LIVE_CODEX_TRIAL/MISSING_SCENARIO" \
  "missing required --scenario" \
  "Pass the scenario to run." \
  "--scenario technical-solution-stop"

case "$scenario_id" in
  technical-solution-stop|reviewer-readonly|main-branch-business-edit-stop) ;;
  *)
    fail \
      "HARNESS_LIVE_CODEX_TRIAL/UNKNOWN_SCENARIO" \
      "unsupported live Codex trial scenario: $scenario_id" \
      "Use a documented Live Sandbox Eval scenario." \
      "technical-solution-stop | reviewer-readonly | main-branch-business-edit-stop"
    ;;
esac

case "$mode" in
  safety|exploratory) ;;
  *)
    fail \
      "HARNESS_LIVE_CODEX_TRIAL/INVALID_MODE" \
      "mode must be safety or exploratory" \
      "Choose safety for stop-point rules." \
      "--mode safety"
    ;;
esac

if ! [[ "$runs" =~ ^[0-9]+$ ]] || [[ "$runs" -lt 1 ]]; then
  fail \
    "HARNESS_LIVE_CODEX_TRIAL/INVALID_RUNS" \
    "runs must be a positive integer" \
    "Use --runs with a value greater than zero." \
    "--runs 3"
fi

if [[ "$codex_bin" == */* ]]; then
  [[ -x "$codex_bin" ]] || fail \
    "HARNESS_LIVE_CODEX_TRIAL/MISSING_CODEX" \
    "Codex executable not found or not executable: $codex_bin" \
    "Install Codex CLI or pass a valid executable with --codex-bin." \
    "--codex-bin codex"
  resolved_codex_bin="$codex_bin"
else
  resolved_codex_bin="$(command -v "$codex_bin" || true)"
  [[ -n "$resolved_codex_bin" ]] || fail \
    "HARNESS_LIVE_CODEX_TRIAL/MISSING_CODEX" \
    "Codex executable not found on PATH: $codex_bin" \
    "Install Codex CLI or pass a valid executable with --codex-bin." \
    "--codex-bin /path/to/codex"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
shim="$tmpdir/codex-live-agent.sh"

cat >"$shim" <<'SHIM'
#!/usr/bin/env bash
set -euo pipefail

"${HARNESS_LIVE_CODEX_BIN:?}" exec \
  --ephemeral \
  --cd "${HARNESS_LIVE_SANDBOX_DIR:?}" \
  --sandbox workspace-write \
  --skip-git-repo-check \
  - <"${HARNESS_LIVE_PROMPT_FILE:?}"
SHIM
chmod +x "$shim"

export HARNESS_LIVE_CODEX_BIN="$resolved_codex_bin"

eval_command="$root/scripts/harness-live-sandbox-eval.sh --scenario $scenario_id --agent-command '$shim'"

printf 'EVAL_TYPE=LIVE_CODEX_TRIAL\n'
printf 'SCENARIO_ID=%s\n' "$scenario_id"
printf 'RUNS=%s\n' "$runs"
printf 'MODE=%s\n' "$mode"
printf 'CODEX_BIN=%s\n' "$(basename "$resolved_codex_bin")"

"$root/scripts/harness-behavior-reliability.sh" \
  --runs "$runs" \
  --mode "$mode" \
  --eval-command "$eval_command"
