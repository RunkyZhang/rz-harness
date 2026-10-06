#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/parallel-worktree-gate.sh <backend-worktree> <frontend-worktree>

Checks:
  - both paths exist and are git worktree roots
  - backend and frontend implementation paths are distinct
  - implementation worktrees are not nested inside the control plane
  - implementation worktrees are not the default business repo main worktrees

Default main worktrees:
  ${SFA_REPO_BACKEND_SALES_MANAGEMENT:-$HOME/codex/sfa-projects/sfa-sales-management}
  ${SFA_REPO_FRONTEND_MAP_SYSTEM:-$HOME/codex/sfa-projects/mapSystem}
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

config_file="${SFA_HARNESS_CONFIG:-}"
if [[ -z "$config_file" ]]; then
  candidate="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/config/repos.local.sh"
  [[ -f "$candidate" ]] && config_file="$candidate"
fi

if [[ -n "$config_file" ]]; then
  # shellcheck source=/dev/null
  source "$config_file"
fi

backend_path="${1:-}"
frontend_path="${2:-}"

[[ -n "$backend_path" ]] || fail "missing backend worktree path"
[[ -n "$frontend_path" ]] || fail "missing frontend worktree path"
[[ -d "$backend_path" ]] || fail "backend worktree path not found: $backend_path"
[[ -d "$frontend_path" ]] || fail "frontend worktree path not found: $frontend_path"

control_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
backend_root="$(git -C "$backend_path" rev-parse --show-toplevel 2>/dev/null || true)"
frontend_root="$(git -C "$frontend_path" rev-parse --show-toplevel 2>/dev/null || true)"

[[ -n "$backend_root" ]] || fail "backend path is not a git worktree: $backend_path"
[[ -n "$frontend_root" ]] || fail "frontend path is not a git worktree: $frontend_path"

backend_root="$(cd "$backend_root" && pwd -P)"
frontend_root="$(cd "$frontend_root" && pwd -P)"

[[ "$backend_root" != "$frontend_root" ]] || fail "backend and frontend worktrees must be distinct"

case "$backend_root" in
  "$control_root"|"$control_root"/*) fail "backend worktree must not be inside control plane: $backend_root" ;;
esac
case "$frontend_root" in
  "$control_root"|"$control_root"/*) fail "frontend worktree must not be inside control plane: $frontend_root" ;;
esac

default_backend="${SFA_REPO_BACKEND_SALES_MANAGEMENT:-$HOME/codex/sfa-projects/sfa-sales-management}"
default_frontend="${SFA_REPO_FRONTEND_MAP_SYSTEM:-$HOME/codex/sfa-projects/mapSystem}"

[[ "$backend_root" != "$default_backend" ]] || fail "backend Agent must use an isolated worktree, not the main repo: $backend_root"
[[ "$frontend_root" != "$default_frontend" ]] || fail "frontend Agent must use an isolated worktree, not the main repo: $frontend_root"

printf 'PASS: parallel worktree gate passed\n'
printf 'backend_worktree=%s\n' "$backend_root"
printf 'frontend_worktree=%s\n' "$frontend_root"
