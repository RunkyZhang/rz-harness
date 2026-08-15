#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/mvn-targeted-test.sh <repo-path> <module|-> <compile|test> [TestClass]

Examples:
  scripts/mvn-targeted-test.sh /path/to/repo sfa-sales-management-interfaces compile
  scripts/mvn-targeted-test.sh /path/to/repo sfa-sales-management-interfaces test SomeTest
  scripts/mvn-targeted-test.sh /path/to/repo - compile
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }

repo="${1:-}"
module="${2:-}"
mode="${3:-}"
test_class="${4:-}"

[[ -n "$repo" ]] || fail "missing repo path"
[[ -d "$repo" ]] || fail "repo path not found: $repo"
[[ -f "$repo/pom.xml" ]] || fail "pom.xml not found: $repo"
[[ "$mode" == "compile" || "$mode" == "test" ]] || fail "mode must be compile or test"

cd "$repo"

maven_cmd="${SFA_BACKEND_MAVEN_COMMAND:-mvn}"
read -r -a maven_args <<< "${SFA_BACKEND_MAVEN_ARGS:-}"

if [[ "$mode" == "compile" ]]; then
  if [[ "$module" == "-" ]]; then
    exec "$maven_cmd" "${maven_args[@]}" -DskipTests compile
  fi
  exec "$maven_cmd" "${maven_args[@]}" -pl "$module" -am -DskipTests compile
fi

[[ -n "$test_class" ]] || fail "test mode requires TestClass"

if [[ "$module" == "-" ]]; then
  exec "$maven_cmd" "${maven_args[@]}" -Dtest="$test_class" test
fi

exec "$maven_cmd" "${maven_args[@]}" -pl "$module" -Dtest="$test_class" test
