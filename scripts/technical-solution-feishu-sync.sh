#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/technical-solution-feishu-sync.sh [--dry-run] [--skip-readback] [--as user|bot] [--title <title>] <technical-solution.md | change-dir>

Creates or updates the Feishu/Lark child document that mirrors a confirmed
technical-solution.md when the PRD source is a Feishu/Lark link.

The helper writes local sync metadata only after the remote update succeeds.
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

extract_wiki_node_token() {
  local source_url="$1" token
  case "$source_url" in
    *"/wiki/"*)
      token="${source_url#*/wiki/}"
      token="${token%%[\?#/]*}"
      printf '%s' "$token"
      ;;
  esac
}

default_title() {
  local file="$1" fallback="$2" title
  title="$(awk '/^# / { sub(/^# /, ""); print; exit }' "$file")"
  if [[ -n "$title" ]]; then
    printf '%s' "$title"
  else
    printf '%s 技术方案' "$fallback"
  fi
}

write_payload() {
  local source_file="$1" payload_file="$2"
  awk '
    BEGIN { in_mermaid = 0 }
    in_mermaid == 1 && /^[[:space:]]*```[[:space:]]*$/ {
      print "</whiteboard>"
      in_mermaid = 0
      next
    }
    in_mermaid == 1 {
      print
      next
    }
    /^[[:space:]]*```mermaid[[:space:]]*$/ {
      print "<whiteboard type=\"mermaid\">"
      in_mermaid = 1
      next
    }
    $0 !~ /^[[:space:]]*(feishu_solution_doc_url|feishu_solution_sync_status|feishu_solution_synced_at|feishu_solution_source_sha256|feishu_solution_readback_status)[[:space:]]*:/
  ' "$source_file" >"$payload_file"
}

set_field() {
  local file="$1" key="$2" value="$3" dir tmp
  dir="$(dirname "$file")"
  tmp="$(mktemp "$dir/.technical-solution-sync.XXXXXX")"
  awk -v key="$key" -v value="$value" '
    BEGIN { updated = 0 }
    $0 ~ "^[[:space:]]*" key "[[:space:]]*:" {
      print key ": " value
      updated = 1
      next
    }
    { print }
    END {
      if (updated == 0) {
        print key ": " value
      }
    }
  ' "$file" >"$tmp"
  mv "$tmp" "$file"
}

extract_created_doc_ref() {
  local output="$1" ref
  ref="$(printf '%s' "$output" | grep -Eo 'https?://[^"[:space:]]+' | head -n 1 || true)"
  if [[ -n "$ref" ]]; then
    printf '%s' "$ref"
    return 0
  fi
  if command -v jq >/dev/null 2>&1; then
    ref="$(printf '%s' "$output" | jq -r '.. | objects | (.url? // .obj_url? // .doc_url? // .obj_token? // .node_token? // empty)' 2>/dev/null | head -n 1 || true)"
    if [[ -n "$ref" && "$ref" != "null" ]]; then
      printf '%s' "$ref"
      return 0
    fi
  fi
  ref="$(printf '%s' "$output" | sed -n 's/.*"obj_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  [[ -n "$ref" ]] && printf '%s' "$ref"
}

dry_run=0
skip_readback=0
identity="user"
title_override=""
target=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --skip-readback)
      skip_readback=1
      shift
      ;;
    --as)
      identity="${2:-}"
      [[ -n "$identity" ]] || fail "TECH_SOLUTION_FEISHU_SYNC/MISSING_IDENTITY" "missing value for --as" "Pass --as user or --as bot." "--as user"
      shift 2
      ;;
    --title)
      title_override="${2:-}"
      [[ -n "$title_override" ]] || fail "TECH_SOLUTION_FEISHU_SYNC/MISSING_TITLE" "missing value for --title" "Pass a Feishu child document title." "--title \"<需求名称> 技术方案\""
      shift 2
      ;;
    --*)
      fail "TECH_SOLUTION_FEISHU_SYNC/UNKNOWN_OPTION" "unknown option: $1" "Use --help to inspect supported options." "scripts/technical-solution-feishu-sync.sh --dry-run changes/demo"
      ;;
    *)
      if [[ -n "$target" ]]; then
        fail "TECH_SOLUTION_FEISHU_SYNC/TOO_MANY_ARGS" "too many positional arguments" "Pass only one technical solution path or change dir." "scripts/technical-solution-feishu-sync.sh changes/demo"
      fi
      target="$1"
      shift
      ;;
  esac
done

[[ -n "$target" ]] || fail \
  "TECH_SOLUTION_FEISHU_SYNC/MISSING_PATH" \
  "missing technical solution path" \
  "Pass changes/<change-id>/technical-solution.md or changes/<change-id>/." \
  "scripts/technical-solution-feishu-sync.sh changes/demo"

if [[ -d "$target" ]]; then
  change_dir="${target%/}"
  solution="$change_dir/technical-solution.md"
else
  solution="$target"
  change_dir="$(dirname "$solution")"
fi

[[ -f "$solution" ]] || fail \
  "TECH_SOLUTION_FEISHU_SYNC/MISSING_FILE" \
  "technical solution file not found: $solution" \
  "Create technical-solution.md from templates/technical-solution.md first." \
  "changes/<change-id>/technical-solution.md"

confirmation_status="$(field_value "$solution" "confirmation_status")"
prd_source_type="$(field_value "$solution" "prd_source_type")"
prd_source_url="$(field_value "$solution" "prd_source_url")"
prd_source_node_token="$(field_value "$solution" "prd_source_node_token")"
doc_url="$(field_value "$solution" "feishu_solution_doc_url")"
change_id="$(basename "$change_dir")"
sync_title="${title_override:-$(default_title "$solution" "$change_id")}"
current_hash="$(solution_hash "$solution")"
synced_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

if ! is_feishu_source "$prd_source_type" "$prd_source_url"; then
  printf 'PASS: Feishu solution sync not required for %s\n' "$solution"
  exit 0
fi

[[ "$confirmation_status" == "CONFIRMED" ]] || fail \
  "TECH_SOLUTION_FEISHU_SYNC/PENDING_CONFIRMATION" \
  "technical solution must be confirmed before syncing to Feishu" \
  "Get explicit human confirmation first, then set confirmation_status: CONFIRMED and rerun this helper." \
  "confirmation_status: CONFIRMED"

payload_rel=".harness/tmp/${change_id}-technical-solution-feishu.md"
mkdir -p "$(dirname "$payload_rel")"
write_payload "$solution" "$payload_rel"

if is_blankish "$doc_url"; then
  parent_node_token="$prd_source_node_token"
  if is_blankish "$parent_node_token"; then
    parent_node_token="$(extract_wiki_node_token "$prd_source_url")"
  fi
  if is_blankish "$parent_node_token"; then
    fail \
      "TECH_SOLUTION_FEISHU_SYNC/MISSING_PARENT_NODE_TOKEN" \
      "cannot create Feishu child document because PRD wiki parent node token is missing" \
      "Set prd_source_node_token in technical-solution.md or use a Feishu Wiki URL that contains /wiki/<node_token>." \
      "prd_source_node_token: <PARENT_NODE_TOKEN>"
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    printf 'DRY-RUN: would create Feishu child technical solution document:\n'
    printf 'lark-cli wiki +node-create --as %q --parent-node-token %q --title %q --obj-type docx\n' "$identity" "$parent_node_token" "$sync_title"
    doc_url="<NEW_WIKI_OR_DOC_URL_FROM_NODE_CREATE>"
  else
    command -v lark-cli >/dev/null 2>&1 || fail \
      "TECH_SOLUTION_FEISHU_SYNC/MISSING_LARK_CLI" \
      "lark-cli is required to create the Feishu child document" \
      "Install/configure lark-cli or create the child document manually and set feishu_solution_doc_url." \
      "lark-cli wiki +node-create --as user --parent-node-token <PARENT_NODE_TOKEN> --title \"<需求名称> 技术方案\""
    create_output="$(lark-cli wiki +node-create --as "$identity" --parent-node-token "$parent_node_token" --title "$sync_title" --obj-type docx --format json)"
    doc_url="$(extract_created_doc_ref "$create_output")"
    [[ -n "$doc_url" ]] || fail \
      "TECH_SOLUTION_FEISHU_SYNC/CREATE_OUTPUT_UNPARSEABLE" \
      "Feishu child document was created but its URL/token could not be parsed from lark-cli output" \
      "Open the created child document manually, set feishu_solution_doc_url, then rerun this helper." \
      "feishu_solution_doc_url: https://<tenant>.feishu.cn/wiki/<solution-node>"
  fi
fi

if [[ "$dry_run" -eq 1 ]]; then
  printf 'DRY-RUN: would overwrite Feishu child document from local Markdown payload:\n'
  printf 'lark-cli docs +update --as %q --doc %q --command overwrite --doc-format markdown --content %q\n' "$identity" "$doc_url" "@$payload_rel"
  if [[ "$skip_readback" -eq 0 ]]; then
    printf 'DRY-RUN: would read back Feishu child document outline:\n'
    printf 'lark-cli docs +fetch --as %q --doc %q --scope outline --max-depth 2\n' "$identity" "$doc_url"
  fi
  printf 'DRY-RUN: would record local sync metadata:\n'
  printf 'feishu_solution_doc_url: %s\n' "$doc_url"
  printf 'feishu_solution_sync_status: SYNCED\n'
  printf 'feishu_solution_synced_at: %s\n' "$synced_at"
  printf 'feishu_solution_source_sha256: %s\n' "$current_hash"
  exit 0
fi

command -v lark-cli >/dev/null 2>&1 || fail \
  "TECH_SOLUTION_FEISHU_SYNC/MISSING_LARK_CLI" \
  "lark-cli is required to update the Feishu child document" \
  "Install/configure lark-cli or update the child document manually and record sync metadata." \
  "lark-cli docs +update --as user --doc <DOC_URL> --command overwrite --doc-format markdown --content @.harness/tmp/<change-id>-technical-solution-feishu.md"

lark-cli docs +update \
  --as "$identity" \
  --doc "$doc_url" \
  --command overwrite \
  --doc-format markdown \
  --content "@$payload_rel" >/dev/null

if [[ "$skip_readback" -eq 0 ]]; then
  lark-cli docs +fetch \
    --as "$identity" \
    --doc "$doc_url" \
    --scope outline \
    --max-depth 2 >/dev/null
fi

set_field "$solution" "feishu_solution_doc_url" "$doc_url"
set_field "$solution" "feishu_solution_sync_status" "SYNCED"
set_field "$solution" "feishu_solution_synced_at" "$synced_at"
set_field "$solution" "feishu_solution_source_sha256" "$current_hash"

printf 'PASS: synced technical solution to Feishu child document for %s\n' "$solution"
printf 'feishu_solution_doc_url: %s\n' "$doc_url"
printf 'feishu_solution_source_sha256: %s\n' "$current_hash"
