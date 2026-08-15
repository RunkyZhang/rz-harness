#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/agent-task-brief.sh <plan-file> <task-number> <change-id> [outfile]

Extracts one markdown task section into the agent handoff workspace.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }
[[ "$#" -ge 3 && "$#" -le 4 ]] || { usage; exit 2; }

plan_file="$1"
task_number="$2"
change_id="$3"
[[ -f "$plan_file" ]] || fail "plan file not found: $plan_file"
[[ "$task_number" =~ ^[0-9]+$ ]] || fail "task-number must be numeric: $task_number"

plan_dir="$(cd "$(dirname "$plan_file")" && pwd -P)"
repo_root="$(git -C "$plan_dir" rev-parse --show-toplevel 2>/dev/null)" \
  || fail "plan file is not inside a git repository: $plan_file"

if [[ "$#" -eq 4 ]]; then
  out="$4"
else
  workspace="$("$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/agent-workspace.sh" "$repo_root" "$change_id")"
  out="$workspace/task-${task_number}-brief.md"
fi

extract_tmp="$(mktemp "${TMPDIR:-/tmp}/agent-task-brief.XXXXXX")"
trap 'rm -f "$extract_tmp"' EXIT

awk -v n="$task_number" '
  /^```/ { infence = !infence }
  !infence && /^#+[[:space:]]+Task[[:space:]]+[0-9]+/ {
    intask = ($0 ~ ("^#+[[:space:]]+Task[[:space:]]+" n "([^0-9]|$)"))
  }
  intask { print }
' "$plan_file" >"$extract_tmp"

[[ -s "$extract_tmp" ]] || fail "task $task_number not found in $plan_file"

{
  printf '# Agent Task Brief\n\n'
  printf 'change_id: %s\n' "$change_id"
  printf 'task_number: %s\n' "$task_number"
  printf 'source_plan: %s\n' "$plan_file"
  printf 'source_repo: %s\n' "$repo_root"
  printf '\n## Extracted Task\n\n'
  cat "$extract_tmp"
} >"$out"

printf 'wrote %s\n' "$out"
