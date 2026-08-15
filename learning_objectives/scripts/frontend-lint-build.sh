#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/frontend-lint-build.sh <repo-path> <lint|build|script|lint-files> [npm-script|files...]

Examples:
  scripts/frontend-lint-build.sh /path/to/mapSystem lint
  scripts/frontend-lint-build.sh /path/to/mapSystem lint-files src/views/example/index.vue
  scripts/frontend-lint-build.sh /path/to/mapSystem build build:test
  scripts/frontend-lint-build.sh /path/to/sign-up script test:unit
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }

repo="${1:-}"
mode="${2:-}"
script_name="${3:-}"

[[ -n "$repo" ]] || fail "missing repo path"
[[ -d "$repo" ]] || fail "repo path not found: $repo"
[[ -f "$repo/package.json" ]] || fail "package.json not found: $repo"

cd "$repo"

if [[ ! -d node_modules ]]; then
  fail "node_modules missing; install dependencies before claiming frontend lint/build passed"
fi

package_manager="${SFA_FRONTEND_PACKAGE_MANAGER:-npm}"
read -r -a package_manager_args <<< "${SFA_FRONTEND_PACKAGE_MANAGER_ARGS:-}"

case "$mode" in
  lint-files)
    shift 2
    [[ "$#" -gt 0 ]] || fail "lint-files mode requires at least one file path"
    ./node_modules/.bin/eslint --ext .js,.vue "$@"
    exit 0
    ;;
  lint)
    script_name="${script_name:-lint}"
    ;;
  build)
    script_name="${script_name:-build:test}"
    ;;
  script)
    [[ -n "$script_name" ]] || fail "script mode requires npm-script"
    ;;
  *)
    fail "mode must be lint, build, or script"
    ;;
esac

exec "$package_manager" "${package_manager_args[@]}" run "$script_name"
