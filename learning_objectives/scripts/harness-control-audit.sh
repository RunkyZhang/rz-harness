#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-control-audit.sh [--check registry]

Runs a no-fail control-plane health audit for the SFA harness. The default mode
prints warnings and improvement items but exits 0 so it cannot block normal
workflows.
USAGE
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
check="all"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --check)
      check="${2:-}"
      [[ -n "$check" ]] || {
        printf 'FAIL: missing value for --check\n' >&2
        exit 1
      }
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'FAIL: unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [[ "$check" != "all" && "$check" != "registry" ]]; then
  printf 'FAIL: unsupported check: %s\n' "$check" >&2
  exit 1
fi

registry="$root/docs/architecture/gate-registry.md"

collect_gate_scripts() {
  find "$root/scripts" -maxdepth 1 -type f -name '*-gate.sh' ! -name '*-gate-test.sh' \
    -exec basename {} \; | sort
}

collect_registry_gates() {
  [[ -f "$registry" ]] || return 0
  awk -F'|' '
    $2 ~ /`[^`]+-gate\.sh`/ {
      value=$2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/`/, "", value)
      print value
    }
  ' "$registry" | sort -u
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

scripts_list="$tmpdir/scripts"
registry_list="$tmpdir/registry"
missing_list="$tmpdir/missing"
extra_list="$tmpdir/extra"

collect_gate_scripts >"$scripts_list"
collect_registry_gates >"$registry_list"

comm -23 "$scripts_list" "$registry_list" >"$missing_list"
comm -13 "$scripts_list" "$registry_list" >"$extra_list"

script_count="$(wc -l <"$scripts_list" | tr -d ' ')"
registry_count="$(wc -l <"$registry_list" | tr -d ' ')"
missing_count="$(wc -l <"$missing_list" | tr -d ' ')"
extra_count="$(wc -l <"$extra_list" | tr -d ' ')"

score=10
status="PASS"
if [[ "$missing_count" -gt 0 || "$extra_count" -gt 0 ]]; then
  status="WARN"
  score=$((10 - missing_count - extra_count))
  if [[ "$score" -lt 0 ]]; then
    score=0
  fi
fi

printf '# Harness Control Audit\n'
printf 'MODE=%s\n' "$check"
printf 'CATEGORY registry_coverage score=%s/10 status=%s scripts=%s registry=%s missing=%s extra=%s\n' \
  "$score" "$status" "$script_count" "$registry_count" "$missing_count" "$extra_count"
printf 'REGISTRY_SCRIPT_GATES=%s\n' "$script_count"
printf 'REGISTRY_REGISTERED_GATES=%s\n' "$registry_count"
printf 'REGISTRY_MISSING_GATES=%s\n' "$missing_count"
if [[ "$missing_count" -gt 0 ]]; then
  sed 's/^/ - /' "$missing_list"
fi
printf 'REGISTRY_EXTRA_GATES=%s\n' "$extra_count"
if [[ "$extra_count" -gt 0 ]]; then
  sed 's/^/ - /' "$extra_list"
fi

printf 'TOP_ACTIONS:\n'
if [[ "$missing_count" -gt 0 ]]; then
  printf ' - Add missing scripts to docs/architecture/gate-registry.md before using registry data for retirement decisions.\n'
elif [[ "$extra_count" -gt 0 ]]; then
  printf ' - Remove or mark stale registry rows that no longer have matching scripts.\n'
else
  printf ' - Registry coverage is current; next useful step is recording effectiveness data.\n'
fi

printf 'PASS: harness control audit completed with status=%s\n' "$status"
