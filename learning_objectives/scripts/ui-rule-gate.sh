#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/ui-rule-gate.sh <ui-rule-checklist.md | change-dir>

Fails closed unless UI rule checklist contains:
  - ui_rule_status: READY or NOT_APPLICABLE
  - rule_gap_status: NONE / CONFIRMED / NOT_APPLICABLE
  - no unconfirmed UI rule gaps
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

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

target="${1:-}"
[[ -n "$target" ]] || fail \
  "UI_RULE_GATE/MISSING_PATH" \
  "missing UI rule checklist path" \
  "Pass changes/<change-id>/ui-rule-checklist.md or changes/<change-id>/." \
  "templates/ui-rule-checklist.md"

if [[ -d "$target" ]]; then
  ui_file="$target/ui-rule-checklist.md"
else
  ui_file="$target"
fi

[[ -f "$ui_file" ]] || fail \
  "UI_RULE_GATE/MISSING_FILE" \
  "UI rule checklist file not found: $ui_file" \
  "Create it from templates/ui-rule-checklist.md before PRD UI / interaction coding." \
  "changes/<change-id>/ui-rule-checklist.md"

status="$(field_value "$ui_file" "ui_rule_status")"
gap_status="$(field_value "$ui_file" "rule_gap_status")"
screen_breakdown_status="$(field_value "$ui_file" "prd_screen_breakdown_status")"

if [[ "$status" == "NOT_APPLICABLE" ]]; then
  printf 'PASS: UI rule checklist marked NOT_APPLICABLE in %s\n' "$ui_file"
  exit 0
fi

if [[ "$status" != "READY" ]]; then
  fail \
    "UI_RULE_GATE/NOT_READY" \
    "ui_rule_status is '${status:-missing}', not READY or NOT_APPLICABLE" \
    "Read the Harness UI rules, capture PRD/baseline references, and resolve UI gaps." \
    "ui_rule_status: READY"
fi

case "$gap_status" in
  NONE|CONFIRMED|NOT_APPLICABLE) ;;
  *)
    fail \
      "UI_RULE_GATE/GAP_NOT_CONFIRMED" \
      "rule_gap_status is '${gap_status:-missing}', not NONE / CONFIRMED / NOT_APPLICABLE" \
      "If the PRD interaction is not covered by Harness UI rules, get explicit user confirmation before coding." \
      "rule_gap_status: CONFIRMED"
    ;;
esac

if ! grep -qF "## 规则与基线" "$ui_file" || ! grep -qF "## UI 规范映射" "$ui_file"; then
  fail \
    "UI_RULE_GATE/MISSING_SECTIONS" \
    "UI rule checklist must include rule/baseline and mapping sections" \
    "Use templates/ui-rule-checklist.md without removing required sections." \
    "## 规则与基线"
fi

case "$screen_breakdown_status" in
  READY)
    screen_row_count="$(awk -F'|' '
      /^\|[[:space:]]*UI-[0-9]+/ && NF >= 9 { count++ }
      END { print count + 0 }
    ' "$ui_file")"
    if ! grep -qF "## PRD 截图逐屏拆解表" "$ui_file" \
      || [[ "$screen_row_count" -lt 1 ]]; then
      fail \
        "UI_RULE_GATE/MISSING_SCREEN_BREAKDOWN" \
        "PRD screenshot breakdown is marked READY but section or UI-* rows are missing" \
        "Add one row per PRD screenshot/prototype state, or mark prd_screen_breakdown_status: NOT_APPLICABLE with a reason." \
        "templates/ui-rule-checklist.md"
    fi
    ;;
  NOT_APPLICABLE)
    ;;
  *)
    fail \
      "UI_RULE_GATE/SCREEN_BREAKDOWN_NOT_READY" \
      "prd_screen_breakdown_status is '${screen_breakdown_status:-missing}', not READY / NOT_APPLICABLE" \
      "Complete the PRD screenshot breakdown before UI coding, or mark it NOT_APPLICABLE with a concrete reason." \
      "prd_screen_breakdown_status: READY"
    ;;
esac

if [[ "$screen_breakdown_status" == "READY" ]]; then
  if awk -F'|' '
    /^\|[[:space:]]*UI-[0-9]+/ && NF >= 9 {
      status=$8
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
      if (status != "READY" && status != "CONFIRMED" && status != "N/A") {
        print NR ":" $0
      }
    }
  ' "$ui_file" >/tmp/sfa-ui-screen-breakdown-blocked.out; then
    if [[ -s /tmp/sfa-ui-screen-breakdown-blocked.out ]]; then
      printf 'Blocked PRD screen breakdown rows:\n' >&2
      sed -n '1,20p' /tmp/sfa-ui-screen-breakdown-blocked.out >&2
      rm -f /tmp/sfa-ui-screen-breakdown-blocked.out
      fail \
        "UI_RULE_GATE/BLOCKED_SCREEN_BREAKDOWN" \
        "PRD screen breakdown contains UI-* rows not marked READY / CONFIRMED / N/A" \
        "Resolve screenshot differences or get explicit user confirmation before coding." \
        "| UI-001 | <prd> | <areas> | <mapping> | <diff> | <decision> | READY |"
    fi
  fi
fi
rm -f /tmp/sfa-ui-screen-breakdown-blocked.out

if awk -F'|' '
  /^\|[[:space:]]*UIG-[0-9]+/ {
    status=$6
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
    if (status != "CONFIRMED") {
      print NR ":" $0
    }
  }
' "$ui_file" >/tmp/sfa-ui-rule-unconfirmed.out; then
  if [[ -s /tmp/sfa-ui-rule-unconfirmed.out ]]; then
    printf 'Unconfirmed UI gaps:\n' >&2
    sed -n '1,20p' /tmp/sfa-ui-rule-unconfirmed.out >&2
    rm -f /tmp/sfa-ui-rule-unconfirmed.out
    fail \
      "UI_RULE_GATE/UNCONFIRMED_GAP_ROWS" \
      "UI rule checklist contains UIG-* rows not marked CONFIRMED" \
      "Confirm each UI rule gap with the user or remove it if no longer applicable." \
      "| UIG-001 | <gap> | <options> | <decision> | CONFIRMED |"
  fi
fi
rm -f /tmp/sfa-ui-rule-unconfirmed.out

if grep -nE '\b(TODO|TBD)\b|待补|未定|<[^>]+>' "$ui_file" >/tmp/sfa-ui-rule-placeholders.out; then
  printf 'Unresolved placeholders:\n' >&2
  sed -n '1,20p' /tmp/sfa-ui-rule-placeholders.out >&2
  rm -f /tmp/sfa-ui-rule-placeholders.out
  fail \
    "UI_RULE_GATE/UNRESOLVED_PLACEHOLDER" \
    "UI rule checklist contains unresolved placeholders" \
    "Replace placeholders with concrete PRD references, baselines, rules, decisions, or explicit N/A reasons." \
    "templates/ui-rule-checklist.md"
fi
rm -f /tmp/sfa-ui-rule-placeholders.out

printf 'PASS: UI rule checklist ready in %s\n' "$ui_file"
