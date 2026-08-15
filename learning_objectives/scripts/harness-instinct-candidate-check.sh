#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-instinct-candidate-check.sh <instinct-candidates.jsonl>

Validates sanitized instinct_candidate JSONL rows before any project/global
memory promotion discussion. This does not write memory or modify rules.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  printf 'CODE: %s\n' "$2" >&2
  printf 'FIX: %s\n' "$3" >&2
  exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

candidate_file="${1:-}"
[[ -n "$candidate_file" ]] || fail "missing candidate JSONL path" "INSTINCT/MISSING_PATH" "Pass a JSONL file path."
[[ -f "$candidate_file" ]] || fail "candidate JSONL file does not exist: $candidate_file" "INSTINCT/FILE_MISSING" "Create the file or pass the correct path."
command -v node >/dev/null 2>&1 || fail "node is required for JSONL validation" "INSTINCT/NODE_MISSING" "Install Node.js or use the workspace bundled runtime."

node - "$candidate_file" <<'NODE'
const fs = require('fs');

const file = process.argv[2];
const required = [
  'candidate_id',
  'change_id',
  'repo_id',
  'target_scope',
  'promotion_state',
  'confidence',
  'source_type',
  'issue_category',
  'proposed_rule',
  'evidence_ref',
];
const allowedFields = new Set(required);
const scopes = new Set(['repo', 'project', 'global']);
const states = new Set(['candidate', 'promoted_project', 'promoted_global', 'rejected', 'expired']);
const sources = new Set([
  'local_fact',
  'ecc_source',
  'sp_source',
  'official_doc',
  'multi_project_evidence',
  'ai_inference',
]);
const globalSources = new Set(['ecc_source', 'sp_source', 'official_doc', 'multi_project_evidence']);
const sensitivePattern = /(password|passwd|pwd\s*=|token\s*=|cookie|authorization|access[_-]?token|refresh[_-]?token|db[_-]?password|secret\s*=|private[_-]?key|BEGIN\s+(RSA|OPENSSH|PRIVATE)|select\s+.*from\s+)/i;

function fail(code, message, fix) {
  console.error(`FAIL: ${message}`);
  console.error(`CODE: ${code}`);
  console.error(`FIX: ${fix}`);
  process.exit(1);
}

function label(index, row) {
  return row && row.candidate_id ? `${row.candidate_id} line ${index}` : `line ${index}`;
}

const content = fs.readFileSync(file, 'utf8');
const lines = content.split(/\r?\n/).filter((line) => line.trim().length > 0);
if (lines.length === 0) {
  fail('INSTINCT/EMPTY_FILE', 'candidate JSONL has no rows', 'Add at least one sanitized instinct_candidate row.');
}

const scopeCounts = new Map();
for (let i = 0; i < lines.length; i += 1) {
  const lineNumber = i + 1;
  let row;
  try {
    row = JSON.parse(lines[i]);
  } catch (error) {
    fail('INSTINCT/INVALID_JSON', `invalid JSON at line ${lineNumber}: ${error.message}`, 'Write one valid JSON object per line.');
  }

  if (!row || Array.isArray(row) || typeof row !== 'object') {
    fail('INSTINCT/INVALID_ROW', `candidate row must be a JSON object at line ${lineNumber}`, 'Use an object with the required fields.');
  }

  for (const key of Object.keys(row)) {
    if (!allowedFields.has(key)) {
      fail('INSTINCT/UNKNOWN_FIELD', `${label(lineNumber, row)} has unknown field: ${key}`, 'Remove the field or update the contract and tests first.');
    }
  }

  for (const key of required) {
    if (row[key] === undefined || row[key] === null || String(row[key]).trim() === '') {
      fail('INSTINCT/MISSING_FIELD', `${label(lineNumber, row)} is missing required field: ${key}`, 'Add all fields documented in docs/architecture/harness-memory-profile.md.');
    }
  }

  for (const [key, value] of Object.entries(row)) {
    const text = String(value);
    if (sensitivePattern.test(text)) {
      fail('INSTINCT/SENSITIVE_VALUE', `${label(lineNumber, row)} field ${key} appears to contain sensitive or raw data`, 'Keep candidates sanitized: ids, counts, short rules, and evidence references only.');
    }
  }

  if (!scopes.has(row.target_scope)) {
    fail('INSTINCT/UNKNOWN_SCOPE', `${label(lineNumber, row)} has unknown target_scope: ${row.target_scope}`, 'Use one of repo, project, global.');
  }
  if (!states.has(row.promotion_state)) {
    fail('INSTINCT/UNKNOWN_STATE', `${label(lineNumber, row)} has unknown promotion_state: ${row.promotion_state}`, 'Use candidate, promoted_project, promoted_global, rejected, or expired.');
  }
  if (!sources.has(row.source_type)) {
    fail('INSTINCT/UNKNOWN_SOURCE', `${label(lineNumber, row)} has unknown source_type: ${row.source_type}`, 'Use local_fact, ecc_source, sp_source, official_doc, multi_project_evidence, or ai_inference.');
  }

  const confidence = Number(row.confidence);
  if (!Number.isFinite(confidence) || confidence < 0 || confidence > 1) {
    fail('INSTINCT/CONFIDENCE_RANGE', `${label(lineNumber, row)} confidence must be a number from 0 to 1`, 'Set confidence to a decimal between 0 and 1.');
  }

  if (String(row.proposed_rule).length > 280) {
    fail('INSTINCT/RULE_TOO_LONG', `${label(lineNumber, row)} proposed_rule is too long`, 'Keep proposed_rule at or below 280 characters and cite details in evidence_ref.');
  }

  if (row.target_scope === 'global') {
    if (!globalSources.has(row.source_type)) {
      fail('INSTINCT/GLOBAL_SOURCE', `${label(lineNumber, row)} global candidate needs non-local evidence source`, 'Use ecc_source, sp_source, official_doc, or multi_project_evidence for global candidates.');
    }
    if (confidence < 0.8) {
      fail('INSTINCT/GLOBAL_CONFIDENCE', `${label(lineNumber, row)} global candidate confidence is below 0.80`, 'Keep weak candidates at repo/project scope until more evidence exists.');
    }
  }

  if (row.promotion_state === 'promoted_project') {
    if (row.target_scope !== 'project') {
      fail('INSTINCT/PROMOTED_PROJECT_SCOPE', `${label(lineNumber, row)} promoted_project must target project scope`, 'Use target_scope=project for promoted_project.');
    }
    if (confidence < 0.7) {
      fail('INSTINCT/PROMOTED_PROJECT_CONFIDENCE', `${label(lineNumber, row)} promoted_project confidence is below 0.70`, 'Collect more evidence or keep the row as candidate.');
    }
  }

  if (row.promotion_state === 'promoted_global') {
    if (row.target_scope !== 'global') {
      fail('INSTINCT/PROMOTED_GLOBAL_SCOPE', `${label(lineNumber, row)} promoted_global must target global scope`, 'Use target_scope=global for promoted_global.');
    }
    if (confidence < 0.85) {
      fail('INSTINCT/PROMOTED_GLOBAL_CONFIDENCE', `${label(lineNumber, row)} promoted_global confidence is below 0.85`, 'Collect stronger external or multi-project evidence.');
    }
  }

  scopeCounts.set(row.target_scope, (scopeCounts.get(row.target_scope) || 0) + 1);
}

const scopeSummary = [...scopeCounts.entries()]
  .sort(([a], [b]) => a.localeCompare(b))
  .map(([scope, count]) => `${scope}:${count}`)
  .join(',');

console.log(`PASS: instinct candidates valid rows=${lines.length} scopes=${scopeSummary} file=${file}`);
NODE
