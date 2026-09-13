#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  changes/status-card.sh [--json] <change-dir>

Read-only. Prints a compact status snapshot from change artifacts.
Does not write status-card.md and does not replace individual gates.
The main agent merges this output into changes/<id>/status-card.md
without overwriting Agent Roster, 当前阻塞, or 人工确认待办.
This script lives at changes/ root and is committed.
Change packages under changes/<id>/ are gitignored.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

field_value() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 0
  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*:" {
      sub("^[[:space:]]*" key "[[:space:]]*:[[:space:]]*", "")
      sub("[[:space:]]+$", "")
      print
      exit
    }
  ' "$file"
}

table_item_value() {
  local file="$1" item="$2"
  [[ -f "$file" ]] || return 0
  awk -F'|' -v item="$item" '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }
    NF >= 4 && trim($2) == item {
      print trim($3)
      exit
    }
  ' "$file"
}

exists_status() {
  local file="$1" label="$2"
  if [[ -f "$file" ]]; then
    printf '%s: present\n' "$label"
  else
    printf '%s: missing\n' "$label"
  fi
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

json_bool() {
  if [[ "$1" == "YES" ]]; then
    printf 'true'
  else
    printf 'false'
  fi
}

needs_feishu_sync() {
  local source_type="$1" source_url="$2" sync_status="$3"
  if [[ "$source_type" == "feishu" || "$source_url" =~ feishu\.cn|larksuite\.com ]]; then
    [[ "$sync_status" != "SYNCED" ]]
    return
  fi
  return 1
}

json_mode=0
if [[ "${1:-}" == "--json" ]]; then
  json_mode=1
  shift
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

change_dir="${1:-}"
[[ -n "$change_dir" ]] || fail "missing change dir"
[[ -d "$change_dir" ]] || fail "change dir not found: $change_dir"

change_id="$(basename "$change_dir")"
spec="$change_dir/spec.md"
technical_solution="$change_dir/technical-solution.md"
ai_test_plan="$change_dir/ai-test-plan.md"
environment_readiness="$change_dir/environment-readiness.md"
test_agent_verification="$change_dir/test-agent-verification.md"
ai_test_report="$change_dir/ai-test-report.md"
ui_rule_checklist="$change_dir/ui-rule-checklist.md"
ui_confirmation="$change_dir/ui-confirmation.md"
review="$change_dir/review.md"
pre_pr="$change_dir/pre-pr.md"
agent_dispatch_plan="$change_dir/agent-dispatch-plan.md"
verification_map="$change_dir/verification-map.md"
verification_run_report="$change_dir/verification-run-report.md"
status_card="$change_dir/status-card.md"

technical_status="$(field_value "$technical_solution" "confirmation_status")"
technical_next_stage="$(field_value "$technical_solution" "allowed_next_stage")"
technical_prd_source_type="$(field_value "$technical_solution" "prd_source_type")"
technical_prd_source_url="$(field_value "$technical_solution" "prd_source_url")"
technical_feishu_doc_url="$(field_value "$technical_solution" "feishu_solution_doc_url")"
technical_feishu_sync_status="$(field_value "$technical_solution" "feishu_solution_sync_status")"
ai_test_plan_status="$(field_value "$ai_test_plan" "test_plan_status")"
environment_status="$(field_value "$environment_readiness" "environment_status")"
test_agent_status="$(field_value "$test_agent_verification" "verification_status")"
test_agent_decision="$(field_value "$test_agent_verification" "final_decision")"
ai_report_status="$(field_value "$ai_test_report" "confirmation_status")"
ai_report_recommendation="$(field_value "$ai_test_report" "recommendation")"
ui_rule_status="$(field_value "$ui_rule_checklist" "ui_rule_status")"
ui_rule_gap_status="$(field_value "$ui_rule_checklist" "rule_gap_status")"
ui_status="$(field_value "$ui_confirmation" "Status")"
if [[ -z "$ui_status" ]]; then
  ui_status="$(table_item_value "$ui_confirmation" "Status")"
fi
agent_dispatch_status="$(field_value "$agent_dispatch_plan" "plan_status")"
verification_run_status="$(field_value "$verification_run_report" "run_status")"

tester_started() {
  case "$test_agent_status" in
    ISSUES_FOUND|RETESTING|GOAL_ACHIEVED|BLOCKED) return 0 ;;
    *) return 1 ;;
  esac
}

tester_goal_achieved() {
  [[ "$test_agent_status" == "GOAL_ACHIEVED" && "$test_agent_decision" == "GOAL_ACHIEVED" ]]
}

current_phase="需求理解"
next_action="补齐 spec 三标签，清阻塞 [QUESTION]"
can_proceed="NO"

if [[ -f "$technical_solution" && "$technical_status" != "CONFIRMED" ]]; then
  current_phase="方案确认"
  next_action="补齐并确认完整技术方案"
  can_proceed="NO"
elif [[ -f "$technical_solution" ]] && needs_feishu_sync "$technical_prd_source_type" "$technical_prd_source_url" "$technical_feishu_sync_status"; then
  current_phase="方案确认"
  next_action="运行 gates/technical-solution-feishu-sync-gate.sh changes/${change_id}，同步飞书技术方案子文档"
  can_proceed="NO"
elif [[ -f "$ai_test_plan" && "$ai_test_plan_status" != "CONFIRMED" ]]; then
  current_phase="方案确认"
  next_action="由独立 Test Strategy 生成或修订 ai-test-plan.md，并等待用户确认"
  can_proceed="NO"
elif tester_started && ! tester_goal_achieved; then
  current_phase="AI测试待确认"
  if [[ "$test_agent_status" == "BLOCKED" ]]; then
    next_action="Tester 返回 BLOCKED：记录最小阻塞条件并升级给用户决策"
  else
    next_action="主 Agent 修复 Tester 反馈问题，Tester 复测"
  fi
  can_proceed="NO"
elif tester_goal_achieved && [[ -f "$ai_test_report" && "$ai_report_status" != "CONFIRMED" ]]; then
  current_phase="AI测试待确认"
  next_action="人工 review ai-test-report.md 的结果和残余风险"
  can_proceed="NO"
elif [[ "$ai_report_status" == "CONFIRMED" && "$ai_report_recommendation" == "允许进入预发" ]]; then
  current_phase="预发待发布"
  next_action="按发布流程进入测试 / 预发环境"
  can_proceed="YES"
elif [[ "$technical_status" == "CONFIRMED" && ( ! -f "$ai_test_plan" || "$ai_test_plan_status" == "CONFIRMED" ) ]]; then
  current_phase="允许开工"
  next_action="前置门禁已过，可开始实现：建立业务仓 harness/${change_id} 分支并跑开工 gate。实现开始后由主 Agent 手动置为「实现中」"
  if [[ -f "$environment_readiness" && "$environment_status" != "READY" && "$environment_status" != "NOT_APPLICABLE" ]]; then
    next_action="${next_action}；真实 E2E 前需补齐 environment-readiness.md"
  fi
  can_proceed="YES"
fi

if [[ "$json_mode" -eq 1 ]]; then
  cat <<EOF
{
  "change_id": "$(json_escape "$change_id")",
  "current_phase": "$(json_escape "$current_phase")",
  "next_action": "$(json_escape "$next_action")",
  "can_proceed": $(json_bool "$can_proceed"),
  "technical_solution": {
    "present": $([[ -f "$technical_solution" ]] && printf true || printf false),
    "confirmation_status": "$(json_escape "${technical_status:-MISSING}")",
    "allowed_next_stage": "$(json_escape "${technical_next_stage:-MISSING}")",
    "feishu_solution_sync_status": "$(json_escape "${technical_feishu_sync_status:-MISSING}")"
  },
  "ai_test_plan": {
    "present": $([[ -f "$ai_test_plan" ]] && printf true || printf false),
    "test_plan_status": "$(json_escape "${ai_test_plan_status:-MISSING}")"
  },
  "environment_readiness": {
    "present": $([[ -f "$environment_readiness" ]] && printf true || printf false),
    "environment_status": "$(json_escape "${environment_status:-MISSING}")"
  },
  "test_agent_verification": {
    "present": $([[ -f "$test_agent_verification" ]] && printf true || printf false),
    "verification_status": "$(json_escape "${test_agent_status:-MISSING}")",
    "final_decision": "$(json_escape "${test_agent_decision:-MISSING}")"
  },
  "ai_test_report": {
    "present": $([[ -f "$ai_test_report" ]] && printf true || printf false),
    "confirmation_status": "$(json_escape "${ai_report_status:-MISSING}")",
    "recommendation": "$(json_escape "${ai_report_recommendation:-MISSING}")"
  },
  "artifacts": {
    "status_card": $([[ -f "$status_card" ]] && printf true || printf false),
    "spec": $([[ -f "$spec" ]] && printf true || printf false),
    "review": $([[ -f "$review" ]] && printf true || printf false),
    "pre_pr": $([[ -f "$pre_pr" ]] && printf true || printf false)
  }
}
EOF
  exit 0
fi

cat <<EOF
# 状态卡快照：$change_id

> 只读摘要。主 Agent 同步进 status-card.md 的阶段表 / Gate 状态；不要用本输出覆盖 Agent Roster。

| Item | Value |
| --- | --- |
| 当前阶段 | $current_phase |
| 下一步 | $next_action |
| 是否允许进入下一阶段 | $can_proceed |
| 技术方案确认 | ${technical_status:-MISSING} |
| 技术方案允许阶段 | ${technical_next_stage:-MISSING} |
| 飞书技术方案同步 | ${technical_feishu_sync_status:-MISSING} |
| 飞书技术方案子文档 | ${technical_feishu_doc_url:-MISSING} |
| AI 测试方案确认 | ${ai_test_plan_status:-MISSING} |
| 环境就绪 | ${environment_status:-MISSING} |
| Tester 验收 | ${test_agent_status:-MISSING} |
| Tester 最终决定 | ${test_agent_decision:-MISSING} |
| AI 测试报告确认 | ${ai_report_status:-MISSING} |
| AI 测试发布建议 | ${ai_report_recommendation:-MISSING} |
| UI 规则检查 | ${ui_rule_status:-MISSING} |
| UI 规则缺口 | ${ui_rule_gap_status:-MISSING} |
| UI 确认 | ${ui_status:-MISSING} |
| Agent 派发计划 | ${agent_dispatch_status:-MISSING} |
| Verification Run | ${verification_run_status:-MISSING} |

## 关键产物

- $(exists_status "$status_card" "status-card.md")
- $(exists_status "$spec" "spec.md")
- $(exists_status "$technical_solution" "technical-solution.md")
- $(exists_status "$ai_test_plan" "ai-test-plan.md")
- $(exists_status "$environment_readiness" "environment-readiness.md")
- $(exists_status "$test_agent_verification" "test-agent-verification.md")
- $(exists_status "$ai_test_report" "ai-test-report.md")
- $(exists_status "$ui_rule_checklist" "ui-rule-checklist.md")
- $(exists_status "$ui_confirmation" "ui-confirmation.md")
- $(exists_status "$agent_dispatch_plan" "agent-dispatch-plan.md")
- $(exists_status "$verification_map" "verification-map.md")
- $(exists_status "$verification_run_report" "verification-run-report.md")
- $(exists_status "$review" "review.md")
- $(exists_status "$pre_pr" "pre-pr.md")

## 人工确认停点

- 技术方案确认：未 CONFIRMED 时不得进入业务代码实现。
- 飞书技术方案同步：PRD 来源为飞书 / Lark 时，确认后的技术方案必须先同步到 PRD 子文档。
- AI 测试方案确认：未 CONFIRMED 时不得进入业务代码实现。
- 环境就绪：目标环境未 READY 时不得执行真实 E2E。
- Tester 独立验收：未 GOAL_ACHIEVED 时主 Agent 不得声明最终目标达成。
- AI 测试报告确认：未 CONFIRMED 且未建议 允许进入预发 时不得进入测试 / 预发发布。
EOF
