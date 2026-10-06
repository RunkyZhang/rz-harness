#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-replay-fixture-eval.sh [--root <repo-root>]

Grades sanitized replay fixtures under evals/harness-behavior/replay.
This runner does not execute a live agent; it checks transcript, diff, and
artifact fixtures against deterministic expectations.
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

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --root)
      root="${2:-}"
      [[ -n "$root" ]] || fail \
        "HARNESS_REPLAY_FIXTURE_EVAL/MISSING_ROOT" \
        "missing value for --root" \
        "Pass a repository root containing evals/harness-behavior/replay." \
        "scripts/harness-replay-fixture-eval.sh --root /path/to/repo"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail \
        "HARNESS_REPLAY_FIXTURE_EVAL/UNKNOWN_ARG" \
        "unknown argument: $1" \
        "Use --root only when validating a fixture copy." \
        "scripts/harness-replay-fixture-eval.sh"
      ;;
  esac
done

replay_dir="$root/evals/harness-behavior/replay"
[[ -d "$replay_dir" ]] || fail \
  "HARNESS_REPLAY_FIXTURE_EVAL/MISSING_REPLAY_DIR" \
  "missing replay fixture directory: $replay_dir" \
  "Create evals/harness-behavior/replay/<scenario>/<fixture>/." \
  "evals/harness-behavior/replay/technical-solution-stop/positive-stop-no-edit/"

grade_fixture() {
  local fixture_dir="$1" rel="$2"
  local metadata="$fixture_dir/metadata.env"
  local transcript="$fixture_dir/transcript.md"
  local diff_stat="$fixture_dir/diff.stat"

  [[ -f "$metadata" ]] || fail \
    "HARNESS_REPLAY_FIXTURE_EVAL/MISSING_METADATA" \
    "missing metadata.env for replay fixture: $rel" \
    "Add metadata.env with SCENARIO_ID, EXPECTED_RESULT, and fixture rules." \
    "$rel/metadata.env"

  SCENARIO_ID=""
  EXPECTED_RESULT=""
  FIXTURE_TYPE=""
  REQUIRES_CLEAN_DIFF=""
  REQUIRED_ARTIFACTS=""
  REQUIRED_TRANSCRIPT_PATTERNS=""
  FORBIDDEN_TRANSCRIPT_PATTERNS=""

  # Fixtures are versioned, trusted harness inputs. Keep metadata shell-simple.
  # shellcheck disable=SC1090
  . "$metadata"

  [[ -n "$SCENARIO_ID" ]] || fail \
    "HARNESS_REPLAY_FIXTURE_EVAL/MISSING_REQUIRED_FIELD" \
    "metadata missing SCENARIO_ID: $rel" \
    "Set SCENARIO_ID to the scenario directory name." \
    "SCENARIO_ID=technical-solution-stop"
  [[ -n "$EXPECTED_RESULT" ]] || fail \
    "HARNESS_REPLAY_FIXTURE_EVAL/MISSING_REQUIRED_FIELD" \
    "metadata missing EXPECTED_RESULT: $rel" \
    "Set EXPECTED_RESULT to PASS or FAIL." \
    "EXPECTED_RESULT=PASS"
  [[ -n "$FIXTURE_TYPE" ]] || fail \
    "HARNESS_REPLAY_FIXTURE_EVAL/MISSING_REQUIRED_FIELD" \
    "metadata missing FIXTURE_TYPE: $rel" \
    "Set FIXTURE_TYPE to positive or negative." \
    "FIXTURE_TYPE=positive"

  case "$EXPECTED_RESULT" in
    PASS|FAIL) ;;
    *)
      fail \
        "HARNESS_REPLAY_FIXTURE_EVAL/INVALID_EXPECTED_RESULT" \
        "EXPECTED_RESULT must be PASS or FAIL: $rel" \
        "Use deterministic expected result labels." \
        "EXPECTED_RESULT=FAIL"
      ;;
  esac

  local observed="PASS"
  local reason="matched"

  if [[ ! -f "$transcript" ]]; then
    observed="FAIL"
    reason="missing transcript.md"
  elif [[ ! -f "$diff_stat" ]]; then
    observed="FAIL"
    reason="missing diff.stat"
  fi

  if [[ "$observed" == "PASS" && "$REQUIRES_CLEAN_DIFF" == "1" && -s "$diff_stat" ]]; then
    observed="FAIL"
    reason="diff.stat is not empty"
  fi

  if [[ "$observed" == "PASS" && -n "$REQUIRED_ARTIFACTS" ]]; then
    local artifact
    printf '%s' "$REQUIRED_ARTIFACTS" | tr ',' '\n' | while IFS= read -r artifact; do
      [[ -z "$artifact" ]] && continue
      [[ -f "$fixture_dir/$artifact" ]] || exit 9
    done || {
      observed="FAIL"
      reason="required artifact missing"
    }
  fi

  if [[ "$observed" == "PASS" && -n "$REQUIRED_TRANSCRIPT_PATTERNS" ]]; then
    local pattern
    while IFS= read -r pattern; do
      [[ -z "$pattern" ]] && continue
      if ! grep -Eq "$pattern" "$transcript"; then
        observed="FAIL"
        reason="required transcript pattern missing: $pattern"
        break
      fi
    done <<EOF
$(printf '%s' "$REQUIRED_TRANSCRIPT_PATTERNS" | tr ';' '\n')
EOF
  fi

  if [[ "$observed" == "PASS" && -n "$FORBIDDEN_TRANSCRIPT_PATTERNS" ]]; then
    local pattern
    while IFS= read -r pattern; do
      [[ -z "$pattern" ]] && continue
      if grep -Eq "$pattern" "$transcript"; then
        observed="FAIL"
        reason="forbidden transcript pattern found: $pattern"
        break
      fi
    done <<EOF
$(printf '%s' "$FORBIDDEN_TRANSCRIPT_PATTERNS" | tr ';' '\n')
EOF
  fi

  printf 'FIXTURE %s EXPECTED=%s OBSERVED=%s REASON=%s\n' "$rel" "$EXPECTED_RESULT" "$observed" "$reason"

  if [[ "$EXPECTED_RESULT" != "$observed" ]]; then
    fail \
      "HARNESS_REPLAY_FIXTURE_EVAL/UNEXPECTED_RESULT" \
      "replay fixture grader result did not match expectation: $rel" \
      "Fix the fixture metadata or grader rules before trusting this suite." \
      "EXPECTED=$EXPECTED_RESULT OBSERVED=$observed"
  fi
}

total=0
matched=0
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
fixtures="$tmpdir/fixtures"

find "$replay_dir" -mindepth 2 -maxdepth 2 -type d | sort >"$fixtures"
[[ -s "$fixtures" ]] || fail \
  "HARNESS_REPLAY_FIXTURE_EVAL/MISSING_FIXTURES" \
  "no replay fixtures found under $replay_dir" \
  "Add at least one scenario fixture directory with metadata.env." \
  "evals/harness-behavior/replay/technical-solution-stop/positive-stop-no-edit/"

while IFS= read -r fixture_dir; do
  rel="${fixture_dir#"$replay_dir"/}"
  grade_fixture "$fixture_dir" "$rel"
  total=$((total + 1))
  matched=$((matched + 1))
done <"$fixtures"

printf 'EVAL_TYPE=REPLAY_FIXTURE\n'
printf 'LIVE_AGENT_TRACE_SUPPORTED=0\n'
printf 'REPLAY_FIXTURE_TOTAL=%s\n' "$total"
printf 'REPLAY_FIXTURE_MATCHED=%s\n' "$matched"
printf 'PASS: replay fixture eval completed\n'
