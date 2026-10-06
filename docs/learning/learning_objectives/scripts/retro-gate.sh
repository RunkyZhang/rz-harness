#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/retro-gate.sh [--required] <retro.md | change-dir>

Layered closeout retro gate:
  - Tier M/L changes are required when harness-status.md has artifact_profile.
  - --required forces retro.md to exist.
  - Tier S / small changes may omit retro.md and keep closeout metrics in
    harness-status.md or evidence.md.
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

require_pattern() {
  local file="$1" pattern="$2" code="$3" message="$4" fix="$5" sample="$6"
  if ! grep -Eq "$pattern" "$file"; then
    fail "$code" "$message" "$fix" "$sample"
  fi
}

require_numeric_field() {
  local file="$1" key="$2"
  local value
  value="$(field_value "$file" "$key")"
  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    fail \
      "RETRO/INVALID_METRIC" \
      "retro metric '$key' is '${value:-missing}', not a non-negative integer" \
      "Fill $key with a concrete non-negative integer." \
      "$key: 0"
  fi
}

required=0
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --required)
      required=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      fail \
        "RETRO/UNKNOWN_OPTION" \
        "unknown option: $1" \
        "Use scripts/retro-gate.sh [--required] <retro.md | change-dir>." \
        "scripts/retro-gate.sh --required changes/example"
      ;;
    *)
      break
      ;;
  esac
done

target="${1:-}"
[[ -n "$target" ]] || fail \
  "RETRO/MISSING_PATH" \
  "missing retro path" \
  "Pass changes/<change-id> or changes/<change-id>/retro.md." \
  "scripts/retro-gate.sh changes/example"

if [[ -d "$target" ]]; then
  change_dir="${target%/}"
  retro="$change_dir/retro.md"
else
  retro="$target"
  change_dir="$(dirname "$retro")"
fi

profile="$(field_value "$change_dir/harness-status.md" "artifact_profile")"
case "$profile" in
  tier-m|tier-l)
    required=1
    ;;
esac

if [[ ! -f "$retro" ]]; then
  if [[ "$required" -eq 1 ]]; then
    fail \
      "RETRO/MISSING_REQUIRED" \
      "retro.md is required but missing: $retro" \
      "Create changes/<change-id>/retro.md from templates/retro.md, fill metrics and closeout decisions, then rerun this gate." \
      "templates/retro.md"
  fi
  printf 'PASS: no retro required for %s\n' "$change_dir"
  exit 0
fi

status="$(field_value "$retro" "retro_status")"
required_value="$(field_value "$retro" "retro_required")"
knowledge_status="$(field_value "$retro" "knowledge_updates_status")"
instinct_count="$(field_value "$retro" "instinct_candidate_count")"

if [[ "$status" != "READY" ]]; then
  fail \
    "RETRO/NOT_READY" \
    "retro_status is '${status:-missing}', not READY" \
    "Finish closeout metrics, user correction summary, gate false-positive review, and knowledge decisions before marking retro_status: READY." \
    "retro_status: READY"
fi

if [[ "$required_value" != "yes" && "$required_value" != "no" ]]; then
  fail \
    "RETRO/INVALID_REQUIRED_FLAG" \
    "retro_required is '${required_value:-missing}', not yes/no" \
    "Set retro_required to yes for Tier M/L, cross-repo, rework/incident, or high-risk changes; otherwise no." \
    "retro_required: yes"
fi

if [[ "$knowledge_status" != "READY" && "$knowledge_status" != "N/A" ]]; then
  fail \
    "RETRO/INVALID_KNOWLEDGE_STATUS" \
    "knowledge_updates_status is '${knowledge_status:-missing}', not READY/N/A" \
    "Record whether knowledge updates are READY or explicitly N/A." \
    "knowledge_updates_status: READY"
fi

for metric in \
  total_rework_count \
  gate_trigger_count \
  gate_false_positive_count \
  reviewer_high_risk_count \
  user_correction_count \
  instinct_candidate_count; do
  require_numeric_field "$retro" "$metric"
done

for section in \
  "触发条件" \
  "关键指标" \
  "用户纠正与返工" \
  "Gate 触发与误报" \
  "规则升级 / 不升级决策" \
  "知识沉淀"; do
  require_pattern \
    "$retro" \
    "^##[[:space:]]+$section" \
    "RETRO/MISSING_SECTION" \
    "retro.md is missing section: $section" \
    "Use templates/retro.md and keep the required closeout sections." \
    "## $section"
done

if grep -nE '\b(TODO|TBD)\b|待补|未定|BLOCKED' "$retro" >/tmp/sfa-retro-placeholder.out; then
  printf 'Unresolved retro placeholders:\n' >&2
  sed -n '1,20p' /tmp/sfa-retro-placeholder.out >&2
  rm -f /tmp/sfa-retro-placeholder.out
  fail \
    "RETRO/UNRESOLVED_PLACEHOLDER" \
    "retro.md contains unresolved placeholders or BLOCKED markers" \
    "Replace placeholders with concrete metrics, explicit N/A rows, or keep the change blocked before closeout." \
    "templates/retro.md"
fi
rm -f /tmp/sfa-retro-placeholder.out

if [[ "$instinct_count" -gt 0 ]]; then
  if ! grep -qE '^\|[[:space:]]*IC-[0-9]+' "$retro"; then
    fail \
      "RETRO/MISSING_INSTINCT_CANDIDATE" \
      "instinct_candidate_count is $instinct_count but no IC-* candidate row exists" \
      "Add at least one IC-* row under '规则升级 / 不升级决策', or set instinct_candidate_count: 0." \
      "| IC-001 | <candidate> | <source> | promote / reject / defer | <reason> | READY |"
  fi
fi

printf 'PASS: retro ready in %s\n' "$retro"
