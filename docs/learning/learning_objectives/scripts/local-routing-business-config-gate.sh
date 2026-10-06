#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/local-routing-business-config-gate.sh [--allow-business-config] <changed-file> [changed-file...]

Blocks local-smoke proxy mutations in business frontend configuration.
Use harness local-routing.yml and VUE_APP_BASE_API=http://127.0.0.1:19080/
instead of editing business vue.config.js or .env* files.
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

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

allow="no"
if [[ "${1:-}" == "--allow-business-config" ]]; then
  allow="yes"
  shift
fi

[[ "$#" -gt 0 ]] || fail \
  "LOCAL_ROUTING/MISSING_CHANGED_FILES" \
  "missing changed files" \
  "Pass changed frontend files before local smoke." \
  "scripts/local-routing-business-config-gate.sh /absolute/path/src/page.vue"

if [[ "$allow" == "yes" ]]; then
  printf 'PASS: business frontend config mutation explicitly allowed for %s file(s)\n' "$#"
  exit 0
fi

for file in "$@"; do
  base="$(basename "$file")"
  case "$base" in
    vue.config.js|.env|.env.*)
      fail \
        "LOCAL_ROUTING/BUSINESS_CONFIG_MUTATION" \
        "business frontend config file should not be changed for local proxy routing: $file" \
        "Put route decisions in changes/<change-id>/local-routing.yml and start the frontend with VUE_APP_BASE_API=http://127.0.0.1:19080/." \
        "scripts/generate-local-routing.sh --change-id <id> --frontend-repo frontend-map-system --active-backends backend-sales-management"
      ;;
  esac
done

printf 'PASS: local routing business config gate passed for %s file(s)\n' "$#"
