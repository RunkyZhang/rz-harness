#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/contract-delta-gate.sh <changed-file> [changed-file...]

Checks:
  - If docs/contracts/<change-id>-api.md changed, then changes/<change-id>/contract-delta.md must also be changed.
  - Prints a frontend notification line for the orchestrator to forward to Frontend Agent.
USAGE
}

fail() {
  local code="$1"
  local message="$2"
  local fix="$3"
  local sample="$4"
  printf 'FAIL: %s\n' "$message" >&2
  printf 'CODE: %s\n' "$code" >&2
  printf 'FIX: %s\n' "$fix" >&2
  printf 'SAMPLE: %s\n' "$sample" >&2
  exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

[[ "$#" -gt 0 ]] || fail \
  "CONTRACT_DELTA/MISSING_CHANGED_FILES" \
  "missing changed files" \
  "Pass the changed file list so contract edits can be paired with contract-delta.md." \
  "templates/contract-delta.md"

normalize_relative() {
  local path="$1"
  local root
  root="$(pwd)"
  if [[ "$path" = "$root/"* ]]; then
    printf '%s\n' "${path#"$root/"}"
  else
    printf '%s\n' "$path"
  fi
}

changed=()
for file in "$@"; do
  changed+=("$(normalize_relative "$file")")
done

contains_file() {
  local needle="$1"
  local file
  for file in "${changed[@]}"; do
    [[ "$file" == "$needle" ]] && return 0
  done
  return 1
}

checked=0
for file in "${changed[@]}"; do
  if [[ "$file" =~ ^docs/contracts/(.+)-api\.md$ ]]; then
    checked=1
    change_id="${BASH_REMATCH[1]}"
    delta_file="changes/${change_id}/contract-delta.md"
    if ! contains_file "$delta_file"; then
      fail \
        "CONTRACT_DELTA/MISSING_DELTA_FILE" \
        "contract changed but missing delta file: ${delta_file}" \
        "Create or update ${delta_file}, include the contract delta summary, and notify Frontend Agent before implementation continues." \
        "templates/contract-delta.md"
    fi
    printf 'NOTICE: contract changed for %s; notify Frontend Agent to read %s and %s\n' \
      "$change_id" "$file" "$delta_file"
  fi
done

if [[ "$checked" -eq 0 ]]; then
  printf 'PASS: no contract changes detected\n'
else
  printf 'PASS: contract delta gate passed\n'
fi
