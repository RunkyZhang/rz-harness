#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/gitnexus-detect-changes.sh <repo-path> [--scope all|staged|compare] [--base-ref REF] [--required]

Runs GitNexus detect_changes as an advisory pre-PR impact sensor.

Behavior:
  - GitNexus unavailable: prints GITNEXUS_STATUS=UNAVAILABLE and exits 0 unless --required is passed.
  - Output containing HIGH or CRITICAL: exits non-zero with CODE: GITNEXUS/HIGH_RISK.
USAGE
}

fail() {
  local code="$1"
  local message="$2"
  local fix="$3"
  local sample="$4"
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
  "GITNEXUS/MISSING_REPO" \
  "missing repo path" \
  "Pass the target business repo path as the first argument." \
  "scripts/gitnexus-detect-changes.sh \"$SFA_REPO_BACKEND_SALES_MANAGEMENT\" --scope all"
[[ -d "$repo" ]] || fail \
  "GITNEXUS/REPO_NOT_FOUND" \
  "repo path not found: $repo" \
  "Check config/repos.local.sh or pass a valid local repository path." \
  "scripts/gitnexus-detect-changes.sh /path/to/repo --scope all"
shift

scope="all"
base_ref=""
required=0

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --scope)
      scope="${2:-}"
      [[ "$scope" == "all" || "$scope" == "staged" || "$scope" == "compare" ]] || fail \
        "GITNEXUS/INVALID_SCOPE" \
        "scope must be all, staged, or compare" \
        "Use all for local worktree review, staged for pre-commit, compare for PR review." \
        "--scope all"
      shift 2
      ;;
    --base-ref)
      base_ref="${2:-}"
      [[ -n "$base_ref" ]] || fail \
        "GITNEXUS/MISSING_BASE_REF" \
        "missing base ref after --base-ref" \
        "Pass the branch or ref to compare against." \
        "--base-ref main"
      shift 2
      ;;
    --required)
      required=1
      shift
      ;;
    *)
      fail \
        "GITNEXUS/UNKNOWN_OPTION" \
        "unknown option: $1" \
        "Use --help to see supported options." \
        "scripts/gitnexus-detect-changes.sh /path/to/repo --scope compare --base-ref main"
      ;;
  esac
done

if [[ "$scope" == "compare" && -z "$base_ref" ]]; then
  base_ref="main"
fi

gitnexus_version="${SFA_GITNEXUS_VERSION:-1.6.5}"
if [[ -n "${SFA_GITNEXUS_COMMAND:-}" ]]; then
  read -r -a gitnexus_cmd <<< "$SFA_GITNEXUS_COMMAND"
else
  gitnexus_cmd=(npm exec --yes --package "gitnexus@$gitnexus_version" -- gitnexus)
fi

gitnexus_args=(mcp detect_changes --scope "$scope")
[[ -n "$base_ref" ]] && gitnexus_args+=(--base-ref "$base_ref")

tmp_output="$(mktemp)"
trap 'rm -f "$tmp_output"' EXIT

set +e
(cd "$repo" && "${gitnexus_cmd[@]}" "${gitnexus_args[@]}") >"$tmp_output" 2>&1
status="$?"
set -e

if [[ "$status" -ne 0 ]]; then
  cat "$tmp_output" >&2 || true
  printf 'WARN: GitNexus detect_changes unavailable or failed; degrade to rg/git diff/test evidence.\n' >&2
  printf 'GITNEXUS_STATUS=UNAVAILABLE\n' >&2
  printf 'CODE: GITNEXUS/UNAVAILABLE\n' >&2
  printf 'FIX: Record this degradation in changes/<change-id>/evidence.md and run source search plus targeted checks.\n' >&2
  printf 'SAMPLE: git diff --name-status && rg -n "<changed-symbol>" /path/to/repo\n' >&2
  if [[ "$required" -eq 1 ]]; then
    exit "$status"
  fi
  exit 0
fi

cat "$tmp_output"

if grep -Eiq '(^|[^A-Za-z])(HIGH|CRITICAL)([^A-Za-z]|$)' "$tmp_output"; then
  printf 'FAIL: GitNexus detect_changes reported HIGH or CRITICAL impact.\n' >&2
  printf 'CODE: GITNEXUS/HIGH_RISK\n' >&2
  printf 'FIX: Pause automation, record the impacted scope, and get user confirmation before implementation or PR.\n' >&2
  printf 'SAMPLE: Add the GitNexus summary to changes/<change-id>/evidence.md and list the accepted risk in pre-pr.md.\n' >&2
  exit 2
fi

printf 'PASS: GitNexus detect_changes completed\n'
