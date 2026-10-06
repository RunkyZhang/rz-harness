#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/verification-run.sh [--dry-run] [--report <path>] <change-dir>

Runs executable rows from changes/<change-id>/verification-map.md and writes a
verification-run-report.md. The verification map must already pass
scripts/verification-map-gate.sh.

Supported Verification cell formats:
  shell: <command>   run from the harness repo root
  manual: <criteria> require Status=PASS
  N/A                skip when Status=N/A
USAGE
}

fail() {
  local code="$1" message="$2" fix="$3"
  printf 'FAIL: %s\n' "$message" >&2
  printf 'CODE: %s\n' "$code" >&2
  printf 'FIX: %s\n' "$fix" >&2
  exit 1
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

strip_wrapping_backticks() {
  local value="$1"
  value="$(trim "$value")"
  if [[ "$value" == \`*\` && "$value" == *\` ]]; then
    value="${value#\`}"
    value="${value%\`}"
  fi
  printf '%s' "$value"
}

md_cell() {
  local value="$1"
  value="${value//$'\n'/ }"
  value="${value//$'\r'/ }"
  value="${value//|/\\|}"
  printf '%s' "$value"
}

dry_run=0
report_path=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    --report)
      [[ -n "${2:-}" ]] || fail \
        "VERIFICATION_RUN/MISSING_REPORT_PATH" \
        "missing value for --report" \
        "Pass --report <path> or omit it to use changes/<change-id>/verification-run-report.md."
      report_path="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      fail \
        "VERIFICATION_RUN/UNKNOWN_OPTION" \
        "unknown option: $1" \
        "Use scripts/verification-run.sh [--dry-run] [--report <path>] <change-dir>."
      ;;
    *)
      break
      ;;
  esac
done

change_dir="${1:-}"
[[ -n "$change_dir" ]] || fail \
  "VERIFICATION_RUN/MISSING_CHANGE_DIR" \
  "missing change dir" \
  "Pass changes/<change-id>."
[[ -d "$change_dir" ]] || fail \
  "VERIFICATION_RUN/MISSING_CHANGE_DIR" \
  "change dir not found: $change_dir" \
  "Pass an existing changes/<change-id> directory."

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
change_dir_abs="$(cd "$change_dir" && pwd -P)"
map_file="$change_dir_abs/verification-map.md"
[[ -f "$map_file" ]] || fail \
  "VERIFICATION_RUN/MISSING_MAP" \
  "verification map file not found: $map_file" \
  "Create verification-map.md and run scripts/verification-map-gate.sh first."

"$root/scripts/verification-map-gate.sh" "$change_dir_abs" >/dev/null

if [[ -z "$report_path" ]]; then
  report_path="$change_dir_abs/verification-run-report.md"
fi
report_dir="$(dirname "$report_path")"
mkdir -p "$report_dir"
tmp_report="$(mktemp "${TMPDIR:-/tmp}/sfa-verification-run.XXXXXX")"
tmp_out="$(mktemp "${TMPDIR:-/tmp}/sfa-verification-run-out.XXXXXX")"
trap 'rm -f "$tmp_report" "$tmp_out"' EXIT

change_id="$(basename "$change_dir_abs")"
{
  printf '# Verification Run Report: %s\n\n' "$change_id"
  printf '```yaml\n'
  printf 'change_id: %s\n' "$change_id"
  printf 'dry_run: %s\n' "$dry_run"
  printf 'map_file: %s\n' "$map_file"
  printf '```\n\n'
  printf '| ID | Runner | Result | Actual | Evidence |\n'
  printf '| --- | --- | --- | --- | --- |\n'
} >"$tmp_report"

failure_count=0
pass_count=0
skip_count=0
dry_run_count=0
first_code=""
first_message=""
first_fix=""
row_count=0

while IFS=$'\t' read -r row_id _constraint _source verification evidence status; do
  row_count=$((row_count + 1))
  verification="$(strip_wrapping_backticks "$verification")"
  evidence="$(strip_wrapping_backticks "$evidence")"
  status="$(strip_wrapping_backticks "$status")"

  runner="unsupported"
  result="FAIL"
  actual="unsupported Verification runner"

  if [[ "$status" == "N/A" || "$verification" == "N/A" || "$verification" == N/A:* ]]; then
    runner="N/A"
    result="SKIP"
    actual="explicit N/A row"
  elif [[ "$verification" == manual:* ]]; then
    runner="manual"
    if [[ "$status" == "PASS" ]]; then
      result="PASS"
      actual="recorded manual evidence"
    else
      actual="manual row status=${status:-missing}"
      failure_count=$((failure_count + 1))
      if [[ -z "$first_code" ]]; then
        first_code="VERIFICATION_RUN/MANUAL_PENDING"
        first_message="manual verification row is not PASS: $row_id"
        first_fix="Complete the manual verification evidence, set Status to PASS, or mark the row N/A with a reason."
      fi
    fi
  elif [[ "$verification" == shell:* ]]; then
    runner="shell"
    command="$(trim "${verification#shell:}")"
    if [[ -z "$command" ]]; then
      actual="empty shell command"
      failure_count=$((failure_count + 1))
      if [[ -z "$first_code" ]]; then
        first_code="VERIFICATION_RUN/EMPTY_COMMAND"
        first_message="shell verification row has an empty command: $row_id"
        first_fix="Write shell: <command> in the Verification column."
      fi
    elif [[ "$dry_run" -eq 1 ]]; then
      result="DRY_RUN"
      actual="not executed"
    else
      set +e
      (
        cd "$root"
        HARNESS_CHANGE_DIR="$change_dir_abs" \
        HARNESS_VERIFICATION_ID="$row_id" \
        HARNESS_VERIFICATION_REPORT="$report_path" \
        bash -lc "$command"
      ) >"$tmp_out" 2>&1
      exit_code=$?
      set -e
      actual="exit=$exit_code"
      if [[ "$exit_code" -eq 0 ]]; then
        result="PASS"
      else
        result="FAIL"
        failure_count=$((failure_count + 1))
        if [[ -z "$first_code" ]]; then
          first_code="VERIFICATION_RUN/SHELL_FAILED"
          first_message="shell verification row failed: $row_id"
          first_fix="Fix the implementation or verification command, then rerun scripts/verification-run.sh $change_dir_abs."
        fi
      fi
    fi
  else
    failure_count=$((failure_count + 1))
    if [[ -z "$first_code" ]]; then
      first_code="VERIFICATION_RUN/UNSUPPORTED_RUNNER"
      first_message="planned verification row has no supported runner: $row_id"
      first_fix="Prefix executable rows with 'shell:' or manual rows with 'manual:'. Keep N/A rows explicit."
    fi
  fi

  printf '| %s | %s | %s | %s | %s |\n' \
    "$(md_cell "$row_id")" \
    "$(md_cell "$runner")" \
    "$(md_cell "$result")" \
    "$(md_cell "$actual")" \
    "$(md_cell "$evidence")" >>"$tmp_report"

  case "$result" in
    PASS) pass_count=$((pass_count + 1)) ;;
    SKIP) skip_count=$((skip_count + 1)) ;;
    DRY_RUN) dry_run_count=$((dry_run_count + 1)) ;;
  esac
done < <(
  awk -F'|' '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }
    /^\|[[:space:]]*VM-[0-9]+/ {
      printf "%s\t%s\t%s\t%s\t%s\t%s\n", trim($2), trim($3), trim($4), trim($5), trim($6), trim($7)
    }
  ' "$map_file"
)

run_status="PASS"
if [[ "$failure_count" -gt 0 ]]; then
  run_status="FAIL"
elif [[ "$dry_run_count" -gt 0 ]]; then
  run_status="DRY_RUN"
fi

{
  printf '\n## Summary\n\n'
  printf '```yaml\n'
  printf 'run_status: %s\n' "$run_status"
  printf 'pass_count: %s\n' "$pass_count"
  printf 'fail_count: %s\n' "$failure_count"
  printf 'skip_count: %s\n' "$skip_count"
  printf 'dry_run_count: %s\n' "$dry_run_count"
  printf '```\n'
} >>"$tmp_report"

mv "$tmp_report" "$report_path"
tmp_report=""

record_telemetry() {
  local telemetry_args=()
  local telemetry_err="$tmp_out.telemetry"
  if [[ -n "${SFA_HARNESS_TELEMETRY_DIR:-}" ]]; then
    telemetry_args=(--telemetry-dir "$SFA_HARNESS_TELEMETRY_DIR")
  fi
  local failure_arg=()
  if [[ -n "${first_code:-}" ]]; then
    failure_arg=(--failure-reason "$first_code")
  fi
  set +u
  if "$root/scripts/harness-telemetry-record.sh" \
    "${telemetry_args[@]}" \
    --event-type verification_run_event \
    --change-id "$change_id" \
    --verification-id all \
    --verification-runner mixed \
    --result "$run_status" \
    --pass-count "$pass_count" \
    --fail-count "$failure_count" \
    --skip-count "$skip_count" \
    --dry-run "$([[ "$dry_run" -eq 1 ]] && printf true || printf false)" \
    "${failure_arg[@]}" \
    --source-ref "$report_path" >/dev/null 2>"$telemetry_err"; then
    set -u
    return 0
  fi
  set -u
  printf 'WARN: verification telemetry was not recorded\n' >&2
  sed -n '1,4p' "$telemetry_err" >&2 || true
  rm -f "$telemetry_err"
}

if [[ "$row_count" -eq 0 ]]; then
  fail \
    "VERIFICATION_RUN/EMPTY_MAP" \
    "verification map has no runnable rows" \
    "Add at least one VM-* row and run scripts/verification-map-gate.sh first."
fi

record_telemetry

if [[ "$failure_count" -gt 0 ]]; then
  fail \
    "${first_code:-VERIFICATION_RUN/FAILED}" \
    "${first_message:-verification run failed}" \
    "${first_fix:-Review verification-run-report.md and fix failed rows.}"
fi

printf 'PASS: verification run completed for %s; report=%s; rows=%s\n' "$change_dir_abs" "$report_path" "$row_count"
