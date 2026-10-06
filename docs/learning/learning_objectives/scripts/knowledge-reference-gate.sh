#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/knowledge-reference-gate.sh <change-file> [change-file...]
  scripts/knowledge-reference-gate.sh --audit

Validate mode (default):
  - Reads the `knowledge_refs:` block from each given change file.
  - Verifies every referenced knowledge ID resolves to a real active entry
    under docs/pitfalls/, docs/samples/, or docs/decision-log/.
  - FAIL (with CODE/FIX/SAMPLE) if any referenced ID is dangling.
  - On success, prints the resolved refs so the ARCHIVE step can update
    last_referenced / referenced_by on those entries.
  - No knowledge_refs declared is allowed (refs are optional).

Audit mode (--audit):
  - Scans every changes/**/*.md for knowledge_refs IDs (the referenced set).
  - Lists active knowledge entries (docs/pitfalls + docs/samples) whose ID is
    never referenced -> decay candidates. Informational only, never blocks.

This gate is read-only. It never edits any knowledge entry.
USAGE
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

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

# Token patterns for knowledge IDs.
id_regex='(SFA-PIT-[0-9]+|SFA-SMP-[0-9]+|DEC-[0-9]{4}-[0-9]{2}-[0-9]{2}-[A-Za-z0-9-]+)'

# Extract knowledge IDs declared under a `knowledge_refs:` block in a file.
extract_refs() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  awk '
    /^[[:space:]]*knowledge_refs:[[:space:]]*$/ { in_block=1; next }
    in_block && /^[[:space:]]*$/ { next }
    in_block && /^[[:space:]]*-/ { print; next }
    in_block && /^[[:space:]]*#/ { next }
    in_block { in_block=0 }
  ' "$file" \
    | grep -oE "$id_regex" \
    || true
}

# True if an ID resolves to a real active entry (excludes TEMPLATE placeholders).
resolve_id() {
  local id="$1"
  grep -RlE "^id:[[:space:]]*${id}[[:space:]]*$" \
      docs/pitfalls docs/samples docs/decision-log 2>/dev/null \
    | grep -v '/TEMPLATE\.md$' \
    | grep -q .
}

# Collect all active knowledge entry IDs from pitfalls + samples catalogs.
active_entry_ids() {
  grep -rhE "^id:[[:space:]]*(SFA-PIT-[0-9]+|SFA-SMP-[0-9]+)[[:space:]]*$" \
      docs/pitfalls docs/samples 2>/dev/null \
    | sed -E 's/^id:[[:space:]]*//; s/[[:space:]]*$//' \
    | sort -u \
    || true
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--audit" ]]; then
  referenced="$(
    {
      while IFS= read -r f; do
        extract_refs "$f"
      done < <(find changes -type f -name '*.md' 2>/dev/null)
    } | sort -u
  )"

  active="$(active_entry_ids)"
  if [[ -z "$active" ]]; then
    printf 'PASS: no active knowledge entries yet; nothing to audit\n'
    exit 0
  fi

  candidates=()
  while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    if ! printf '%s\n' "$referenced" | grep -qxF "$id"; then
      candidates+=("$id")
    fi
  done <<< "$active"

  if [[ "${#candidates[@]}" -eq 0 ]]; then
    printf 'PASS: every active knowledge entry is referenced by at least one change\n'
    exit 0
  fi

  printf 'NOTICE: decay candidates (active entries never referenced by any change):\n'
  printf ' - %s\n' "${candidates[@]}"
  printf 'NOTE: informational only. Review against last_referenced before downgrading maturity.\n'
  exit 0
fi

[[ "$#" -gt 0 ]] || fail \
  "KNOWLEDGE_REF/MISSING_ARGS" \
  "missing change file(s)" \
  "Pass the change file(s) to validate, or run with --audit for the decay report." \
  "templates/spec-tier-s.md"

dangling=()
resolved=()

for file in "$@"; do
  [[ -f "$file" ]] || fail \
    "KNOWLEDGE_REF/FILE_NOT_FOUND" \
    "file not found: $file" \
    "Pass an existing change file path." \
    "templates/spec-tier-s.md"

  while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    if resolve_id "$id"; then
      resolved+=("$file -> $id")
    else
      dangling+=("$file -> $id")
    fi
  done < <(extract_refs "$file")
done

if [[ "${#dangling[@]}" -gt 0 ]]; then
  printf 'FAIL: knowledge_refs point to unknown knowledge IDs:\n' >&2
  printf 'CODE: KNOWLEDGE_REF/DANGLING_REFERENCE\n' >&2
  printf 'FIX: Create the referenced entry under docs/pitfalls or docs/samples (with matching front-matter id:), or fix the typo in knowledge_refs.\n' >&2
  printf 'SAMPLE: docs/pitfalls/TEMPLATE.md\n' >&2
  printf ' - %s\n' "${dangling[@]}" >&2
  exit 1
fi

if [[ "${#resolved[@]}" -eq 0 ]]; then
  printf 'PASS: no knowledge_refs declared (references are optional)\n'
  exit 0
fi

printf 'PASS: all knowledge_refs resolved\n'
printf 'NOTICE: update last_referenced / referenced_by for these entries in the ARCHIVE step:\n'
printf ' - %s\n' "${resolved[@]}"
