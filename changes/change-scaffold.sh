#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  changes/change-scaffold.sh --tier S|M|L [--changes-dir <dir>] <change-id>

Creates the minimum change artifact skeleton for the selected tier. The command
refuses to overwrite an existing change directory.

RZ notes:
  - Lives in changes/ as change-control tooling, not inside a change package.
  - Does not read PRD and does not let the model write body text.
  - M/L copies templates/agent-dispatch-plan.md instead of calling
    specimen agent-dispatch-plan.sh / agent-registry.yml.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tier=""
changes_dir="$root/changes"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --tier)
      tier="${2:-}"
      [[ -n "$tier" ]] || fail "missing value for --tier"
      shift 2
      ;;
    --changes-dir)
      changes_dir="${2:-}"
      [[ -n "$changes_dir" ]] || fail "missing value for --changes-dir"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      fail "unknown argument: $1"
      ;;
    *)
      break
      ;;
  esac
done

[[ "$#" -eq 1 ]] || { usage; exit 2; }
change_id="$1"
[[ "$change_id" =~ ^[A-Za-z0-9._-]+$ ]] || fail "change-id contains unsupported characters: $change_id"

tier_upper="$(printf '%s' "$tier" | tr '[:lower:]' '[:upper:]')"
case "$tier_upper" in
  S) profile="tier-s"; spec_template="spec-tier-s.md" ;;
  M) profile="tier-m"; spec_template="spec-tier-m.md" ;;
  L) profile="tier-l"; spec_template="spec-tier-l.md" ;;
  *) fail "tier must be S, M, or L" ;;
esac

target="$changes_dir/$change_id"
[[ ! -e "$target" ]] || fail "change directory already exists: $target"
mkdir -p "$target"

copy_template() {
  local template="$1" dest="$2"
  [[ -f "$root/templates/$template" ]] || fail "missing template: templates/$template"
  sed "s|<change-id>|$change_id|g" "$root/templates/$template" >"$target/$dest"
}

write_evidence() {
  cat >"$target/evidence.md" <<EOF
# Evidence: $change_id

> 记录可复核验证证据。禁止记录 token、cookie、DB password、客户资料、未脱敏 SQL 结果或原始私密 prompt。

| Check | Command / Source | Result | Summary |
| --- | --- | --- | --- |
| Scaffold | \`changes/change-scaffold.sh --tier $tier_upper $change_id\` | \`PASS\` | Initial artifact skeleton created. |
EOF
}

write_status() {
  {
    printf 'artifact_profile: %s\n' "$profile"
    printf 'artifact_schema_version: 1\n\n'
    sed "s|<change-id>|$change_id|g" "$root/templates/harness-status.md"
  } >"$target/harness-status.md"
}

copy_template "$spec_template" "spec.md"
write_status
write_evidence

if [[ "$profile" == "tier-m" || "$profile" == "tier-l" ]]; then
  copy_template "plan-tier-m.md" "plan.md"
  copy_template "api-contract.md" "contract.md"
  copy_template "technical-solution.md" "technical-solution.md"
  copy_template "verification-map.md" "verification-map.md"
  copy_template "ai-test-plan.md" "ai-test-plan.md"
  copy_template "test-agent-verification.md" "test-agent-verification.md"
  copy_template "agent-dispatch-plan.md" "agent-dispatch-plan.md"
  copy_template "skill-usage.md" "skill-usage.md"
  copy_template "review.md" "review.md"
fi

if [[ "$profile" == "tier-l" ]]; then
  copy_template "environment-readiness.md" "environment-readiness.md"
  copy_template "ai-test-report.md" "ai-test-report.md"
  copy_template "decisions.md" "decisions.md"
fi

printf 'PASS: change scaffold created %s with %s\n' "$target" "$profile"
printf 'NEXT: gates/change-artifacts-gate.sh %s\n' "$target"
