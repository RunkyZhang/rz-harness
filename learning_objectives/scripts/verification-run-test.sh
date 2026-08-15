#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

run_expect_pass() {
  local name="$1"
  shift
  if "$@" >"$out" 2>"$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,40p' "$out" >&2 || true
    sed -n '1,40p' "$err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local name="$1"
  local expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$name"
    sed -n '1,40p' "$out" >&2 || true
    return
  fi

  if grep -q "^CODE: ${expected_code}$" "$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,40p' "$out" >&2 || true
    sed -n '1,40p' "$err" >&2 || true
  fi
}

tmpdir="$(mktemp -d)"
out="$tmpdir/out"
err="$tmpdir/err"
export SFA_HARNESS_TELEMETRY_DIR="$tmpdir/telemetry"
trap 'rm -rf "$tmpdir"' EXIT

valid_dir="$tmpdir/valid-change"
mkdir -p "$valid_dir"
cat >"$valid_dir/verification-map.md" <<'MARKDOWN'
# Verification Map

```yaml
verification_map_status: READY
```

| ID | Constraint | Source | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| VM-001 | Harness script syntax stays valid | harness | shell: bash -n scripts/verification-map-gate.sh | changes/demo/verification-run-report.md | PLANNED |
| VM-002 | Manual browser comparison was reviewed | product confirmation | manual: compare PRD screenshot and local screenshot | changes/demo/ui-confirmation.md | PASS |
| VM-003 | Native camera not touched | user confirmation | N/A | N/A: fixture excludes native camera | N/A |
MARKDOWN

run_expect_pass "verification run executes shell rows and writes report" \
  "$root/scripts/verification-run.sh" "$valid_dir"
if [[ -f "$valid_dir/verification-run-report.md" ]] \
  && grep -q '| VM-001 | shell | PASS | exit=0 |' "$valid_dir/verification-run-report.md" \
  && grep -q '| VM-002 | manual | PASS | recorded manual evidence |' "$valid_dir/verification-run-report.md" \
  && grep -q '| VM-003 | N/A | SKIP | explicit N/A row |' "$valid_dir/verification-run-report.md" \
  && grep -q 'run_status: PASS' "$valid_dir/verification-run-report.md"; then
  pass "verification run report records shell/manual/na outcomes"
else
  fail "verification run report records shell/manual/na outcomes"
  sed -n '1,120p' "$valid_dir/verification-run-report.md" >&2 || true
fi

if grep -q '"event_type":"verification_run_event"' "$SFA_HARNESS_TELEMETRY_DIR/events.jsonl" \
  && grep -q '"result":"PASS"' "$SFA_HARNESS_TELEMETRY_DIR/events.jsonl"; then
  pass "verification run records local telemetry"
else
  fail "verification run records local telemetry"
  sed -n '1,80p' "$err" >&2 || true
fi

failing_dir="$tmpdir/failing-change"
mkdir -p "$failing_dir"
cat >"$failing_dir/verification-map.md" <<'MARKDOWN'
# Verification Map

```yaml
verification_map_status: READY
```

| ID | Constraint | Source | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| VM-001 | Broken command blocks closeout | harness | shell: false | changes/demo/verification-run-report.md | PLANNED |
MARKDOWN

run_expect_fail_with_code "verification run blocks failing shell rows" \
  "VERIFICATION_RUN/SHELL_FAILED" \
  "$root/scripts/verification-run.sh" "$failing_dir"
grep -q '| VM-001 | shell | FAIL | exit=1 |' "$failing_dir/verification-run-report.md" \
  && pass "failing shell row is recorded in report" \
  || fail "failing shell row is recorded in report"

manual_pending_dir="$tmpdir/manual-pending-change"
mkdir -p "$manual_pending_dir"
cat >"$manual_pending_dir/verification-map.md" <<'MARKDOWN'
# Verification Map

```yaml
verification_map_status: READY
```

| ID | Constraint | Source | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| VM-001 | UI visual check needs human evidence | PRD | manual: compare PRD screenshot and local screenshot | changes/demo/ui-confirmation.md | PLANNED |
MARKDOWN

run_expect_fail_with_code "verification run blocks pending manual rows" \
  "VERIFICATION_RUN/MANUAL_PENDING" \
  "$root/scripts/verification-run.sh" "$manual_pending_dir"

unsupported_dir="$tmpdir/unsupported-change"
mkdir -p "$unsupported_dir"
cat >"$unsupported_dir/verification-map.md" <<'MARKDOWN'
# Verification Map

```yaml
verification_map_status: READY
```

| ID | Constraint | Source | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| VM-001 | Planned row must declare runner | harness | `bash -n scripts/verification-map-gate.sh` | changes/demo/verification-run-report.md | PLANNED |
MARKDOWN

run_expect_fail_with_code "verification run blocks planned rows without runner" \
  "VERIFICATION_RUN/UNSUPPORTED_RUNNER" \
  "$root/scripts/verification-run.sh" "$unsupported_dir"

run_expect_pass "verification run supports dry-run without executing shell" \
  "$root/scripts/verification-run.sh" --dry-run "$failing_dir"
if grep -q '| VM-001 | shell | DRY_RUN | not executed |' "$failing_dir/verification-run-report.md"; then
  pass "dry-run report records non-execution"
else
  fail "dry-run report records non-execution"
  sed -n '1,120p' "$failing_dir/verification-run-report.md" >&2 || true
fi

if grep -q 'scripts/verification-run.sh' docs/README.md \
  && grep -q 'scripts/verification-run-test.sh' docs/README.md \
  && grep -q 'runner: shell/manual/N/A' templates/verification-map.md; then
  pass "docs and template describe verification runner"
else
  fail "docs and template describe verification runner"
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: verification run test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: verification run test passed\n'
