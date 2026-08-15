#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/agent-review-package.sh [--scope task|whole-branch] <base-ref> <head-ref> <change-id> [outfile]

Writes a reviewer handoff package with commit list, diff stat, and full diff.
Run from the git repository/worktree being reviewed.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }

scope="task"
if [[ "${1:-}" == "--scope" ]]; then
  shift
  [[ "$#" -ge 1 ]] || { usage; exit 2; }
  scope="$1"
  shift
fi

case "$scope" in
  task|whole-branch) ;;
  *) fail "scope must be task or whole-branch: $scope" ;;
esac

[[ "$#" -ge 3 && "$#" -le 4 ]] || { usage; exit 2; }

base_ref="$1"
head_ref="$2"
change_id="$3"
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || fail "current directory is not inside a git repository"

git rev-parse --verify --quiet "$base_ref" >/dev/null || fail "bad base ref: $base_ref"
git rev-parse --verify --quiet "$head_ref" >/dev/null || fail "bad head ref: $head_ref"

base_short="$(git rev-parse --short "$base_ref")"
head_short="$(git rev-parse --short "$head_ref")"

if [[ "$#" -eq 4 ]]; then
  out="$4"
else
  workspace="$("$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/agent-workspace.sh" "$repo_root" "$change_id")"
  out="$workspace/review-${scope}-${base_short}..${head_short}.diff"
fi

{
  printf '# Review package: %s..%s\n\n' "$base_ref" "$head_ref"
  printf 'change_id: %s\n' "$change_id"
  printf 'review_scope: %s\n' "$scope"
  printf 'reviewer_independence: READ_ONLY\n'
  printf 'required_verdicts: spec_compliance, code_quality\n'
  printf 'base_ref: %s\n' "$base_ref"
  printf 'head_ref: %s\n' "$head_ref"
  printf '\n'
  printf '## Commits\n'
  git log --oneline "${base_ref}..${head_ref}"
  printf '\n## Files changed\n'
  git diff --stat "${base_ref}..${head_ref}"
  printf '\n## Diff\n'
  git diff -U10 "${base_ref}..${head_ref}"
} >"$out"

printf 'wrote %s\n' "$out"
