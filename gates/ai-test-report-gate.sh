#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/ai-test-report-gate.sh <ai-test-report.md | change-dir>

Fails closed unless the AI test report contains:
  - a confirmed ai-test-plan.md in the same change dir
  - a Test Agent verification report with verification_status: GOAL_ACHIEVED
  confirmation_status: CONFIRMED
  recommendation: 允许进入预发
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
  "AI_TEST_REPORT_GATE/MISSING_PATH" \
  "missing AI test report path" \
  "Pass changes/<change-id>/ai-test-report.md or changes/<change-id>/." \
  "templates/ai-test-report.md"

if [[ -d "$target" ]]; then
  report="$target/ai-test-report.md"
  change_dir="$target"
else
  report="$target"
  change_dir="$(dirname "$target")"
fi

[[ -f "$report" ]] || fail \
  "AI_TEST_REPORT_GATE/MISSING_FILE" \
  "AI test report file not found: $report" \
  "Create the AI test report from templates/ai-test-report.md after AI verification, then get human confirmation before pre-release." \
  "changes/<change-id>/ai-test-report.md"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

"$script_dir/ai-test-plan-gate.sh" "$change_dir" || fail \
  "AI_TEST_REPORT_GATE/TEST_PLAN_NOT_CONFIRMED" \
  "AI test plan gate failed" \
  "Confirm changes/<change-id>/ai-test-plan.md before final AI test report confirmation." \
  "scripts/ai-test-plan-gate.sh changes/<change-id>"

"$script_dir/test-agent-verification-gate.sh" "$change_dir" || fail \
  "AI_TEST_REPORT_GATE/TEST_AGENT_NOT_VERIFIED" \
  "Test Agent verification gate failed" \
  "Run the Main Agent fix / Test Agent retest loop until verification_status: GOAL_ACHIEVED." \
  "scripts/test-agent-verification-gate.sh changes/<change-id>"

if ! grep -qF "ai-test-plan.md" "$report"; then
  fail \
    "AI_TEST_REPORT_GATE/MISSING_TEST_PLAN_REFERENCE" \
    "AI test report does not reference ai-test-plan.md" \
    "Add a test plan reference section to the report." \
    "Test plan: changes/<change-id>/ai-test-plan.md"
fi

if ! grep -qF "test-agent-verification.md" "$report"; then
  fail \
    "AI_TEST_REPORT_GATE/MISSING_TEST_AGENT_REFERENCE" \
    "AI test report does not reference test-agent-verification.md" \
    "Add a Test Agent verification reference section to the report." \
    "Test Agent verification: changes/<change-id>/test-agent-verification.md"
fi

status="$(field_value "$report" "confirmation_status")"
recommendation="$(field_value "$report" "recommendation")"

if [[ "$status" != "CONFIRMED" ]]; then
  fail \
    "AI_TEST_REPORT_GATE/PENDING_CONFIRMATION" \
    "AI test report confirmation_status is '${status:-missing}', not CONFIRMED" \
    "Ask the human reviewer to review test cases, screenshots, API/SQL evidence, residual risks, and update confirmation_status / confirmed_by / confirmed_at." \
    "confirmation_status: CONFIRMED"
fi

if [[ "$recommendation" != "允许进入预发" ]]; then
  fail \
    "AI_TEST_REPORT_GATE/PRE_RELEASE_NOT_ALLOWED" \
    "AI test report recommendation is '${recommendation:-missing}', not '允许进入预发'" \
    "Only proceed to pre-release after the report explicitly recommends pre-release and the human confirmation is CONFIRMED." \
    "recommendation: 允许进入预发"
fi

printf 'PASS: AI test report confirmed for %s; recommendation=%s\n' "$report" "$recommendation"
