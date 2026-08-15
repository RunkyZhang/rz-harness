#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/gitnexus-impact.sh <repo-path> <symbol> [--direction upstream|downstream|both] [--depth N] [--repo-id ID] [--include-tests] [--required]

Runs GitNexus impact as an advisory impact sensor.

Defaults:
  - Uses SFA_GITNEXUS_COMMAND when set.
  - Otherwise runs: npm exec --yes --package gitnexus@${SFA_GITNEXUS_VERSION:-1.6.5} -- gitnexus
  - If GitNexus is unavailable, prints GITNEXUS_STATUS=UNAVAILABLE and exits 0 unless --required is passed.
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
symbol="${2:-}"
[[ -n "$repo" ]] || fail \
  "GITNEXUS/MISSING_REPO" \
  "missing repo path" \
  "Pass the target business repo path as the first argument." \
  "scripts/gitnexus-impact.sh \"$SFA_REPO_BACKEND_SALES_MANAGEMENT\" OrderService"
[[ -d "$repo" ]] || fail \
  "GITNEXUS/REPO_NOT_FOUND" \
  "repo path not found: $repo" \
  "Check config/repos.local.sh or pass a valid local repository path." \
  "scripts/gitnexus-impact.sh /path/to/repo OrderService"
[[ -n "$symbol" ]] || fail \
  "GITNEXUS/MISSING_SYMBOL" \
  "missing symbol" \
  "Pass the class, method, file, or symbol you plan to change." \
  "scripts/gitnexus-impact.sh /path/to/repo OrderService --direction upstream"
shift 2

direction=""
depth=""
repo_id=""
include_tests=0
required=0

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --direction)
      direction="${2:-}"
      [[ "$direction" == "upstream" || "$direction" == "downstream" || "$direction" == "both" ]] || fail \
        "GITNEXUS/INVALID_DIRECTION" \
        "direction must be upstream, downstream, or both" \
        "Use upstream for blast radius, downstream for dependency understanding." \
        "--direction upstream"
      shift 2
      ;;
    --depth)
      depth="${2:-}"
      [[ "$depth" =~ ^[0-9]+$ ]] || fail \
        "GITNEXUS/INVALID_DEPTH" \
        "depth must be a positive integer" \
        "Use a small depth first, usually 2 or 3." \
        "--depth 3"
      shift 2
      ;;
    --repo-id)
      repo_id="${2:-}"
      [[ -n "$repo_id" ]] || fail \
        "GITNEXUS/MISSING_REPO_ID" \
        "missing repo id after --repo-id" \
        "Pass the GitNexus repository id when using a multi-repo registry." \
        "--repo-id backend-sales-management"
      shift 2
      ;;
    --include-tests)
      include_tests=1
      shift
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
        "scripts/gitnexus-impact.sh /path/to/repo OrderService --direction upstream --depth 3"
      ;;
  esac
done

gitnexus_version="${SFA_GITNEXUS_VERSION:-1.6.5}"
if [[ -n "${SFA_GITNEXUS_COMMAND:-}" ]]; then
  read -r -a gitnexus_cmd <<< "$SFA_GITNEXUS_COMMAND"
else
  gitnexus_cmd=(npm exec --yes --package "gitnexus@$gitnexus_version" -- gitnexus)
fi

gitnexus_args=(impact "$symbol")
[[ -n "$direction" ]] && gitnexus_args+=(--direction "$direction")
[[ -n "$depth" ]] && gitnexus_args+=(--depth "$depth")
[[ -n "$repo_id" ]] && gitnexus_args+=(--repo "$repo_id")
[[ "$include_tests" -eq 1 ]] && gitnexus_args+=(--include-tests)

tmp_output="$(mktemp)"
trap 'rm -f "$tmp_output"' EXIT

if (cd "$repo" && "${gitnexus_cmd[@]}" "${gitnexus_args[@]}") >"$tmp_output" 2>&1; then
  cat "$tmp_output"
  printf 'PASS: GitNexus impact completed\n'
  exit 0
fi

status="$?"
cat "$tmp_output" >&2 || true
printf 'WARN: GitNexus impact unavailable or failed; degrade to rg/git diff/test evidence.\n' >&2
printf 'GITNEXUS_STATUS=UNAVAILABLE\n' >&2
printf 'CODE: GITNEXUS/UNAVAILABLE\n' >&2
printf 'FIX: Record this degradation in changes/<change-id>/evidence.md and run source search plus targeted checks.\n' >&2
printf 'SAMPLE: rg -n "%s" /path/to/repo && git diff --name-status\n' "$symbol" >&2

if [[ "$required" -eq 1 ]]; then
  exit "$status"
fi
exit 0
