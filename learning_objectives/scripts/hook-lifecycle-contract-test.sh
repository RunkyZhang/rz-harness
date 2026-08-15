#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
contract="$root/docs/architecture/hook-lifecycle-contract.md"
failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

expect_grep() {
  local pattern="$1" file="$2" label="$3"
  if grep -Eq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

if [[ -f "$contract" ]]; then
  pass "hook lifecycle contract exists"
else
  fail "hook lifecycle contract exists"
fi

if [[ -f "$contract" ]]; then
  expect_grep 'runtime_changes_allowed:[[:space:]]*false' "$contract" "contract forbids runtime changes in docs-only phase"
  expect_grep 'SessionStart' "$contract" "contract covers SessionStart"
  expect_grep 'PreToolUse' "$contract" "contract covers PreToolUse"
  expect_grep 'PostToolUse' "$contract" "contract covers PostToolUse"
  expect_grep 'Stop' "$contract" "contract covers Stop"
  expect_grep 'PreCompact' "$contract" "contract covers PreCompact"
  expect_grep 'Codex' "$contract" "contract covers Codex adapter"
  expect_grep 'Cursor' "$contract" "contract covers Cursor adapter"
  expect_grep 'OpenCode' "$contract" "contract covers OpenCode adapter"
  expect_grep 'RUNNER_ONLY' "$contract" "contract distinguishes runner-only support"
  expect_grep 'ADAPTER_WIRED' "$contract" "contract distinguishes wired adapter support"
  expect_grep 'NOT_SUPPORTED' "$contract" "contract distinguishes unsupported lifecycle events"
  expect_grep 'can_block' "$contract" "contract declares lifecycle block semantics"
  expect_grep '`pre`' "$contract" "contract distinguishes pre-event hard blocking"
  expect_grep '`post`' "$contract" "contract distinguishes post-event warning semantics"
  expect_grep '`none`' "$contract" "contract distinguishes non-blocking lifecycle events"
  expect_grep 'max_context_lines:[[:space:]]*30' "$contract" "contract caps future SessionStart context lines"
  expect_grep 'max_context_chars:[[:space:]]*2000' "$contract" "contract caps future SessionStart context chars"
  expect_grep 'Do not modify `.codex/hooks.json`' "$contract" "contract protects Codex hook runtime"
  expect_grep 'Do not modify `.cursor/hooks.json`' "$contract" "contract protects Cursor hook runtime"
  expect_grep 'Do not modify `scripts/harness-sensor-runner.sh`' "$contract" "contract protects sensor runner runtime"
fi

expect_grep 'hook-lifecycle-contract.md' "$root/docs/README.md" "docs index references hook lifecycle contract"
expect_grep 'hook-lifecycle-contract-test.sh' "$root/docs/README.md" "docs index references hook lifecycle test"

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: hook lifecycle contract test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: hook lifecycle contract test passed\n'
