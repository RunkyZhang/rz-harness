#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/workstream-dispatch-gate.sh <change-dir>

For multi-repo/full-stack changes, checks harness-status.md contains:
  - target_repos with at least two repositories
  - "## Workstream Dispatch"
  - one dispatch table row per target repo
  - each row has a non-empty verification command and actionable status
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

change_dir="${1:-}"
[[ -n "$change_dir" ]] || fail \
  "WORKSTREAM_DISPATCH/MISSING_CHANGE_DIR" \
  "missing change directory" \
  "Pass changes/<change-id>." \
  "scripts/workstream-dispatch-gate.sh changes/<change-id>"
status_file="$change_dir/harness-status.md"
[[ -f "$status_file" ]] || fail \
  "WORKSTREAM_DISPATCH/MISSING_STATUS" \
  "harness-status.md not found in $change_dir" \
  "Create the visible harness status card before implementation dispatch." \
  "templates/harness-status.md"

target_repos=()
while IFS= read -r repo; do
  [[ -n "$repo" ]] && target_repos+=("$repo")
done < <(
  awk '
    /^target_repos:/ { in_targets=1; next }
    in_targets && /^[^[:space:]]/ { in_targets=0 }
    in_targets && /^[[:space:]]*-[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      sub(/[[:space:]]*:.*$/, "", line)
      gsub(/^"|"$/, "", line)
      gsub(/^'\''|'\''$/, "", line)
      print line
    }
  ' "$status_file"
)

if [[ "${#target_repos[@]}" -lt 2 ]]; then
  printf 'PASS: workstream dispatch gate not required for single-repo change in %s\n' "$change_dir"
  exit 0
fi

grep -q '^## Workstream Dispatch' "$status_file" || fail \
  "WORKSTREAM_DISPATCH/MISSING_SECTION" \
  "multi-repo change lacks ## Workstream Dispatch section" \
  "Add a dispatch table for backend, PC, mini-program, and any other affected workstream before code start." \
  "templates/harness-status.md"

for repo in "${target_repos[@]}"; do
  row="$(
    awk '
      /^## Workstream Dispatch[[:space:]]*$/ { in_section=1; next }
      in_section && /^## / { in_section=0 }
      in_section { print }
    ' "$status_file" | grep -E "^[|][[:space:]]*\`?${repo//\//\\/}\`?[[:space:]]*[|]" || true
  )"
  [[ -n "$row" ]] || fail \
    "WORKSTREAM_DISPATCH/MISSING_REPO_ROW" \
    "missing workstream row for target repo: $repo" \
    "Add a Workstream Dispatch table row with repo, scope, agent mode, verification, and status." \
    "| $repo | <scope> | <agent-or-DEGRADED reason> | <verification command> | READY |"
  IFS='|' read -r _ col_repo col_scope col_agent col_verification col_status _ <<<"$row"
  col_verification="${col_verification#"${col_verification%%[![:space:]]*}"}"
  col_verification="${col_verification%"${col_verification##*[![:space:]]}"}"
  col_status="${col_status#"${col_status%%[![:space:]]*}"}"
  col_status="${col_status%"${col_status##*[![:space:]]}"}"
  col_status="${col_status#\`}"
  col_status="${col_status%\`}"
  [[ -n "$col_verification" && "$col_verification" != "-" ]] || fail \
    "WORKSTREAM_DISPATCH/MISSING_VERIFICATION" \
    "workstream row lacks verification command for repo: $repo" \
    "Record the narrowest useful compile/lint/smoke command for this workstream." \
    "| $repo | <scope> | <agent> | npm run lint | READY |"
  case "$col_status" in
    READY|IN_PROGRESS|DONE|DEGRADED) ;;
    *)
      fail \
        "WORKSTREAM_DISPATCH/INVALID_STATUS" \
        "invalid workstream status '$col_status' for repo: $repo" \
        "Use READY, IN_PROGRESS, DONE, or DEGRADED before implementation." \
        "| $repo | <scope> | <agent> | <verification> | READY |"
      ;;
  esac
done

printf 'PASS: workstream dispatch gate passed for %s (%s repos)\n' "$change_dir" "${#target_repos[@]}"
