#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/business-dirty-worktree-gate.sh <repo> [--ledger <dirty-worktree-ledger.md>]

Fails when a business repo has dirty files unless every dirty path is recorded
in a ledger with an owner and decision. This protects user work from being
silently overwritten.
USAGE
}

fail() {
  local code="$1" message="$2" fix="$3" sample="$4"
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

repo="${1:-}"
[[ -n "$repo" ]] || fail \
  "DIRTY_WORKTREE/MISSING_REPO" \
  "missing repo path" \
  "Pass the business repository path." \
  "scripts/business-dirty-worktree-gate.sh /path/to/repo --ledger changes/<id>/dirty-worktree-ledger.md"
shift || true

ledger=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --ledger)
      ledger="${2:-}"
      shift 2
      ;;
    *)
      fail "DIRTY_WORKTREE/UNKNOWN_ARG" "unknown argument: $1" "Use --ledger <file> or remove the argument." "--ledger changes/<id>/dirty-worktree-ledger.md"
      ;;
  esac
done

[[ -d "$repo" ]] || fail \
  "DIRTY_WORKTREE/REPO_NOT_FOUND" \
  "repo not found: $repo" \
  "Pass an existing business repository path." \
  "/path/to/repo"
git -C "$repo" rev-parse --show-toplevel >/dev/null 2>&1 || fail \
  "DIRTY_WORKTREE/NOT_GIT_REPO" \
  "not a git repository: $repo" \
  "Run this gate against the business repo root." \
  "git -C <repo> status --short"

dirty_lines=()
while IFS= read -r line; do
  dirty_lines+=("$line")
done < <(git -C "$repo" status --porcelain)
if [[ "${#dirty_lines[@]}" -eq 0 ]]; then
  printf 'PASS: dirty worktree gate passed for %s (clean)\n' "$repo"
  exit 0
fi

[[ -n "$ledger" ]] || fail \
  "DIRTY_WORKTREE/UNOWNED_CHANGES" \
  "repo has dirty files but no ownership ledger: $repo" \
  "Record each dirty path as user-owned, codex-owned, or retained before editing." \
  "templates/dirty-worktree-ledger.md"
[[ -f "$ledger" ]] || fail \
  "DIRTY_WORKTREE/LEDGER_NOT_FOUND" \
  "dirty worktree ledger not found: $ledger" \
  "Create the ledger and list every dirty path." \
  "templates/dirty-worktree-ledger.md"

status="$(awk '/^dirty_worktree_status:/ { sub(/^dirty_worktree_status:[[:space:]]*/, ""); print; exit }' "$ledger")"
[[ "$status" == "READY" ]] || fail \
  "DIRTY_WORKTREE/LEDGER_NOT_READY" \
  "dirty_worktree_status is '${status:-missing}', not READY" \
  "Set dirty_worktree_status: READY after every dirty file has owner and decision." \
  "dirty_worktree_status: READY"

repo_root="$(git -C "$repo" rev-parse --show-toplevel)"
for line in "${dirty_lines[@]}"; do
  rel="${line:3}"
  abs="$repo_root/$rel"
  if ! grep -Fq "$abs" "$ledger" && ! grep -Fq "$rel" "$ledger"; then
    fail \
      "DIRTY_WORKTREE/UNOWNED_CHANGES" \
      "dirty path is not recorded in ownership ledger: $rel" \
      "Add a row for this path with Owner and Decision before editing or staging." \
      "| $abs | user | preserve | existing user work |"
  fi
done

printf 'PASS: dirty worktree gate passed for %s (%s dirty item(s) recorded)\n' "$repo" "${#dirty_lines[@]}"
