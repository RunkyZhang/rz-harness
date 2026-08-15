#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/no-personal-paths.sh [path...]

Scans team-facing harness docs, templates, rules, skills, and scripts for real
personal absolute paths under macOS or Windows user home directories. Historical
evidence and local ignored config are intentionally not part of the default scan.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

targets=("$@")
if [[ "${#targets[@]}" -eq 0 ]]; then
  targets=(
    AGENTS.md
    README.md
    docs/README.md
    docs/onboarding.md
    docs/skills-routing.md
    docs/architecture/adapter-compliance.md
    docs/architecture/ecc-integration.md
    templates
    rules
    skills
    scripts
    config/repos.local.example.sh
    .codex
    .cursor
    .opencode
    opencode.json
  )
fi

placeholder_re='/Users/(example|me|user|username|you|yourname|yourusername|your-username)(/|$)|C:\\Users\\(example|me|user|username|you|yourname|yourusername|your-username)(\\|$)'
path_re='/Users/[^/[:space:]]+|C:\\Users\\[^[:space:]\\]+'

files=()
for target in "${targets[@]}"; do
  [[ -e "$target" ]] || continue
  if [[ -f "$target" ]]; then
    files+=("$target")
  else
    while IFS= read -r file; do
      files+=("$file")
    done < <(find "$target" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.js' -o -name '*.json' -o -name '*.toml' -o -name '*.yml' -o -name '*.yaml' -o -name '*.mdc' \) | sort)
  fi
done

is_scanner_fixture() {
  local file="$1"
  local hit="$2"
  case "$file:$hit" in
    scripts/no-personal-paths.sh:*_re=*) return 0 ;;
    scripts/harness-team-readiness-test.sh:*personal_path_pattern=*) return 0 ;;
    *) return 1 ;;
  esac
}

failures=0
for file in "${files[@]}"; do
  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    if is_scanner_fixture "$file" "$hit"; then
      continue
    fi
    if printf '%s\n' "$hit" | grep -Eq "$placeholder_re"; then
      continue
    fi
    printf 'ERROR: personal path detected in %s:%s\n' "$file" "$hit" >&2
    failures=$((failures + 1))
  done < <(grep -nE "$path_re" "$file" || true)
done

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: personal paths found in team-facing harness files\n' >&2
  exit 1
fi

printf 'PASS: no personal paths found in team-facing harness files\n'
