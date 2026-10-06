#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
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

run_expect_fail_with_code() {
  local label="$1" expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$label"
    sed -n '1,80p' "$out" >&2 || true
    return
  fi
  if grep -q "^CODE: ${expected_code}$" "$err"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,80p' "$out" >&2 || true
    sed -n '1,80p' "$err" >&2 || true
  fi
}

run_expect_pass "superseded docs gate passes current legacy docs" \
  "$root/scripts/superseded-docs-gate.sh"

for legacy in \
  harness-engineering-target-plan.md \
  multi-repo-harness-implementation-plan.md \
  deep-research-report.md; do
  if sed -n '1,12p' "$root/$legacy" \
    | grep -q 'SUPERSEDED by docs/architecture/harness-workflow-and-design-principles.md'; then
    pass "$legacy has SUPERSEDED banner"
  else
    fail "$legacy has SUPERSEDED banner"
  fi
done

if [[ -f "$root/docs/archive/README.md" ]] \
  && grep -q 'harness-engineering-target-plan.md' "$root/docs/archive/README.md" \
  && grep -q 'docs/architecture/harness-workflow-and-design-principles.md' "$root/docs/archive/README.md"; then
  pass "archive index records legacy root docs and active SSOT"
else
  fail "archive index records legacy root docs and active SSOT"
fi

fixture_root="$tmp_dir/fixture"
mkdir -p "$fixture_root/docs/architecture"
printf '# Current\n' >"$fixture_root/docs/architecture/harness-workflow-and-design-principles.md"
printf '# Old\n' >"$fixture_root/harness-engineering-target-plan.md"
printf '# Old\n> SUPERSEDED by docs/architecture/harness-workflow-and-design-principles.md\n' >"$fixture_root/multi-repo-harness-implementation-plan.md"
printf '# Old\n> SUPERSEDED by docs/architecture/harness-workflow-and-design-principles.md\n' >"$fixture_root/deep-research-report.md"

run_expect_fail_with_code "superseded docs gate blocks missing banner in fixture" \
  "SUPERSEDED_DOCS/MISSING_BANNER" \
  "$root/scripts/superseded-docs-gate.sh" --root "$fixture_root"

if grep -q 'scripts/superseded-docs-gate.sh' "$root/docs/README.md" \
  && grep -q 'scripts/superseded-docs-gate-test.sh' "$root/docs/README.md"; then
  pass "docs index lists superseded docs gate"
else
  fail "docs index lists superseded docs gate"
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: superseded docs gate test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: superseded docs gate test passed\n'
