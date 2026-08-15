#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/knowledge-lint.sh [--strict]

Read-only knowledge-base linter. Reports findings for active knowledge entries
under docs/pitfalls/ and docs/samples/ (and any docs/decision-log entry that
carries maturity front matter):

  - decay   : maturity vs last_referenced exceeds the lifecycle thresholds
              (proven > 12mo, verified > 6mo since last_referenced).
  - orphan  : last_referenced is never (no change has used the entry).
  - index   : entry id is missing from its catalog README table.

This linter NEVER edits any entry. Downgrades/archival stay a human decision
during the periodic self-audit. See
docs/decision-log/2026-05-29-knowledge-lifecycle.md.

Options:
  --strict   exit non-zero when any finding exists (for use as a gate)
USAGE
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

PROVEN_DAYS=365
VERIFIED_DAYS=180
DRAFT_DAYS=180

strict=0
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
if [[ "${1:-}" == "--strict" ]]; then
  strict=1
fi

today_epoch="$(date +%s)"

to_epoch() {
  local d="$1"
  date -d "$d" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null || true
}

# Read first front-matter value for a key, stripping inline comments/space.
front_value() {
  local file="$1"
  local key="$2"
  grep -m1 -E "^${key}:" "$file" 2>/dev/null \
    | sed -E "s/^${key}:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//" \
    || true
}

is_date() {
  [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

days_since() {
  local d="$1"
  local e
  e="$(to_epoch "$d")"
  [[ -n "$e" ]] || { printf '\n'; return; }
  printf '%s\n' "$(( (today_epoch - e) / 86400 ))"
}

findings=()

lint_dir() {
  local dir="$1"
  local catalog="$2"
  [[ -d "$dir" ]] || return 0

  local file base id maturity last_ref days
  for file in "$dir"/*.md; do
    [[ -e "$file" ]] || continue
    base="$(basename "$file")"
    [[ "$base" == "README.md" || "$base" == "TEMPLATE.md" ]] && continue

    id="$(front_value "$file" "id")"
    maturity="$(front_value "$file" "maturity")"
    last_ref="$(front_value "$file" "last_referenced")"
    [[ -n "$id" ]] || continue

    # index consistency
    if [[ -f "$catalog" ]]; then
      if ! grep -qF "$id" "$catalog"; then
        findings+=("LOW  | index  | $id ($file) 未在 catalog $catalog 中列出")
      fi
    fi

    if is_date "$last_ref"; then
      # decay (only for real dates)
      days="$(days_since "$last_ref")"
      [[ -n "$days" ]] || continue
      case "$maturity" in
        proven)
          if [[ "$days" -gt "$PROVEN_DAYS" ]]; then
            findings+=("MED  | decay  | $id 已 ${days} 天未引用 (> ${PROVEN_DAYS})；建议 proven -> verified")
          fi
          ;;
        verified)
          if [[ "$days" -gt "$VERIFIED_DAYS" ]]; then
            findings+=("MED  | decay  | $id 已 ${days} 天未引用 (> ${VERIFIED_DAYS})；建议 verified -> draft")
          fi
          ;;
        draft)
          if [[ "$days" -gt "$DRAFT_DAYS" ]]; then
            findings+=("MED  | decay  | $id 已 ${days} 天未引用 (> ${DRAFT_DAYS})；建议 draft -> 归档")
          fi
          ;;
      esac
    elif [[ -z "$last_ref" || "$last_ref" == "never" ]]; then
      # orphan: never referenced
      findings+=("MED  | orphan | $id ($file) last_referenced=never；$maturity 条目从未被引用")
    fi
    # non-date placeholder values are skipped silently
  done
}

lint_dir docs/pitfalls docs/pitfalls/README.md
lint_dir docs/samples docs/samples/README.md
lint_dir docs/decision-log ""

if [[ "${#findings[@]}" -eq 0 ]]; then
  printf 'PASS: knowledge lint found no decay / orphan / index issues\n'
  exit 0
fi

printf 'NOTICE: knowledge lint findings (%d). Review in self-audit; downgrades are manual.\n' "${#findings[@]}"
printf 'SEV  | kind   | detail\n'
printf '%s\n' "${findings[@]}"
printf 'FIX: edit the entry front matter (maturity / archive) by hand after confirming against last_referenced.\n'

if [[ "$strict" -eq 1 ]]; then
  exit 1
fi
exit 0
