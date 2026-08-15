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
  if "$@" >"$readiness_out" 2>"$readiness_err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,20p' "$readiness_err" >&2 || true
  fi
}

run_expect_fail() {
  local name="$1"
  shift
  if "$@" >"$readiness_out" 2>"$readiness_err"; then
    fail "$name"
    sed -n '1,20p' "$readiness_out" >&2 || true
  else
    pass "$name"
  fi
}

run_expect_fail_with_code() {
  local name="$1"
  local expected_code="$2"
  shift 2
  if "$@" >"$readiness_out" 2>"$readiness_err"; then
    fail "$name"
    sed -n '1,20p' "$readiness_out" >&2 || true
    return
  fi

  if grep -q "^CODE: ${expected_code}$" "$readiness_err" \
    && grep -q '^FIX: ' "$readiness_err" \
    && grep -q '^SAMPLE: ' "$readiness_err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,20p' "$readiness_err" >&2 || true
  fi
}

tmp_dir="$(mktemp -d)"
readiness_out="$tmp_dir/readiness.out"
readiness_err="$tmp_dir/readiness.err"
trap 'rm -rf "$tmp_dir"' EXIT

non_blocking_spec="$tmp_dir/non-blocking-spec.md"
cat > "$non_blocking_spec" <<'SPEC'
# readiness non blocking

- [FACT] This is a fact.
- [ASSUMP] 无进入实现的假设。

non_blocking_questions:
  - [QUESTION] None.
SPEC

blocking_spec="$tmp_dir/blocking-spec.md"
cat > "$blocking_spec" <<'SPEC'
# readiness blocking

- [FACT] This is a fact.
- [ASSUMP] 无进入实现的假设。
- [QUESTION] Which repo should be changed?
SPEC

allowed_spec="$tmp_dir/allowed-spec.md"
cat > "$allowed_spec" <<SPEC
# readiness allowed paths

allowed_paths:
  repo:
    - $tmp_dir/work/**
forbidden_paths:
  - "**/.env*"
  - "**/db/migration/**"
SPEC

default_forbidden_spec="$tmp_dir/default-forbidden-spec.md"
cat > "$default_forbidden_spec" <<SPEC
# readiness default forbidden paths

allowed_paths:
  repo:
    - $tmp_dir/work/**
SPEC

approved_protected_spec="$tmp_dir/approved-protected-spec.md"
cat > "$approved_protected_spec" <<SPEC
# readiness approved protected paths

allowed_paths:
  repo:
    - $tmp_dir/work/**
approved_protected_paths:
  - $tmp_dir/work/db/migration/**
SPEC

env_allowed_spec="$tmp_dir/env-allowed-spec.md"
cat > "$env_allowed_spec" <<'SPEC'
# readiness env allowed paths

allowed_paths:
  repo:
    - $SFA_READINESS_REPO/src/**
forbidden_paths:
  - "**/.env*"
SPEC

mkdir -p "$tmp_dir/work/db/migration"
mkdir -p "$tmp_dir/env-repo/src"
touch "$tmp_dir/work/src.txt"
touch "$tmp_dir/work/.env.prod"
touch "$tmp_dir/work/db/migration/V1.sql"
touch "$tmp_dir/env-repo/src/example.txt"

run_expect_pass "confidence gate allows non_blocking_questions by default" \
  scripts/confidence-gate.sh "$non_blocking_spec"

run_expect_fail_with_code "confidence gate still blocks real unresolved questions with remediation output" \
  "CONFIDENCE_GATE/UNRESOLVED_QUESTION" \
  scripts/confidence-gate.sh "$blocking_spec"

run_expect_pass "allowed paths permits files inside allowed prefixes" \
  scripts/allowed-paths.sh "$allowed_spec" "$tmp_dir/work/src.txt"

SFA_READINESS_REPO="$tmp_dir/env-repo" run_expect_pass "allowed paths expands environment variables in allowed prefixes" \
  scripts/allowed-paths.sh "$env_allowed_spec" "$tmp_dir/env-repo/src/example.txt"

run_expect_fail_with_code "allowed paths blocks forbidden .env files with remediation output" \
  "ALLOWED_PATHS/FORBIDDEN_PATH" \
  scripts/allowed-paths.sh "$allowed_spec" "$tmp_dir/work/.env.prod"

run_expect_fail_with_code "allowed paths blocks forbidden DB migration files with remediation output" \
  "ALLOWED_PATHS/FORBIDDEN_PATH" \
  scripts/allowed-paths.sh "$allowed_spec" "$tmp_dir/work/db/migration/V1.sql"

run_expect_fail_with_code "allowed paths blocks default protected DB migration files with remediation output" \
  "ALLOWED_PATHS/PROTECTED_PATH" \
  scripts/allowed-paths.sh "$default_forbidden_spec" "$tmp_dir/work/db/migration/V1.sql"

run_expect_pass "allowed paths permits explicitly approved protected paths" \
  scripts/allowed-paths.sh "$approved_protected_spec" "$tmp_dir/work/db/migration/V1.sql"

assumption_spec="$tmp_dir/assumption-spec.md"
cat > "$assumption_spec" <<'SPEC'
# readiness assumption leak

- [FACT] Confirmed fact.
- [ASSUMP] `ownerConfirmStatus` might default to pending.
- [QUESTION] None blocking.
SPEC

assumption_impl="$tmp_dir/work/OwnerConfirmExample.java"
cat > "$assumption_impl" <<'SPEC'
class OwnerConfirmExample {
  private String ownerConfirmStatus;
}
SPEC

assumption_tag_impl="$tmp_dir/work/AssumptionTagExample.java"
cat > "$assumption_tag_impl" <<'SPEC'
class AssumptionTagExample {
  // [ASSUMP] This must stay out of implementation files.
}
SPEC

no_assumption_spec="$tmp_dir/no-assumption-spec.md"
cat > "$no_assumption_spec" <<'SPEC'
# readiness no assumptions

- [FACT] Confirmed fact.
SPEC

run_expect_fail_with_code "assumption leak gate blocks implementation files containing ASSUMP identifiers with remediation output" \
  "ASSUMPTION_LEAK/TOKEN_LEAK" \
  scripts/assumption-leak-gate.sh "$assumption_spec" "$assumption_impl"

run_expect_fail_with_code "assumption leak gate still scans changed files when spec has no ASSUMP entries" \
  "ASSUMPTION_LEAK/TAG_LEAK" \
  scripts/assumption-leak-gate.sh "$no_assumption_spec" "$assumption_tag_impl"

run_expect_fail_with_code "assumption leak gate fails closed for missing changed files" \
  "ASSUMPTION_LEAK/CHANGED_FILE_NOT_FOUND" \
  scripts/assumption-leak-gate.sh "$assumption_spec" "$tmp_dir/work/does-not-exist.java"

local_routing_config="$tmp_dir/local-routing.yml"
cat > "$local_routing_config" <<'SPEC'
change_id: readiness-local-routing
frontend_repo: frontend-map-system
fallback_base_url: https://test.example.invalid
proxy_listen:
  host: 127.0.0.1
  port: 19080
routes:
  - id: changed-page
    frontend_prefix: /local/sfa/salesmanagement/bdOwnerConfirmTask
    strip_prefix: /local/sfa/salesmanagement
    backend_prefix: /
    backend_repo: backend-sales-management
    local_target: http://127.0.0.1:31010
    source_contract: docs/contracts/readiness-local-routing-api.md
    reason: current change endpoint is called by the frontend page
SPEC

wildcard_routing_config="$tmp_dir/wildcard-routing.yml"
cat > "$wildcard_routing_config" <<'SPEC'
change_id: readiness-bad-routing
frontend_repo: frontend-map-system
fallback_base_url: https://test.example.invalid
routes:
  - id: bad
    frontend_prefix: /
    strip_prefix: /
    backend_prefix: /
    backend_repo: backend-sales-management
    local_target: http://127.0.0.1:31010
    source_contract: docs/contracts/readiness-bad-routing-api.md
    reason: this would capture everything
SPEC

nonlocal_routing_config="$tmp_dir/nonlocal-routing.yml"
cat > "$nonlocal_routing_config" <<'SPEC'
change_id: readiness-bad-target
frontend_repo: frontend-map-system
fallback_base_url: https://test.example.invalid
routes:
  - id: bad
    frontend_prefix: /local/sfa/changed
    strip_prefix: /local/sfa
    backend_prefix: /
    backend_repo: backend-sales-management
    local_target: https://test-backend.example.invalid
    source_contract: docs/contracts/readiness-bad-target-api.md
    reason: target is not local
SPEC

run_expect_pass "local routing gate accepts local backend route" \
  scripts/local-routing-gate.sh "$local_routing_config"

run_expect_fail_with_code "local routing gate blocks catch-all frontend routes with remediation output" \
  "LOCAL_ROUTING/INVALID_CONFIG" \
  scripts/local-routing-gate.sh "$wildcard_routing_config"

run_expect_fail_with_code "local routing gate blocks non-local backend targets with remediation output" \
  "LOCAL_ROUTING/INVALID_CONFIG" \
  scripts/local-routing-gate.sh "$nonlocal_routing_config"

business_change="$tmp_dir/business-change"
business_repo="$tmp_dir/business-repo"
mkdir -p "$business_change" "$business_repo/src"
git -C "$business_repo" init -q -b main
touch "$business_repo/src/OwnerConfirm.java"
cat > "$business_change/technical-solution.md" <<'SPEC'
# readiness business code start

confirmation_status: CONFIRMED
allowed_next_stage: code_start

全栈 PRD 覆盖：Backend / PC Web / 小程序 / 导出 / 埋点 N/A。
SPEC
cat > "$business_change/verification-map.md" <<'SPEC'
verification_map_status: READY

| ID | Constraint | Source | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| VM-001 | branch gate | harness | command | readiness | PLANNED |
SPEC
cat > "$business_change/harness-status.md" <<'SPEC'
# readiness business status

target_repos:
  - business-repo
SPEC
cat > "$business_change/contract.md" <<SPEC
# readiness contract

allowed_paths:
  repo:
    - $business_repo/src/**
SPEC

run_expect_fail_with_code "business code-start gate blocks edits on main branch" \
  "BUSINESS_CODE_START/PROTECTED_BRANCH" \
  scripts/business-code-start-gate.sh "$business_change" "$business_repo/src/OwnerConfirm.java"

git -C "$business_repo" switch -q -c codex/readiness-business-gate
run_expect_pass "business code-start gate accepts confirmed change on codex branch and allowed path" \
  scripts/business-code-start-gate.sh "$business_change" "$business_repo/src/OwnerConfirm.java"

touch "$business_repo/forbidden.java"
run_expect_fail_with_code "business code-start gate blocks files outside contract allowed paths" \
  "BUSINESS_CODE_START/PATH_NOT_ALLOWED" \
  scripts/business-code-start-gate.sh "$business_change" "$business_repo/forbidden.java"

prototype_change="$tmp_dir/prototype-change"
mkdir -p "$prototype_change"
cat > "$prototype_change/technical-solution.md" <<'SPEC'
# readiness prototype only

confirmation_status: CONFIRMED
allowed_next_stage: prototype

全栈 PRD 覆盖：Backend / PC Web / 小程序 / 导出 / 埋点 N/A。
SPEC
cp "$business_change/verification-map.md" "$prototype_change/verification-map.md"
cp "$business_change/contract.md" "$prototype_change/contract.md"
run_expect_fail_with_code "business code-start gate blocks confirmed non-code-start stages" \
  "BUSINESS_CODE_START/NEXT_STAGE_NOT_CODE_START" \
  scripts/business-code-start-gate.sh "$prototype_change" "$business_repo/src/OwnerConfirm.java"

workstream_change="$tmp_dir/workstream-change"
mkdir -p "$workstream_change"
cat > "$workstream_change/harness-status.md" <<'SPEC'
# readiness workstream status

target_repos:
  - backend-sales-management
  - frontend-merchant-wechatapp
  - frontend-map-system

## Workstream Dispatch

| Repo | Scope | Agent mode | Verification | Status |
| --- | --- | --- | --- | --- |
| backend-sales-management | service | backend-agent | mvn -pl sfa-sales-management-interfaces -am -DskipTests compile | READY |
| frontend-merchant-wechatapp | miniapp | frontend-agent | npm run tsc && npm run lint | READY |
| frontend-map-system | pc | frontend-agent | scripts/frontend-lint-build.sh frontend-map-system lint-files <files> | READY |
SPEC
run_expect_pass "workstream dispatch gate accepts all target repos with verification commands" \
  scripts/workstream-dispatch-gate.sh "$workstream_change"

missing_workstream_change="$tmp_dir/missing-workstream-change"
mkdir -p "$missing_workstream_change"
cat > "$missing_workstream_change/harness-status.md" <<'SPEC'
# readiness missing workstream status

target_repos:
  - backend-sales-management
  - frontend-merchant-wechatapp
SPEC
run_expect_fail_with_code "workstream dispatch gate blocks multi-repo changes without dispatch table" \
  "WORKSTREAM_DISPATCH/MISSING_SECTION" \
  scripts/workstream-dispatch-gate.sh "$missing_workstream_change"

frontend_config_repo="$tmp_dir/frontend-config-repo"
mkdir -p "$frontend_config_repo/src"
touch "$frontend_config_repo/src/page.vue" "$frontend_config_repo/vue.config.js" "$frontend_config_repo/.env.local"
run_expect_pass "local routing business config gate allows ordinary frontend source files" \
  scripts/local-routing-business-config-gate.sh "$frontend_config_repo/src/page.vue"

run_expect_fail_with_code "local routing business config gate blocks vue.config.js proxy mutations" \
  "LOCAL_ROUTING/BUSINESS_CONFIG_MUTATION" \
  scripts/local-routing-business-config-gate.sh "$frontend_config_repo/vue.config.js"

run_expect_fail_with_code "local routing business config gate blocks frontend env mutations" \
  "LOCAL_ROUTING/BUSINESS_CONFIG_MUTATION" \
  scripts/local-routing-business-config-gate.sh "$frontend_config_repo/.env.local"

java_repo="$tmp_dir/java-repo"
mkdir -p "$java_repo/src"
touch "$java_repo/pom.xml"
cat > "$java_repo/src/BadLog.java" <<'SPEC'
class BadLog {
  void run() {
    System.out.println("bad");
  }
}
SPEC

run_expect_fail_with_code "java mechanical quality gate reports remediation output" \
  "JAVA_MECHANICAL/VIOLATIONS" \
  scripts/java-mechanical-quality.sh "$java_repo" "$java_repo/src/BadLog.java"

mobile_repo="$tmp_dir/mobile-repo"
mkdir -p "$mobile_repo/app/src/main/java/com/want/sfa" "$mobile_repo/FProject/FProject/MakeWang"
cat > "$mobile_repo/app/src/main/java/com/want/sfa/BadActivity.java" <<'SPEC'
class BadActivity {
  void run() {
    System.out.println("debug");
  }
}
SPEC
cat > "$mobile_repo/FProject/FProject/MakeWang/BadController.m" <<'SPEC'
@implementation BadController
- (void)run {
  NSLog(@"debug");
}
@end
SPEC

run_expect_fail_with_code "mobile mechanical quality gate blocks Android debug output" \
  "MOBILE_MECHANICAL/VIOLATIONS" \
  scripts/mobile-mechanical-quality.sh "$mobile_repo" "$mobile_repo/app/src/main/java/com/want/sfa/BadActivity.java"

run_expect_fail_with_code "mobile mechanical quality gate blocks iOS debug output" \
  "MOBILE_MECHANICAL/VIOLATIONS" \
  scripts/mobile-mechanical-quality.sh "$mobile_repo" "$mobile_repo/FProject/FProject/MakeWang/BadController.m"

drift_repo="$tmp_dir/drift-repo"
mkdir -p "$drift_repo/backend/src" "$drift_repo/frontend/src/views" "$drift_repo/miniprogram/pages/bind" "$drift_repo/app/src/main/java/com/want/sfa"
cat > "$drift_repo/backend/src/BadController.java" <<'SPEC'
class BadController {
  private UserMapper userMapper;
}
SPEC
cat > "$drift_repo/frontend/src/views/BadPage.vue" <<'SPEC'
<script>
export default {
  mounted() {
    fetch('/sfa/backend/bad')
  }
}
</script>
SPEC
cat > "$drift_repo/miniprogram/pages/bind/index.ts" <<'SPEC'
wx.request({ url: '/api/bad' })
SPEC
cat > "$drift_repo/app/src/main/java/com/want/sfa/BadActivity.java" <<'SPEC'
class BadActivity {
  private okhttp3.OkHttpClient client;
}
SPEC

run_expect_fail_with_code "architecture drift gate blocks Java controller mapper dependency" \
  "ARCH_DRIFT/VIOLATIONS" \
  scripts/architecture-drift-gate.sh "$drift_repo" "$drift_repo/backend/src/BadController.java"

run_expect_fail_with_code "architecture drift gate blocks Vue page direct request" \
  "ARCH_DRIFT/VIOLATIONS" \
  scripts/architecture-drift-gate.sh "$drift_repo" "$drift_repo/frontend/src/views/BadPage.vue"

run_expect_fail_with_code "architecture drift gate blocks mini-program page direct wx.request" \
  "ARCH_DRIFT/VIOLATIONS" \
  scripts/architecture-drift-gate.sh "$drift_repo" "$drift_repo/miniprogram/pages/bind/index.ts"

run_expect_fail_with_code "architecture drift gate blocks Android Activity direct network client" \
  "ARCH_DRIFT/VIOLATIONS" \
  scripts/architecture-drift-gate.sh "$drift_repo" "$drift_repo/app/src/main/java/com/want/sfa/BadActivity.java"

service_routing_registry="$tmp_dir/local-backend-services.yml"
cat > "$service_routing_registry" <<'SPEC'
fallback_base_url: https://test.example.invalid
proxy_listen:
  host: 127.0.0.1
  port: 19080
services:
  - backend_repo: backend-sales-management
    frontend_prefix: /sfa/salesmanagement
    strip_prefix: /sfa/salesmanagement
    backend_prefix: /
    local_target: http://127.0.0.1:31010
    frontend_repos: frontend-map-system
    source_contract: docs/architecture/repo-registry.md
    reason: backend-sales-management owns the sfa salesmanagement service prefix
  - backend_repo: backend-sfa-backend
    frontend_prefix: /sfa/backend
    strip_prefix: /sfa/backend
    backend_prefix: /
    local_target: http://127.0.0.1:30080
    frontend_repos: frontend-map-system
    source_contract: docs/architecture/repo-registry.md
    reason: backend-sfa-backend owns the sfa backend service prefix
SPEC

generated_routing="$tmp_dir/generated-local-routing.yml"
generated_env="$tmp_dir/generated-frontend.env"
run_expect_pass "service routing generator builds active backend local routing" \
  scripts/generate-local-routing.sh \
    --change-id readiness-service-routing \
    --frontend-repo frontend-map-system \
    --active-backends backend-sales-management \
    --services "$service_routing_registry" \
    --output "$generated_routing" \
    --env-output "$generated_env"

run_expect_pass "generated service route passes local routing gate" \
  scripts/local-routing-gate.sh "$generated_routing"

run_expect_pass "service routing env points frontend at harness proxy" \
  bash -lc "grep -q 'VUE_APP_BASE_API=http://127.0.0.1:19080/' '$generated_env' && grep -q 'SFA_HARNESS_ACTIVE_BACKENDS=backend-sales-management' '$generated_env' && grep -q 'SFA_HARNESS_LOCAL_SERVICE_PREFIXES=/sfa/salesmanagement' '$generated_env' && ! grep -q '/sfa/backend' '$generated_env'"

env_service_routing_registry="$tmp_dir/env-local-backend-services.yml"
cat > "$env_service_routing_registry" <<'SPEC'
fallback_base_url: https://test.example.invalid
proxy_listen:
  host: 127.0.0.1
  port: 19080
services:
  - backend_repo: backend-sales-management
    frontend_prefix: /sfa/salesmanagement
    strip_prefix: /sfa/salesmanagement
    backend_prefix: /
    local_target: $READINESS_SALES_MANAGEMENT_URL
    frontend_repos: frontend-map-system
    source_contract: docs/architecture/repo-registry.md
    reason: backend-sales-management owns the sfa salesmanagement service prefix
SPEC

READINESS_SALES_MANAGEMENT_URL=http://127.0.0.1:31010 run_expect_pass "service routing generator expands local target environment variables" \
  bash -lc "scripts/generate-local-routing.sh --change-id readiness-env-service-routing --frontend-repo frontend-map-system --active-backends backend-sales-management --services '$env_service_routing_registry' --output '$tmp_dir/env-generated-routing.yml' --env-output '$tmp_dir/env-generated.env' && grep -q 'local_target: http://127.0.0.1:31010' '$tmp_dir/env-generated-routing.yml' && scripts/local-routing-gate.sh '$tmp_dir/env-generated-routing.yml'"

run_expect_pass "service routing generator builds multiple active backend routes" \
  bash -lc "scripts/generate-local-routing.sh --change-id readiness-multi-service-routing --frontend-repo frontend-map-system --active-backends backend-sales-management,backend-sfa-backend --services '$service_routing_registry' --output '$tmp_dir/multi-generated-routing.yml' --env-output '$tmp_dir/multi-generated.env' && grep -q 'frontend_prefix: /sfa/salesmanagement' '$tmp_dir/multi-generated-routing.yml' && grep -q 'frontend_prefix: /sfa/backend' '$tmp_dir/multi-generated-routing.yml' && grep -q 'SFA_HARNESS_LOCAL_SERVICE_PREFIXES=/sfa/salesmanagement,/sfa/backend' '$tmp_dir/multi-generated.env' && scripts/local-routing-gate.sh '$tmp_dir/multi-generated-routing.yml'"

mvn_repo="$tmp_dir/mvn-repo"
fake_bin="$tmp_dir/fake-bin"
mkdir -p "$mvn_repo" "$fake_bin"
touch "$mvn_repo/pom.xml"
cat > "$fake_bin/team-mvn" <<'SPEC'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$SFA_FAKE_MVN_ARGS"
SPEC
chmod +x "$fake_bin/team-mvn"

SFA_FAKE_MVN_ARGS="$tmp_dir/fake-mvn.args" \
SFA_BACKEND_MAVEN_COMMAND="$fake_bin/team-mvn" \
SFA_BACKEND_MAVEN_ARGS="-s $tmp_dir/settings.xml" \
run_expect_pass "maven targeted runner uses SFA_BACKEND_MAVEN_COMMAND" \
  bash -lc "scripts/mvn-targeted-test.sh '$mvn_repo' - compile && grep -q -- '-s $tmp_dir/settings.xml -DskipTests compile' '$tmp_dir/fake-mvn.args'"

run_expect_fail_with_code "canonical command gate blocks interfaces Maven reactor without -am" \
  "CANONICAL_COMMAND/MISSING_ALSO_MAKE" \
  scripts/canonical-command-gate.sh -- mvn -pl sfa-sales-management-interfaces -DskipTests compile

run_expect_fail_with_code "canonical command gate blocks comma-separated interfaces Maven reactor without -am" \
  "CANONICAL_COMMAND/MISSING_ALSO_MAKE" \
  scripts/canonical-command-gate.sh -- mvn -pl sfa-sales-management-interfaces,sfa-sales-management-infrastructure -DskipTests compile

run_expect_pass "canonical command gate accepts interfaces Maven reactor with -am" \
  scripts/canonical-command-gate.sh -- mvn -pl sfa-sales-management-interfaces -am -DskipTests compile

miniapp_env_change="$tmp_dir/miniapp-env-change"
mkdir -p "$miniapp_env_change"
cat > "$miniapp_env_change/miniapp-local-env.md" <<'SPEC'
# Miniapp Local Env

```yaml
status: READY
env_override_key: bd_owner_env_override
current_value: local
actual_request_host: http://127.0.0.1:19080
reentered_miniprogram: yes
clear_command: wx.removeStorageSync('bd_owner_env_override')
```
SPEC
run_expect_pass "miniapp local env gate accepts recorded local override and clear command" \
  scripts/miniapp-local-env-gate.sh "$miniapp_env_change"

bad_miniapp_env_change="$tmp_dir/bad-miniapp-env-change"
mkdir -p "$bad_miniapp_env_change"
cat > "$bad_miniapp_env_change/miniapp-local-env.md" <<'SPEC'
# Miniapp Local Env

```yaml
status: READY
env_override_key: bd_owner_env_override
current_value: local
actual_request_host: http://127.0.0.1:19080
reentered_miniprogram: yes
```
SPEC
run_expect_fail_with_code "miniapp local env gate requires clear command" \
  "MINIAPP_LOCAL_ENV/MISSING_CLEAR_COMMAND" \
  scripts/miniapp-local-env-gate.sh "$bad_miniapp_env_change"

temp_ledger_change="$tmp_dir/temp-ledger-change"
mkdir -p "$temp_ledger_change"
cat > "$temp_ledger_change/temporary-state-ledger.md" <<'SPEC'
# Temporary State Ledger

ledger_status: READY

| Category | Resource | Owner | Cleanup | Status |
| --- | --- | --- | --- | --- |
| local-service | backend:31010 | Codex | stop service | CLEARED |
| miniapp-storage | bd_owner_env_override | user | wx.removeStorageSync('bd_owner_env_override') | USER_OWNED |
SPEC
run_expect_pass "temporary state ledger gate accepts cleared or user-owned temporary state" \
  scripts/temporary-state-ledger-gate.sh "$temp_ledger_change"

open_ledger_change="$tmp_dir/open-ledger-change"
mkdir -p "$open_ledger_change"
cat > "$open_ledger_change/temporary-state-ledger.md" <<'SPEC'
# Temporary State Ledger

ledger_status: READY

| Category | Resource | Owner | Cleanup | Status |
| --- | --- | --- | --- | --- |
| local-service | backend:31010 | Codex | stop service | OPEN |
SPEC
run_expect_fail_with_code "temporary state ledger gate blocks open temporary state" \
  "TEMPORARY_STATE/OPEN_ITEM" \
  scripts/temporary-state-ledger-gate.sh "$open_ledger_change"

codegraph_evidence_change="$tmp_dir/codegraph-evidence-change"
mkdir -p "$codegraph_evidence_change"
cat > "$codegraph_evidence_change/codegraph-evidence.md" <<'SPEC'
# CodeGraph Evidence

codegraph_evidence_status: READY
projectPath: /tmp/repo
result: HIT

| Step | Evidence |
| --- | --- |
| preflight | scripts/codegraph-preflight.sh backend-sales-management |
| codegraph_explore | task="How does BdOwnerConfirmController confirm flow work?", projectPath=/tmp/repo |
| codegraph_node | BdOwnerConfirmController includeCode=true |

Freshness note: no staleness banner reported.
SPEC
run_expect_pass "CodeGraph evidence gate accepts official explore-first HIT workflow" \
  scripts/codegraph-evidence-gate.sh "$codegraph_evidence_change"

bad_codegraph_evidence_change="$tmp_dir/bad-codegraph-evidence-change"
mkdir -p "$bad_codegraph_evidence_change"
cat > "$bad_codegraph_evidence_change/codegraph-evidence.md" <<'SPEC'
# CodeGraph Evidence

codegraph_evidence_status: READY
result: MISS

Only used natural language codegraph_context.
SPEC
run_expect_fail_with_code "CodeGraph evidence gate blocks natural-language-only route evidence" \
  "CODEGRAPH_EVIDENCE/MISSING_PROJECT_PATH" \
  scripts/codegraph-evidence-gate.sh "$bad_codegraph_evidence_change"

review_gate_change="$tmp_dir/review-gate-change"
mkdir -p "$review_gate_change"
cat > "$review_gate_change/review.md" <<'SPEC'
# Reviewer Agent Review

review_status: PASS
reviewer_independence: READ_ONLY
technical_solution_alignment: PASS
harness_constraints: PASS
architecture_drift: PASS
comment_log_quality: PASS
maintainability_readability: PASS
test_evidence: PASS
style_conformance: N/A
high_risk_count: 0
medium_risk_status: RECORDED

## Reviewed Inputs

- changes/demo/spec.md
- docs/contracts/demo-api.md
- changes/demo/technical-solution.md
- changes/demo/ai-test-plan.md
- changes/demo/test-agent-verification.md
- changes/demo/ai-test-report.md
- changes/demo/evidence.md
- git diff

## HIGH
- 无

## MEDIUM
- 无

## LOW
- 无

## 结论
- 建议进入人工 review。
SPEC
run_expect_pass "Reviewer gate accepts complete independent review coverage" \
  scripts/reviewer-gate.sh "$review_gate_change"

high_risk_review_change="$tmp_dir/high-risk-review-change"
mkdir -p "$high_risk_review_change"
cp "$review_gate_change/review.md" "$high_risk_review_change/review.md"
sed 's/high_risk_count: 0/high_risk_count: 1/' "$high_risk_review_change/review.md" > "$high_risk_review_change/review.tmp"
mv "$high_risk_review_change/review.tmp" "$high_risk_review_change/review.md"
run_expect_fail_with_code "Reviewer gate blocks unresolved high risk" \
  "REVIEWER_GATE/HIGH_RISK_NOT_ZERO" \
  scripts/reviewer-gate.sh "$high_risk_review_change"

missing_scope_review_change="$tmp_dir/missing-scope-review-change"
mkdir -p "$missing_scope_review_change"
cp "$review_gate_change/review.md" "$missing_scope_review_change/review.md"
sed 's/technical_solution_alignment: PASS/technical_solution_alignment: PENDING/' "$missing_scope_review_change/review.md" > "$missing_scope_review_change/review.tmp"
mv "$missing_scope_review_change/review.tmp" "$missing_scope_review_change/review.md"
run_expect_fail_with_code "Reviewer gate blocks missing technical solution alignment review" \
  "REVIEWER_GATE/CHECK_NOT_PASS" \
  scripts/reviewer-gate.sh "$missing_scope_review_change"

codegraph_bootstrap_repo="$tmp_dir/codegraph-bootstrap-repo"
mkdir -p "$codegraph_bootstrap_repo"
git -C "$codegraph_bootstrap_repo" init -q -b codex/codegraph-bootstrap
cat > "$fake_bin/codegraph" <<'SPEC'
#!/usr/bin/env bash
case "$1" in
  --version)
    printf 'fake-codegraph 1.0\n'
    ;;
  init)
    printf 'init %s %s\n' "$2" "$3" >> "$SFA_FAKE_CODEGRAPH_LOG"
    mkdir -p "$3/.codegraph"
    ;;
  status)
    printf 'status %s\n' "$2" >> "$SFA_FAKE_CODEGRAPH_LOG"
    ;;
  *)
    printf 'unexpected codegraph args: %s\n' "$*" >&2
    exit 2
    ;;
esac
SPEC
chmod +x "$fake_bin/codegraph"

SFA_FAKE_CODEGRAPH_LOG="$tmp_dir/codegraph-bootstrap.log" \
PATH="$fake_bin:$PATH" \
run_expect_pass "CodeGraph bootstrap initializes missing index and local exclude" \
  scripts/codegraph-bootstrap.sh "$codegraph_bootstrap_repo"
if grep -qxF '.codegraph/' "$codegraph_bootstrap_repo/.git/info/exclude" \
  && grep -qxF "init -i $codegraph_bootstrap_repo" "$tmp_dir/codegraph-bootstrap.log" \
  && grep -qxF "status $codegraph_bootstrap_repo" "$tmp_dir/codegraph-bootstrap.log"; then
  pass "CodeGraph bootstrap records init and status checks"
else
  fail "CodeGraph bootstrap records init and status checks"
fi

codegraph_dry_run_repo="$tmp_dir/codegraph-dry-run-repo"
mkdir -p "$codegraph_dry_run_repo"
git -C "$codegraph_dry_run_repo" init -q -b codex/codegraph-bootstrap-dry-run
SFA_FAKE_CODEGRAPH_LOG="$tmp_dir/codegraph-dry-run.log" \
PATH="$fake_bin:$PATH" \
run_expect_pass "CodeGraph bootstrap dry-run does not mutate business repo" \
  scripts/codegraph-bootstrap.sh --dry-run "$codegraph_dry_run_repo"
if [[ ! -d "$codegraph_dry_run_repo/.codegraph" ]] \
  && [[ ! -f "$tmp_dir/codegraph-dry-run.log" ]] \
  && grep -q 'DRY_RUN: would initialize CodeGraph' "$readiness_out"; then
  pass "CodeGraph bootstrap dry-run reports pending init without mutation"
else
  fail "CodeGraph bootstrap dry-run reports pending init without mutation"
fi

dirty_repo="$tmp_dir/dirty-repo"
mkdir -p "$dirty_repo"
git -C "$dirty_repo" init -q -b codex/readiness-dirty
echo clean > "$dirty_repo/file.txt"
git -C "$dirty_repo" add file.txt
git -C "$dirty_repo" -c user.name=Readiness -c user.email=readiness@example.invalid commit -q -m init
echo dirty >> "$dirty_repo/file.txt"
cat > "$tmp_dir/dirty-ledger.md" <<SPEC
# Dirty Worktree Ledger

dirty_worktree_status: READY

| Path | Owner | Decision | Notes |
| --- | --- | --- | --- |
| $dirty_repo/file.txt | user | preserve | existing user work |
SPEC
run_expect_pass "dirty worktree gate accepts dirty files with ownership ledger" \
  scripts/business-dirty-worktree-gate.sh "$dirty_repo" --ledger "$tmp_dir/dirty-ledger.md"

run_expect_fail_with_code "dirty worktree gate blocks dirty files without ownership ledger" \
  "DIRTY_WORKTREE/UNOWNED_CHANGES" \
  scripts/business-dirty-worktree-gate.sh "$dirty_repo"

frontend_repo="$tmp_dir/frontend-repo"
mkdir -p "$frontend_repo/node_modules" "$fake_bin"
cat > "$frontend_repo/package.json" <<'SPEC'
{"scripts":{"build:test":"echo build"}}
SPEC
cat > "$fake_bin/team-pm" <<'SPEC'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$SFA_FAKE_PM_ARGS"
SPEC
chmod +x "$fake_bin/team-pm"

SFA_FAKE_PM_ARGS="$tmp_dir/fake-pm.args" \
SFA_FRONTEND_PACKAGE_MANAGER="$fake_bin/team-pm" \
SFA_FRONTEND_PACKAGE_MANAGER_ARGS="--foreground-scripts" \
run_expect_pass "frontend runner uses SFA_FRONTEND_PACKAGE_MANAGER" \
  bash -lc "scripts/frontend-lint-build.sh '$frontend_repo' build build:test && grep -q -- '--foreground-scripts run build:test' '$tmp_dir/fake-pm.args'"

gitnexus_repo="$tmp_dir/gitnexus-repo"
mkdir -p "$gitnexus_repo"
cat > "$fake_bin/team-gitnexus" <<'SPEC'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SFA_FAKE_GITNEXUS_ARGS"
if [[ "${SFA_FAKE_GITNEXUS_MODE:-success}" == "fail" ]]; then
  printf 'simulated GitNexus unavailable\n' >&2
  exit 42
fi
if [[ "$*" == *"detect_changes"* && "${SFA_FAKE_GITNEXUS_MODE:-success}" == "critical" ]]; then
  printf 'risk: CRITICAL\n'
  exit 0
fi
printf 'risk: LOW\n'
SPEC
chmod +x "$fake_bin/team-gitnexus"

SFA_FAKE_GITNEXUS_ARGS="$tmp_dir/fake-gitnexus.args" \
SFA_GITNEXUS_COMMAND="$fake_bin/team-gitnexus" \
run_expect_pass "GitNexus impact wrapper calls configured command" \
  bash -lc "scripts/gitnexus-impact.sh '$gitnexus_repo' OrderService --direction downstream --depth 2 && grep -q -- 'impact OrderService --direction downstream --depth 2' '$tmp_dir/fake-gitnexus.args'"

SFA_FAKE_GITNEXUS_ARGS="$tmp_dir/fake-gitnexus-fail.args" \
SFA_FAKE_GITNEXUS_MODE=fail \
SFA_GITNEXUS_COMMAND="$fake_bin/team-gitnexus" \
run_expect_pass "GitNexus impact wrapper degrades when command is unavailable" \
  bash -lc "scripts/gitnexus-impact.sh '$gitnexus_repo' OrderService >'$tmp_dir/gitnexus-impact-degraded.out' 2>'$tmp_dir/gitnexus-impact-degraded.err' && grep -q 'GITNEXUS_STATUS=UNAVAILABLE' '$tmp_dir/gitnexus-impact-degraded.err'"

SFA_FAKE_GITNEXUS_ARGS="$tmp_dir/fake-gitnexus-critical.args" \
SFA_FAKE_GITNEXUS_MODE=critical \
SFA_GITNEXUS_COMMAND="$fake_bin/team-gitnexus" \
run_expect_fail_with_code "GitNexus detect changes wrapper stops on high risk output" \
  "GITNEXUS/HIGH_RISK" \
  scripts/gitnexus-detect-changes.sh "$gitnexus_repo" --scope all

SFA_LOCAL_BACKEND_SALES_MANAGEMENT_URL=http://127.0.0.1:31010 \
SFA_LOCAL_BACKEND_SFA_BACKEND_URL=http://127.0.0.1:30080 \
SFA_LOCAL_BACKEND_CEO_MEMBER_URL=http://127.0.0.1:9168 \
run_expect_pass "service routing generator accepts commented template registry" \
  bash -lc "scripts/generate-local-routing.sh --change-id readiness-template-service-routing --frontend-repo frontend-map-system --active-backends backend-sales-management,backend-sfa-backend,backend-ceo-member --services templates/local-backend-services.yml --output '$tmp_dir/template-generated-routing.yml' --env-output '$tmp_dir/template-generated.env' && grep -q 'frontend_prefix: /sfa/backend' '$tmp_dir/template-generated-routing.yml' && grep -q 'frontend_prefix: /backend/backend-ceo-member' '$tmp_dir/template-generated-routing.yml' && scripts/local-routing-gate.sh '$tmp_dir/template-generated-routing.yml'"

run_expect_fail "service routing generator blocks unknown active backend" \
  scripts/generate-local-routing.sh \
    --change-id readiness-service-routing \
    --frontend-repo frontend-map-system \
    --active-backends backend-not-registered \
    --services "$service_routing_registry" \
    --output "$tmp_dir/unknown-routing.yml"

run_local_proxy_cors_check() {
  local proxy_port=$((30000 + RANDOM % 10000))
  local cors_config="$tmp_dir/cors-routing.yml"
  cat > "$cors_config" <<SPEC
change_id: readiness-cors-routing
frontend_repo: frontend-map-system
fallback_base_url: https://test.example.invalid
proxy_listen:
  host: 127.0.0.1
  port: $proxy_port
routes:
  - id: changed-page
    frontend_prefix: /sfa/salesmanagement/bdOwnerConfirmTask
    strip_prefix: /sfa/salesmanagement
    backend_prefix: /
    backend_repo: backend-sales-management
    local_target: http://127.0.0.1:31010
    source_contract: docs/contracts/readiness-local-routing-api.md
    reason: current change endpoint is called by the frontend page
SPEC

  node scripts/harness-local-proxy.mjs "$cors_config" \
    >"$tmp_dir/cors-proxy.out" 2>"$tmp_dir/cors-proxy.err" &
  local proxy_pid=$!

  local response=""
  for _ in $(seq 1 30); do
    response="$(curl -sS -i --max-time 2 -X OPTIONS "http://127.0.0.1:$proxy_port/sfa/salesmanagement/bdOwnerConfirmTask/page" \
      -H 'Origin: http://127.0.0.1:9528' \
      -H 'Access-Control-Request-Method: POST' \
      -H 'Access-Control-Request-Headers: content-type,authorization' 2>/dev/null || true)"
    if printf '%s\n' "$response" | grep -q 'HTTP/1.1 204'; then
      break
    fi
    sleep 0.2
  done

  kill "$proxy_pid" >/dev/null 2>&1 || true
  wait "$proxy_pid" >/dev/null 2>&1 || true

  printf '%s\n' "$response" | grep -q 'HTTP/1.1 204'
  printf '%s\n' "$response" | grep -qi 'access-control-allow-origin: http://127.0.0.1:9528'
  printf '%s\n' "$response" | grep -qi 'access-control-allow-credentials: true'
  printf '%s\n' "$response" | grep -qi 'access-control-allow-headers: content-type,authorization'
}

run_expect_pass "local proxy handles browser CORS preflight" \
  run_local_proxy_cors_check

run_local_proxy_prefix_boundary_check() {
  local local_port=$((30000 + RANDOM % 10000))
  local fallback_port=$((30000 + RANDOM % 10000))
  local proxy_port=$((30000 + RANDOM % 10000))
  local boundary_config="$tmp_dir/boundary-routing.yml"

  node -e "require('http').createServer((req,res)=>{res.end('local:'+req.url)}).listen($local_port,'127.0.0.1')" \
    >"$tmp_dir/boundary-local.out" 2>"$tmp_dir/boundary-local.err" &
  local local_pid=$!
  node -e "require('http').createServer((req,res)=>{res.end('fallback:'+req.url)}).listen($fallback_port,'127.0.0.1')" \
    >"$tmp_dir/boundary-fallback.out" 2>"$tmp_dir/boundary-fallback.err" &
  local fallback_pid=$!

  cat > "$boundary_config" <<SPEC
change_id: readiness-boundary-routing
frontend_repo: frontend-map-system
fallback_base_url: http://127.0.0.1:$fallback_port
proxy_listen:
  host: 127.0.0.1
  port: $proxy_port
routes:
  - id: backend-service
    frontend_prefix: /sfa/backend
    strip_prefix: /sfa/backend
    backend_prefix: /
    backend_repo: backend-sfa-backend
    local_target: http://127.0.0.1:$local_port
    source_contract: docs/contracts/readiness-local-routing-api.md
    reason: backend service prefix should route locally
SPEC

  node scripts/harness-local-proxy.mjs "$boundary_config" \
    >"$tmp_dir/boundary-proxy.out" 2>"$tmp_dir/boundary-proxy.err" &
  local proxy_pid=$!

  local local_response=""
  local fallback_response=""
  for _ in $(seq 1 30); do
    local_response="$(curl -sS --max-time 2 "http://127.0.0.1:$proxy_port/sfa/backend/businessGroup/search" 2>/dev/null || true)"
    fallback_response="$(curl -sS --max-time 2 "http://127.0.0.1:$proxy_port/sfa/backendExtra/businessGroup/search" 2>/dev/null || true)"
    if [[ "$local_response" == local:* && "$fallback_response" == fallback:* ]]; then
      break
    fi
    sleep 0.2
  done

  kill "$proxy_pid" "$local_pid" "$fallback_pid" >/dev/null 2>&1 || true
  wait "$proxy_pid" "$local_pid" "$fallback_pid" >/dev/null 2>&1 || true

  [[ "$local_response" == local:/businessGroup/search ]]
  [[ "$fallback_response" == fallback:/sfa/backendExtra/businessGroup/search ]]
}

run_expect_pass "local proxy matches service prefixes on path boundaries" \
  run_local_proxy_prefix_boundary_check

eval_root="$tmp_dir/eval-root"
eval_change="readiness-eval"
mkdir -p "$eval_root/changes/$eval_change" "$eval_root/docs/contracts" "$eval_root/repo/src"
cat > "$eval_root/changes/$eval_change/spec.md" <<SPEC
# readiness eval

- [FACT] This is a confirmed eval fact.
- [ASSUMP] None.

non_blocking_questions:
  - [QUESTION] None blocking.

allowed_paths:
  repo:
    - $eval_root/repo/src/**
forbidden_paths:
  - "**/.env*"
SPEC
cat > "$eval_root/docs/contracts/$eval_change-api.md" <<'SPEC'
# API contract
SPEC
cat > "$eval_root/changes/$eval_change/plan.md" <<'SPEC'
# Plan
SPEC
cat > "$eval_root/changes/$eval_change/evidence.md" <<'SPEC'
# Evidence

Result: PASS
SPEC
cat > "$eval_root/changes/$eval_change/review.md" <<'SPEC'
# Review

## HIGH
- 无
SPEC
cat > "$eval_root/changes/$eval_change/pc-e2e-smoke-plan.md" <<'SPEC'
# PC E2E Smoke Plan
SPEC
cat > "$eval_root/changes/$eval_change/pc-e2e-smoke-report.md" <<'SPEC'
# PC E2E Smoke Report

| Result | `BLOCKED` |
SPEC
touch "$eval_root/repo/src/example.java"

SFA_EVAL_ROOT="$eval_root" run_expect_pass "golden eval grader validates a minimal fullstack change" \
  scripts/eval-golden.sh "$eval_change" "$eval_root/repo/src/example.java"

missing_eval_root="$tmp_dir/missing-eval-root"
mkdir -p "$missing_eval_root/changes/missing-eval" "$missing_eval_root/docs/contracts"
cat > "$missing_eval_root/changes/missing-eval/spec.md" <<'SPEC'
# missing eval

- [FACT] Confirmed fact.
- [ASSUMP] None.

non_blocking_questions:
  - [QUESTION] None.
SPEC

run_expect_fail_with_code "golden eval grader reports missing artifacts with remediation output" \
  "EVAL_GOLDEN/MISSING_ARTIFACTS" \
  env SFA_EVAL_ROOT="$missing_eval_root" scripts/eval-golden.sh missing-eval

if [[ -x scripts/harness-sensor-runner.sh ]]; then
  pass "tool-neutral harness sensor runner exists"
else
  fail "tool-neutral harness sensor runner exists"
fi

if [[ -f .cursor/hooks.json ]] \
  && grep -q 'beforeShellExecution' .cursor/hooks.json \
  && grep -q 'afterFileEdit' .cursor/hooks.json \
  && grep -q 'hooks/cursor-before-shell-execution.sh' .cursor/hooks.json; then
  pass "Cursor project hooks call harness adapter wrappers"
else
  fail "Cursor project hooks call harness adapter wrappers"
fi

if [[ -f .cursor/rules/sfa-harness-core.mdc ]] \
  && [[ -f .cursor/rules/sfa-backend-java.mdc ]] \
  && [[ -f .cursor/rules/sfa-frontend-vue2.mdc ]] \
  && grep -q '@AGENTS.md' .cursor/rules/sfa-harness-core.mdc \
  && grep -q '@rules/backend-java.mdc' .cursor/rules/sfa-backend-java.mdc \
  && grep -q '@rules/frontend-vue2.mdc' .cursor/rules/sfa-frontend-vue2.mdc; then
  pass "Cursor project rules adapters reference harness source of truth"
else
  fail "Cursor project rules adapters reference harness source of truth"
fi

if [[ -f .codex/hooks.json ]] \
  && grep -q 'PreToolUse' .codex/hooks.json \
  && grep -q 'PostToolUse' .codex/hooks.json \
  && grep -q 'hooks/codex-pre-tool-use.sh' .codex/hooks.json; then
  pass "Codex project hooks call harness adapter wrappers"
else
  fail "Codex project hooks call harness adapter wrappers"
fi

if [[ -f .codex/config.toml ]] \
  && grep -q '^hooks[[:space:]]*=[[:space:]]*true$' .codex/config.toml \
  && grep -q 'AGENTS.md' .codex/config.toml; then
  pass "Codex project config enables hooks and points to AGENTS.md"
else
  fail "Codex project config enables hooks and points to AGENTS.md"
fi

if grep -q 'scripts/harness-sensor-runner.sh \*' opencode.json; then
  pass "OpenCode can call the tool-neutral sensor runner"
else
  fail "OpenCode can call the tool-neutral sensor runner"
fi

if ! grep -q 'external_directory' opencode.json \
  && ! grep -q 'SFA_PROJECTS_ROOT' opencode.json \
  && ! grep -q 'SFA_PROJECTS_ROOT' .opencode/agents/*.md; then
  pass "OpenCode versioned config does not risk broad external_directory expansion"
else
  fail "OpenCode versioned config does not risk broad external_directory expansion"
fi

if command -v opencode >/dev/null 2>&1; then
  run_expect_pass "OpenCode resolved project config does not allow filesystem root when SFA_PROJECTS_ROOT is unset" \
    bash -lc "env -u SFA_PROJECTS_ROOT opencode debug config --pure >'$tmp_dir/opencode-resolved.json' && node -e \"const c=require('$tmp_dir/opencode-resolved.json'); function walk(v){ if (v && typeof v === 'object') { for (const [k, item] of Object.entries(v)) { if (k === '/**' && item === 'allow') process.exit(1); walk(item); } } } walk(c);\""
else
  pass "OpenCode resolved project config check skipped because opencode is optional and not installed"
fi

if [[ -x scripts/generate-opencode-local-config.sh ]]; then
  pass "OpenCode local config generator exists"
else
  fail "OpenCode local config generator exists"
fi

run_expect_pass "OpenCode local config generator emits concrete external_directory path" \
  bash -lc "mkdir -p '$tmp_dir/projects' && SFA_PROJECTS_ROOT='$tmp_dir/projects' scripts/generate-opencode-local-config.sh --output - >'$tmp_dir/opencode.local.json' && projects_real=\$(cd '$tmp_dir/projects' && pwd -P) && node -e \"const c=require('$tmp_dir/opencode.local.json'); const key=process.argv[1] + '/**'; if (!c.permission.external_directory[key]) process.exit(1); if (!c.agent['sfa-harness-explorer'].permission.external_directory[key]) process.exit(1); if (!c.agent['sfa-harness-reviewer'].permission.external_directory[key]) process.exit(1)\" \"\$projects_real\""

if [[ -x scripts/team-rollout-preflight.sh ]] \
  && grep -q 'scripts/harness-self-audit.sh' scripts/team-rollout-preflight.sh \
  && grep -q 'scripts/dev-env-check.sh' scripts/team-rollout-preflight.sh; then
  pass "team rollout preflight script exists with control-plane and local modes"
else
  fail "team rollout preflight script exists with control-plane and local modes"
fi

run_expect_pass "team rollout preflight control-plane mode passes" \
  scripts/team-rollout-preflight.sh --no-readiness

if grep -q 'hook end-to-end self-check passed' "$readiness_out"; then
  pass "team rollout preflight runs hook end-to-end self-check"
else
  fail "team rollout preflight runs hook end-to-end self-check"
  sed -n '1,120p' "$readiness_out" >&2 || true
fi

if grep -q '^config/opencode.local.json$' .gitignore; then
  pass "generated OpenCode local config is ignored"
else
  fail "generated OpenCode local config is ignored"
fi

if grep -q 'OPENCODE_CONFIG' docs/onboarding.md \
  && grep -q 'Codex.*trust' docs/onboarding.md \
  && grep -q 'Cursor.*Trusted' docs/onboarding.md; then
  pass "tool adapter trust and local config enablement are documented"
else
  fail "tool adapter trust and local config enablement are documented"
fi

if grep -q 'scripts/team-rollout-preflight.sh' README.md docs/onboarding.md docs/README.md; then
  pass "team rollout preflight command is documented"
else
  fail "team rollout preflight command is documented"
fi

run_expect_pass "Cursor shell adapter allows safe shell commands" \
  bash -lc "printf '%s\n' '{\"command\":\"git status --short\",\"hook_event_name\":\"beforeShellExecution\"}' | scripts/harness-sensor-runner.sh cursor beforeShellExecution >'$tmp_dir/cursor-safe.json' && grep -q '\"permission\":\"allow\"' '$tmp_dir/cursor-safe.json'"

run_expect_pass "Cursor shell adapter denies destructive shell commands" \
  bash -lc "printf '%s\n' '{\"command\":\"git reset --hard\",\"hook_event_name\":\"beforeShellExecution\"}' | scripts/harness-sensor-runner.sh cursor beforeShellExecution >'$tmp_dir/cursor-deny.json' && grep -q '\"permission\":\"deny\"' '$tmp_dir/cursor-deny.json' && grep -q 'HARNESS/DANGEROUS_COMMAND' '$tmp_dir/cursor-deny.json'"

run_expect_pass "Codex PreToolUse adapter denies destructive shell commands" \
  bash -lc "printf '%s\n' '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"rm -rf .\"},\"hook_event_name\":\"PreToolUse\"}' | scripts/harness-sensor-runner.sh codex PreToolUse >'$tmp_dir/codex-deny.json' && grep -q '\"permissionDecision\":\"deny\"' '$tmp_dir/codex-deny.json' && grep -q 'HARNESS/DANGEROUS_COMMAND' '$tmp_dir/codex-deny.json'"

run_expect_pass "Codex PreToolUse adapter denies destructive cmd payloads" \
  bash -lc "printf '%s\n' '{\"tool_name\":\"Bash\",\"tool_input\":{\"cmd\":\"git reset --hard\"},\"hook_event_name\":\"PreToolUse\"}' | scripts/harness-sensor-runner.sh codex PreToolUse >'$tmp_dir/codex-cmd-deny.json' && grep -q '\"permissionDecision\":\"deny\"' '$tmp_dir/codex-cmd-deny.json' && grep -q 'HARNESS/DANGEROUS_COMMAND' '$tmp_dir/codex-cmd-deny.json'"

runner_allowed_spec="$tmp_dir/runner-allowed-spec.md"
cat > "$runner_allowed_spec" <<SPEC
# runner allowed paths

allowed_paths:
  repo:
    - $tmp_dir/work/**
forbidden_paths:
  - "**/.env*"
SPEC

run_expect_pass "runner after-file-edit checks allowed paths when SFA_CHANGE_SPEC is set" \
  bash -lc "printf '%s\n' '{\"file_path\":\"$tmp_dir/work/src.txt\",\"hook_event_name\":\"afterFileEdit\"}' | SFA_CHANGE_SPEC='$runner_allowed_spec' scripts/harness-sensor-runner.sh cursor afterFileEdit >'$tmp_dir/cursor-after-edit.json' && grep -q '\"permission\":\"allow\"' '$tmp_dir/cursor-after-edit.json' && grep -q 'allowed paths checked' '$tmp_dir/cursor-after-edit.json'"

run_expect_pass "runner post-tool-use checks apply_patch file headers when SFA_CHANGE_SPEC is set" \
  bash -lc "printf '%s\n' '{\"tool_name\":\"apply_patch\",\"tool_input\":{\"patch\":\"*** Begin Patch\n*** Update File: $tmp_dir/work/src.txt\n@@\n-old\n+new\n*** End Patch\n\"},\"hook_event_name\":\"PostToolUse\"}' | SFA_CHANGE_SPEC='$runner_allowed_spec' scripts/harness-sensor-runner.sh codex PostToolUse >'$tmp_dir/codex-patch-edit.json' && grep -q 'allowed paths checked' '$tmp_dir/codex-patch-edit.json'"

run_expect_pass "runner post-tool-use denies edit payloads without file information when SFA_CHANGE_SPEC is set" \
  bash -lc "printf '%s\n' '{\"tool_name\":\"apply_patch\",\"tool_input\":{\"patch\":\"no file headers\"},\"hook_event_name\":\"PostToolUse\"}' | SFA_CHANGE_SPEC='$runner_allowed_spec' scripts/harness-sensor-runner.sh codex PostToolUse >'$tmp_dir/codex-patch-missing.json' && grep -q 'HARNESS/MISSING_CHANGED_FILE' '$tmp_dir/codex-patch-missing.json'"

scan_targets=(
  AGENTS.md
  README.md
  multi-repo-harness-implementation-plan.md
  docs/architecture/repo-registry.md
  docs/README.md
  docs/onboarding.md
  templates
  lanes
  rules
  evals
  scripts
  opencode.json
  .opencode/agents
  config
)

existing_scan_targets=()
for target in "${scan_targets[@]}"; do
  [[ -e "$target" ]] && existing_scan_targets+=("$target")
done

personal_path_pattern='/Users/'"00555733"

if ! command -v rg >/dev/null 2>&1; then
  fail "ripgrep is required for team-facing personal path scan"
elif rg -n "$personal_path_pattern" "${existing_scan_targets[@]}" \
  --glob '!config/repos.local.sh' \
  >/tmp/sfa-harness-readiness.out 2>/tmp/sfa-harness-readiness.err; then
  fail "team-facing active files must not hard-code personal machine paths"
  sed -n '1,40p' /tmp/sfa-harness-readiness.out >&2 || true
else
  pass "team-facing active files do not hard-code personal machine paths"
fi

if [[ -f config/repos.local.example.sh ]]; then
  pass "local repo config example exists"
else
  fail "local repo config example exists"
fi

if [[ -f docs/onboarding.md ]]; then
  pass "onboarding manual exists"
else
  fail "onboarding manual exists"
fi

if rg -q '业务仓扫描' docs/onboarding.md AGENTS.md; then
  pass "business repo scan policy is documented"
else
  fail "business repo scan policy is documented"
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: readiness test found %s issue(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness team readiness checks passed\n'
