#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/environment-readiness-gate.sh <environment-readiness.md | change-dir>

Fails closed unless environment readiness contains:
  - environment_status: READY
  - environment, system runtime, topology, role/account, permission, data, device/tool sections
  - at least one concrete READY system runtime row
  - app runtime standards when iOS/Android is declared required
  - no open blockers, placeholders, or reusable credentials
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

field_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*:" {
      sub("^[[:space:]]*" key "[[:space:]]*:[[:space:]]*", "")
      sub("[[:space:]]+$", "")
      print
      exit
    }
  ' "$file"
}

require_text() {
  local file="$1" text="$2" code="$3" message="$4"
  if ! grep -qF "$text" "$file"; then
    fail "$code" "$message" "Add the missing section before marking environment_status READY." "$text"
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

target="${1:-}"
[[ -n "$target" ]] || fail \
  "ENVIRONMENT_READINESS/MISSING_PATH" \
  "missing environment readiness path" \
  "Pass changes/<change-id>/environment-readiness.md or changes/<change-id>/." \
  "templates/environment-readiness.md"

if [[ -d "$target" ]]; then
  env_file="$target/environment-readiness.md"
else
  env_file="$target"
fi

[[ -f "$env_file" ]] || fail \
  "ENVIRONMENT_READINESS/MISSING_FILE" \
  "environment readiness file not found: $env_file" \
  "Create it from templates/environment-readiness.md and fill target environments, roles, data, and permissions." \
  "changes/<change-id>/environment-readiness.md"

status="$(field_value "$env_file" "environment_status")"
if [[ "$status" != "READY" ]]; then
  fail \
    "ENVIRONMENT_READINESS/NOT_READY" \
    "environment_status is '${status:-missing}', not READY" \
    "Resolve required environment, account, permission, and test data prerequisites before implementation or E2E testing." \
    "environment_status: READY"
fi

require_text "$env_file" "## 环境矩阵" "ENVIRONMENT_READINESS/MISSING_ENV_MATRIX" "environment matrix is required"
require_text "$env_file" "## 本轮必测系统" "ENVIRONMENT_READINESS/MISSING_TARGET_SYSTEMS" "target system matrix is required"
require_text "$env_file" "## 系统运行标准" "ENVIRONMENT_READINESS/MISSING_RUNTIME_STANDARDS" "system runtime standard section is required"
require_text "$env_file" "## 本地联调拓扑" "ENVIRONMENT_READINESS/MISSING_INTEGRATION_TOPOLOGY" "local integration topology section is required"
require_text "$env_file" "## App 端运行标准" "ENVIRONMENT_READINESS/MISSING_APP_RUNTIME" "app runtime standard section is required"
require_text "$env_file" "## 角色账号" "ENVIRONMENT_READINESS/MISSING_ROLES" "role/account matrix is required"
require_text "$env_file" "## 数据与权限" "ENVIRONMENT_READINESS/MISSING_PERMISSIONS" "data and permission matrix is required"
require_text "$env_file" "## 测试数据准备" "ENVIRONMENT_READINESS/MISSING_TEST_DATA" "test data preparation section is required"
require_text "$env_file" "## 设备与工具" "ENVIRONMENT_READINESS/MISSING_DEVICES" "device and tool section is required"

role_count="$(grep -cE '^\|[[:space:]]*[^|<[:space:]][^|]*[[:space:]]*\|[[:space:]]*(local|test|pre-release|production-readonly)' "$env_file" || true)"
if [[ "$role_count" -eq 0 ]]; then
  fail \
    "ENVIRONMENT_READINESS/NO_ROLE_ROWS" \
    "role/account matrix has no concrete role rows" \
    "Add at least one role row with environment, credential source, data scope, and status." \
    "| Region manager | test | redacted account | Keychain | org scope | READY |"
fi

target_count="$(grep -cE '^\|[[:space:]]*TGT-[0-9]+' "$env_file" || true)"
if [[ "$target_count" -eq 0 ]]; then
  fail \
    "ENVIRONMENT_READINESS/NO_TARGET_SYSTEM_ROWS" \
    "target system matrix has no TGT-* rows" \
    "Add target system rows and mark required systems READY or out-of-scope systems N/A." \
    "| TGT-001 | PC Web | yes | SYS-001 | READY | N/A |"
fi

if awk -F'|' '
  function trim(value) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    return value
  }
  /^\|[[:space:]]*TGT-[0-9]+/ {
    required=tolower(trim($4))
    status=trim($6)
    reason=trim($7)
    if (required == "yes" && status != "READY") {
      print NR ":" $0
    }
    if (required == "no" && status != "N/A") {
      print NR ":" $0
    }
    if (required == "no" && status == "N/A" && (reason == "" || reason == "-")) {
      print NR ":" $0
    }
  }
' "$env_file" >/tmp/sfa-environment-target-systems.out; then
  if [[ -s /tmp/sfa-environment-target-systems.out ]]; then
    printf 'Invalid target system rows:\n' >&2
    sed -n '1,20p' /tmp/sfa-environment-target-systems.out >&2
    rm -f /tmp/sfa-environment-target-systems.out
    fail \
      "ENVIRONMENT_READINESS/INVALID_TARGET_SYSTEM_ROWS" \
      "required systems must be READY; out-of-scope systems must be N/A with a reason" \
      "Fix the target system matrix before setting environment_status READY." \
      "| TGT-002 | iOS | no | N/A | N/A | Not touched by this change |"
  fi
fi
rm -f /tmp/sfa-environment-target-systems.out

ready_system_count="$(awk -F'|' '
  function trim(value) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    return value
  }
  /^\|[[:space:]]*SYS-[0-9]+/ {
    status=trim($10)
    if (status == "READY") count += 1
  }
  END { print count + 0 }
' "$env_file")"
if [[ "$ready_system_count" -eq 0 ]]; then
  fail \
    "ENVIRONMENT_READINESS/NO_READY_RUNTIME_STANDARD" \
    "system runtime standards have no concrete READY SYS-* rows" \
    "Add at least one system runtime row with local command/launch method, env profile, dependencies, health check, and evidence." \
    "| SYS-001 | PC Web | frontend-map-system | scripts/frontend-dev-server.sh frontend-map-system 9527 | local + test API | http://localhost:9527 | VPN/proxy | login page screenshot | READY | evidence/path.png |"
fi

ready_topology_count="$(awk -F'|' '
  function trim(value) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    return value
  }
  /^\|[[:space:]]*TOPO-[0-9]+/ {
    status=trim($8)
    if (status == "READY") count += 1
  }
  END { print count + 0 }
' "$env_file")"
if [[ "$ready_topology_count" -eq 0 ]]; then
  fail \
    "ENVIRONMENT_READINESS/NO_READY_TOPOLOGY" \
    "local integration topology has no READY TOPO-* row" \
    "Add a topology row showing whether each client uses local backend, test API, pre-release API, or Harness proxy." \
    "| TOPO-001 | PC Web | local proxy | test DB | test API | VPN | READY | evidence/path.md |"
fi

android_required="$(awk -F'|' '
  function trim(value) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    return value
  }
  /^\|[[:space:]]*TGT-[0-9]+/ {
    sys_name=tolower(trim($3))
    required=tolower(trim($4))
    status=trim($6)
    if (required == "yes" && status == "READY" && sys_name ~ /android/) count += 1
  }
  END { print count + 0 }
' "$env_file")"
ios_required="$(awk -F'|' '
  function trim(value) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    return value
  }
  /^\|[[:space:]]*TGT-[0-9]+/ {
    sys_name=tolower(trim($3))
    required=tolower(trim($4))
    status=trim($6)
    if (required == "yes" && status == "READY" && sys_name ~ /ios/) count += 1
  }
  END { print count + 0 }
' "$env_file")"
android_app_ready="$(awk -F'|' '
  function trim(value) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    return value
  }
  /^\|[[:space:]]*APP-[0-9]+/ {
    platform=tolower(trim($3))
    status=trim($11)
    if (platform ~ /android/ && status == "READY") count += 1
  }
  END { print count + 0 }
' "$env_file")"
ios_app_ready="$(awk -F'|' '
  function trim(value) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    return value
  }
  /^\|[[:space:]]*APP-[0-9]+/ {
    platform=tolower(trim($3))
    status=trim($11)
    if (platform ~ /ios/ && status == "READY") count += 1
  }
  END { print count + 0 }
' "$env_file")"

if [[ "$android_required" -gt 0 && "$android_app_ready" -eq 0 ]]; then
  fail \
    "ENVIRONMENT_READINESS/MISSING_ANDROID_APP_RUNTIME" \
    "Android is required but no READY Android APP-* runtime row exists" \
    "Record Android flavor/build variant, build command, environment switch, simulator coverage, real-device-only capabilities, SDK limits, and evidence." \
    "| APP-002 | Android | mobile-sfa-android | debug | ./gradlew :app:assembleDebug | debug menu test env | login/display | camera/location | map SDK limit | READY | evidence/android.png |"
fi

if [[ "$ios_required" -gt 0 && "$ios_app_ready" -eq 0 ]]; then
  fail \
    "ENVIRONMENT_READINESS/MISSING_IOS_APP_RUNTIME" \
    "iOS is required but no READY iOS APP-* runtime row exists" \
    "Record iOS scheme/config, build command, environment switch, simulator coverage, real-device-only capabilities, SDK limits, and evidence." \
    "| APP-001 | iOS | mobile-sfa-ios | FProject Debug | xcodebuild ... | debug config test env | login/display | camera/location | SDK stubs | READY | evidence/ios.png |"
fi

if awk -F'|' '
  /^\|/ && $0 !~ /^\|[[:space:]]*-+/ && $0 !~ /^\|[[:space:]]*(Target ID|Environment|Standard ID|Topology ID|App ID|Role|Item|Dataset|Tool|Blocker)[[:space:]]*\|/ {
    for (i = 1; i <= NF; i += 1) {
      cell=$i
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell)
      if (cell == "PENDING" || cell == "BLOCKED" || cell == "OPEN") {
        print NR ":" $0
        break
      }
    }
  }
' "$env_file" >/tmp/sfa-environment-not-ready.out; then
  if [[ -s /tmp/sfa-environment-not-ready.out ]]; then
    printf 'Not-ready rows:\n' >&2
    sed -n '1,20p' /tmp/sfa-environment-not-ready.out >&2
    rm -f /tmp/sfa-environment-not-ready.out
    fail \
      "ENVIRONMENT_READINESS/OPEN_OR_BLOCKED_ROWS" \
      "environment readiness contains PENDING, BLOCKED, or OPEN table rows" \
      "Resolve or mark not-in-scope rows as N/A with notes before setting environment_status READY." \
      "| test | E2E | ... | READY |"
  fi
fi
rm -f /tmp/sfa-environment-not-ready.out

if grep -nE '\b(TODO|TBD)\b|待补|未定|<[^>]+>' "$env_file" >/tmp/sfa-environment-placeholders.out; then
  printf 'Unresolved placeholders:\n' >&2
  sed -n '1,20p' /tmp/sfa-environment-placeholders.out >&2
  rm -f /tmp/sfa-environment-placeholders.out
  fail \
    "ENVIRONMENT_READINESS/UNRESOLVED_PLACEHOLDER" \
    "environment readiness contains unresolved placeholders" \
    "Replace placeholders with concrete entries or explicit N/A reasons." \
    "templates/environment-readiness.md"
fi
rm -f /tmp/sfa-environment-placeholders.out

if grep -nE -i '(password[[:space:]]*[:=]|passwd[[:space:]]*[:=]|pwd[[:space:]]*[:=]|authorization[[:space:]]*[:=]|bearer[[:space:]]+[A-Za-z0-9._-]+|mysql://|jdbc:|rm-[A-Za-z0-9.-]+:[0-9]+|access[_ -]?token[[:space:]]*[:=]|refresh[_ -]?token[[:space:]]*[:=])' "$env_file" >/tmp/sfa-environment-sensitive.out; then
  printf 'Potential sensitive values:\n' >&2
  sed -n '1,20p' /tmp/sfa-environment-sensitive.out >&2
  rm -f /tmp/sfa-environment-sensitive.out
  fail \
    "ENVIRONMENT_READINESS/SENSITIVE_CONTENT" \
    "environment readiness appears to contain reusable credentials or connection details" \
    "Remove secrets and record credential source / permission owner only." \
    "Credential source: Keychain / Feishu permission doc / user-provided at runtime"
fi
rm -f /tmp/sfa-environment-sensitive.out

printf 'PASS: environment readiness confirmed in %s\n' "$env_file"
