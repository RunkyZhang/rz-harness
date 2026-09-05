#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/skill-usage-gate.sh changes/<change-id>

Checks that a change records harness-local skill usage. This gate verifies the
record exists and does not leave TODO statuses. It does not decide whether a
N/A reason is valid; Reviewer must check that.
USAGE
}

[[ "$#" -eq 1 ]] || { usage; exit 2; }

change_dir="$1"
usage_file="$change_dir/skill-usage.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -f "$usage_file" ]] || fail "missing $usage_file; copy templates/skill-usage.md and record harness skill usage"

grep -q 'skills/.*/SKILL.md' "$usage_file" \
  || fail "$usage_file must reference harness skills/*/SKILL.md paths"

if grep -nE '(^|[|[:space:]])TODO([|[:space:]]|$)' "$usage_file" >/tmp/sfa-skill-usage-todo.out; then
  printf 'FAIL: unresolved TODO skill usage rows:\n' >&2
  sed -n '1,20p' /tmp/sfa-skill-usage-todo.out >&2
  rm -f /tmp/sfa-skill-usage-todo.out
  exit 1
fi
rm -f /tmp/sfa-skill-usage-todo.out

if grep -n 'N/A |  |' "$usage_file" >/tmp/sfa-skill-usage-na.out; then
  printf 'FAIL: N/A skill rows must include N/A reason:\n' >&2
  sed -n '1,20p' /tmp/sfa-skill-usage-na.out >&2
  rm -f /tmp/sfa-skill-usage-na.out
  exit 1
fi
rm -f /tmp/sfa-skill-usage-na.out

printf 'PASS: harness skill usage recorded in %s\n' "$usage_file"
