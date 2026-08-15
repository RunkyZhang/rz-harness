#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/business-code-start-gate.sh <change-dir> <changed-file> [changed-file...]

Checks before editing business repositories:
  - technical solution is confirmed for code_start or later
  - verification map is READY
  - changed files are listed under contract.md allowed_paths
  - each target git repository is on a non-main/non-master branch
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

field_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*:" {
      sub("^[[:space:]]*" key "[[:space:]]*:[[:space:]]*", "")
      sub("[[:space:]]+$", "")
      print
      exit
    }
  ' "$file"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

change_dir="${1:-}"
[[ -n "$change_dir" ]] || fail \
  "BUSINESS_CODE_START/MISSING_CHANGE_DIR" \
  "missing change directory" \
  "Pass changes/<change-id> before changed files." \
  "scripts/business-code-start-gate.sh changes/<change-id> /absolute/path/File.java"
[[ -d "$change_dir" ]] || fail \
  "BUSINESS_CODE_START/CHANGE_DIR_NOT_FOUND" \
  "change directory not found: $change_dir" \
  "Create the active harness change package first." \
  "changes/<change-id>"
shift || true
[[ "$#" -gt 0 ]] || fail \
  "BUSINESS_CODE_START/MISSING_CHANGED_FILES" \
  "missing changed files" \
  "Pass every business file that will be edited." \
  "scripts/business-code-start-gate.sh changes/<change-id> /absolute/path/File.java"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
"$root/scripts/technical-solution-gate.sh" "$change_dir" >/dev/null
"$root/scripts/verification-map-gate.sh" "$change_dir" >/dev/null

technical_solution="$change_dir/technical-solution.md"
next_stage="$(field_value "$technical_solution" "allowed_next_stage")"
if [[ "$next_stage" != "code_start" ]]; then
  fail \
    "BUSINESS_CODE_START/NEXT_STAGE_NOT_CODE_START" \
    "technical solution allowed_next_stage is '$next_stage', not code_start" \
    "Only start business-code edits after the human confirmation explicitly allows code_start." \
    "allowed_next_stage: code_start"
fi
"$root/scripts/workstream-dispatch-gate.sh" "$change_dir" >/dev/null

contract="$change_dir/contract.md"
[[ -f "$contract" ]] || fail \
  "BUSINESS_CODE_START/MISSING_CONTRACT" \
  "contract.md not found in $change_dir" \
  "Create contract.md with allowed_paths before editing business repos." \
  "templates/api-contract.md"

expand_path_rule() {
  local rule="$1"
  local var_name=""
  local suffix=""

  if [[ "$rule" =~ ^\$\{([A-Za-z_][A-Za-z0-9_]*)\}(.*)$ ]]; then
    var_name="${BASH_REMATCH[1]}"
    suffix="${BASH_REMATCH[2]}"
  elif [[ "$rule" =~ ^\$([A-Za-z_][A-Za-z0-9_]*)(.*)$ ]]; then
    var_name="${BASH_REMATCH[1]}"
    suffix="${BASH_REMATCH[2]}"
  fi

  if [[ -n "$var_name" ]]; then
    local value="${!var_name:-}"
    [[ -n "$value" ]] || fail \
      "BUSINESS_CODE_START/ENV_NOT_SET" \
      "environment variable not set for allowed path: $var_name" \
      "Source config/repos.local.sh or replace the allowed path with an absolute path." \
      "config/repos.local.example.sh"
    printf '%s%s\n' "$value" "$suffix"
    return
  fi

  printf '%s\n' "$rule"
}

allowed_rules=()
while IFS= read -r rule; do
  expanded_rule="$(expand_path_rule "$rule")"
  [[ "$expanded_rule" = /* ]] || continue
  allowed_rules+=("$expanded_rule")
done < <(
  awk '
    /^allowed_paths:/ { in_allowed=1; next }
    /^blocked_until_code_start:/ { in_allowed=0 }
    /^forbidden_paths:/ { in_allowed=0 }
    in_allowed && /^[[:space:]]*-[[:space:]]*(\/|\$)/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      gsub(/^"|"$/, "", line)
      gsub(/^'\''|'\''$/, "", line)
      print line
    }
  ' "$contract"
)

[[ "${#allowed_rules[@]}" -gt 0 ]] || fail \
  "BUSINESS_CODE_START/NO_ALLOWED_PATHS" \
  "no absolute allowed_paths found in $contract" \
  "Add absolute business allowed_paths to contract.md before code start." \
  "allowed_paths:\n  - /absolute/repo/src/**"

normalize_path() {
  local path="$1"
  if [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$PWD" "$path"
  fi
}

matches_rule() {
  local file="$1"
  local rule="$2"
  if [[ "$rule" == *'/**' ]]; then
    local prefix="${rule%/**}"
    [[ "$file" == "$prefix" || "$file" == "$prefix/"* ]]
  elif [[ "$rule" == *'*' ]]; then
    [[ "$file" == $rule ]]
  else
    [[ "$file" == "$rule" ]]
  fi
}

repo_roots=()
seen_repos=" "
for changed in "$@"; do
  file="$(normalize_path "$changed")"
  allowed="no"
  for rule in "${allowed_rules[@]}"; do
    if matches_rule "$file" "$rule"; then
      allowed="yes"
      break
    fi
  done
  [[ "$allowed" == "yes" ]] || fail \
    "BUSINESS_CODE_START/PATH_NOT_ALLOWED" \
    "changed file is not covered by contract allowed_paths: $file" \
    "Add the path to contract.md allowed_paths, or do not edit this file." \
    "$contract"

  probe="$file"
  [[ -d "$probe" ]] || probe="$(dirname "$probe")"
  repo_root="$(git -C "$probe" rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -n "$repo_root" ]] || fail \
    "BUSINESS_CODE_START/NOT_A_GIT_REPO" \
    "changed file is not inside a git repository: $file" \
    "Run this gate with files from configured business repositories." \
    "git -C <repo> branch --show-current"
  if [[ "$seen_repos" != *" $repo_root "* ]]; then
    repo_roots+=("$repo_root")
    seen_repos+=" $repo_root "
  fi
done

for repo_root in "${repo_roots[@]}"; do
  branch="$(git -C "$repo_root" branch --show-current 2>/dev/null || true)"
  [[ -n "$branch" ]] || fail \
    "BUSINESS_CODE_START/DETACHED_HEAD" \
    "business repo is not on a named branch: $repo_root" \
    "Switch to a codex/<change-id> branch before editing." \
    "git -C $repo_root switch -c codex/<change-id>"
  case "$branch" in
    main|master)
      fail \
        "BUSINESS_CODE_START/PROTECTED_BRANCH" \
        "business repo is on protected branch '$branch': $repo_root" \
        "Create or switch to a codex/<change-id> branch before editing business code." \
        "git -C $repo_root switch -c codex/<change-id>"
      ;;
  esac
done

printf 'PASS: business code start gate passed for %s (%s file(s), %s repo(s))\n' "$change_dir" "$#" "${#repo_roots[@]}"
