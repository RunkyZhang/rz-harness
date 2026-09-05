#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$root/gates/lib/tempfiles.sh"

usage() {
  cat <<'USAGE'
Usage:
  scripts/assumption-leak-gate.sh <spec-file> <changed-file> [changed-file...]

Checks:
  - Non-spec changed files must not contain literal [ASSUMP] tags.
  - High-signal identifiers from [ASSUMP] lines must not appear in implementation files.

Notes:
  - This is a conservative mechanical gate. Reviewer still owns business semantics.
  - Put uncertain business rules in spec questions or residual risks, not implementation.
  - Harness meta files such as AGENTS.md, templates/, rules/, docs index /
    onboarding, gate scripts, and readiness fixture scripts may mention
    confidence tags as instructions and are excluded from tag-leak checks.
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

spec_file="${1:-}"
[[ -n "$spec_file" ]] || fail \
  "ASSUMPTION_LEAK/MISSING_SPEC_FILE" \
  "missing spec file" \
  "Pass the active change spec path before the changed files." \
  "templates/spec-tier-s.md"
[[ -f "$spec_file" ]] || fail \
  "ASSUMPTION_LEAK/SPEC_FILE_NOT_FOUND" \
  "spec file not found: $spec_file" \
  "Create the active change spec first, then rerun with that path." \
  "templates/spec-tier-s.md"
shift || true
[[ "$#" -gt 0 ]] || fail \
  "ASSUMPTION_LEAK/MISSING_CHANGED_FILES" \
  "missing changed files" \
  "Pass every changed file path after the spec path." \
  "templates/spec-tier-s.md"

tag_out="$(sfa_tmp_file sfa-assump-tag)"
token_out="$(sfa_tmp_file sfa-assump-token)"
trap 'rm -f "$tag_out" "$token_out"' EXIT

canonical_path() {
  local path="$1"
  local dir
  local base
  dir="$(dirname "$path")"
  base="$(basename "$path")"
  (cd "$dir" && printf '%s/%s\n' "$(pwd -P)" "$base")
}

assumption_lines="$(
  awk '
    /\[ASSUMP\]/ && $0 !~ /`\[ASSUMP\]`/ {
      print FNR ":" $0
    }
  ' "$spec_file" || true
)"
spec_canon="$(canonical_path "$spec_file")"

blocking_assumptions=""
if [[ -n "$assumption_lines" ]]; then
  blocking_assumptions="$(
    printf '%s\n' "$assumption_lines" \
      | grep -viE '\[ASSUMP\][[:space:]]*(none|无|不涉及|not applicable|n/a)[[:space:]]*[\.;。]*$' \
      || true
  )"
fi

is_implementation_file() {
  case "$1" in
    *.java|*.xml|*.js|*.jsx|*.ts|*.tsx|*.vue|*.sql|*.yml|*.yaml|*.properties|*.json)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_harness_meta_file() {
  case "$1" in
    AGENTS.md|templates/*|rules/*|docs/README.md|docs/onboarding.md|scripts/assumption-leak-gate.sh|scripts/harness-team-readiness-test.sh)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

tokens=""
if [[ -n "$blocking_assumptions" ]]; then
  tokens="$(
    {
      printf '%s\n' "$blocking_assumptions" | grep -oE '`[^`]+`' | tr -d '`' || true
      printf '%s\n' "$blocking_assumptions" | grep -oE '[A-Za-z_][A-Za-z0-9_]{3,}' || true
    } \
      | grep -vE '^(ASSUMP|FACT|QUESTION|None|none|might|default|from|with|this|that|pending|implementation|item)$' \
      | sort -u \
      || true
  )"
fi

tag_violations=()
token_violations=()

for changed in "$@"; do
  [[ "$changed" == "branch_only" ]] && continue
  [[ -f "$changed" ]] || fail \
    "ASSUMPTION_LEAK/CHANGED_FILE_NOT_FOUND" \
    "changed file not found: $changed" \
    "Pass only files that exist in the active workspace, or remove stale paths from the changed-file list." \
    "templates/spec-tier-s.md"
  [[ "$(canonical_path "$changed")" == "$spec_canon" ]] && continue
  is_harness_meta_file "$changed" && continue

  is_implementation_file "$changed" || continue

  if grep -n '\[ASSUMP\]' "$changed" >"$tag_out" 2>/dev/null; then
    while IFS= read -r hit; do
      tag_violations+=("$changed:$hit")
    done <"$tag_out"
  fi

  [[ -n "$tokens" ]] || continue

  while IFS= read -r token; do
    [[ -n "$token" ]] || continue
    if grep -nF "$token" "$changed" >"$token_out" 2>/dev/null; then
      while IFS= read -r hit; do
        token_violations+=("$changed contains ASSUMP token '$token' at $hit")
      done <"$token_out"
    fi
  done <<< "$tokens"
done

if [[ "${#tag_violations[@]}" -gt 0 ]]; then
  printf 'FAIL: [ASSUMP] tags leaked outside spec:\n' >&2
  printf 'CODE: ASSUMPTION_LEAK/TAG_LEAK\n' >&2
  printf 'FIX: Move uncertain claims back to the spec as [ASSUMP] or resolve them into [FACT] before implementation.\n' >&2
  printf 'SAMPLE: templates/spec-tier-s.md\n' >&2
  printf ' - %s\n' "${tag_violations[@]}" >&2
  exit 1
fi

if [[ "${#token_violations[@]}" -gt 0 ]]; then
  printf 'FAIL: identifiers from [ASSUMP] entries appear in implementation files:\n' >&2
  printf 'CODE: ASSUMPTION_LEAK/TOKEN_LEAK\n' >&2
  printf 'FIX: Confirm or remove the assumption before using its identifiers in implementation files.\n' >&2
  printf 'SAMPLE: templates/spec-tier-s.md\n' >&2
  printf ' - %s\n' "${token_violations[@]}" >&2
  exit 1
fi

if [[ -z "$assumption_lines" ]]; then
  printf 'PASS: no [ASSUMP] entries found in %s; implementation files scanned for leaked tags\n' "$spec_file"
  exit 0
fi

if [[ -z "$blocking_assumptions" ]]; then
  printf 'PASS: only explicit empty [ASSUMP] entries found in %s; implementation files scanned for leaked tags\n' "$spec_file"
  exit 0
fi

if [[ -z "$tokens" ]]; then
  printf 'NOTICE: [ASSUMP] entries found, but no high-signal identifiers were extracted\n'
fi

printf 'PASS: assumption leak gate passed for %s file(s)\n' "$#"
