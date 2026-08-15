#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/change-artifacts-gate.sh [--historical] <change-dir>

Validates the artifact profile and root-file names for a change directory.
New changes fail closed. Historical changes can be checked with --historical,
which emits warnings for migration gaps and exits 0.
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

warn() {
  printf 'WARN: %s\n' "$1" >&2
}

historical=0
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --historical)
      historical=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      fail \
        "CHANGE_ARTIFACTS/UNKNOWN_ARG" \
        "unknown argument: $1" \
        "Use only --historical plus the change directory." \
        "scripts/change-artifacts-gate.sh --historical changes/old-change"
      ;;
    *)
      break
      ;;
  esac
done

[[ "$#" -eq 1 ]] || { usage; exit 2; }
change_dir="$1"
[[ -d "$change_dir" ]] || fail \
  "CHANGE_ARTIFACTS/MISSING_CHANGE_DIR" \
  "change directory not found: $change_dir" \
  "Pass an existing changes/<change-id> directory." \
  "scripts/change-artifacts-gate.sh changes/example"

field_value() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 1
  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*:" {
      sub("^[[:space:]]*" key "[[:space:]]*:[[:space:]]*", "")
      sub("[[:space:]]+$", "")
      print
      exit
    }
  ' "$file"
}

artifact_profile() {
  local value
  value="$(field_value "$change_dir/harness-status.md" "artifact_profile" || true)"
  if [[ -n "$value" ]]; then
    printf '%s\n' "$value"
    return
  fi
  value="$(field_value "$change_dir/spec.md" "artifact_profile" || true)"
  if [[ -n "$value" ]]; then
    printf '%s\n' "$value"
  fi
}

profile="$(artifact_profile || true)"
case "$profile" in
  S|s|tier-S|tier-s) profile="tier-s" ;;
  M|m|tier-M|tier-m) profile="tier-m" ;;
  L|l|tier-L|tier-l) profile="tier-l" ;;
  "")
    if [[ "$historical" -eq 1 ]]; then
      warn "historical change has no artifact_profile: $change_dir"
    else
      fail \
        "CHANGE_ARTIFACTS/MISSING_PROFILE" \
        "new change is missing artifact_profile marker" \
        "Create the change with scripts/change-scaffold.sh or add artifact_profile: tier-s|tier-m|tier-l to harness-status.md." \
        "scripts/change-scaffold.sh --tier S my-change"
    fi
    ;;
  *)
    if [[ "$historical" -eq 1 ]]; then
      warn "historical change has unknown artifact_profile=$profile: $change_dir"
      profile=""
    else
      fail \
        "CHANGE_ARTIFACTS/UNKNOWN_PROFILE" \
        "unknown artifact_profile: $profile" \
        "Use tier-s, tier-m, or tier-l." \
        "artifact_profile: tier-m"
    fi
    ;;
esac

allowed_names=(
  spec.md
  requirement-intake.md
  harness-status.md
  harness-state.yml
  plan.md
  contract.md
  api-contract.md
  technical-solution.md
  verification-map.md
  ai-test-plan.md
  test-agent-verification.md
  agent-dispatch-plan.md
  agent-candidate-confirmation.md
  ai-test-report.md
  verification-run-report.md
  review.md
  evidence.md
  retro.md
  skill-usage.md
  environment-readiness.md
  backend-test-plan.md
  ui-rule-checklist.md
  ui-confirmation.md
  data-model.md
  data-model-sql.md
  contract-delta.md
  decisions.md
  decision-matrix.md
  implementation-readiness.md
  pre-pr.md
  pre-pr-review.md
  pc-e2e-smoke-plan.md
  pc-e2e-smoke-report.md
  miniapp-local-env.md
  temporary-state-ledger.md
  codegraph-evidence.md
  local-routing.yml
  local-routing.env
  local-proxy.ndjson
  product-prd.md
  sit-checklist.md
  human-review-package.md
  test-data-readiness.md
  screenshot-test-evidence.md
  README.md
)

is_allowed_name() {
  local name="$1" allowed
  for allowed in "${allowed_names[@]}"; do
    [[ "$name" == "$allowed" ]] && return 0
  done
  return 1
}

while IFS= read -r file; do
  name="$(basename "$file")"
  if ! is_allowed_name "$name"; then
    if [[ "$historical" -eq 1 ]]; then
      warn "historical change has unknown root artifact: $name"
    else
      fail \
        "CHANGE_ARTIFACTS/UNKNOWN_ROOT_FILE" \
        "unknown root artifact in new change: $name" \
        "Use a registered artifact name or move supporting files under evidence/, runtime-smoke/, prd-ui/, tests/, or artifacts/." \
        "docs/architecture/change-artifacts-spec.md"
    fi
  fi
done < <(find "$change_dir" -maxdepth 1 -type f | sort)

required=()
case "$profile" in
  tier-s)
    required=(spec.md harness-status.md evidence.md)
    ;;
  tier-m)
    required=(spec.md harness-status.md evidence.md plan.md contract.md technical-solution.md verification-map.md ai-test-plan.md test-agent-verification.md agent-dispatch-plan.md skill-usage.md review.md)
    ;;
  tier-l)
    required=(spec.md harness-status.md evidence.md plan.md contract.md technical-solution.md verification-map.md ai-test-plan.md test-agent-verification.md agent-dispatch-plan.md skill-usage.md review.md environment-readiness.md ai-test-report.md decisions.md)
    ;;
esac

if [[ "${#required[@]}" -gt 0 ]]; then
  missing=()
  for artifact in "${required[@]}"; do
    [[ -f "$change_dir/$artifact" ]] || missing+=("$artifact")
  done
  if [[ "${#missing[@]}" -gt 0 ]]; then
    fail \
      "CHANGE_ARTIFACTS/MISSING_REQUIRED" \
      "missing required artifact(s) for $profile: ${missing[*]}" \
      "Create the missing files or re-run scaffold in a new change directory." \
      "scripts/change-scaffold.sh --tier ${profile#tier-} <change-id>"
  fi
fi

printf 'PASS: change artifacts gate passed for %s%s\n' "$change_dir" "${profile:+ ($profile)}"
