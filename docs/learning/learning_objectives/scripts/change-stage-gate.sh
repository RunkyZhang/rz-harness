#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/change-stage-gate.sh <change-id|change-dir> <stage> [changed-file...]

Stages:
  intake              spec confidence only
  solution-confirm    confirmed technical solution
  code-start          solution + AI test plan + confidence + path/assumption gates
  pre-commit          confidence + path/assumption + verification/UI gates
  pre-push            pre-commit + required evidence/status artifacts
  pre-test-release    environment + Test Agent + AI test report
  pre-pr              reviewer gate
  closeout            pre-test-release + pre-pr

If changed files are omitted for file-aware stages, this script reads:
  <change-dir>/changed-files.txt
USAGE
}

fail() {
  local code="$1"
  local message="$2"
  local fix="$3"
  local sample="$4"
  export SFA_CHANGE_STAGE_BLOCK_CODE="$code"
  printf 'FAIL: %s\n' "$message" >&2
  printf 'CODE: %s\n' "$code" >&2
  printf 'FIX: %s\n' "$fix" >&2
  printf 'SAMPLE: %s\n' "$sample" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

record_stage_telemetry() {
  local result="$1"
  local block_code="${2:-}"
  local change_id source_ref telemetry_output
  local -a telemetry_args
  [[ -n "${stage:-}" && -n "${change_dir:-}" ]] || return 0
  [[ -x "$root/scripts/harness-telemetry-record.sh" ]] || return 0

  change_id="$(basename "$change_dir")"
  if [[ -f "$change_dir/evidence.md" ]]; then
    source_ref="$change_dir/evidence.md"
  else
    source_ref="$change_dir"
  fi

  telemetry_args=(
    --event-type gate_run
    --change-id "$change_id"
    --gate-id "change-stage:$stage"
    --risk-tier L3
    --result "$result"
    --source-ref "$source_ref"
  )
  if [[ -n "$block_code" ]]; then
    telemetry_args+=(--block-code "$block_code")
  fi
  if [[ -n "${SFA_HARNESS_TELEMETRY_DIR:-}" ]]; then
    telemetry_args=(--telemetry-dir "$SFA_HARNESS_TELEMETRY_DIR" "${telemetry_args[@]}")
  fi

  if ! telemetry_output="$("$root/scripts/harness-telemetry-record.sh" "${telemetry_args[@]}" 2>&1)"; then
    printf 'WARN: change-stage telemetry record failed: %s\n' "$(printf '%s' "$telemetry_output" | tr '\n' ' ' | cut -c1-300)" >&2
  fi
}

on_exit() {
  local status="$?"
  if [[ "${SFA_CHANGE_STAGE_TELEMETRY_RECORDED:-0}" != "1" ]]; then
    SFA_CHANGE_STAGE_TELEMETRY_RECORDED=1
    if [[ "$status" -eq 0 ]]; then
      record_stage_telemetry PASS ""
    else
      record_stage_telemetry BLOCK "${SFA_CHANGE_STAGE_BLOCK_CODE:-EXIT_$status}"
    fi
  fi
  exit "$status"
}

trap on_exit EXIT

if [[ -f config/repos.local.sh ]]; then
  # shellcheck disable=SC1091
  source config/repos.local.sh
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

change_arg="${1:-}"
stage="${2:-}"
[[ -n "$change_arg" ]] || fail \
  "CHANGE_STAGE/MISSING_CHANGE" \
  "missing change id or change dir" \
  "Pass changes/<change-id> or a change id under changes/." \
  "scripts/change-stage-gate.sh changes/example code-start"
[[ -n "$stage" ]] || fail \
  "CHANGE_STAGE/MISSING_STAGE" \
  "missing stage" \
  "Pass a supported stage such as code-start, pre-commit, or pre-test-release." \
  "scripts/change-stage-gate.sh changes/example code-start"
shift 2 || true

if [[ -d "$change_arg" ]]; then
  change_dir="${change_arg%/}"
elif [[ -d "changes/$change_arg" ]]; then
  change_dir="changes/$change_arg"
else
  fail \
    "CHANGE_STAGE/CHANGE_NOT_FOUND" \
    "change dir not found: $change_arg" \
    "Create the change under changes/<change-id> before running stage gates." \
    "changes/add-distribution-qr-abnormal-tag-filter"
fi

spec_file="$change_dir/spec.md"

require_file() {
  local file="$1"
  local label="$2"
  [[ -f "$file" ]] || fail \
    "CHANGE_STAGE/MISSING_ARTIFACT" \
    "missing required artifact: $file" \
    "Create and fill $label before entering stage '$stage'." \
    "$file"
}

changed_files=("$@")
load_changed_files() {
  if [[ "${#changed_files[@]}" -gt 0 ]]; then
    return
  fi
  local changed_list="$change_dir/changed-files.txt"
  [[ -f "$changed_list" ]] || fail \
    "CHANGE_STAGE/MISSING_CHANGED_FILES" \
    "stage '$stage' needs changed files, but none were supplied" \
    "Pass changed files as arguments or create $changed_list with one path per line." \
    "scripts/change-stage-gate.sh $change_dir $stage /abs/path/to/file.vue"
  mapfile -t changed_files < <(grep -vE '^[[:space:]]*($|#)' "$changed_list")
  [[ "${#changed_files[@]}" -gt 0 ]] || fail \
    "CHANGE_STAGE/EMPTY_CHANGED_FILES" \
    "$changed_list has no changed file entries" \
    "Add at least one concrete changed file path." \
    "$changed_list"
}

run_confidence_gate() {
  require_file "$spec_file" "spec.md"
  scripts/confidence-gate.sh "$spec_file"
}

run_file_guards() {
  require_file "$spec_file" "spec.md"
  load_changed_files
  scripts/allowed-paths.sh "$spec_file" "${changed_files[@]}"
  scripts/assumption-leak-gate.sh "$spec_file" "${changed_files[@]}"
}

agent_dispatch_plan="$change_dir/agent-dispatch-plan.md"

agent_plan_has() {
  local agent_id="$1"
  [[ -f "$agent_dispatch_plan" ]] && grep -q "^agent_id: $agent_id$" "$agent_dispatch_plan"
}

run_agent_dispatch_plan_gate_if_present() {
  if [[ -f "$agent_dispatch_plan" ]]; then
    scripts/agent-dispatch-plan-gate.sh "$change_dir"
  fi
}

run_intake() {
  run_confidence_gate
}

run_solution_confirm() {
  scripts/technical-solution-gate.sh "$change_dir"
}

run_code_start() {
  run_solution_confirm
  scripts/ai-test-plan-gate.sh "$change_dir"
  run_confidence_gate
  run_file_guards
}

run_pre_commit() {
  run_confidence_gate
  run_file_guards
  scripts/swagger-model-documentation-gate.sh "$change_dir" "${changed_files[@]}"
  scripts/verification-map-gate.sh "$change_dir"
  if [[ -f "$change_dir/ui-rule-checklist.md" ]]; then
    scripts/ui-rule-gate.sh "$change_dir"
  fi
}

run_pre_push() {
  run_pre_commit
  require_file "$change_dir/evidence.md" "evidence.md"
  require_file "$change_dir/harness-status.md" "harness-status.md"
}

run_pre_test_release() {
  scripts/environment-readiness-gate.sh "$change_dir"
  run_agent_dispatch_plan_gate_if_present
  if agent_plan_has "sfa-test-agent"; then
    scripts/agent-output-contract-gate.sh "$change_dir" sfa-test-agent
  else
    scripts/test-agent-verification-gate.sh "$change_dir"
  fi
  scripts/ai-test-report-gate.sh "$change_dir"
}

run_pre_pr() {
  run_agent_dispatch_plan_gate_if_present
  if agent_plan_has "sfa-harness-reviewer"; then
    scripts/agent-output-contract-gate.sh "$change_dir" sfa-harness-reviewer
  else
    scripts/reviewer-gate.sh "$change_dir"
  fi
}

case "$stage" in
  intake)
    run_intake
    ;;
  solution-confirm)
    run_solution_confirm
    ;;
  code-start)
    run_code_start
    ;;
  pre-commit)
    run_pre_commit
    ;;
  pre-push)
    run_pre_push
    ;;
  pre-test-release)
    run_pre_test_release
    ;;
  pre-pr)
    run_pre_pr
    ;;
  closeout)
    run_pre_test_release
    run_pre_pr
    scripts/retro-gate.sh "$change_dir"
    ;;
  *)
    fail \
      "CHANGE_STAGE/UNKNOWN_STAGE" \
      "unknown stage: $stage" \
      "Use one of: intake, solution-confirm, code-start, pre-commit, pre-push, pre-test-release, pre-pr, closeout." \
      "scripts/change-stage-gate.sh changes/example pre-commit"
    ;;
esac

printf 'PASS: change stage gate passed for %s at %s\n' "$stage" "$change_dir"
