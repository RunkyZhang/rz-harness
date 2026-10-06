#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/temp-hardcode-scan.sh <changed-file-or-dir>...

Scans changed business files before merge for temporary hardcoding markers:
CODX, smoke, mock, localhost, token, password, TODO, FIXME.

The report prints only path, line, and matched marker. It intentionally does not
print the full source line to avoid leaking secrets into evidence.
USAGE
}

if [[ "$#" -eq 0 ]]; then
  usage
  exit 2
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "FAIL: rg is required for temp hardcode scan" >&2
  exit 2
fi

tmp="${TMPDIR:-/tmp}/sfa-temp-hardcode-scan.$$"
trap 'rm -f "$tmp"' EXIT

pattern='CODX|smoke|mock|localhost|token|password|TODO|FIXME'

rg -nI --with-filename --color never --ignore-case --only-matching \
  --glob '!node_modules/**' \
  --glob '!target/**' \
  --glob '!dist/**' \
  --glob '!build/**' \
  --glob '!coverage/**' \
  --glob '!.git/**' \
  --regexp "$pattern" \
  -- "$@" >"$tmp" || true

if [[ -s "$tmp" ]]; then
  echo "FAIL: temporary hardcode markers found. Remove them, configure them, or document a reviewed false positive in evidence." >&2
  awk -F: '{ printf " - %s:%s matched %s\n", $1, $2, $3 }' "$tmp" >&2
  exit 1
fi

echo "PASS: no temporary hardcode markers found"
