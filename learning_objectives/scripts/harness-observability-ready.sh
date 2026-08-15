#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

change_dir="$tmpdir/change"
mkdir -p "$change_dir"
cat >"$change_dir/technical-solution.md" <<'MARKDOWN'
confirmation_status: CONFIRMED
allowed_next_stage: code_start
MARKDOWN
cat >"$change_dir/ai-test-report.md" <<'MARKDOWN'
confirmation_status: PENDING
recommendation: 修复后重测
MARKDOWN

status_json="$(scripts/harness-status.sh --json "$change_dir")"
STATUS_JSON="$status_json" node <<'NODE'
const raw = process.env.STATUS_JSON || "";
let status;
try {
  status = JSON.parse(raw);
} catch (error) {
  console.error(`FAIL: harness-status did not emit valid JSON: ${error.message}`);
  process.exit(1);
}

const required = {
  change_id: "string",
  current_phase: "string",
  next_action: "string",
  can_proceed: "boolean",
  technical_solution: "object",
  ai_test_plan: "object",
  environment_readiness: "object",
  test_agent_verification: "object",
  ai_test_report: "object",
  ui_rule_checklist: "object",
  ui_confirmation: "object",
  artifacts: "object",
};

for (const [key, type] of Object.entries(required)) {
  if (typeof status[key] !== type || status[key] === null) {
    console.error(`FAIL: harness-status JSON missing ${key} as ${type}`);
    process.exit(1);
  }
}
NODE

scripts/adapter-compliance-gate.sh docs/architecture/adapter-compliance.md >/dev/null
scripts/no-personal-paths.sh >/dev/null
scripts/ecc/ecc-sidecar.sh status >/dev/null

[[ -f docs/architecture/ecc-integration.md ]] || { printf 'FAIL: missing ECC integration docs\n' >&2; exit 1; }
[[ -f evals/harness-config-quality/scenario.json ]] || { printf 'FAIL: missing harness config eval scenario\n' >&2; exit 1; }
[[ -f evals/harness-config-quality/verifier-result.json ]] || { printf 'FAIL: missing harness config eval verifier result\n' >&2; exit 1; }

printf 'PASS: harness observability readiness signals are available; ECC remains optional\n'
