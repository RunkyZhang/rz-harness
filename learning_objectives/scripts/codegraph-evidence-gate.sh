#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/codegraph-evidence-gate.sh <codegraph-evidence.md | change-dir>

Checks CodeGraph evidence follows current CodeGraph guidance:
  preflight/status -> codegraph_explore or other MCP/CLI graph query
  HIT: no mandatory grep fallback
  PARTIAL/MISS/UNAVAILABLE: record downgrade and fallback evidence
and does not treat MISS/PARTIAL/UNAVAILABLE as no-impact proof.
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

target="${1:-}"
[[ -n "$target" ]] || fail \
  "CODEGRAPH_EVIDENCE/MISSING_PATH" \
  "missing CodeGraph evidence path" \
  "Pass changes/<change-id>/codegraph-evidence.md or changes/<change-id>." \
  "templates/codegraph-evidence.md"
if [[ -d "$target" ]]; then
  evidence="$target/codegraph-evidence.md"
else
  evidence="$target"
fi
[[ -f "$evidence" ]] || fail \
  "CODEGRAPH_EVIDENCE/MISSING_FILE" \
  "CodeGraph evidence file not found: $evidence" \
  "Create codegraph-evidence.md when CodeGraph is used for impact or route tracing." \
  "templates/codegraph-evidence.md"

status="$(awk '/^codegraph_evidence_status:/ { sub(/^codegraph_evidence_status:[[:space:]]*/, ""); print; exit }' "$evidence")"
[[ "$status" == "READY" ]] || fail \
  "CODEGRAPH_EVIDENCE/NOT_READY" \
  "codegraph_evidence_status is '${status:-missing}', not READY" \
  "Set codegraph_evidence_status: READY after recording exact-symbol and fallback evidence." \
  "codegraph_evidence_status: READY"

project_path="$(awk '/^projectPath:/ { sub(/^projectPath:[[:space:]]*/, ""); print; exit }' "$evidence")"
[[ -n "$project_path" && "$project_path" != "-" ]] || fail \
  "CODEGRAPH_EVIDENCE/MISSING_PROJECT_PATH" \
  "CodeGraph evidence must record the business repo projectPath" \
  "Run scripts/codegraph-preflight.sh <repo-id-or-path> and copy CODEGRAPH_PROJECT_PATH." \
  "projectPath: /absolute/business/repo"

grep -q 'codegraph-preflight' "$evidence" || fail \
  "CODEGRAPH_EVIDENCE/MISSING_PREFLIGHT" \
  "CodeGraph evidence is missing preflight/status evidence" \
  "Record scripts/codegraph-preflight.sh output before MCP/CLI graph queries." \
  "scripts/codegraph-preflight.sh backend-sales-management"

result="$(awk '/^result:/ { sub(/^result:[[:space:]]*/, ""); print; exit }' "$evidence")"
[[ "$result" =~ ^(HIT|PARTIAL|MISS|UNAVAILABLE)$ ]] || fail \
  "CODEGRAPH_EVIDENCE/MISSING_RESULT" \
  "CodeGraph evidence result must be HIT, PARTIAL, MISS, or UNAVAILABLE" \
  "Record the sensor result and downgrade path explicitly." \
  "result: PARTIAL"

if ! grep -qE 'codegraph_(explore|context|search|node|trace|callers|callees|impact)|codegraph (explore|query|node|callers|callees|impact|affected)' "$evidence"; then
  fail \
    "CODEGRAPH_EVIDENCE/MISSING_GRAPH_QUERY" \
    "CodeGraph evidence is missing a graph query result" \
    "Use codegraph_explore first for broad questions, or node/search/callers/trace for exact symbol work." \
    "codegraph_explore task=\"How does X work?\" projectPath=/absolute/repo"
fi

if [[ "$result" == "HIT" ]]; then
  if grep -qiE 'stale|pending sync|edited since the last index sync' "$evidence" \
    && ! grep -qiE 'Read them directly|direct read|已直接读取|freshness note|no staleness banner' "$evidence"; then
    fail \
      "CODEGRAPH_EVIDENCE/STALE_WITHOUT_FRESHNESS_NOTE" \
      "CodeGraph evidence mentions stale/pending files without a freshness follow-up" \
      "If CodeGraph reports a staleness banner, directly read the named files or record why the response is fresh." \
      "Freshness note: no staleness banner reported."
  fi
fi

if [[ "$result" =~ ^(PARTIAL|MISS|UNAVAILABLE)$ ]]; then
  if ! grep -qE 'rg|direct read|直接读|compile|test|Reviewer|downgrade|降级' "$evidence"; then
    fail \
      "CODEGRAPH_EVIDENCE/MISSING_DOWNGRADE_FALLBACK" \
      "CodeGraph degraded evidence must include fallback proof" \
      "Use rg/direct reads/compile/tests/Reviewer evidence when CodeGraph is partial, missing, or unavailable." \
      "Downgrade note: CodeGraph MISS does not prove no impact; fallback: rg ..."
  fi
fi

if grep -viE 'does not prove no impact|不能表示无影响|不代表无影响|不能证明无影响' "$evidence" \
  | grep -qiE 'no impact|无需测试|无影响' \
  && [[ "$result" =~ ^(PARTIAL|MISS|UNAVAILABLE)$ ]]; then
  fail \
    "CODEGRAPH_EVIDENCE/MISS_AS_NO_IMPACT" \
    "CodeGraph PARTIAL/MISS/UNAVAILABLE evidence is being treated as no impact" \
    "Record downgrade evidence and use rg/direct reads/compile/tests; do not infer no impact from a missed sensor." \
    "Downgrade note: CodeGraph MISS does not prove no impact."
fi

printf 'PASS: CodeGraph evidence gate passed for %s\n' "$evidence"
