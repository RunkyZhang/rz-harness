#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/frontend-dev-server.sh <frontend-map-system|frontend-sign-up|repo-path> [port]

Starts a frontend dev server with the harness-approved local runtime hints.
For mapSystem, this script prefers the configured Node 14.21.3 binary because
Vue CLI 3 + node-sass@4.14.1 fails on modern Node runtimes.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$#" -gt 2 ]]; then
  usage
  fail "too many arguments"
fi

if [[ -f "$root/config/repos.local.sh" ]]; then
  # shellcheck disable=SC1091
  source "$root/config/repos.local.sh"
fi

target="${1:-}"
port="${2:-${SFA_FRONTEND_MAP_SYSTEM_DEV_PORT:-9527}}"
host="${SFA_FRONTEND_DEV_HOST:-0.0.0.0}"

[[ -n "$target" ]] || { usage; fail "missing frontend repo id or path"; }

case "$target" in
  frontend-map-system|mapSystem)
    repo="${SFA_REPO_FRONTEND_MAP_SYSTEM:-}"
    expected_node="${SFA_FRONTEND_NODE_VERSION:-14.21.3}"
    ;;
  frontend-sign-up|sign-up)
    repo="${SFA_REPO_FRONTEND_SIGN_UP:-}"
    expected_node="${SFA_FRONTEND_SIGN_UP_NODE_VERSION:-${SFA_FRONTEND_NODE_VERSION:-14.21.3}}"
    ;;
  *)
    repo="$target"
    expected_node="${SFA_FRONTEND_NODE_VERSION:-14.21.3}"
    ;;
esac

[[ -n "$repo" ]] || fail "repo path is empty; check config/repos.local.sh"
[[ -d "$repo" ]] || fail "repo path not found: $repo"
[[ -f "$repo/package.json" ]] || fail "package.json not found: $repo"

node_bin_dir="${SFA_FRONTEND_NODE_BIN_DIR:-}"
if [[ -z "$node_bin_dir" && -d "${NVM_DIR:-$HOME/.nvm}/versions/node/v$expected_node/bin" ]]; then
  node_bin_dir="${NVM_DIR:-$HOME/.nvm}/versions/node/v$expected_node/bin"
fi
if [[ -z "$node_bin_dir" && -d "$HOME/.nvm/versions/node/v$expected_node/bin" ]]; then
  node_bin_dir="$HOME/.nvm/versions/node/v$expected_node/bin"
fi

if [[ -n "$node_bin_dir" ]]; then
  [[ -x "$node_bin_dir/node" ]] || fail "configured Node bin dir has no executable node: $node_bin_dir"
  export PATH="$node_bin_dir:$PATH"
fi

actual_node="$(node -v 2>/dev/null | sed 's/^v//' || true)"
[[ -n "$actual_node" ]] || fail "node is not available; install Node $expected_node or set SFA_FRONTEND_NODE_BIN_DIR"

if [[ "$target" == "frontend-map-system" || "$target" == "mapSystem" || "$repo" == *"/mapSystem" ]]; then
  if [[ "$actual_node" != "$expected_node" ]]; then
    fail "mapSystem local dev expects Node $expected_node, current Node is $actual_node; set SFA_FRONTEND_NODE_BIN_DIR or install via nvm"
  fi
fi

if [[ ! -d "$repo/node_modules" ]]; then
  fail "node_modules missing in $repo; install dependencies before starting dev server"
fi

cd "$repo"
printf 'INFO: repo=%s\n' "$repo"
printf 'INFO: node=%s npm=%s\n' "$(node -v)" "$(npm -v)"
printf 'INFO: starting dev server on host=%s port=%s\n' "$host" "$port"
exec env BROWSER=none npm run dev -- --host "$host" --port "$port"
