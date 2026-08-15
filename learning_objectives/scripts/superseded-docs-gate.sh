#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/superseded-docs-gate.sh [--root <harness-root>]

Checks that legacy root-level harness planning documents are clearly marked as
superseded and point readers to the current workflow/design SSOT.
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

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --root)
      root="${2:-}"
      [[ -n "$root" ]] || fail \
        "SUPERSEDED_DOCS/MISSING_ROOT" \
        "missing value for --root" \
        "Pass a harness root path." \
        "scripts/superseded-docs-gate.sh --root /path/to/sfa-ai-harness"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail \
        "SUPERSEDED_DOCS/UNKNOWN_ARG" \
        "unknown argument: $1" \
        "Use --root only when testing a fixture copy." \
        "scripts/superseded-docs-gate.sh"
      ;;
  esac
done

[[ -d "$root" ]] || fail \
  "SUPERSEDED_DOCS/MISSING_ROOT_DIR" \
  "harness root not found: $root" \
  "Pass an existing harness root." \
  "scripts/superseded-docs-gate.sh --root /path/to/sfa-ai-harness"

replacement="docs/architecture/harness-workflow-and-design-principles.md"
[[ -f "$root/$replacement" ]] || fail \
  "SUPERSEDED_DOCS/MISSING_REPLACEMENT" \
  "replacement SSOT not found: $replacement" \
  "Create or restore the current workflow/design SSOT document." \
  "$replacement"

legacy_docs=(
  harness-engineering-target-plan.md
  multi-repo-harness-implementation-plan.md
  deep-research-report.md
)

for legacy in "${legacy_docs[@]}"; do
  path="$root/$legacy"
  [[ -f "$path" ]] || fail \
    "SUPERSEDED_DOCS/MISSING_LEGACY_DOC" \
    "legacy document not found: $legacy" \
    "Either restore the legacy document with a SUPERSEDED banner or update superseded-docs-gate.sh if the document was intentionally removed." \
    "$legacy"

  if ! sed -n '1,12p' "$path" | grep -q "SUPERSEDED by $replacement"; then
    fail \
      "SUPERSEDED_DOCS/MISSING_BANNER" \
      "legacy document is missing SUPERSEDED banner: $legacy" \
      "Add a top-of-file banner pointing to the active SSOT." \
      "> SUPERSEDED by $replacement"
  fi
done

printf 'PASS: superseded docs gate passed\n'
