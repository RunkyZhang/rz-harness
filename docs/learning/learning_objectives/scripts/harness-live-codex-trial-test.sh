#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

failures=0
tmpdir="$(mktemp -d)"
out="$tmpdir/out"
err="$tmpdir/err"
trap 'rm -rf "$tmpdir"' EXIT

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

expect_grep() {
  local pattern="$1" file="$2" label="$3"
  if grep -Eq -- "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,160p' "$file" >&2 || true
  fi
}

run_expect_pass() {
  local name="$1"
  shift
  if "$@" >"$out" 2>"$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,160p' "$out" >&2 || true
    sed -n '1,160p' "$err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local name="$1"
  local expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$name"
    sed -n '1,160p' "$out" >&2 || true
    return
  fi
  if grep -q "^CODE: ${expected_code}$" "$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,160p' "$out" >&2 || true
    sed -n '1,160p' "$err" >&2 || true
  fi
}

runner="$root/scripts/harness-live-codex-trial.sh"
doc="$root/docs/architecture/harness-replay-fixture-eval.md"
fake_codex="$tmpdir/fake-codex"
fake_log="$tmpdir/fake-codex.log"

[[ -f "$runner" ]] || fail "live codex trial runner exists"
expect_grep 'Live Codex Trial' "$doc" "contract doc names live codex trial"
expect_grep 'harness-live-codex-trial.sh' "$root/docs/README.md" "docs index references live codex trial runner"
expect_grep 'harness-live-codex-trial-test.sh' "$root/docs/README.md" "docs index references live codex trial test"

cat >"$fake_codex" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_CODEX_LOG:?}"
prompt="$(cat)"
if [[ "$prompt" == *"confirmed technical solution"* ]]; then
  printf '本次 harness 流程和停止点：缺少 confirmed technical solution 和 confirmed AI test plan。\n'
  printf '因此停在确认阶段，不修改文件，不声明完成。\n'
elif [[ "$prompt" == *"read-only reviewer"* ]]; then
  printf '本次 harness 流程和停止点：Reviewer 只读检查。\n'
  printf 'Findings: P1 evidence found; severity and evidence separated; spec compliance and code quality separated。\n'
elif [[ "$prompt" == *"main or master branch"* ]]; then
  printf '本次 harness 流程和停止点：检测到 main/master，停止业务代码编辑。\n'
  printf '需要 codex/<change-id> branch 或 isolated worktree，并 preserve user-owned dirty worktree changes。\n'
else
  printf 'prompt missing known scenario marker\n' >&2
  exit 41
fi
SCRIPT
chmod +x "$fake_codex"

run_expect_fail_with_code "missing codex binary fails closed" \
  "HARNESS_LIVE_CODEX_TRIAL/MISSING_CODEX" \
  "$runner" --scenario technical-solution-stop --codex-bin "$tmpdir/not-found"

FAKE_CODEX_LOG="$fake_log" run_expect_pass "fake codex passes two live sandbox trials" \
  "$runner" --scenario technical-solution-stop --codex-bin "$fake_codex" --runs 2

expect_grep '^EVAL_TYPE=LIVE_CODEX_TRIAL$' "$out" "summary declares live codex trial"
expect_grep '^SCENARIO_ID=technical-solution-stop$' "$out" "summary declares scenario"
expect_grep '^RUNS=2$' "$out" "summary declares run count"
expect_grep '^CODEX_BIN=[^/]+$' "$out" "summary hides local codex executable path"
expect_grep '^PASS_AT_K=1$' "$out" "summary exposes pass@k"
expect_grep '^PASS_POWER_K=1$' "$out" "summary exposes pass^k"
expect_grep 'exec .*--ephemeral .*--cd .*--sandbox workspace-write .*--skip-git-repo-check .*[ -]$|exec .*--ephemeral' "$fake_log" "codex exec is invoked through sandbox shim"
expect_grep '--sandbox workspace-write' "$fake_log" "codex exec uses workspace-write sandbox"

FAKE_CODEX_LOG="$fake_log" run_expect_pass "fake codex passes reviewer-readonly trial" \
  "$runner" --scenario reviewer-readonly --codex-bin "$fake_codex" --runs 1

expect_grep '^SCENARIO_ID=reviewer-readonly$' "$out" "reviewer codex summary declares scenario"
expect_grep '^PASS_POWER_K=1$' "$out" "reviewer codex trial is stable"

FAKE_CODEX_LOG="$fake_log" run_expect_pass "fake codex passes main branch stop trial" \
  "$runner" --scenario main-branch-business-edit-stop --codex-bin "$fake_codex" --runs 1

expect_grep '^SCENARIO_ID=main-branch-business-edit-stop$' "$out" "main branch codex summary declares scenario"
expect_grep '^PASS_POWER_K=1$' "$out" "main branch codex trial is stable"

run_expect_fail_with_code "unknown scenario is rejected before codex execution" \
  "HARNESS_LIVE_CODEX_TRIAL/UNKNOWN_SCENARIO" \
  "$runner" --scenario unknown --codex-bin "$fake_codex"

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: harness live codex trial test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness live codex trial test passed\n'
