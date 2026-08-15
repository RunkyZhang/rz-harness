#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/technical-solution-gate.sh <technical-solution.md | change-dir>

Fails closed unless the technical solution contains:
  confirmation_status: CONFIRMED
  allowed_next_stage: <non-empty value other than none>
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

require_pattern() {
  local file="$1" pattern="$2" code="$3" message="$4" fix="$5" sample="$6"
  if ! grep -Eq "$pattern" "$file"; then
    fail "$code" "$message" "$fix" "$sample"
  fi
}

reject_pattern() {
  local file="$1" pattern="$2" code="$3" message="$4" fix="$5" sample="$6"
  if grep -Eq "$pattern" "$file"; then
    fail "$code" "$message" "$fix" "$sample"
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

target="${1:-}"
[[ -n "$target" ]] || fail \
  "TECHNICAL_SOLUTION_GATE/MISSING_PATH" \
  "missing technical solution path" \
  "Pass changes/<change-id>/technical-solution.md or changes/<change-id>/." \
  "templates/technical-solution.md"

if [[ -d "$target" ]]; then
  solution="$target/technical-solution.md"
  change_dir="$target"
else
  solution="$target"
  change_dir="$(dirname "$target")"
fi

[[ -f "$solution" ]] || fail \
  "TECHNICAL_SOLUTION_GATE/MISSING_FILE" \
  "technical solution file not found: $solution" \
  "Create the technical solution from templates/technical-solution.md and get explicit human confirmation." \
  "changes/<change-id>/technical-solution.md"

status="$(field_value "$solution" "confirmation_status")"
next_stage="$(field_value "$solution" "allowed_next_stage")"

data_model="$change_dir/data-model.md"
if [[ -f "$data_model" ]]; then
  schema_change_required="$(field_value "$data_model" "schema_change_required")"
  if [[ "$schema_change_required" == "yes" ]]; then
    require_pattern \
      "$solution" \
      'DB|数据模型|DDL|schema|表结构' \
      "TECHNICAL_SOLUTION_GATE/MISSING_DB_MODEL_SECTION" \
      "data-model.md declares schema_change_required: yes, but technical solution does not include a DB/data-model section" \
      "Inline the core DB/DDL design in technical-solution.md. Do not only link to data-model.md; reviewers must be able to check affected tables, DDL, fields, rollback, and verification from the main solution." \
      "### DB / 数据模型设计"

    require_pattern \
      "$solution" \
      'ALTER TABLE|CREATE TABLE|ADD COLUMN|DROP COLUMN|CREATE INDEX|变更表|涉及表|新增字段|DDL 草案|ER 图' \
      "TECHNICAL_SOLUTION_GATE/MISSING_INLINE_SCHEMA_CHANGE_DETAILS" \
      "technical solution mentions DB/data-model, but does not inline concrete schema-change details" \
      "Copy the essential schema-change design from data-model.md into technical-solution.md: affected tables, DDL or field list, field semantics, rollback risk, and verification. A bare 'see data-model.md' reference is insufficient." \
      "ALTER TABLE example_table ADD COLUMN status varchar(16) ..."
  fi
fi

if [[ "$status" != "CONFIRMED" ]]; then
  fail \
    "TECHNICAL_SOLUTION_GATE/PENDING_CONFIRMATION" \
    "technical solution confirmation_status is '${status:-missing}', not CONFIRMED" \
    "Ask the human reviewer to confirm the complete technical solution, then update confirmation_status / confirmed_by / confirmed_at / confirmed_scope." \
    "confirmation_status: CONFIRMED"
fi

if [[ -z "$next_stage" || "$next_stage" == "none" ]]; then
  fail \
    "TECHNICAL_SOLUTION_GATE/MISSING_NEXT_STAGE" \
    "technical solution allowed_next_stage is '${next_stage:-missing}'" \
    "Record the exact next stage allowed by this confirmation, such as code_start, prototype, ai_test, or pre_release." \
    "allowed_next_stage: code_start"
fi

reject_pattern \
  "$solution" \
  'READY_FOR_SQL|OPEN_SQL_DETAIL|TODO|TBD|FIXME|\[QUESTION\]|\[ASSUMP\]|<[A-Za-z][A-Za-z0-9_./ -]*>' \
  "TECHNICAL_SOLUTION_GATE/UNRESOLVED_IMPLEMENTATION_DETAIL" \
  "confirmed technical solution contains unresolved implementation-detail markers" \
  "Replace unresolved markers with concrete field sources, processing logic, UI behavior, verification, or explicit N/A with source before confirmation." \
  "Field source: table.column; Processing: exact match; Empty display: '-'"

require_pattern \
  "$solution" \
  '全栈' \
  "TECHNICAL_SOLUTION_GATE/MISSING_FULLSTACK_SCOPE" \
  "technical solution does not declare a full-stack scope" \
  "Add a full-stack technical solution section covering every PRD-affected backend, PC Web, H5, mini-program, APP, DB, job/MQ, export, analytics, verification, release, and rollback surface; mark non-applicable surfaces with N/A and source." \
  "## PRD 端到端覆盖矩阵"

require_pattern \
  "$solution" \
  'PRD.*覆盖|端到端覆盖|全栈页面流|页面流' \
  "TECHNICAL_SOLUTION_GATE/MISSING_PRD_COVERAGE_MATRIX" \
  "technical solution does not show PRD end-to-end coverage" \
  "Add a PRD coverage matrix or equivalent page flow that maps PRD pages, APIs, exports, analytics, permissions, and acceptance items to implementation and verification." \
  "### 0. PRD 端到端覆盖矩阵"

require_pattern \
  "$solution" \
  'PC Web|H5|小程序|APP|前端/客户端|Frontend|N/A' \
  "TECHNICAL_SOLUTION_GATE/MISSING_CLIENT_SURFACE" \
  "technical solution does not cover frontend/client surfaces" \
  "Cover PC Web, H5, mini-program, and APP surfaces that appear in the PRD; if a surface is not applicable, record N/A with the source." \
  "### 7. 前端/客户端页面方案"

require_pattern \
  "$solution" \
  '导出|Export|N/A' \
  "TECHNICAL_SOLUTION_GATE/MISSING_EXPORT_SURFACE" \
  "technical solution does not cover export/report surfaces" \
  "Record export/report requirements, field source, trigger point, and verification; if not applicable, record N/A with the source." \
  "导出: N/A, PRD 不涉及"

require_pattern \
  "$solution" \
  '埋点|分析|Analytics|N/A' \
  "TECHNICAL_SOLUTION_GATE/MISSING_ANALYTICS_SURFACE" \
  "technical solution does not cover analytics/event surfaces" \
  "Record analytics/event requirements and verification; if not applicable, record N/A with the source." \
  "埋点/分析: N/A, PRD 不涉及"

require_pattern \
  "$solution" \
  '字段来源|字段映射|Source / derivation|处理逻辑|筛选逻辑' \
  "TECHNICAL_SOLUTION_GATE/MISSING_FIELD_SOURCE_AND_LOGIC" \
  "technical solution does not include field source and processing logic" \
  "For each changed/new/query/export interface, include request and response field source, filter/sort/export logic, empty-value handling, and verification." \
  "字段来源: sfa_table.column；处理逻辑: exact match / aggregate / enum translation"

if grep -Eq 'PC Web|Frontend|前端|页面|UI' "$solution"; then
  require_pattern \
    "$solution" \
    'UI 参考|HTML 原型|PRD 截图|组件|交互|空态|加载态|失败态|路由|route' \
    "TECHNICAL_SOLUTION_GATE/MISSING_FRONTEND_UI_DETAIL" \
    "technical solution mentions frontend/UI but does not include concrete UI implementation detail" \
    "Include route, page structure, UI baseline or PRD/HTML/screenshot reference, component responsibility, state handling, empty/loading/error states, and smoke screenshots." \
    "UI 参考: PRD HTML + distributionList.vue；路由: /Demo；空态/加载态/失败态: ..."
fi

"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/scripts/technical-solution-feishu-sync-gate.sh" "$solution" >/dev/null

printf 'PASS: technical solution confirmed for %s; allowed_next_stage=%s\n' "$solution" "$next_stage"
