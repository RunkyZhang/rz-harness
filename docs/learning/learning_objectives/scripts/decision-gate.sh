#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/decision-gate.sh <decisions.md | change-dir>
  scripts/decision-gate.sh --notify <decisions.md | change-dir>

Async-approval decision ledger helper for BLOCKING decisions that surface
mid-implementation (see templates/decisions.md).

Modes:
  (default)   Gate. FAIL (exit 1) if any decision has `status: pending`.
              A missing decisions.md means no async decisions -> PASS.
  --notify    Render pending decisions into Lark-ready text (DRY-RUN only).
              This MVP NEVER sends. If SFA_DECISION_LARK_CHAT is set it prints
              the lark-cli command it WOULD run, without executing it.

Environment:
  SFA_DECISION_LARK_CHAT   Target Lark chat/open_id (set in config/repos.local.sh).
                           Empty by default -> dry-run note only (fail-closed).
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

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

mode="gate"
if [[ "${1:-}" == "--notify" ]]; then
  mode="notify"
  shift
fi

target="${1:-}"
[[ -n "$target" ]] || fail \
  "DECISION_GATE/MISSING_PATH" \
  "missing decisions path" \
  "Pass a decisions.md file or a change dir, e.g. changes/<change-id>/decisions.md or changes/<change-id>/." \
  "templates/decisions.md"

if [[ -d "$target" ]]; then
  ledger="$target/decisions.md"
else
  ledger="$target"
fi

# Extract pending blocks: lines "ID<TAB>question<TAB>options<TAB>default"
pending_blocks() {
  awk '
    function val(line){ sub(/^[^:]*:[[:space:]]*/, "", line); sub(/[[:space:]]+$/, "", line); return line }
    /^##[[:space:]]+DEC-/ {
      if (id != "" && status == "pending") print id "\t" q "\t" opt "\t" def
      id=$0; sub(/^##[[:space:]]+/, "", id); status=""; q=""; opt=""; def=""
      next
    }
    /^-[[:space:]]+status:/   { status=val($0) }
    /^-[[:space:]]+question:/ { q=val($0) }
    /^-[[:space:]]+options:/  { opt=val($0) }
    /^-[[:space:]]+default:/  { def=val($0) }
    END { if (id != "" && status == "pending") print id "\t" q "\t" opt "\t" def }
  ' "$1"
}

if [[ ! -f "$ledger" ]]; then
  if [[ "$mode" == "notify" ]]; then
    printf 'NOTICE: no decisions ledger at %s; nothing to notify.\n' "$ledger"
  else
    printf 'PASS: no decisions ledger at %s (no async decisions to resolve)\n' "$ledger"
  fi
  exit 0
fi

blocks="$(pending_blocks "$ledger")"

if [[ "$mode" == "notify" ]]; then
  if [[ -z "$blocks" ]]; then
    printf 'NOTICE: no pending decisions in %s; nothing to notify.\n' "$ledger"
    exit 0
  fi
  count="$(printf '%s\n' "$blocks" | wc -l | tr -d ' ')"
  msg="$(
    printf '[决策待办] %s 项待拍板 — %s\n' "$count" "$ledger"
    i=0
    while IFS=$'\t' read -r id q opt def; do
      i=$((i + 1))
      printf '%d. %s\n   问题: %s\n   选项: %s\n   未决默认(fail-closed): %s\n' "$i" "$id" "$q" "$opt" "$def"
    done <<< "$blocks"
    printf '请回复 approve/reject，并在 %s 填 decided_by / decided_at。\n' "$ledger"
  )"
  printf '%s\n' "$msg"
  printf -- '---\n'
  if [[ -n "${SFA_DECISION_LARK_CHAT:-}" ]]; then
    printf 'DRY-RUN: would send (NOT executed) -> lark-cli im send --chat %q --text <上述文案>\n' "$SFA_DECISION_LARK_CHAT"
  else
    printf 'NOTE: set SFA_DECISION_LARK_CHAT in config/repos.local.sh to target a chat. This MVP never auto-sends; copy the text above or wire --send in a follow-up change.\n'
  fi
  exit 0
fi

# gate mode
if [[ -z "$blocks" ]]; then
  printf 'PASS: no pending decisions in %s\n' "$ledger"
  exit 0
fi

count="$(printf '%s\n' "$blocks" | wc -l | tr -d ' ')"
printf 'Pending decisions (%s):\n' "$count" >&2
while IFS=$'\t' read -r id q opt def; do
  printf ' - %s | %s\n' "$id" "$q" >&2
done <<< "$blocks"
fail \
  "DECISION_GATE/PENDING_DECISIONS" \
  "$count decision(s) still pending in $ledger" \
  "Resolve each pending decision (set status: approved|rejected, fill decided_by/decided_at) before merge. Use --notify to render a Lark message for async sign-off." \
  "templates/decisions.md"
