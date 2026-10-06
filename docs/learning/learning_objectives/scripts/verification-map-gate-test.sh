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
    sed -n '1,30p' "$out" >&2 || true
    sed -n '1,30p' "$err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local name="$1"
  local expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$name"
    sed -n '1,30p' "$out" >&2 || true
    return
  fi

  if grep -q "^CODE: ${expected_code}$" "$err" \
    && grep -q '^FIX: ' "$err" \
    && grep -q '^SAMPLE: ' "$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,30p' "$out" >&2 || true
    sed -n '1,30p' "$err" >&2 || true
  fi
}

tmpdir="$(mktemp -d)"
out="$tmpdir/out"
err="$tmpdir/err"
trap 'rm -rf "$tmpdir"' EXIT

missing_dir="$tmpdir/missing-change"
mkdir -p "$missing_dir"

run_expect_fail_with_code "gate fails when verification-map.md is missing" \
  "VERIFICATION_MAP/MISSING_FILE" \
  "$root/scripts/verification-map-gate.sh" "$missing_dir"

valid_dir="$tmpdir/valid-change"
mkdir -p "$valid_dir"
cat >"$valid_dir/verification-map.md" <<'MARKDOWN'
# Verification Map

```yaml
verification_map_status: READY
```

| ID | Constraint | Source | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| VM-001 | 用户只能看到所属租户数据 | contract | `mvn -Dtest=TenantFilterTest test` | `changes/demo/evidence.md#tenant-filter` | PLANNED |
| VM-002 | 本次不改生产配置 | spec | `scripts/allowed-paths.sh changes/demo/spec.md <changed-files>` | `changes/demo/evidence.md#allowed-paths` | PASS |
| VM-003 | PC UI 不适用 | user confirmation | N/A | `N/A: backend-only change` | N/A |
MARKDOWN

run_expect_pass "gate accepts ready verification map" \
  "$root/scripts/verification-map-gate.sh" "$valid_dir"

todo_dir="$tmpdir/todo-change"
mkdir -p "$todo_dir"
cat >"$todo_dir/verification-map.md" <<'MARKDOWN'
# Verification Map

```yaml
verification_map_status: READY
```

| ID | Constraint | Source | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| VM-001 | TODO | contract | `mvn test` | `changes/demo/evidence.md` | PLANNED |
MARKDOWN

run_expect_fail_with_code "gate blocks unresolved placeholders" \
  "VERIFICATION_MAP/UNRESOLVED_PLACEHOLDER" \
  "$root/scripts/verification-map-gate.sh" "$todo_dir"

blocked_dir="$tmpdir/blocked-change"
mkdir -p "$blocked_dir"
cat >"$blocked_dir/verification-map.md" <<'MARKDOWN'
# Verification Map

```yaml
verification_map_status: READY
```

| ID | Constraint | Source | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| VM-001 | 权限校验 | contract | `mvn test` | `changes/demo/evidence.md` | BLOCKED |
MARKDOWN

run_expect_fail_with_code "gate blocks BLOCKED verification rows" \
  "VERIFICATION_MAP/BLOCKED_ROW" \
  "$root/scripts/verification-map-gate.sh" "$blocked_dir"

bare_na_dir="$tmpdir/bare-na-change"
mkdir -p "$bare_na_dir"
cat >"$bare_na_dir/verification-map.md" <<'MARKDOWN'
# Verification Map

```yaml
verification_map_status: READY
```

| ID | Constraint | Source | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| VM-001 | PC UI | spec | N/A |  | N/A |
MARKDOWN

run_expect_fail_with_code "gate requires N/A reason" \
  "VERIFICATION_MAP/MISSING_NA_REASON" \
  "$root/scripts/verification-map-gate.sh" "$bare_na_dir"

missing_status_dir="$tmpdir/missing-status-change"
mkdir -p "$missing_status_dir"
cat >"$missing_status_dir/verification-map.md" <<'MARKDOWN'
# Verification Map

| ID | Constraint | Source | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| VM-001 | 权限校验 | contract | `mvn test` | `changes/demo/evidence.md` | PLANNED |
MARKDOWN

run_expect_fail_with_code "gate requires READY status" \
  "VERIFICATION_MAP/NOT_READY" \
  "$root/scripts/verification-map-gate.sh" "$missing_status_dir"

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: verification map gate test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: verification map gate test passed\n'
