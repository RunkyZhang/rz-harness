#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"
guide="docs/onboarding/local-dev-environment.md"

failures=0
warnings=0

pass() {
  printf 'PASS: %s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1" >&2
  warnings=$((warnings + 1))
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

fix_hint() {
  printf 'FIX: %s\n' "$1" >&2
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

version_gte() {
  local actual="$1"
  local expected="$2"
  node -e '
const actual = process.argv[1].split(".").map(Number);
const expected = process.argv[2].split(".").map(Number);
for (let i = 0; i < Math.max(actual.length, expected.length); i += 1) {
  const a = actual[i] || 0;
  const e = expected[i] || 0;
  if (a > e) process.exit(0);
  if (a < e) process.exit(1);
}
process.exit(0);
' "$actual" "$expected"
}

package_has_script() {
  local package_json="$1"
  local script_name="$2"
  grep -q "\"$script_name\"[[:space:]]*:" "$package_json"
}

check_cmd() {
  local name="$1"
  local cmd="$2"
  if have_cmd "$cmd"; then
    pass "$name is available: $(command -v "$cmd")"
  else
    fail "$name is missing: $cmd"
  fi
}

if [[ -f config/repos.local.sh ]]; then
  # shellcheck disable=SC1091
  source config/repos.local.sh
  pass "loaded config/repos.local.sh"
else
  warn "missing config/repos.local.sh; using exported SFA_* environment variables if present"
  fix_hint "Copy config/repos.local.example.sh to config/repos.local.sh; see $guide"
fi

: "${SFA_PROJECTS_ROOT:=$HOME/codex/sfa-projects}"
: "${SFA_REPO_BACKEND_CEO_MEMBER:=$SFA_PROJECTS_ROOT/backend-ceo-member}"
: "${SFA_REPO_FRONTEND_MERCHANT_WECHATAPP:=$SFA_PROJECTS_ROOT/merchant-wechatapp}"
: "${SFA_REPO_BACKEND_SFA_ROOT:=$SFA_PROJECTS_ROOT/sfa-root}"
: "${SFA_REPO_FRONTEND_SFAINTL:=$SFA_PROJECTS_ROOT/SfaIntl}"
: "${SFA_REPO_MOBILE_SFA_IOS:=$SFA_PROJECTS_ROOT/sfa-ios}"
: "${SFA_REPO_MOBILE_SFA_ANDROID:=$SFA_PROJECTS_ROOT/sfa-android}"

expected_java_major="${SFA_BACKEND_JAVA_MAJOR:-8}"
expected_node_version="${SFA_FRONTEND_NODE_VERSION:-14.21.3}"
expected_wechatapp_node_version="${SFA_FRONTEND_MERCHANT_WECHATAPP_NODE_VERSION:-18.18.0}"
maven_cmd="${SFA_BACKEND_MAVEN_COMMAND:-mvn}"
maven_args="${SFA_BACKEND_MAVEN_ARGS:-}"
package_manager="${SFA_FRONTEND_PACKAGE_MANAGER:-npm}"
package_manager_args="${SFA_FRONTEND_PACKAGE_MANAGER_ARGS:-}"

check_cmd "Git" git
check_cmd "ripgrep" rg
check_cmd "Java" java
check_cmd "Maven" "$maven_cmd"
check_cmd "Node.js" node
check_cmd "npm" npm
check_cmd "Frontend package manager" "$package_manager"

if [[ "$maven_cmd" == *" "* ]]; then
  fail "SFA_BACKEND_MAVEN_COMMAND must be an executable path only; put fixed arguments in SFA_BACKEND_MAVEN_ARGS"
  fix_hint "Move fixed Maven args to SFA_BACKEND_MAVEN_ARGS in config/repos.local.sh"
fi

if [[ "$package_manager" == *" "* ]]; then
  fail "SFA_FRONTEND_PACKAGE_MANAGER must be an executable path only; put fixed arguments in SFA_FRONTEND_PACKAGE_MANAGER_ARGS"
  fix_hint "Move package manager args to SFA_FRONTEND_PACKAGE_MANAGER_ARGS in config/repos.local.sh"
fi

[[ -n "$maven_args" ]] && printf 'INFO: maven fixed args: %s\n' "$maven_args"
[[ -n "$package_manager_args" ]] && printf 'INFO: frontend package manager fixed args: %s\n' "$package_manager_args"

if have_cmd java; then
  java_version_output="$(java -version 2>&1 | sed -n '1p')"
  printf 'INFO: java version: %s\n' "$java_version_output"
  if [[ "$expected_java_major" == "8" ]]; then
    if [[ "$java_version_output" == *'"1.8.'* || "$java_version_output" == *'"8.'* ]]; then
      pass "Java major version matches expected $expected_java_major"
    else
      fail "Java major version should be $expected_java_major for SFA backend repos"
    fi
  fi
fi

if have_cmd node; then
  node_version="$(node -v | sed 's/^v//')"
  printf 'INFO: node version: %s\n' "$node_version"
  if [[ "$node_version" == "$expected_node_version" ]]; then
    pass "Node.js version matches expected $expected_node_version"
  else
    expected_node_available=0
    if [[ -n "${SFA_FRONTEND_NODE_BIN_DIR:-}" && -x "${SFA_FRONTEND_NODE_BIN_DIR}/node" ]]; then
      configured_node_version="$("${SFA_FRONTEND_NODE_BIN_DIR}/node" -v | sed 's/^v//')"
      if [[ "$configured_node_version" == "$expected_node_version" ]]; then
        expected_node_available=1
        pass "Node.js expected version $expected_node_version is available via SFA_FRONTEND_NODE_BIN_DIR"
      fi
    fi
    if [[ "$expected_node_available" -eq 0 ]] && EXPECTED_NODE_VERSION="$expected_node_version" bash -lc 'source ~/.nvm/nvm.sh >/dev/null 2>&1 && nvm exec "$EXPECTED_NODE_VERSION" node -v' >/dev/null 2>&1; then
      expected_node_available=1
      pass "Node.js expected version $expected_node_version is available via nvm"
    fi
    if [[ "$expected_node_available" -eq 0 ]]; then
      warn "Node.js version is $node_version; mapSystem local dev expects $expected_node_version"
      fix_hint "Install/use Node $expected_node_version with nvm or set SFA_FRONTEND_NODE_BIN_DIR; see $guide"
    fi
  fi

  expected_wechatapp_node_available=0
  if version_gte "$node_version" "$expected_wechatapp_node_version"; then
    expected_wechatapp_node_available=1
    pass "Node.js version satisfies merchant-wechatapp >=$expected_wechatapp_node_version"
  elif [[ -n "${SFA_FRONTEND_MERCHANT_WECHATAPP_NODE_BIN_DIR:-}" && -x "${SFA_FRONTEND_MERCHANT_WECHATAPP_NODE_BIN_DIR}/node" ]]; then
    configured_wechatapp_node_version="$("${SFA_FRONTEND_MERCHANT_WECHATAPP_NODE_BIN_DIR}/node" -v | sed 's/^v//')"
    if version_gte "$configured_wechatapp_node_version" "$expected_wechatapp_node_version"; then
      expected_wechatapp_node_available=1
      pass "Node.js satisfies merchant-wechatapp >=$expected_wechatapp_node_version via SFA_FRONTEND_MERCHANT_WECHATAPP_NODE_BIN_DIR"
    fi
  fi
  if [[ "$expected_wechatapp_node_available" -eq 0 ]] && EXPECTED_WECHATAPP_NODE_VERSION="$expected_wechatapp_node_version" bash -lc 'source ~/.nvm/nvm.sh >/dev/null 2>&1 && nvm exec "$EXPECTED_WECHATAPP_NODE_VERSION" node -v' >/dev/null 2>&1; then
    expected_wechatapp_node_available=1
    pass "Node.js expected version $expected_wechatapp_node_version is available via nvm for merchant-wechatapp"
  fi
  if [[ "$expected_wechatapp_node_available" -eq 0 ]]; then
    warn "merchant-wechatapp requires Node >=$expected_wechatapp_node_version; current Node is $node_version"
    fix_hint "Install/use Node >=$expected_wechatapp_node_version or set SFA_FRONTEND_MERCHANT_WECHATAPP_NODE_BIN_DIR"
  fi
fi

if have_cmd npm; then
  printf 'INFO: npm version: %s\n' "$(npm -v)"
fi

if have_cmd nvm || bash -lc 'type nvm' >/dev/null 2>&1; then
  pass "nvm is available"
else
  warn "nvm is not available; install it or provide a project-local Node $expected_node_version"
  fix_hint "Install nvm or configure SFA_FRONTEND_NODE_BIN_DIR; see $guide"
fi

repo_vars=(
  SFA_REPO_BACKEND_SALES_MANAGEMENT
  SFA_REPO_BACKEND_SFA_BACKEND
  SFA_REPO_FRONTEND_MAP_SYSTEM
  SFA_REPO_FRONTEND_SIGN_UP
  SFA_REPO_FRONTEND_MERCHANT_WECHATAPP
)

optional_repo_vars=(
  SFA_REPO_BACKEND_SFA_ROOT
  SFA_REPO_BACKEND_CEO_MEMBER
  SFA_REPO_FRONTEND_SFAINTL
  SFA_REPO_MOBILE_SFA_IOS
  SFA_REPO_MOBILE_SFA_ANDROID
)

check_repo_path() {
  local var_name="$1"
  local required="$2"
  repo_path="${!var_name:-}"
  if [[ -z "$repo_path" ]]; then
    if [[ "$required" == "required" ]]; then
      fail "$var_name is not set"
    else
      warn "$var_name is not set; required only when the change touches this system"
    fi
    fix_hint "Set $var_name in config/repos.local.sh when this system is in scope"
    return
  fi
  if [[ ! -d "$repo_path" ]]; then
    if [[ "$required" == "required" ]]; then
      fail "$var_name does not exist: $repo_path"
    else
      warn "$var_name does not exist: $repo_path; mark N/A in readiness if out of scope"
    fi
    fix_hint "Clone the repo or correct $var_name in config/repos.local.sh when this system is in scope"
    return
  fi
  pass "$var_name exists: $repo_path"
  if git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch="$(git -C "$repo_path" branch --show-current 2>/dev/null || true)"
    remote="$(git -C "$repo_path" remote get-url origin 2>/dev/null || true)"
    pass "$var_name is a git repository"
    printf 'INFO: %s branch: %s\n' "$var_name" "${branch:-unknown}"
    printf 'INFO: %s origin: %s\n' "$var_name" "${remote:-unknown}"
  else
    if [[ "$required" == "required" ]]; then
      fail "$var_name is not a git repository: $repo_path"
    else
      warn "$var_name is not a git repository: $repo_path; use the real repo when this system is in scope"
    fi
    fix_hint "Use the real Codeup working copy for $var_name, not an extracted build/output directory"
  fi
}

for var_name in "${repo_vars[@]}"; do
  check_repo_path "$var_name" "required"
done

for var_name in "${optional_repo_vars[@]}"; do
  check_repo_path "$var_name" "optional"
done

if [[ -n "${SFA_REPO_BACKEND_SALES_MANAGEMENT:-}" && -f "$SFA_REPO_BACKEND_SALES_MANAGEMENT/pom.xml" ]]; then
  pass "sfa-sales-management pom.xml exists"
else
  fail "sfa-sales-management pom.xml is missing"
fi

if [[ -n "${SFA_REPO_BACKEND_CEO_MEMBER:-}" && -d "$SFA_REPO_BACKEND_CEO_MEMBER" ]]; then
  if [[ -f "$SFA_REPO_BACKEND_CEO_MEMBER/pom.xml" ]]; then
    pass "backend-ceo-member pom.xml exists"
  else
    warn "backend-ceo-member repo exists but pom.xml is missing"
  fi
  if [[ -d "$SFA_REPO_BACKEND_CEO_MEMBER/backend-ceo-member-webapi" && -d "$SFA_REPO_BACKEND_CEO_MEMBER/backend-ceo-member-service" ]]; then
    pass "backend-ceo-member expected webapi/service modules exist"
  else
    warn "backend-ceo-member expected webapi/service modules are missing"
  fi
fi

if [[ -n "${SFA_REPO_FRONTEND_MAP_SYSTEM:-}" && -f "$SFA_REPO_FRONTEND_MAP_SYSTEM/package.json" ]]; then
  pass "mapSystem package.json exists"
else
  fail "mapSystem package.json is missing"
fi

if [[ -n "${SFA_REPO_FRONTEND_MERCHANT_WECHATAPP:-}" && -f "$SFA_REPO_FRONTEND_MERCHANT_WECHATAPP/package.json" ]]; then
  pass "merchant-wechatapp package.json exists"
  for script_name in tsc build dev lint; do
    if package_has_script "$SFA_REPO_FRONTEND_MERCHANT_WECHATAPP/package.json" "$script_name"; then
      pass "merchant-wechatapp package.json has npm script: $script_name"
    else
      fail "merchant-wechatapp package.json missing npm script: $script_name"
    fi
  done
  [[ -f "$SFA_REPO_FRONTEND_MERCHANT_WECHATAPP/project.config.json" ]] || fail "merchant-wechatapp project.config.json is missing"
  [[ -d "$SFA_REPO_FRONTEND_MERCHANT_WECHATAPP/miniprogram/pages" ]] || fail "merchant-wechatapp miniprogram/pages is missing"
else
  fail "merchant-wechatapp package.json is missing"
fi

if [[ -n "${SFA_REPO_MOBILE_SFA_IOS:-}" && -d "$SFA_REPO_MOBILE_SFA_IOS" ]]; then
  if find "$SFA_REPO_MOBILE_SFA_IOS" -maxdepth 2 \( -name '*.xcworkspace' -o -name '*.xcodeproj' \) | grep -q .; then
    pass "iOS project/workspace exists"
  else
    warn "iOS repo exists but no xcodeproj/xcworkspace found within depth 2"
  fi
fi

if [[ -n "${SFA_REPO_MOBILE_SFA_ANDROID:-}" && -d "$SFA_REPO_MOBILE_SFA_ANDROID" ]]; then
  if [[ -f "$SFA_REPO_MOBILE_SFA_ANDROID/settings.gradle" || -f "$SFA_REPO_MOBILE_SFA_ANDROID/settings.gradle.kts" ]]; then
    pass "Android Gradle settings file exists"
  else
    warn "Android repo exists but settings.gradle/settings.gradle.kts is missing"
  fi
fi

if have_cmd lark-cli; then
  pass "lark-cli is available"
  if lark_version="$(lark-cli --version 2>&1 | sed -n '1p')" && [[ -n "$lark_version" ]]; then
    printf 'INFO: lark-cli version: %s\n' "$lark_version"
  elif lark_version="$(lark-cli -v 2>&1 | sed -n '1p')" && [[ -n "$lark_version" ]]; then
    printf 'INFO: lark-cli version: %s\n' "$lark_version"
  elif lark_version="$(lark-cli version 2>&1 | sed -n '1p')" && [[ -n "$lark_version" ]]; then
    printf 'INFO: lark-cli version: %s\n' "$lark_version"
  else
    warn "lark-cli exists but version check failed"
  fi
else
  warn "lark-cli is missing; Feishu PRD/wiki sync will require manual copy"
  fix_hint "Install/configure lark-cli if the requirement uses Feishu PRD or report sync"
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: dev environment check found %s failure(s), %s warning(s)\n' "$failures" "$warnings" >&2
  printf 'INFO: Local setup guide: %s\n' "$guide" >&2
  exit 1
fi

printf 'PASS: dev environment check passed with %s warning(s)\n' "$warnings"
printf 'INFO: Local setup guide: %s\n' "$guide"
printf 'INFO: runtime services still require company network/VPN and access to Nacos, Redis, MQ, database, and test login state.\n'
