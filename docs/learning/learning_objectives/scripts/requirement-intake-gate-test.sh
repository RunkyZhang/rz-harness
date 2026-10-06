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

if [[ -f "$root/templates/requirement-intake.md" ]] \
  && grep -q 'requirement_intake_status' "$root/templates/requirement-intake.md" \
  && grep -q '业务对象' "$root/templates/requirement-intake.md"; then
  pass "requirement intake template exists with key fields"
else
  fail "requirement intake template exists with key fields"
fi

missing_change="$tmp_dir/missing-change"
mkdir -p "$missing_change"
run_expect_fail_with_code "requirement intake gate blocks missing artifact" \
  "REQUIREMENT_INTAKE/MISSING_FILE" \
  "$root/scripts/requirement-intake-gate.sh" "$missing_change"

pending_change="$tmp_dir/pending-change"
mkdir -p "$pending_change"
cat >"$pending_change/requirement-intake.md" <<'SPEC'
# Requirement Intake

requirement_intake_status: PENDING
prd_item_count: 1
key_questions_complete: yes
blocking_questions_status: RESOLVED

| Category | Answer / Source | Status |
| --- | --- | --- |
| 业务对象 | [FACT] demo | READY |
| 入口和角色 | [FACT] demo | READY |
| CRUD 范围 | [FACT] demo | READY |
| 字段口径 | [FACT] demo | READY |
| DB/权限/状态机/MQ/job 涉及面 | [FACT] demo | READY |
| 最小回滚 | [FACT] demo | READY |
SPEC
run_expect_fail_with_code "requirement intake gate blocks non-ready status" \
  "REQUIREMENT_INTAKE/STATUS_NOT_READY" \
  "$root/scripts/requirement-intake-gate.sh" "$pending_change"

ready_change="$tmp_dir/ready-change"
mkdir -p "$ready_change"
cat >"$ready_change/requirement-intake.md" <<'SPEC'
# Requirement Intake

requirement_intake_status: READY
prd_item_count: 2
key_questions_complete: yes
blocking_questions_status: RESOLVED

## PRD 逐条编号表

| ID | PRD item | Source | Classification | Status |
| --- | --- | --- | --- | --- |
| PRD-001 | 新增字段展示 | 飞书 PRD §1 | [FACT] | READY |
| PRD-002 | 保存按钮权限 | 用户确认 2026-07-02 | [FACT] | READY |

## 六类关键问题

| Category | Answer / Source | Status |
| --- | --- | --- |
| 业务对象 | [FACT] 特陈任务 | READY |
| 入口和角色 | [FACT] PC 管理后台 / BD | READY |
| CRUD 范围 | [FACT] 查询 + 编辑 | READY |
| 字段口径 | [FACT] 必填 / 枚举 / 空态已列明 | READY |
| DB/权限/状态机/MQ/job 涉及面 | [FACT] 无 MQ/job；权限沿用现有角色 | READY |
| 最小回滚 | [FACT] 回滚前端入口 + 后端接口 | READY |

## 质疑记录

| Question | User answer | Status |
| --- | --- | --- |
| 是否需要导出 | 不需要 | RESOLVED |
SPEC
run_expect_pass "requirement intake gate accepts complete ready intake" \
  "$root/scripts/requirement-intake-gate.sh" "$ready_change"

missing_category="$tmp_dir/missing-category-change"
mkdir -p "$missing_category"
cp "$ready_change/requirement-intake.md" "$missing_category/requirement-intake.md"
awk '$0 !~ /最小回滚/' "$ready_change/requirement-intake.md" >"$missing_category/requirement-intake.md"
run_expect_fail_with_code "requirement intake gate blocks missing key category" \
  "REQUIREMENT_INTAKE/MISSING_KEY_CATEGORY" \
  "$root/scripts/requirement-intake-gate.sh" "$missing_category"

open_question="$tmp_dir/open-question-change"
mkdir -p "$open_question"
cp "$ready_change/requirement-intake.md" "$open_question/requirement-intake.md"
sed 's/blocking_questions_status: RESOLVED/blocking_questions_status: OPEN/' "$ready_change/requirement-intake.md" >"$open_question/requirement-intake.md"
run_expect_fail_with_code "requirement intake gate blocks open questions" \
  "REQUIREMENT_INTAKE/OPEN_QUESTIONS" \
  "$root/scripts/requirement-intake-gate.sh" "$open_question"

if grep -q 'templates/requirement-intake.md' "$root/docs/README.md" \
  && grep -q 'scripts/requirement-intake-gate.sh' "$root/docs/README.md" \
  && grep -q 'scripts/requirement-intake-gate-test.sh' "$root/docs/README.md"; then
  pass "docs index lists requirement intake template and gate"
else
  fail "docs index lists requirement intake template and gate"
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: requirement intake gate test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: requirement intake gate test passed\n'
