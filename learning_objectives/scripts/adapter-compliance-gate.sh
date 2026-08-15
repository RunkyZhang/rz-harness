#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/adapter-compliance-gate.sh docs/architecture/adapter-compliance.md

Checks that every adapter row records state, onramp, verification, risk, owner,
last verified date, and source docs.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

matrix="${1:-docs/architecture/adapter-compliance.md}"
[[ -f "$matrix" ]] || { printf 'FAIL: adapter matrix not found: %s\n' "$matrix" >&2; exit 1; }

awk -F'|' '
function trim(value) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
  return value
}
BEGIN {
  failures = 0
  rows = 0
}
/^\|/ {
  first = trim($2)
  if (first == "Adapter" || first == "---") next
  if (NF < 11) {
    print "FAIL: malformed adapter row: " $0 > "/dev/stderr"
    failures++
    next
  }
  rows++
  state = trim($3)
  if (first == "") {
    print "FAIL: missing adapter name: " $0 > "/dev/stderr"
    failures++
  }
  if (state !~ /^(Native|Adapter-backed|Instruction-backed|Reference-only)$/) {
    print "FAIL: invalid state for " first ": " state > "/dev/stderr"
    failures++
  }
  for (i = 4; i <= 11; i++) {
    if (trim($i) == "" || trim($i) == "-") {
      print "FAIL: missing required adapter field for " first ": column " i > "/dev/stderr"
      failures++
    }
  }
  if (trim($10) !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) {
    print "FAIL: invalid last verified date for " first ": " trim($10) > "/dev/stderr"
    failures++
  }
}
END {
  if (rows == 0) {
    print "FAIL: adapter matrix has no rows" > "/dev/stderr"
    exit 1
  }
  if (failures > 0) exit 1
  printf "PASS: adapter compliance matrix has %d verified rows\n", rows
}
' "$matrix"
