#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
registry="$root/config/agent-registry.yml"
output_dir="$root/.harness/generated/codex-agents"
mode="dry-run"
allow_global="deny-global"

usage() {
  cat <<'USAGE'
Usage: scripts/codex-agent-generator.sh [--registry <path>] [--output-dir <path>] [--dry-run|--apply] [--allow-global]

Default mode is --dry-run. Writing under $HOME/.codex/agents requires --allow-global.
USAGE
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --registry)
      [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }
      registry="$2"
      shift 2
      ;;
    --output-dir)
      [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }
      output_dir="$2"
      shift 2
      ;;
    --dry-run)
      mode="dry-run"
      shift
      ;;
    --apply)
      mode="apply"
      shift
      ;;
    --allow-global)
      allow_global="allow-global"
      shift
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

node "$root/scripts/lib/agent-registry.mjs" generate "$root" "$registry" "$output_dir" "$mode" "$allow_global"
