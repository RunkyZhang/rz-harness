#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/test-agent-verification-gate.sh <test-agent-verification.md | change-dir>

Fails closed unless the independent Test Agent verification contains:
  - verification_status: GOAL_ACHIEVED
  - final_decision: GOAL_ACHIEVED
  - no open/blocking P0/P1/P2 issues
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

target="${1:-}"
[[ -n "$target" ]] || fail \
  "TEST_AGENT_VERIFICATION/MISSING_PATH" \
  "missing test-agent verification path" \
  "Pass changes/<change-id>/test-agent-verification.md or changes/<change-id>/." \
  "templates/test-agent-verification.md"

if [[ -d "$target" ]]; then
  verification="$target/test-agent-verification.md"
else
  verification="$target"
fi

[[ -f "$verification" ]] || fail \
  "TEST_AGENT_VERIFICATION/MISSING_FILE" \
  "test-agent verification file not found: $verification" \
  "Create it from templates/test-agent-verification.md and have the Test Agent independently verify the work." \
  "changes/<change-id>/test-agent-verification.md"

status="$(field_value "$verification" "verification_status")"
final_decision="$(field_value "$verification" "final_decision")"

if [[ "$status" != "GOAL_ACHIEVED" ]]; then
  fail \
    "TEST_AGENT_VERIFICATION/GOAL_NOT_ACHIEVED" \
    "verification_status is '${status:-missing}', not GOAL_ACHIEVED" \
    "Continue the Main Agent fix / Test Agent retest loop, or mark BLOCKED with blocker details." \
    "verification_status: GOAL_ACHIEVED"
fi

if [[ "$final_decision" != "GOAL_ACHIEVED" ]]; then
  fail \
    "TEST_AGENT_VERIFICATION/FINAL_DECISION_NOT_ACHIEVED" \
    "final_decision is '${final_decision:-missing}', not GOAL_ACHIEVED" \
    "Have the Test Agent record final_decision: GOAL_ACHIEVED after independent retest." \
    "final_decision: GOAL_ACHIEVED"
fi

if ! grep -qE '^\|[[:space:]]*Issue ID[[:space:]]*\|[[:space:]]*Severity[[:space:]]*\|[[:space:]]*Source Case[[:space:]]*\|[[:space:]]*Expected[[:space:]]*\|[[:space:]]*Actual[[:space:]]*\|[[:space:]]*Evidence[[:space:]]*\|[[:space:]]*Returned to Main Agent[[:space:]]*\|[[:space:]]*Retest Result[[:space:]]*\|[[:space:]]*Status[[:space:]]*\|' "$verification"; then
  fail \
    "TEST_AGENT_VERIFICATION/MISSING_ISSUE_TABLE" \
    "issue table header is missing or has wrong columns" \
    "Use templates/test-agent-verification.md issue table columns exactly." \
    "| Issue ID | Severity | Source Case | Expected | Actual | Evidence | Returned to Main Agent | Retest Result | Status |"
fi

if awk -F'|' '
  /^\|[[:space:]]*TAV-[0-9]+/ {
    severity=$3
    status=$10
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", severity)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
    if (severity ~ /^P[0-2]$/ && status ~ /^(OPEN|BLOCKED)$/) {
      print NR ":" $0
    }
  }
' "$verification" >/tmp/sfa-test-agent-open-blocking.out; then
  if [[ -s /tmp/sfa-test-agent-open-blocking.out ]]; then
    printf 'Open blocking issues:\n' >&2
    sed -n '1,20p' /tmp/sfa-test-agent-open-blocking.out >&2
    rm -f /tmp/sfa-test-agent-open-blocking.out
    fail \
      "TEST_AGENT_VERIFICATION/OPEN_BLOCKING_ISSUES" \
      "test-agent verification contains open/blocking P0/P1/P2 issue(s)" \
      "Return the issue(s) to Main Agent, fix, rerun regular tests, then have Test Agent retest." \
      "| TAV-001 | P1 | TC-001 | ... | FIXED |"
  fi
fi
rm -f /tmp/sfa-test-agent-open-blocking.out

if grep -nE '\b(TODO|TBD)\b|待补|未定|<[^>]+>' "$verification" >/tmp/sfa-test-agent-placeholders.out; then
  printf 'Unresolved placeholders:\n' >&2
  sed -n '1,20p' /tmp/sfa-test-agent-placeholders.out >&2
  rm -f /tmp/sfa-test-agent-placeholders.out
  fail \
    "TEST_AGENT_VERIFICATION/UNRESOLVED_PLACEHOLDER" \
    "test-agent verification contains unresolved placeholders" \
    "Replace placeholders with concrete rounds, issues, retest evidence, or explicit N/A reasons." \
    "templates/test-agent-verification.md"
fi
rm -f /tmp/sfa-test-agent-placeholders.out

printf 'PASS: Test Agent verified goal achieved in %s\n' "$verification"

