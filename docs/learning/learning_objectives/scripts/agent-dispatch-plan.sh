#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
registry="$root/config/agent-registry.yml"
runtime=""
stage=""
agent_id=""
allow_candidate="deny-candidate"
candidate_confirmation=""
change_id=""
output=""

usage() {
  cat <<'USAGE'
Usage:
  scripts/agent-dispatch-plan.sh [--registry <path>] [--runtime <target>] [--stage <stage>] [--agent-id <id>] [--allow-candidate] [--candidate-confirmation <path>] [--change-id <id>] [--output <path>]

Produces a registry-derived agent dispatch plan. It does not execute agents.
Candidate implementation agents require --allow-candidate and --candidate-confirmation.
USAGE
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --registry)
      [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }
      registry="$2"
      shift 2
      ;;
    --runtime)
      [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }
      runtime="$2"
      shift 2
      ;;
    --stage)
      [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }
      stage="$2"
      shift 2
      ;;
    --agent-id)
      [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }
      agent_id="$2"
      shift 2
      ;;
    --allow-candidate)
      allow_candidate="allow-candidate"
      shift
      ;;
    --candidate-confirmation)
      [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }
      candidate_confirmation="$2"
      shift 2
      ;;
    --change-id)
      [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }
      change_id="$2"
      shift 2
      ;;
    --output)
      [[ "$#" -ge 2 ]] || { usage >&2; exit 2; }
      output="$2"
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

node "$root/scripts/lib/agent-registry.mjs" dispatch "$root" "$registry" "$runtime" "$stage" "$agent_id" "$allow_candidate" "$change_id" "$output" "$candidate_confirmation"
