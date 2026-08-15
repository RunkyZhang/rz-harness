#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

run_expect_pass() {
  local name="$1"
  shift
  if "$@" >"$out" 2>"$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,40p' "$out" >&2 || true
    sed -n '1,40p' "$err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local name="$1"
  local expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$name"
    sed -n '1,40p' "$out" >&2 || true
    return
  fi

  if grep -q "^CODE: ${expected_code}$" "$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,40p' "$out" >&2 || true
    sed -n '1,40p' "$err" >&2 || true
  fi
}

tmpdir="$(mktemp -d)"
out="$tmpdir/out"
err="$tmpdir/err"
trap 'rm -rf "$tmpdir"' EXIT

optional_dir="$tmpdir/tier-s"
mkdir -p "$optional_dir"
cat >"$optional_dir/harness-status.md" <<'MARKDOWN'
artifact_profile: tier-s
MARKDOWN
run_expect_pass "retro gate allows missing retro for tier-s" \
  "$root/scripts/retro-gate.sh" "$optional_dir"

required_dir="$tmpdir/tier-m-missing"
mkdir -p "$required_dir"
cat >"$required_dir/harness-status.md" <<'MARKDOWN'
artifact_profile: tier-m
MARKDOWN
run_expect_fail_with_code "retro gate requires retro for tier-m" \
  "RETRO/MISSING_REQUIRED" \
  "$root/scripts/retro-gate.sh" "$required_dir"

valid_dir="$tmpdir/valid-retro"
mkdir -p "$valid_dir"
cat >"$valid_dir/harness-status.md" <<'MARKDOWN'
artifact_profile: tier-m
MARKDOWN
cat >"$valid_dir/retro.md" <<'MARKDOWN'
# Retro：sample-change

```yaml
change_id: sample-change
retro_status: READY
retro_required: yes
change_tier: M
risk_trigger_status: READY
total_rework_count: 1
gate_trigger_count: 4
gate_false_positive_count: 0
reviewer_high_risk_count: 0
user_correction_count: 1
instinct_candidate_count: 1
knowledge_updates_status: READY
```

## 触发条件

| Trigger | Applies? | Evidence |
| --- | --- | --- |
| Tier M/L | yes | harness-status.md |

## 关键指标

| Metric | Value | Evidence |
| --- | --- | --- |
| total_rework_count | 1 | evidence.md |

## 用户纠正与返工

| ID | Source | Correction / Rework | Cause | Follow-up | Status |
| --- | --- | --- | --- | --- | --- |
| UC-001 | user | 补充 verification-run | static map could not execute | add runner | CLOSED |

## Gate 触发与误报

| Gate | Trigger count | False positive count | Action | Status |
| --- | --- | --- | --- | --- |
| verification-map-gate.sh | 1 | 0 | keep | READY |

## 规则升级 / 不升级决策

| ID | Candidate | Source | Decision | Reason | Status |
| --- | --- | --- | --- | --- | --- |
| IC-001 | Add verification-run runner contract | UC-001 | promote to template/script | repeated static-map gap | READY |

## 知识沉淀

| Target | Action | Status |
| --- | --- | --- |
| templates/verification-map.md | updated runner contract | READY |
MARKDOWN
run_expect_pass "retro gate accepts complete required retro" \
  "$root/scripts/retro-gate.sh" "$valid_dir"

pending_dir="$tmpdir/pending-retro"
cp -R "$valid_dir" "$pending_dir"
LC_ALL=C LC_CTYPE=C LANG=C perl -0pi -e 's/retro_status: READY/retro_status: PENDING/' "$pending_dir/retro.md"
run_expect_fail_with_code "retro gate blocks non-ready retro" \
  "RETRO/NOT_READY" \
  "$root/scripts/retro-gate.sh" "$pending_dir"

placeholder_dir="$tmpdir/placeholder-retro"
cp -R "$valid_dir" "$placeholder_dir"
printf '\nTODO: summarize later\n' >>"$placeholder_dir/retro.md"
run_expect_fail_with_code "retro gate blocks placeholders" \
  "RETRO/UNRESOLVED_PLACEHOLDER" \
  "$root/scripts/retro-gate.sh" "$placeholder_dir"

missing_ic_dir="$tmpdir/missing-ic-retro"
cp -R "$valid_dir" "$missing_ic_dir"
LC_ALL=C LC_CTYPE=C LANG=C perl -0pi -e 's/^\| IC-001 .*\n//m' "$missing_ic_dir/retro.md"
run_expect_fail_with_code "retro gate requires instinct candidate rows when count is positive" \
  "RETRO/MISSING_INSTINCT_CANDIDATE" \
  "$root/scripts/retro-gate.sh" "$missing_ic_dir"

run_expect_pass "retro gate required flag forces missing retro to fail" \
  "$root/scripts/retro-gate.sh" --required "$valid_dir"

if grep -q 'templates/retro.md' docs/README.md \
  && grep -q 'scripts/retro-gate.sh' docs/README.md \
  && grep -q 'scripts/retro-gate-test.sh' docs/README.md \
  && grep -q 'retro-gate.sh' scripts/change-stage-gate.sh; then
  pass "docs and closeout stage reference retro gate"
else
  fail "docs and closeout stage reference retro gate"
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: retro gate test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: retro gate test passed\n'
