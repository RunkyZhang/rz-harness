#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
failures=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

run_expect_pass() {
  local name="$1"
  shift
  if "$@" >"$tmp_dir/out" 2>"$tmp_dir/err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,40p' "$tmp_dir/err" >&2
  fi
}

run_expect_fail_code() {
  local name="$1" code="$2"
  shift 2
  if "$@" >"$tmp_dir/out" 2>"$tmp_dir/err"; then
    fail "$name"
  elif grep -q "^CODE: $code$" "$tmp_dir/err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,40p' "$tmp_dir/err" >&2
  fi
}

repo="$tmp_dir/repo"
response_dir="$repo/sfa-sales-management-application/src/main/java/com/wantwant/sfa/sales/management/application/response"
mkdir -p "$response_dir" "$tmp_dir/change"
git -C "$repo" init -q
git -C "$repo" config user.email fixture@example.com
git -C "$repo" config user.name fixture

if grep -q 'scripts/swagger-model-documentation-gate.sh "$change_dir" "${changed_files\[@\]}"' \
  "$root/scripts/change-stage-gate.sh"; then
  pass "pre-commit stage invokes Swagger model documentation gate"
else
  fail "pre-commit stage invokes Swagger model documentation gate"
fi

documented="$response_dir/DocumentedVO.java"
cat >"$documented" <<'JAVA'
import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
@ApiModel(description = "fixture")
public class DocumentedVO {
    @ApiModelProperty("编号")
    private String id;
}
JAVA

run_expect_pass "documented newly added response VO passes" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$repo" "$root/scripts/swagger-model-documentation-gate.sh" "$tmp_dir/change" "$documented"

missing_model="$response_dir/MissingModelVO.java"
cat >"$missing_model" <<'JAVA'
public class MissingModelVO {
    private String id;
}
JAVA
run_expect_fail_code "missing class annotation blocks" "SWAGGER_MODEL_DOC/MISSING_API_MODEL" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$repo" "$root/scripts/swagger-model-documentation-gate.sh" "$tmp_dir/change" "$missing_model"
rm "$missing_model"

missing_field="$response_dir/MissingFieldVO.java"
cat >"$missing_field" <<'JAVA'
import io.swagger.annotations.ApiModel;
@ApiModel(description = "fixture")
public class MissingFieldVO {
    private String id;
}
JAVA
run_expect_fail_code "missing field annotation blocks" "SWAGGER_MODEL_DOC/MISSING_FIELD_PROPERTY" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$repo" "$root/scripts/swagger-model-documentation-gate.sh" "$tmp_dir/change" "$missing_field"
rm "$missing_field"

legacy="$response_dir/LegacyVO.java"
cat >"$legacy" <<'JAVA'
public class LegacyVO {
    private String id;
}
JAVA
git -C "$repo" add .
git -C "$repo" commit -qm fixture
printf '\n// existing model update\n' >>"$legacy"
run_expect_pass "tracked legacy response VO remains non-retroactive" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$repo" "$root/scripts/swagger-model-documentation-gate.sh" "$tmp_dir/change" "$legacy"

export_model="$response_dir/TerminalExportExcel.java"
cat >"$export_model" <<'JAVA'
public class TerminalExportExcel {
    private String id;
}
JAVA
run_expect_pass "non-VO export model is outside profile scope" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$repo" "$root/scripts/swagger-model-documentation-gate.sh" "$tmp_dir/change" "$export_model"

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: Swagger model documentation gate tests found %s issue(s)\n' "$failures" >&2
  exit 1
fi
printf 'PASS: Swagger model documentation gate tests passed\n'
