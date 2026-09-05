#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/technical-solution-feishu-sync-gate.sh <technical-solution.md | change-dir>

When a confirmed technical solution uses a Feishu/Lark PRD source, this gate
requires a synced Feishu child document and a current source hash.
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

trim_value() {
  local value="$1"
  printf '%s' "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

lower_value() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

is_blankish() {
  local value lower
  value="$(trim_value "$1")"
  lower="$(lower_value "$value")"
  case "$lower" in
    ""|"-"|"n/a"|"na"|"none"|"null"|"pending"|"todo"|"tbd")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_feishu_source() {
  local source_type="$1" source_url="$2" lower_type
  lower_type="$(lower_value "$(trim_value "$source_type")")"
  case "$lower_type" in
    feishu|lark|feishu-wiki|lark-wiki)
      return 0
      ;;
  esac
  printf '%s' "$source_url" | grep -Eiq 'https?://[^[:space:]]*(feishu\.cn|larksuite\.com)'
}

solution_hash() {
  local file="$1"
  awk '
    $0 !~ /^[[:space:]]*(feishu_solution_doc_url|feishu_solution_sync_status|feishu_solution_synced_at|feishu_solution_source_sha256|feishu_solution_readback_status)[[:space:]]*:/
  ' "$file" | openssl dgst -sha256 -r | awk '{print $1}'
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

target="${1:-}"
[[ -n "$target" ]] || fail \
  "TECH_SOLUTION_FEISHU/MISSING_PATH" \
  "missing technical solution path" \
  "Pass changes/<change-id>/technical-solution.md or changes/<change-id>/." \
  "templates/technical-solution.md"

if [[ -d "$target" ]]; then
  solution="$target/technical-solution.md"
else
  solution="$target"
fi

[[ -f "$solution" ]] || fail \
  "TECH_SOLUTION_FEISHU/MISSING_FILE" \
  "technical solution file not found: $solution" \
  "Create technical-solution.md before running the Feishu sync gate." \
  "changes/<change-id>/technical-solution.md"

confirmation_status="$(field_value "$solution" "confirmation_status")"
prd_source_type="$(field_value "$solution" "prd_source_type")"
prd_source_url="$(field_value "$solution" "prd_source_url")"

if ! is_feishu_source "$prd_source_type" "$prd_source_url"; then
  printf 'PASS: Feishu solution sync not required for %s\n' "$solution"
  exit 0
fi

if [[ "$confirmation_status" != "CONFIRMED" ]]; then
  printf 'PASS: Feishu solution sync waits until confirmation_status=CONFIRMED for %s\n' "$solution"
  exit 0
fi

doc_url="$(field_value "$solution" "feishu_solution_doc_url")"
sync_status="$(field_value "$solution" "feishu_solution_sync_status")"
recorded_hash="$(field_value "$solution" "feishu_solution_source_sha256")"
current_hash="$(solution_hash "$solution")"

if is_blankish "$doc_url"; then
  fail \
    "TECH_SOLUTION_FEISHU/MISSING_DOC_URL" \
    "confirmed Feishu PRD technical solution has no synced Feishu child document" \
    "Run scripts/technical-solution-feishu-sync.sh changes/<change-id> after human confirmation, then commit the updated sync metadata." \
    "feishu_solution_doc_url: https://<tenant>.feishu.cn/wiki/<solution-node>"
fi

if [[ "$sync_status" != "SYNCED" ]]; then
  fail \
    "TECH_SOLUTION_FEISHU/NOT_SYNCED" \
    "confirmed Feishu PRD technical solution sync status is '${sync_status:-missing}', not SYNCED" \
    "Create or update the Feishu child technical-solution document, then set feishu_solution_sync_status: SYNCED through the sync helper." \
    "feishu_solution_sync_status: SYNCED"
fi

if is_blankish "$recorded_hash"; then
  fail \
    "TECH_SOLUTION_FEISHU/MISSING_HASH" \
    "confirmed Feishu PRD technical solution sync is missing source hash" \
    "Run scripts/technical-solution-feishu-sync.sh changes/<change-id> so local metadata records the synced solution hash." \
    "feishu_solution_source_sha256: <sha256>"
fi

if [[ "$recorded_hash" != "$current_hash" ]]; then
  fail \
    "TECH_SOLUTION_FEISHU/STALE_SYNC" \
    "local technical solution changed after the last Feishu child document sync" \
    "Re-run scripts/technical-solution-feishu-sync.sh changes/<change-id>; the gate only passes when feishu_solution_source_sha256 matches the current local solution content." \
    "feishu_solution_source_sha256: $current_hash"
fi

printf 'PASS: Feishu technical solution child doc is synced for %s; source_sha256=%s\n' "$solution" "$current_hash"
