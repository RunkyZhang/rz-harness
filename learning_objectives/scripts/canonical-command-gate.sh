#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/canonical-command-gate.sh -- <command> [args...]

Blocks known invalid verification commands before they are recorded as evidence.
Current rule:
  - sfa-sales-management-interfaces Maven reactor commands must include -am / --also-make.
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

if [[ "${1:-}" == "--" ]]; then
  shift
fi

[[ "$#" -gt 0 ]] || fail \
  "CANONICAL_COMMAND/MISSING_COMMAND" \
  "missing command" \
  "Pass the exact command after -- before running it." \
  "scripts/canonical-command-gate.sh -- mvn -pl sfa-sales-management-interfaces -am -DskipTests compile"

is_maven="no"
has_interfaces_module="no"
has_also_make="no"
expect_projects_arg="no"

has_module() {
  local modules="$1"
  local old_ifs="$IFS"
  IFS=','
  read -ra module_parts <<< "$modules"
  IFS="$old_ifs"

  local module=""
  for module in "${module_parts[@]}"; do
    module="${module#"${module%%[![:space:]]*}"}"
    module="${module%"${module##*[![:space:]]}"}"
    if [[ "$module" == "sfa-sales-management-interfaces" ]]; then
      return 0
    fi
  done
  return 1
}

for arg in "$@"; do
  if [[ "$expect_projects_arg" == "yes" ]]; then
    if has_module "$arg"; then
      has_interfaces_module="yes"
    fi
    expect_projects_arg="no"
    continue
  fi

  case "$arg" in
    mvn|./mvnw|mvnw|*/mvn|*/mvnw)
      is_maven="yes"
      ;;
    -pl|--projects)
      expect_projects_arg="yes"
      ;;
    -pl=*|--projects=*)
      projects="${arg#*=}"
      if has_module "$projects"; then
        has_interfaces_module="yes"
      fi
      ;;
    sfa-sales-management-interfaces)
      has_interfaces_module="yes"
      ;;
    -am|--also-make)
      has_also_make="yes"
      ;;
  esac
done

if [[ "$is_maven" == "yes" && "$has_interfaces_module" == "yes" && "$has_also_make" != "yes" ]]; then
  fail \
    "CANONICAL_COMMAND/MISSING_ALSO_MAKE" \
    "Maven command targets sfa-sales-management-interfaces without -am / --also-make" \
    "Add -am so Maven also builds required reactor modules; otherwise missing application/domain classes are command noise." \
    "mvn -pl sfa-sales-management-interfaces -am -DskipTests compile"
fi

printf 'PASS: canonical command gate accepted command: %s\n' "$*"
