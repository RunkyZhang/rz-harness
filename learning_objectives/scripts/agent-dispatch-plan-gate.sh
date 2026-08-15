#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
registry="$root/config/agent-registry.yml"

usage() {
  cat <<'USAGE'
Usage:
  scripts/agent-dispatch-plan-gate.sh [--registry <path>] <change-dir>

Checks changes/<change-id>/agent-dispatch-plan.md against config/agent-registry.yml.
Candidate implementation agents require candidate_dispatch: explicit_opt_in.
USAGE
}

while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --registry)
      [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }
      registry="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'FAIL: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

change_dir="${1:-}"
[[ -n "$change_dir" ]] || { usage >&2; exit 2; }

node "$root/scripts/lib/agent-registry.mjs" dispatch-gate "$root" "$registry" "$change_dir"
