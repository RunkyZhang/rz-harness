#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/confidence-gate.sh <spec-file>

Checks:
  - spec contains [FACT], [ASSUMP], and [QUESTION] sections/items
  - blocking [QUESTION] items are not left unresolved

Environment:
  STRICT_QUESTIONS=1  Treat every QUESTION line as blocking, including non_blocking_questions
USAGE
}

fail() {
  local code="$1"
  local message="$2"
  local fix="$3"
  local sample="$4"
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

spec_file="${1:-}"
[[ -n "$spec_file" ]] || fail \
  "CONFIDENCE_GATE/MISSING_SPEC_FILE" \
  "missing spec file" \
  "Pass the active change spec path, for example changes/<change-id>/spec.md." \
  "templates/spec-tier-s.md"
[[ -f "$spec_file" ]] || fail \
  "CONFIDENCE_GATE/SPEC_FILE_NOT_FOUND" \
  "spec file not found: $spec_file" \
  "Create the active change spec first, then rerun this gate with that path." \
  "templates/spec-tier-s.md"

grep -q '\[FACT\]' "$spec_file" || fail \
  "CONFIDENCE_GATE/MISSING_FACT" \
  "missing [FACT] entries" \
  "Add at least one [FACT] backed by PRD, user confirmation, existing code, or contract." \
  "templates/spec-tier-s.md"
grep -q '\[ASSUMP\]' "$spec_file" || fail \
  "CONFIDENCE_GATE/MISSING_ASSUMP" \
  "missing [ASSUMP] entries" \
  "Add [ASSUMP] entries only for unresolved inference; use [ASSUMP] None. when there are none." \
  "templates/spec-tier-s.md"
grep -q '\[QUESTION\]' "$spec_file" || fail \
  "CONFIDENCE_GATE/MISSING_QUESTION" \
  "missing [QUESTION] entries" \
  "Add blocking [QUESTION] items or put confirmed non-blocking items under non_blocking_questions:." \
  "templates/spec-tier-s.md"

question_lines="$(grep -n '\[QUESTION\]' "$spec_file" || true)"
non_blocking_question_lines="$(
  awk '
    /^[[:space:]]*non_blocking_questions:[[:space:]]*$/ { in_non_blocking=1; next }
    in_non_blocking && /^[[:space:]]*$/ { next }
    in_non_blocking && /^[[:space:]]*-/ {
      if ($0 ~ /\[QUESTION\]/) {
        print FNR ":" $0
      }
      next
    }
    in_non_blocking { in_non_blocking=0 }
  ' "$spec_file"
)"

if [[ -n "$question_lines" ]]; then
  if [[ "${STRICT_QUESTIONS:-0}" == "1" ]]; then
    blocking_lines="$question_lines"
  elif [[ -n "$non_blocking_question_lines" ]]; then
    blocking_lines="$(
      grep -Fvx -f <(printf '%s\n' "$non_blocking_question_lines") \
        <(printf '%s\n' "$question_lines") \
        || true
    )"
  else
    blocking_lines="$question_lines"
  fi

  if [[ -n "$blocking_lines" ]]; then
    printf 'FAIL: unresolved [QUESTION] entries found in %s\n' "$spec_file" >&2
    printf 'CODE: CONFIDENCE_GATE/UNRESOLVED_QUESTION\n' >&2
    printf 'FIX: Resolve each blocking [QUESTION] as [FACT] with a source, or move explicitly non-blocking items under non_blocking_questions:.\n' >&2
    printf 'SAMPLE: templates/spec-tier-s.md\n' >&2
    printf '%s\n' "$blocking_lines" >&2
    exit 1
  fi
fi

printf 'PASS: confidence gate passed for %s\n' "$spec_file"
