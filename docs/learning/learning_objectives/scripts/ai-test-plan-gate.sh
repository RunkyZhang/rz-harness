#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/ai-test-plan-gate.sh <ai-test-plan.md | change-dir>

Fails closed unless the AI test plan contains:
  - test_plan_status: CONFIRMED
  - source references, test matrix, boundary scenarios, UI checks, token-risk notes
  - no unresolved placeholders
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

require_text() {
  local file="$1" text="$2" code="$3" message="$4"
  if ! grep -qF "$text" "$file"; then
    fail "$code" "$message" "Add the missing section/content before confirming the test plan." "$text"
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

target="${1:-}"
[[ -n "$target" ]] || fail \
  "AI_TEST_PLAN_GATE/MISSING_PATH" \
  "missing AI test plan path" \
  "Pass changes/<change-id>/ai-test-plan.md or changes/<change-id>/." \
  "templates/ai-test-plan.md"

if [[ -d "$target" ]]; then
  plan="$target/ai-test-plan.md"
else
  plan="$target"
fi

[[ -f "$plan" ]] || fail \
  "AI_TEST_PLAN_GATE/MISSING_FILE" \
  "AI test plan file not found: $plan" \
  "Create it from templates/ai-test-plan.md and get explicit user confirmation." \
  "changes/<change-id>/ai-test-plan.md"

status="$(field_value "$plan" "test_plan_status")"
if [[ "$status" != "CONFIRMED" ]]; then
  fail \
    "AI_TEST_PLAN_GATE/PENDING_CONFIRMATION" \
    "test_plan_status is '${status:-missing}', not CONFIRMED" \
    "Have the user review the test plan, then update test_plan_status / confirmed_by / confirmed_at / confirmed_scope." \
    "test_plan_status: CONFIRMED"
fi

require_text "$plan" "## 来源" "AI_TEST_PLAN_GATE/MISSING_SOURCES" "test plan must cite PRD / technical solution / contract sources"
require_text "$plan" "## 系统运行依据" "AI_TEST_PLAN_GATE/MISSING_RUNTIME_BASIS" "test plan must reference readiness runtime standards and topology"
require_text "$plan" "## 测试用例矩阵" "AI_TEST_PLAN_GATE/MISSING_CASE_MATRIX" "test plan must contain a test case matrix"
require_text "$plan" "## 边界场景" "AI_TEST_PLAN_GATE/MISSING_BOUNDARIES" "test plan must contain boundary scenarios"
require_text "$plan" "## UI 检查" "AI_TEST_PLAN_GATE/MISSING_UI_CHECKS" "test plan must contain UI checks"
require_text "$plan" "## 高 token 风险提示" "AI_TEST_PLAN_GATE/MISSING_TOKEN_RISK" "test plan must contain high token-risk notes"

case_count="$(grep -cE '^\|[[:space:]]*TC-[0-9]+' "$plan" || true)"
if [[ "$case_count" -eq 0 ]]; then
  fail \
    "AI_TEST_PLAN_GATE/EMPTY_CASE_MATRIX" \
    "test plan has no TC-* rows" \
    "Add at least one executable test case row." \
    "| TC-001 | P0 | <role> | <end> | <scenario> | ..."
fi

if grep -nE '\b(TODO|TBD)\b|待补|未定|<[^>]+>' "$plan" >/tmp/sfa-ai-test-plan-placeholders.out; then
  printf 'Unresolved placeholders:\n' >&2
  sed -n '1,20p' /tmp/sfa-ai-test-plan-placeholders.out >&2
  rm -f /tmp/sfa-ai-test-plan-placeholders.out
  fail \
    "AI_TEST_PLAN_GATE/UNRESOLVED_PLACEHOLDER" \
    "AI test plan contains unresolved placeholders" \
    "Replace placeholders with concrete sources, cases, evidence targets, or explicit N/A reasons." \
    "templates/ai-test-plan.md"
fi
rm -f /tmp/sfa-ai-test-plan-placeholders.out

if grep -nE -i '(password[[:space:]]*[:=]|passwd[[:space:]]*[:=]|pwd[[:space:]]*[:=]|authorization[[:space:]]*[:=]|bearer[[:space:]]+[A-Za-z0-9._-]+|mysql://|jdbc:|rm-[A-Za-z0-9.-]+:[0-9]+|access[_ -]?token[[:space:]]*[:=]|refresh[_ -]?token[[:space:]]*[:=])' "$plan" >/tmp/sfa-ai-test-plan-sensitive.out; then
  printf 'Potential sensitive values:\n' >&2
  sed -n '1,20p' /tmp/sfa-ai-test-plan-sensitive.out >&2
  rm -f /tmp/sfa-ai-test-plan-sensitive.out
  fail \
    "AI_TEST_PLAN_GATE/SENSITIVE_CONTENT" \
    "AI test plan appears to contain reusable credentials or connection details" \
    "Remove secrets and record only credential source / environment owner." \
    "Credential source: Keychain / Feishu permission doc / user-provided at runtime"
fi
rm -f /tmp/sfa-ai-test-plan-sensitive.out

printf 'PASS: AI test plan confirmed in %s (%s case row(s))\n' "$plan" "$case_count"
