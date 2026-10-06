#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local file="$1" pattern="$2" label="$3"
  grep -qF "$pattern" "$file" || fail "$label"
}

doc="$root/docs/architecture/harness-memory-profile.md"
checker="$root/scripts/harness-instinct-candidate-check.sh"
docs_index="$root/docs/README.md"

[[ -f "$doc" ]] || fail "memory profile contract is missing"
[[ -x "$checker" ]] || fail "instinct candidate checker is missing or not executable"

assert_contains "$doc" 'auto_promotion_allowed: false' "contract must forbid automatic promotion"
assert_contains "$doc" 'project_memory_scope' "contract must define project memory scope"
assert_contains "$doc" 'global_memory_scope' "contract must define global memory scope"
assert_contains "$doc" 'repo' "contract must mention repo scope"
assert_contains "$doc" 'project' "contract must mention project scope"
assert_contains "$doc" 'global' "contract must mention global scope"
assert_contains "$doc" 'instinct_candidate' "contract must define instinct candidate records"
assert_contains "$doc" 'confidence' "contract must define confidence"
assert_contains "$doc" 'evidence_ref' "contract must require evidence_ref"
assert_contains "$doc" 'human_review_required: true' "contract must require human review before promotion"
assert_contains "$doc" '[ECC-SOURCE]' "contract must attribute ECC source usage"
assert_contains "$doc" '[SP-SOURCE]' "contract must attribute superpowers source usage"
assert_contains "$doc" '[AI-INFERENCE]' "contract must distinguish AI inference"

assert_contains "$docs_index" 'harness-memory-profile.md' "docs index must reference memory profile contract"
assert_contains "$docs_index" 'harness-instinct-candidate-check.sh' "docs index must reference instinct candidate checker"
assert_contains "$docs_index" 'harness-memory-profile-test.sh' "docs index must reference memory profile test"

valid_project="$tmpdir/valid-project.jsonl"
cat >"$valid_project" <<'EOF'
{"candidate_id":"SFA-INST-001","change_id":"harness-evolution-architecture","repo_id":"sfa-ai-harness","target_scope":"project","promotion_state":"candidate","confidence":"0.72","source_type":"local_fact","issue_category":"harness-memory-isolation","proposed_rule":"Keep raw observations local and promote only sanitized project candidates.","evidence_ref":"changes/harness-evolution-architecture/evidence.md"}
EOF
"$checker" "$valid_project" >"$tmpdir/valid-project.out"
assert_contains "$tmpdir/valid-project.out" 'PASS: instinct candidates valid' "valid project candidate was not accepted"
printf 'PASS: valid project instinct candidate is accepted\n'

valid_global="$tmpdir/valid-global.jsonl"
cat >"$valid_global" <<'EOF'
{"candidate_id":"SFA-INST-002","change_id":"harness-evolution-architecture","repo_id":"sfa-ai-harness","target_scope":"global","promotion_state":"candidate","confidence":"0.85","source_type":"ecc_source","issue_category":"hook-lifecycle","proposed_rule":"Keep lifecycle reminders bounded and separate from raw transcript persistence.","evidence_ref":"docs/research/ecc-superpowers-source-evidence.md"}
EOF
"$checker" "$valid_global" >"$tmpdir/valid-global.out"
assert_contains "$tmpdir/valid-global.out" 'PASS: instinct candidates valid' "valid global candidate was not accepted"
printf 'PASS: global candidate with external source and confidence is accepted\n'

bad_global="$tmpdir/bad-global.jsonl"
cat >"$bad_global" <<'EOF'
{"candidate_id":"SFA-INST-003","change_id":"harness-evolution-architecture","repo_id":"sfa-ai-harness","target_scope":"global","promotion_state":"candidate","confidence":"0.91","source_type":"local_fact","issue_category":"local-only","proposed_rule":"Promote one local observation to global memory.","evidence_ref":"changes/harness-evolution-architecture/evidence.md"}
EOF
if "$checker" "$bad_global" >"$tmpdir/bad-global.out" 2>&1; then
  fail "global candidate based only on local_fact was accepted"
fi
assert_contains "$tmpdir/bad-global.out" 'INSTINCT/GLOBAL_SOURCE' "global source rejection code missing"
printf 'PASS: global candidate needs non-local evidence source\n'

low_confidence="$tmpdir/low-confidence.jsonl"
cat >"$low_confidence" <<'EOF'
{"candidate_id":"SFA-INST-004","change_id":"harness-evolution-architecture","repo_id":"sfa-ai-harness","target_scope":"global","promotion_state":"candidate","confidence":"0.60","source_type":"sp_source","issue_category":"candidate-quality","proposed_rule":"Use low confidence global candidate.","evidence_ref":"docs/research/ecc-superpowers-source-evidence.md"}
EOF
if "$checker" "$low_confidence" >"$tmpdir/low-confidence.out" 2>&1; then
  fail "low-confidence global candidate was accepted"
fi
assert_contains "$tmpdir/low-confidence.out" 'INSTINCT/GLOBAL_CONFIDENCE' "global confidence rejection code missing"
printf 'PASS: global candidate needs minimum confidence\n'

sensitive="$tmpdir/sensitive.jsonl"
cat >"$sensitive" <<'EOF'
{"candidate_id":"SFA-INST-005","change_id":"harness-evolution-architecture","repo_id":"sfa-ai-harness","target_scope":"project","promotion_state":"candidate","confidence":"0.72","source_type":"local_fact","issue_category":"secret-leak","proposed_rule":"Never record token=fixture in memory.","evidence_ref":"changes/harness-evolution-architecture/evidence.md"}
EOF
if "$checker" "$sensitive" >"$tmpdir/sensitive.out" 2>&1; then
  fail "sensitive candidate was accepted"
fi
assert_contains "$tmpdir/sensitive.out" 'INSTINCT/SENSITIVE_VALUE' "sensitive value rejection code missing"
printf 'PASS: sensitive instinct candidate content is rejected\n'

missing_field="$tmpdir/missing-field.jsonl"
cat >"$missing_field" <<'EOF'
{"candidate_id":"SFA-INST-006","change_id":"harness-evolution-architecture","repo_id":"sfa-ai-harness","target_scope":"project","promotion_state":"candidate","confidence":"0.72","source_type":"local_fact","issue_category":"missing-evidence","proposed_rule":"Missing evidence ref must fail."}
EOF
if "$checker" "$missing_field" >"$tmpdir/missing-field.out" 2>&1; then
  fail "candidate missing evidence_ref was accepted"
fi
assert_contains "$tmpdir/missing-field.out" 'INSTINCT/MISSING_FIELD' "missing field rejection code missing"
printf 'PASS: missing required candidate fields are rejected\n'

printf 'PASS: harness memory profile test passed\n'
