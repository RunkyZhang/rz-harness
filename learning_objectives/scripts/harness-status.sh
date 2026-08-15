#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-status.sh [--json] <change-dir>

Prints a compact, user-facing Harness status card from change artifacts.
This script is read-only and does not replace individual gates.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

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

count_table_result() {
  local file="$1" result="$2"
  [[ -f "$file" ]] || { printf '0'; return 0; }
  grep -Ec "\\|[[:space:]]*$result[[:space:]]*\\|" "$file" 2>/dev/null || true
}

count_pattern() {
  local file="$1" pattern="$2"
  [[ -f "$file" ]] || { printf '0'; return 0; }
  grep -Eoc "$pattern" "$file" 2>/dev/null || true
}

csv_agent_ids() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  grep -Eo 'sfa-[A-Za-z0-9_-]+' "$file" 2>/dev/null | sort -u | paste -sd ',' - || true
}

telemetry_counts() {
  local telemetry_dir="$1" target_change_id="$2"
  local total=0 change_total=0 file file_count change_count
  if [[ -d "$telemetry_dir" ]]; then
    while IFS= read -r file; do
      file_count="$(wc -l <"$file" | tr -d ' ')"
      change_count="$(grep -F -c "\"change_id\":\"$target_change_id\"" "$file" 2>/dev/null || true)"
      total=$((total + file_count))
      change_total=$((change_total + change_count))
    done < <(find "$telemetry_dir" -type f -name '*.jsonl' ! -path '*/rehearsal/*' -print | sort)
  fi
  printf '%s %s\n' "$total" "$change_total"
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
technical_solution="$change_dir/technical-solution.md"
ai_test_plan="$change_dir/ai-test-plan.md"
environment_readiness="$change_dir/environment-readiness.md"
test_agent_verification="$change_dir/test-agent-verification.md"
ai_test_report="$change_dir/ai-test-report.md"
ui_rule_checklist="$change_dir/ui-rule-checklist.md"
ui_confirmation="$change_dir/ui-confirmation.md"
pc_smoke_report="$change_dir/pc-e2e-smoke-report.md"
review="$change_dir/review.md"
pre_pr="$change_dir/pre-pr.md"
harness_state="$change_dir/harness-state.yml"
agent_dispatch_plan="$change_dir/agent-dispatch-plan.md"
verification_map="$change_dir/verification-map.md"
verification_run_report="$change_dir/verification-run-report.md"
business_repo_bootstrap="$change_dir/business-repo-bootstrap.md"
telemetry_dir="${SFA_HARNESS_TELEMETRY_DIR:-$root/.harness/telemetry}"

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
state_current_stage="$(field_value "$harness_state" "current_stage")"
state_next_action="$(field_value "$harness_state" "next_action")"
agent_dispatch_status="$(field_value "$agent_dispatch_plan" "dispatch_plan_status")"
agent_ids="$(csv_agent_ids "$agent_dispatch_plan")"
agent_candidate_count="$(count_pattern "$agent_dispatch_plan" '[Cc]andidate')"
verification_map_rows="$(count_pattern "$verification_map" 'VM-[0-9A-Za-z._-]+')"
verification_map_status="MISSING"
if [[ -f "$verification_map" ]]; then
  if [[ "$verification_map_rows" -gt 0 ]]; then
    verification_map_status="READY"
  else
    verification_map_status="EMPTY"
  fi
fi
verification_run_status="$(field_value "$verification_run_report" "run_status")"
verification_run_dry_run="$(field_value "$verification_run_report" "dry_run")"
verification_run_pass_count="$(field_value "$verification_run_report" "pass_count")"
verification_run_fail_count="$(field_value "$verification_run_report" "fail_count")"
verification_run_skip_count="$(field_value "$verification_run_report" "skip_count")"
if [[ -f "$verification_run_report" ]]; then
  [[ -n "$verification_run_status" ]] || {
    if grep -qE '\|[[:space:]]*FAIL[[:space:]]*\|' "$verification_run_report"; then
      verification_run_status="FAIL"
    elif grep -qE '\|[[:space:]]*PASS[[:space:]]*\|' "$verification_run_report"; then
      verification_run_status="PASS"
    else
      verification_run_status="UNKNOWN"
    fi
  }
  [[ -n "$verification_run_pass_count" ]] || verification_run_pass_count="$(count_table_result "$verification_run_report" "PASS")"
  [[ -n "$verification_run_fail_count" ]] || verification_run_fail_count="$(count_table_result "$verification_run_report" "FAIL")"
  [[ -n "$verification_run_skip_count" ]] || verification_run_skip_count="$(count_table_result "$verification_run_report" "SKIP")"
else
  verification_run_status="MISSING"
  verification_run_pass_count="0"
  verification_run_fail_count="0"
  verification_run_skip_count="0"
fi
business_repo_bootstrap_status="$(field_value "$business_repo_bootstrap" "bootstrap_status")"
business_repo_bootstrap_repo_count="$(field_value "$business_repo_bootstrap" "repo_count")"
[[ -n "$business_repo_bootstrap_status" ]] || {
  if [[ -f "$business_repo_bootstrap" ]]; then
    business_repo_bootstrap_status="UNKNOWN"
  else
    business_repo_bootstrap_status="MISSING"
  fi
}
[[ -n "$business_repo_bootstrap_repo_count" ]] || business_repo_bootstrap_repo_count="$(count_pattern "$business_repo_bootstrap" 'frontend-|backend-|mobile-')"
read -r telemetry_total_events telemetry_change_events < <(telemetry_counts "$telemetry_dir" "$change_id")

current_phase="方案确认"
next_action="补齐并确认完整技术方案"
can_proceed="NO"

if [[ "$technical_status" == "CONFIRMED" ]]; then
  current_phase="AI 测试方案待确认"
  next_action="由独立 Test Strategy Agent 生成 ai-test-plan.md，并等待用户确认"
  can_proceed="NO"
fi

if [[ "$technical_status" == "CONFIRMED" \
  && ( "$technical_prd_source_type" == "feishu" || "$technical_prd_source_url" =~ feishu\.cn|larksuite\.com ) \
  && "$technical_feishu_sync_status" != "SYNCED" ]]; then
  current_phase="技术方案飞书同步待完成"
  next_action="运行 scripts/technical-solution-feishu-sync.sh changes/<change-id>，在 PRD 飞书节点下创建或更新技术方案子文档"
  can_proceed="NO"
fi

if [[ "$ai_test_plan_status" == "CONFIRMED" ]]; then
  current_phase="环境就绪 / 实现准备"
  next_action="确认 environment-readiness.md 后按 plan 推进实现"
  can_proceed="YES"
fi

if [[ -f "$environment_readiness" && "$environment_status" != "READY" ]]; then
  current_phase="环境就绪待确认"
  next_action="补齐环境、账号、数据和权限准备"
  can_proceed="NO"
fi

if [[ "$ai_test_plan_status" == "CONFIRMED" && ( ! -f "$environment_readiness" || "$environment_status" == "READY" ) ]]; then
  current_phase="实现 / 常规测试"
  next_action="主 Agent 实现、修复、补常规测试和证据"
  can_proceed="YES"
fi

if [[ -f "$test_agent_verification" && "$test_agent_status" != "GOAL_ACHIEVED" ]]; then
  current_phase="测试 Agent 独立验收中"
  next_action="主 Agent 修复测试 Agent 反馈问题，测试 Agent 复测"
  can_proceed="NO"
fi

if [[ "$test_agent_status" == "GOAL_ACHIEVED" && "$test_agent_decision" == "GOAL_ACHIEVED" ]]; then
  current_phase="AI 测试报告准备"
  next_action="汇总常规测试、测试 Agent 验收和残余风险，形成人工确认报告"
  can_proceed="YES"
fi

if [[ -f "$ai_test_report" && "$ai_report_status" != "CONFIRMED" ]]; then
  current_phase="AI 测试待人工确认"
  next_action="人工 review ai-test-report.md 的用例、截图、结果和残余风险"
  can_proceed="NO"
fi

if [[ "$ai_report_status" == "CONFIRMED" && "$ai_report_recommendation" == "允许进入预发" ]]; then
  current_phase="预发待发布"
  next_action="按发布流程进入测试 / 预发环境"
  can_proceed="YES"
fi

# Re-apply earliest-blocker priority so later artifacts cannot hide a missing
# upstream confirmation.
if [[ "$technical_status" != "CONFIRMED" ]]; then
  current_phase="方案确认"
  next_action="补齐并确认完整技术方案"
  can_proceed="NO"
elif [[ ( "$technical_prd_source_type" == "feishu" || "$technical_prd_source_url" =~ feishu\.cn|larksuite\.com ) \
  && "$technical_feishu_sync_status" != "SYNCED" ]]; then
  current_phase="技术方案飞书同步待完成"
  next_action="运行 scripts/technical-solution-feishu-sync.sh changes/<change-id>，在 PRD 飞书节点下创建或更新技术方案子文档"
  can_proceed="NO"
elif [[ "$ai_test_plan_status" != "CONFIRMED" ]]; then
  current_phase="AI 测试方案待确认"
  if [[ -f "$ai_test_plan" ]]; then
    next_action="人工 review ai-test-plan.md，并确认或退回修改"
  else
    next_action="由独立 Test Strategy Agent 生成 ai-test-plan.md，并等待用户确认"
  fi
  can_proceed="NO"
elif [[ -f "$environment_readiness" && "$environment_status" != "READY" ]]; then
  current_phase="环境就绪待确认"
  next_action="补齐环境、账号、数据和权限准备"
  can_proceed="NO"
elif [[ -f "$test_agent_verification" && ( "$test_agent_status" != "GOAL_ACHIEVED" || "$test_agent_decision" != "GOAL_ACHIEVED" ) ]]; then
  current_phase="测试 Agent 独立验收中"
  next_action="主 Agent 修复测试 Agent 反馈问题，测试 Agent 复测"
  can_proceed="NO"
elif [[ -f "$ai_test_report" && "$ai_report_status" != "CONFIRMED" ]]; then
  current_phase="AI 测试待人工确认"
  next_action="人工 review ai-test-report.md 的用例、截图、结果和残余风险"
  can_proceed="NO"
elif [[ "$ai_report_status" == "CONFIRMED" && "$ai_report_recommendation" == "允许进入预发" ]]; then
  current_phase="预发待发布"
  next_action="按发布流程进入测试 / 预发环境"
  can_proceed="YES"
fi

if [[ "$json_mode" -eq 1 ]]; then
  cat <<EOF
{
  "change_id": "$(json_escape "$change_id")",
  "owner_agent": "sfa-harness-orchestrator",
  "current_phase": "$(json_escape "$current_phase")",
  "next_action": "$(json_escape "$next_action")",
  "can_proceed": $(json_bool "$can_proceed"),
  "technical_solution": {
    "present": $([[ -f "$technical_solution" ]] && printf true || printf false),
    "confirmation_status": "$(json_escape "${technical_status:-MISSING}")",
    "allowed_next_stage": "$(json_escape "${technical_next_stage:-MISSING}")",
    "prd_source_type": "$(json_escape "${technical_prd_source_type:-MISSING}")",
    "prd_source_url": "$(json_escape "${technical_prd_source_url:-MISSING}")",
    "feishu_solution_doc_url": "$(json_escape "${technical_feishu_doc_url:-MISSING}")",
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
  "ui_rule_checklist": {
    "present": $([[ -f "$ui_rule_checklist" ]] && printf true || printf false),
    "ui_rule_status": "$(json_escape "${ui_rule_status:-MISSING}")",
    "rule_gap_status": "$(json_escape "${ui_rule_gap_status:-MISSING}")"
  },
  "ui_confirmation": {
    "present": $([[ -f "$ui_confirmation" ]] && printf true || printf false),
    "status": "$(json_escape "${ui_status:-MISSING}")"
  },
  "agent_dispatch_plan": {
    "present": $([[ -f "$agent_dispatch_plan" ]] && printf true || printf false),
    "dispatch_plan_status": "$(json_escape "${agent_dispatch_status:-MISSING}")",
    "agent_ids": "$(json_escape "${agent_ids:-}")",
    "candidate_count": $agent_candidate_count
  },
  "verification_map": {
    "present": $([[ -f "$verification_map" ]] && printf true || printf false),
    "verification_map_status": "$(json_escape "$verification_map_status")",
    "row_count": $verification_map_rows
  },
  "verification_run": {
    "present": $([[ -f "$verification_run_report" ]] && printf true || printf false),
    "run_status": "$(json_escape "$verification_run_status")",
    "dry_run": "$(json_escape "${verification_run_dry_run:-MISSING}")",
    "pass_count": $verification_run_pass_count,
    "fail_count": $verification_run_fail_count,
    "skip_count": $verification_run_skip_count
  },
  "business_repo_bootstrap": {
    "present": $([[ -f "$business_repo_bootstrap" ]] && printf true || printf false),
    "bootstrap_status": "$(json_escape "$business_repo_bootstrap_status")",
    "repo_count": $business_repo_bootstrap_repo_count
  },
  "telemetry": {
    "telemetry_dir": "$(json_escape "$telemetry_dir")",
    "total_events": $telemetry_total_events,
    "change_events": $telemetry_change_events
  },
  "artifacts": {
    "harness_state": $([[ -f "$harness_state" ]] && printf true || printf false),
    "technical_solution": $([[ -f "$technical_solution" ]] && printf true || printf false),
    "ai_test_plan": $([[ -f "$ai_test_plan" ]] && printf true || printf false),
    "environment_readiness": $([[ -f "$environment_readiness" ]] && printf true || printf false),
    "test_agent_verification": $([[ -f "$test_agent_verification" ]] && printf true || printf false),
    "ai_test_report": $([[ -f "$ai_test_report" ]] && printf true || printf false),
    "ui_rule_checklist": $([[ -f "$ui_rule_checklist" ]] && printf true || printf false),
    "ui_confirmation": $([[ -f "$ui_confirmation" ]] && printf true || printf false),
    "agent_dispatch_plan": $([[ -f "$agent_dispatch_plan" ]] && printf true || printf false),
    "verification_map": $([[ -f "$verification_map" ]] && printf true || printf false),
    "verification_run_report": $([[ -f "$verification_run_report" ]] && printf true || printf false),
    "business_repo_bootstrap": $([[ -f "$business_repo_bootstrap" ]] && printf true || printf false),
    "pc_e2e_smoke_report": $([[ -f "$pc_smoke_report" ]] && printf true || printf false),
    "review": $([[ -f "$review" ]] && printf true || printf false),
    "pre_pr": $([[ -f "$pre_pr" ]] && printf true || printf false)
  }
}
EOF
  exit 0
fi

cat <<EOF
# Harness 状态卡：$change_id

| Item | Value |
| --- | --- |
| 当前阶段 | $current_phase |
| 状态机阶段 | ${state_current_stage:-MISSING} |
| 下一步 | $next_action |
| 状态机下一步 | ${state_next_action:-MISSING} |
| 是否允许进入下一阶段 | $can_proceed |
| 技术方案确认 | ${technical_status:-MISSING} |
| 技术方案允许阶段 | ${technical_next_stage:-MISSING} |
| 技术方案 PRD 来源类型 | ${technical_prd_source_type:-MISSING} |
| 技术方案 PRD 来源 | ${technical_prd_source_url:-MISSING} |
| 飞书技术方案子文档 | ${technical_feishu_doc_url:-MISSING} |
| 飞书技术方案同步 | ${technical_feishu_sync_status:-MISSING} |
| AI 测试方案确认 | ${ai_test_plan_status:-MISSING} |
| 环境就绪 | ${environment_status:-MISSING} |
| 测试 Agent 验收 | ${test_agent_status:-MISSING} |
| 测试 Agent 最终决定 | ${test_agent_decision:-MISSING} |
| AI 测试报告确认 | ${ai_report_status:-MISSING} |
| AI 测试发布建议 | ${ai_report_recommendation:-MISSING} |
| UI 规则检查 | ${ui_rule_status:-MISSING} |
| UI 规则缺口 | ${ui_rule_gap_status:-MISSING} |
| UI 确认 | ${ui_status:-MISSING} |
| Agent 派发计划 | ${agent_dispatch_status:-MISSING} (${agent_ids:-none}) |
| Verification Map | $verification_map_status / rows=$verification_map_rows |
| Verification Run | $verification_run_status / pass=$verification_run_pass_count fail=$verification_run_fail_count skip=$verification_run_skip_count |
| 业务仓本地约束 | $business_repo_bootstrap_status / repos=$business_repo_bootstrap_repo_count |
| Telemetry | total=$telemetry_total_events / change=$telemetry_change_events |

## 关键产物

- $(exists_status "$technical_solution" "technical-solution.md")
- $(exists_status "$harness_state" "harness-state.yml")
- $(exists_status "$ai_test_plan" "ai-test-plan.md")
- $(exists_status "$environment_readiness" "environment-readiness.md")
- $(exists_status "$test_agent_verification" "test-agent-verification.md")
- $(exists_status "$ai_test_report" "ai-test-report.md")
- $(exists_status "$ui_rule_checklist" "ui-rule-checklist.md")
- $(exists_status "$ui_confirmation" "ui-confirmation.md")
- $(exists_status "$agent_dispatch_plan" "agent-dispatch-plan.md")
- $(exists_status "$verification_map" "verification-map.md")
- $(exists_status "$verification_run_report" "verification-run-report.md")
- $(exists_status "$business_repo_bootstrap" "business-repo-bootstrap.md")
- $(exists_status "$pc_smoke_report" "pc-e2e-smoke-report.md")
- $(exists_status "$review" "review.md")
- $(exists_status "$pre_pr" "pre-pr.md")

## 人工确认停点

- 技术方案确认：未 CONFIRMED 时不得进入业务代码实现。
- 飞书技术方案同步：PRD 来源为飞书 / Lark 时，确认后的技术方案必须先同步到 PRD 子文档；本地方案后续修改后必须重新同步。
- AI 测试方案确认：未 CONFIRMED 时不得进入业务代码实现。
- 环境就绪：目标环境、角色、数据和权限未 READY 时不得执行真实 E2E。
- 测试 Agent 独立验收：未 GOAL_ACHIEVED 时主 Agent 不得声明最终目标达成。
- AI 测试报告确认：未 CONFIRMED 且未建议 允许进入预发 时不得进入测试 / 预发发布。
- DB 写入、生产配置、发布范围变更仍需要二次确认。
EOF
