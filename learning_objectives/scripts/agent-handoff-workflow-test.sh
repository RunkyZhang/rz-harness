#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

expect_file() {
  local path="$1" label="$2"
  if [[ -f "$path" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

repo="$tmp/repo"
mkdir -p "$repo"
repo_real="$(cd "$repo" && pwd -P)"
git -C "$repo" init -q
git -C "$repo" config user.email harness@example.invalid
git -C "$repo" config user.name "Harness Test"

cat >"$repo/README.md" <<'EOF'
# Fixture
EOF
git -C "$repo" add README.md
git -C "$repo" commit -q -m "initial fixture"
base="$(git -C "$repo" rev-parse HEAD)"

cat >"$repo/plan.md" <<'EOF'
# Fixture Plan

## Global Constraints

- Keep all handoff scratch files out of committed diffs.

### Task 1: Build handoff fixture

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: `plan.md`
- Produces: `.harness/agent-work/<change-id>/task-1-brief.md`

- [ ] **Step 1: 独立验证**

Run: `grep -q Fixture README.md`
Expected: PASS

### Task 2: Follow-up fixture

**Files:**
- Modify: `README.md`
EOF

printf '\nchanged\n' >>"$repo/README.md"
git -C "$repo" add README.md
git -C "$repo" commit -q -m "change fixture"
head="$(git -C "$repo" rev-parse HEAD)"

workspace="$("$root/scripts/agent-workspace.sh" "$repo" sample-change)"
if [[ "$workspace" == "$repo_real/.harness/agent-work/sample-change" ]]; then
  pass "agent workspace path is change-scoped inside the repo"
else
  fail "agent workspace path is change-scoped inside the repo"
fi
expect_file "$workspace/.gitignore" "agent workspace is self-ignored"
expect_file "$repo_real/.harness/active-change" "agent workspace writes active change pointer"
if [[ -f "$repo_real/.harness/active-change" ]] && [[ "$(cat "$repo_real/.harness/active-change")" == "sample-change" ]]; then
  pass "active change pointer contains change id"
else
  fail "active change pointer contains change id"
fi
if git -C "$repo" check-ignore -q .harness/active-change \
  && git -C "$repo" check-ignore -q .harness/agent-work/sample-change/task.md; then
  pass "agent workspace scratch paths are ignored"
else
  fail "agent workspace scratch paths are ignored"
fi
expect_file "$workspace/progress-ledger.md" "agent workspace creates progress ledger"
if grep -q '| Task | Status | Owner | Task brief | Implementer report | Review package | Review verdict | Test / evidence | Notes |' "$workspace/progress-ledger.md"; then
  pass "progress ledger carries standard handoff evidence columns"
else
  fail "progress ledger carries standard handoff evidence columns"
fi

brief_output="$("$root/scripts/agent-task-brief.sh" "$repo/plan.md" 1 sample-change)"
brief_path="${brief_output##* }"
expect_file "$brief_path" "task brief is written to agent workspace"
if grep -q '^change_id: sample-change' "$brief_path" \
  && grep -q '^task_number: 1' "$brief_path" \
  && grep -q '^source_plan:' "$brief_path"; then
  pass "task brief includes stable handoff metadata"
else
  fail "task brief includes stable handoff metadata"
fi
if grep -q 'Task 1: Build handoff fixture' "$brief_path" && ! grep -q 'Task 2:' "$brief_path"; then
  pass "task brief extracts only the requested task"
else
  fail "task brief extracts only the requested task"
fi

review_output="$(cd "$repo" && "$root/scripts/agent-review-package.sh" --scope task "$base" "$head" sample-change)"
review_path="${review_output##* }"
expect_file "$review_path" "review package is written to agent workspace"
if grep -q '^review_scope: task' "$review_path" \
  && grep -q '^reviewer_independence: READ_ONLY' "$review_path" \
  && grep -q '^required_verdicts: spec_compliance, code_quality' "$review_path"; then
  pass "review package declares scope and reviewer contract"
else
  fail "review package declares scope and reviewer contract"
fi
if grep -q '^## Commits' "$review_path" \
  && grep -q '^## Files changed' "$review_path" \
  && grep -q '^## Diff' "$review_path"; then
  pass "review package includes commits, stat, and diff"
else
  fail "review package includes commits, stat, and diff"
fi

contract="$root/docs/architecture/agent-handoff-contract.md"
expect_file "$contract" "agent handoff architecture contract exists"
if grep -q 'task-<N>-brief.md' "$contract" \
  && grep -q 'task-<N>-implementer-report.md' "$contract" \
  && grep -q 'progress-ledger.md' "$contract" \
  && grep -q 'review-<scope>-<base>..<head>.diff' "$contract" \
  && grep -q 'spec_compliance' "$contract" \
  && grep -q 'code_quality' "$contract" \
  && grep -q 'READ_ONLY' "$contract"; then
  pass "agent handoff contract defines files and review verdicts"
else
  fail "agent handoff contract defines files and review verdicts"
fi

grep -q '## Global Constraints' "$root/templates/plan-tier-m.md" \
  && grep -q '\*\*Interfaces:\*\*' "$root/templates/plan-tier-m.md" \
  && grep -q '独立验证' "$root/templates/plan-tier-m.md" \
  && pass "plan template carries global constraints, interfaces, and independent verification" \
  || fail "plan template carries global constraints, interfaces, and independent verification"

grep -q '不得预设 Reviewer 结论' "$root/skills/reviewer/SKILL.md" \
  && grep -q '不要报' "$root/skills/reviewer/SKILL.md" \
  && pass "reviewer skill forbids orchestrator pre-judging reviewer findings" \
  || fail "reviewer skill forbids orchestrator pre-judging reviewer findings"

"$root/scripts/harness-bootstrap-smoke.sh" >/dev/null \
  && pass "bootstrap smoke validates AGENTS hooks and skills routing" \
  || fail "bootstrap smoke validates AGENTS hooks and skills routing"

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: agent handoff workflow test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: agent handoff workflow test passed\n'
