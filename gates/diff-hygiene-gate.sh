#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/diff-hygiene-gate.sh <repo-root> [--base <ref>] [changed-file...]

Checks changed files for review-noise whitespace-only diff hunks.
If changed files are omitted, checks git diff --name-only from the selected base.
Default base is HEAD.
EOF
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

[[ "$#" -ge 1 ]] || fail \
  "DIFF_HYGIENE/MISSING_REPO" \
  "missing repo root" \
  "Pass the target business repo root first." \
  "scripts/diff-hygiene-gate.sh /path/to/repo --base sit src/Foo.m"

repo="$1"
shift

[[ -d "$repo" ]] || fail \
  "DIFF_HYGIENE/REPO_NOT_FOUND" \
  "repo root does not exist: $repo" \
  "Pass a valid local repo path from config/runtime_local.sh." \
  "config/runtime_local.sh"

repo="$(cd "$repo" && pwd -P)"
base="HEAD"
files=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --base)
      [[ -n "${2:-}" ]] || fail \
        "DIFF_HYGIENE/MISSING_BASE" \
        "--base requires a git ref" \
        "Pass the branch or commit used as the review baseline." \
        "--base sit"
      base="$2"
      shift 2
      ;;
    --base=*)
      base="${1#--base=}"
      shift
      ;;
    --)
      shift
      while [[ "$#" -gt 0 ]]; do
        files+=("$1")
        shift
      done
      ;;
    -*)
      fail \
        "DIFF_HYGIENE/UNKNOWN_OPTION" \
        "unknown option: $1" \
        "Use only --base <ref> before changed files." \
        "scripts/diff-hygiene-gate.sh /path/to/repo --base main src/Foo.java"
      ;;
    *)
      files+=("$1")
      shift
      ;;
  esac
done

git -C "$repo" rev-parse --verify "$base^{commit}" >/dev/null 2>&1 || fail \
  "DIFF_HYGIENE/BASE_NOT_FOUND" \
  "base ref is not a commit in repo: $base" \
  "Pass a local base branch or commit that exists in the target repo." \
  "git -C <repo> fetch && scripts/diff-hygiene-gate.sh <repo> --base origin/main"

tmp_files="$(mktemp)"
tmp_report="$(mktemp)"
trap 'rm -f "$tmp_files" "$tmp_report"' EXIT

if [[ "${#files[@]}" -gt 0 ]]; then
  for item in "${files[@]}"; do
    if [[ "$item" == "$repo/"* ]]; then
      printf '%s\n' "${item#"$repo/"}" >> "$tmp_files"
    elif [[ "$item" == /* ]]; then
      real_item="$(cd "$(dirname "$item")" && pwd -P)/$(basename "$item")"
      case "$real_item" in
        "$repo"/*) printf '%s\n' "${real_item#"$repo/"}" >> "$tmp_files" ;;
      esac
    else
      printf '%s\n' "$item" >> "$tmp_files"
    fi
  done
else
  git -C "$repo" diff --name-only "$base" -- > "$tmp_files" || true
fi

checked=0
while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  checked=$((checked + 1))
  git -C "$repo" diff --no-color --unified=0 "$base" -- "$file" | awk -v file="$file" '
    function flush_hunk() {
      if (hunk != "" && removed_ws && added_ws) {
        printf "%s:%s [DIFF-HYGIENE-BLANK-WHITESPACE] whitespace-only blank line churn\n", file, hunk
      }
      removed_ws = 0
      added_ws = 0
    }
    /^@@ / {
      flush_hunk()
      hunk = $0
      next
    }
    /^--- / || /^\+\+\+ / { next }
    /^-[[:space:]]*$/ {
      removed_ws = 1
      next
    }
    /^\+[[:space:]]*$/ {
      added_ws = 1
      next
    }
    END {
      flush_hunk()
    }
  ' >> "$tmp_report"
done < "$tmp_files"

if [[ -s "$tmp_report" ]]; then
  cat "$tmp_report" >&2
  fail \
    "DIFF_HYGIENE/WHITESPACE_ONLY_NOISE" \
    "diff contains whitespace-only blank-line churn" \
    "Restore baseline blank-line whitespace or re-apply only semantic code changes before review." \
    "git diff --ignore-all-space --ignore-blank-lines <base> -- <files...>"
fi

printf 'PASS: diff hygiene gate checked %s file(s) against %s\n' "$checked" "$base"
