#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
registry="${1:-"$root/config/agent-registry.yml"}"

node "$root/scripts/lib/agent-registry.mjs" gate "$root" "$registry"
