#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file AGENTS.md
require_file docs/README.md
require_file lanes/fullstack-crud.md
require_file scripts/harness-self-audit.sh

if awk 'length($0) > 360 { print FNR ":" length($0) ":" $0; found=1 } END { exit found ? 1 : 0 }' AGENTS.md >/tmp/harness-gc-agents-lines.$$; then
  pass "AGENTS lines stay scan-friendly"
else
  cat /tmp/harness-gc-agents-lines.$$ >&2
  rm -f /tmp/harness-gc-agents-lines.$$
  fail "AGENTS.md has over-dense lines; move details to docs or lane files"
fi
rm -f /tmp/harness-gc-agents-lines.$$

default_flow="$(awk '
  /^## 默认最小流程/ { in_section=1; next }
  /^## Optional Packs/ { in_section=0 }
  in_section { print }
' lanes/fullstack-crud.md)"

[[ -n "$default_flow" ]] || fail "fullstack CRUD lane must define ## 默认最小流程"

for heavy in \
  "ai-test-plan.md" \
  "environment-readiness.md" \
  "local-dev-readiness.md" \
  "ui-rule-checklist.md" \
  "pc-e2e-smoke" \
  "test-agent-verification.md" \
  "ai-test-report.md" \
  "temporary-state-ledger.md"; do
  if grep -q "$heavy" <<<"$default_flow"; then
    fail "fullstack CRUD default flow must not require trigger-based pack artifact: $heavy"
  fi
done
pass "fullstack CRUD default flow is minimal"

for required_pack in "UI Pack" "E2E Pack" "Test Agent Pack" "Environment Pack" "Temporary State Pack"; do
  grep -q "$required_pack" lanes/fullstack-crud.md || fail "fullstack CRUD lane must document optional pack: $required_pack"
done
pass "fullstack CRUD optional packs are documented"

grep -q '| 脚本 | layer | trigger | required_by | owner | last_validated | 用途 | 当前状态 |' docs/README.md \
  || fail "Sensors table must include layer/trigger/required_by/owner/last_validated metadata"
pass "Sensors table has lifecycle metadata columns"

grep -q 'scripts/harness-gc-test.sh' scripts/harness-self-audit.sh \
  || fail "self-audit must call harness-gc-test.sh instead of carrying GC checks inline"
pass "self-audit delegates harness GC checks"

printf 'PASS: harness GC test passed\n'
