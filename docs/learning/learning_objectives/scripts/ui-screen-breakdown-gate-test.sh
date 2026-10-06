#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0
out="$tmp_dir/out"
err="$tmp_dir/err"

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

run_expect_pass() {
  local label="$1"
  shift
  if "$@" >"$out" 2>"$err"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,80p' "$out" >&2 || true
    sed -n '1,80p' "$err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local label="$1" expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$label"
    sed -n '1,80p' "$out" >&2 || true
    return
  fi
  if grep -q "^CODE: ${expected_code}$" "$err"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,80p' "$out" >&2 || true
    sed -n '1,80p' "$err" >&2 || true
  fi
}

if grep -q 'prd_screen_breakdown_status' "$root/templates/ui-rule-checklist.md" \
  && grep -q 'PRD 截图逐屏拆解表' "$root/templates/ui-rule-checklist.md" \
  && grep -q 'Side-by-side' "$root/templates/ui-rule-checklist.md"; then
  pass "ui rule checklist template includes screen breakdown fields"
else
  fail "ui rule checklist template includes screen breakdown fields"
fi

ready="$tmp_dir/ready"
mkdir -p "$ready"
cat >"$ready/ui-rule-checklist.md" <<'SPEC'
# UI Rule Checklist：demo

```yaml
ui_rule_status: READY
owner: Frontend Agent
updated_at: 2026-07-02
rule_gap_status: NONE
prd_screen_breakdown_status: READY
```

## 规则与基线

| Item | Path / URL | Status | Notes |
| --- | --- | --- | --- |
| PRD UI source | Feishu image UI-01 | READ | demo |
| Online baseline | Existing detail page screenshot | CAPTURED | demo |
| Harness rule pack | rules/frontend-vue2.mdc | READ | demo |
| Existing page sample | src/views/demo/list.vue | READ | demo |

## PRD 截图逐屏拆解表

| Screenshot ID | PRD screenshot reference | Area breakdown | Target skeleton / class mapping | Difference from sample | Decision | Status |
| --- | --- | --- | --- | --- | --- | --- |
| UI-001 | Feishu image UI-01 | header/search/table/pagination | new-search-wrapper/customerlist-table | one extra action button | reuse existing action slot | READY |

## UI 规范映射

| UI / Interaction | PRD expectation | Harness rule / baseline | Covered by rule? | Decision |
| --- | --- | --- | --- | --- |
| Search table | match PRD | frontend-vue2.mdc | yes | reuse existing pattern |

## 规范缺口

| Gap ID | Gap | Options considered | User decision | Status |
| --- | --- | --- | --- | --- |

## Side-by-side 验收证据计划

| Screenshot ID | PRD screenshot | Implementation screenshot target | Difference marker | Status |
| --- | --- | --- | --- | --- |
| UI-001 | Feishu image UI-01 | artifacts/demo/ui/ui-001-impl.png | none expected | PLANNED |
SPEC

run_expect_pass "ui rule gate accepts ready screen breakdown" \
  "$root/scripts/ui-rule-gate.sh" "$ready"

blocked="$tmp_dir/blocked"
mkdir -p "$blocked"
cp "$ready/ui-rule-checklist.md" "$blocked/ui-rule-checklist.md"
sed 's/| UI-001 | Feishu image UI-01 | header/| UI-001 | Feishu image UI-01 | header/; s/| READY |$/| BLOCKED |/' "$ready/ui-rule-checklist.md" >"$blocked/ui-rule-checklist.md"
run_expect_fail_with_code "ui rule gate blocks blocked screen breakdown row" \
  "UI_RULE_GATE/BLOCKED_SCREEN_BREAKDOWN" \
  "$root/scripts/ui-rule-gate.sh" "$blocked"

missing="$tmp_dir/missing"
mkdir -p "$missing"
awk '$0 !~ /PRD 截图逐屏拆解表/ && $0 !~ /^\\| Screenshot ID / && $0 !~ /^\\| UI-001 /' "$ready/ui-rule-checklist.md" >"$missing/ui-rule-checklist.md"
run_expect_fail_with_code "ui rule gate blocks missing screen breakdown section" \
  "UI_RULE_GATE/MISSING_SCREEN_BREAKDOWN" \
  "$root/scripts/ui-rule-gate.sh" "$missing"

na="$tmp_dir/na"
mkdir -p "$na"
cat >"$na/ui-rule-checklist.md" <<'SPEC'
# UI Rule Checklist：demo

```yaml
ui_rule_status: READY
rule_gap_status: NOT_APPLICABLE
prd_screen_breakdown_status: NOT_APPLICABLE
```

## 规则与基线

| Item | Path / URL | Status | Notes |
| --- | --- | --- | --- |
| PRD UI source | N/A: no screenshot | N/A | no UI |

## UI 规范映射

| UI / Interaction | PRD expectation | Harness rule / baseline | Covered by rule? | Decision |
| --- | --- | --- | --- | --- |
| N/A | N/A | N/A | yes | N/A: no screenshot UI |
SPEC
run_expect_pass "ui rule gate accepts not-applicable screen breakdown" \
  "$root/scripts/ui-rule-gate.sh" "$na"

if grep -q 'PRD 截图逐屏拆解' "$root/templates/technical-solution.md"; then
  pass "technical solution template references UI screen breakdown"
else
  fail "technical solution template references UI screen breakdown"
fi

if grep -q 'scripts/ui-screen-breakdown-gate-test.sh' "$root/docs/README.md"; then
  pass "docs index lists ui screen breakdown gate test"
else
  fail "docs index lists ui screen breakdown gate test"
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: ui screen breakdown gate test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: ui screen breakdown gate test passed\n'
