#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
gate="$root/scripts/agent-registry-gate.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0
out="$tmp_dir/out"
err="$tmp_dir/err"

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

run_expect_pass() {
  local label="$1"
  shift
  if "$@" >"$out" 2>"$err"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,80p' "$out" >&2 || true
    sed -n '1,80p' "$err" >&2 || true
  fi
}

run_expect_fail() {
  local label="$1" expected="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$label"
    sed -n '1,80p' "$out" >&2 || true
    return
  fi
  if grep -q "$expected" "$err"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,80p' "$out" >&2 || true
    sed -n '1,80p' "$err" >&2 || true
  fi
}

run_expect_pass "default registry passes" "$gate"

missing_required="$tmp_dir/missing-required.yml"
cat >"$missing_required" <<'YAML'
version: 1
agents:
  - agent_id: broken-reviewer
    kind: runtime_agent
YAML
run_expect_fail "registry missing required fields is blocked" "missing required key" \
  "$gate" "$missing_required"

duplicate="$tmp_dir/duplicate.yml"
cat >"$duplicate" <<'YAML'
version: 1
agents:
  - agent_id: duplicate-agent
    display_name: Duplicate A
    kind: runtime_agent
    adoption_level: active
    role_type: reviewer
    source: local
    source_files: [AGENTS.md]
    runtime_targets: [codex_generated]
    permission: read_only
    trigger_stage: review
    input_artifacts: [diff]
    output_artifacts: [review.md]
    output_contract: review_findings
    required_gates: [scripts/reviewer-gate.sh]
    gate_consumers: [scripts/reviewer-gate.sh]
    degradation: BLOCKED_OR_EXPLICIT_NA
  - agent_id: duplicate-agent
    display_name: Duplicate B
    kind: runtime_agent
    adoption_level: active
    role_type: reviewer
    source: local
    source_files: [AGENTS.md]
    runtime_targets: [codex_generated]
    permission: read_only
    trigger_stage: review
    input_artifacts: [diff]
    output_artifacts: [review.md]
    output_contract: review_findings
    required_gates: [scripts/reviewer-gate.sh]
    gate_consumers: [scripts/reviewer-gate.sh]
    degradation: BLOCKED_OR_EXPLICIT_NA
YAML
run_expect_fail "duplicate agent ids are blocked" "duplicate agent_id" \
  "$gate" "$duplicate"

missing_source="$tmp_dir/missing-source.yml"
cat >"$missing_source" <<'YAML'
version: 1
agents:
  - agent_id: missing-source-agent
    display_name: Missing Source
    kind: runtime_agent
    adoption_level: active
    role_type: reviewer
    source: local
    source_files: [missing/source.md]
    runtime_targets: [codex_generated]
    permission: read_only
    trigger_stage: review
    input_artifacts: [diff]
    output_artifacts: [review.md]
    output_contract: review_findings
    required_gates: [scripts/reviewer-gate.sh]
    gate_consumers: [scripts/reviewer-gate.sh]
    degradation: BLOCKED_OR_EXPLICIT_NA
YAML
run_expect_fail "missing source files are blocked" "source file not found" \
  "$gate" "$missing_source"

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: agent registry gate test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: agent registry gate test passed\n'
