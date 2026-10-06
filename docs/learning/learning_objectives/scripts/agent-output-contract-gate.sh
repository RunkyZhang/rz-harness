#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
registry="$root/config/agent-registry.yml"

usage() {
  cat <<'USAGE'
Usage:
  scripts/agent-output-contract-gate.sh [--registry <path>] <change-dir> <agent-id>

Checks that the selected registry agent produced its declared artifacts and
that contract-specific gates pass. This script validates outputs; it does not
execute agents.
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
agent_id="${2:-}"

[[ -n "$change_dir" && -n "$agent_id" ]] || { usage >&2; exit 2; }

node "$root/scripts/lib/agent-registry.mjs" output-gate "$root" "$registry" "$change_dir" "$agent_id"
