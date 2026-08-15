#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/agent-workspace.sh <repo-or-worktree> <change-id>

Creates and prints a git-ignored, change-scoped workspace for agent handoff
files: task briefs, reports, review packages, and progress ledger.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }
[[ "$#" -eq 2 ]] || { usage; exit 2; }

repo="$1"
change_id="$2"
[[ -d "$repo" ]] || fail "repo/worktree not found: $repo"
[[ "$change_id" =~ ^[A-Za-z0-9._-]+$ ]] || fail "change-id contains unsupported characters: $change_id"

root="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)" \
  || fail "not inside a git repository: $repo"
workspace="$root/.harness/agent-work/$change_id"

mkdir -p "$root/.harness"
cat >"$root/.harness/.gitignore" <<'EOF'
active-change
agent-work/
EOF
printf '%s\n' "$change_id" >"$root/.harness/active-change"

mkdir -p "$workspace"
printf '*\n' >"$workspace/.gitignore"

ledger="$workspace/progress-ledger.md"
if [[ ! -f "$ledger" ]]; then
  cat >"$ledger" <<EOF
# Agent Progress Ledger: $change_id

| Task | Status | Owner | Task brief | Implementer report | Review package | Review verdict | Test / evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
EOF
fi

cd "$workspace" && pwd
