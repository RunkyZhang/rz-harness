#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
failures=0

expect_contains() {
  local file="$1" pattern="$2" label="$3"
  if ! grep -Eq "$pattern" "$root/$file"; then
    printf 'FAIL: %s missing pattern %s in %s\n' "$label" "$pattern" "$file" >&2
    failures=$((failures + 1))
  fi
}

expect_contains "AGENTS.md" '用户.*开始开发|开始开发' "strict workflow note"
expect_contains "AGENTS.md" 'harness-status\.md' "status update rule"
expect_contains "AGENTS.md" 'phase changes|阶段变化' "status phase-change rule"
expect_contains "AGENTS.md" 'Reviewer Agent' "reviewer stale rule"
expect_contains "AGENTS.md" 'code changes|业务代码变化' "business-code stale rule"
expect_contains "AGENTS.md" 'Agent Label: <change-id> / <role> / <scope>' "agent label rule"

expect_contains "templates/harness-status.md" '^## Agent Roster$' "agent roster section"
expect_contains "templates/harness-status.md" 'Runtime / Nickname' "runtime nickname column"
expect_contains "templates/harness-status.md" 'STALE' "stale agent status"

expect_contains "templates/technical-solution.md" '^## 确认前无模糊实现细节自检$' "no-ambiguity checklist"
expect_contains "templates/technical-solution.md" '接口字段来源' "field source check"
expect_contains "templates/technical-solution.md" '前端 UI 细节' "frontend UI detail check"
expect_contains "templates/technical-solution.md" 'DB / BD 设计' "DB/BD check"
expect_contains "templates/technical-solution.md" '跨页面入口' "cross-page entry check"

expect_contains "docs/standards/subagent-dispatch.md" 'Agent Label: <change-id> / <role> / <scope>' "subagent label standard"
expect_contains "docs/standards/subagent-dispatch.md" 'Final reply first line' "subagent output contract"
expect_contains "docs/standards/subagent-dispatch.md" 'STALE' "subagent stale rule"

expect_contains "AGENTS.md" 'local-service-lifecycle\.sh' "local backend lifecycle standard"
expect_contains "AGENTS.md" 'HEALTH=UP' "no false ready claim"
expect_contains "docs/onboarding/local-dev-environment.md" 'Successful `restart` or launch-command return alone is insufficient' "launch return is insufficient"
expect_contains "templates/temporary-state-ledger.md" 'Lifecycle tooling must not automatically create or update this ledger' "lifecycle tooling does not auto-update ledger"
expect_contains "templates/temporary-state-ledger.md" 'JAR_MTIME' "verified local service evidence"
expect_contains "docs/onboarding/local-dev-environment.md" 'check-web-stack' "web stack verification command"

if (( failures > 0 )); then
  printf 'FAIL: harness process contract test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness process contract test passed\n'
