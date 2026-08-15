#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/codegraph-bootstrap.sh [--all] [--dry-run] <repo-id-or-path>...

Initializes CodeGraph for configured business repos on the current machine.
This script is intentionally explicit: preflight checks never call it
automatically. It may write only local business-repo state:
  - <business-repo>/.codegraph/
  - <business-repo>/.git/info/exclude

Options:
  --all      bootstrap every known repo id from the harness registry
  --dry-run  report what would change without writing files or running init

Known repo ids:
  backend-sales-management | sfa-sales-management
  backend-sfa-backend      | sfa-backend
  backend-sfa-root         | sfa-root
  backend-ceo-member       | ceo-member
  frontend-map-system      | mapSystem
  frontend-sign-up         | sign-up
  frontend-merchant-wechatapp | merchant-wechatapp
  frontend-sfaintl         | SfaIntl
  mobile-sfa-ios           | sfa-ios
  mobile-sfa-android       | sfa-android
USAGE
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
local_config="$root/config/repos.local.sh"
if [[ -f "$local_config" ]]; then
  # shellcheck disable=SC1090
  source "$local_config"
fi

: "${SFA_PROJECTS_ROOT:=$HOME/codex/sfa-projects}"
: "${SFA_REPO_BACKEND_SALES_MANAGEMENT:=$SFA_PROJECTS_ROOT/sfa-sales-management}"
: "${SFA_REPO_BACKEND_SFA_BACKEND:=$SFA_PROJECTS_ROOT/sfa-backend}"
: "${SFA_REPO_BACKEND_SFA_ROOT:=$SFA_PROJECTS_ROOT/sfa-root}"
: "${SFA_REPO_BACKEND_CEO_MEMBER:=$SFA_PROJECTS_ROOT/backend-ceo-member}"
: "${SFA_REPO_FRONTEND_MAP_SYSTEM:=$SFA_PROJECTS_ROOT/mapSystem}"
: "${SFA_REPO_FRONTEND_SIGN_UP:=$SFA_PROJECTS_ROOT/sign-up}"
: "${SFA_REPO_FRONTEND_MERCHANT_WECHATAPP:=$SFA_PROJECTS_ROOT/merchant-wechatapp}"
: "${SFA_REPO_FRONTEND_SFAINTL:=$SFA_PROJECTS_ROOT/SfaIntl}"
: "${SFA_REPO_MOBILE_SFA_IOS:=$SFA_PROJECTS_ROOT/sfa-ios}"
: "${SFA_REPO_MOBILE_SFA_ANDROID:=$SFA_PROJECTS_ROOT/sfa-android}"

all_repo_ids=(
  backend-sales-management
  backend-sfa-backend
  backend-sfa-root
  backend-ceo-member
  frontend-map-system
  frontend-sign-up
  frontend-merchant-wechatapp
  frontend-sfaintl
  mobile-sfa-ios
  mobile-sfa-android
)

dry_run=0
repos=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --all)
      repos+=("${all_repo_ids[@]}")
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [[ "$#" -gt 0 ]]; do repos+=("$1"); shift; done
      ;;
    -*)
      echo "FAIL: unknown option $1" >&2
      usage
      exit 2
      ;;
    *)
      repos+=("$1")
      shift
      ;;
  esac
done

if [[ "${#repos[@]}" -eq 0 ]]; then
  usage
  exit 2
fi

resolve_repo() {
  case "$1" in
    backend-sales-management|sfa-sales-management)
      printf '%s' "${SFA_REPO_BACKEND_SALES_MANAGEMENT:-}"
      ;;
    backend-sfa-backend|sfa-backend)
      printf '%s' "${SFA_REPO_BACKEND_SFA_BACKEND:-}"
      ;;
    backend-sfa-root|sfa-root)
      printf '%s' "${SFA_REPO_BACKEND_SFA_ROOT:-}"
      ;;
    backend-ceo-member|ceo-member)
      printf '%s' "${SFA_REPO_BACKEND_CEO_MEMBER:-}"
      ;;
    frontend-map-system|mapSystem)
      printf '%s' "${SFA_REPO_FRONTEND_MAP_SYSTEM:-}"
      ;;
    frontend-sign-up|sign-up)
      printf '%s' "${SFA_REPO_FRONTEND_SIGN_UP:-}"
      ;;
    frontend-merchant-wechatapp|merchant-wechatapp|wechatapp)
      printf '%s' "${SFA_REPO_FRONTEND_MERCHANT_WECHATAPP:-}"
      ;;
    frontend-sfaintl|SfaIntl|sfaintl)
      printf '%s' "${SFA_REPO_FRONTEND_SFAINTL:-}"
      ;;
    mobile-sfa-ios|sfa-ios|ios)
      printf '%s' "${SFA_REPO_MOBILE_SFA_IOS:-}"
      ;;
    mobile-sfa-android|sfa-android|android)
      printf '%s' "${SFA_REPO_MOBILE_SFA_ANDROID:-}"
      ;;
    *)
      printf '%s' "$1"
      ;;
  esac
}

fail_count=0
record_fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL: %s\n' "$1" >&2
}

canonicalize_repo() {
  local repo="$1"
  if [[ "$repo" == /* ]]; then
    printf '%s' "$repo"
    return
  fi
  cd "$repo" 2>/dev/null && pwd -P
}

ensure_local_exclude() {
  local repo="$1"
  local git_dir
  git_dir="$(git -C "$repo" rev-parse --git-dir)"
  if [[ "$git_dir" != /* ]]; then
    git_dir="$repo/$git_dir"
  fi
  mkdir -p "$git_dir/info"
  local exclude_file="$git_dir/info/exclude"
  touch "$exclude_file"
  if grep -qxF '.codegraph/' "$exclude_file"; then
    printf 'PASS: CODEGRAPH_EXCLUDE_OK projectPath=%s\n' "$repo"
    return
  fi
  printf '\n.codegraph/\n' >> "$exclude_file"
  printf 'PASS: CODEGRAPH_EXCLUDE_ADDED projectPath=%s\n' "$repo"
}

if ! command -v codegraph >/dev/null 2>&1; then
  record_fail "CODEGRAPH_BOOTSTRAP/CLI_MISSING codegraph CLI not found; install CodeGraph before bootstrapping."
  exit 1
fi

printf 'INFO: codegraph CLI %s\n' "$(codegraph --version 2>/dev/null || printf 'unknown')"

for repo_arg in "${repos[@]}"; do
  repo="$(resolve_repo "$repo_arg")"
  printf 'INFO: repo_arg=%s\n' "$repo_arg"

  if [[ -z "$repo" ]]; then
    record_fail "CODEGRAPH_BOOTSTRAP/UNCONFIGURED repo id $repo_arg has no path in config/repos.local.sh"
    continue
  fi

  if ! repo="$(canonicalize_repo "$repo")"; then
    record_fail "CODEGRAPH_BOOTSTRAP/REPO_MISSING projectPath does not exist for $repo_arg"
    continue
  fi

  printf 'CODEGRAPH_PROJECT_PATH=%s\n' "$repo"

  if [[ ! -d "$repo/.git" ]]; then
    record_fail "CODEGRAPH_BOOTSTRAP/NOT_GIT_REPO projectPath is not a git repo: $repo"
    continue
  fi

  if [[ -d "$repo/.codegraph" ]]; then
    printf 'PASS: CODEGRAPH_BOOTSTRAP_ALREADY_INITIALIZED projectPath=%s\n' "$repo"
    if [[ "$dry_run" -eq 0 ]]; then
      codegraph status "$repo"
    fi
    continue
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    printf 'DRY_RUN: would initialize CodeGraph for projectPath=%s\n' "$repo"
    printf 'DRY_RUN: would ensure .codegraph/ is ignored in local git exclude\n'
    continue
  fi

  ensure_local_exclude "$repo"
  codegraph init -i "$repo"
  codegraph status "$repo"
  printf 'PASS: CODEGRAPH_BOOTSTRAP_INIT_DONE projectPath=%s\n' "$repo"
done

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL: CodeGraph bootstrap completed with %s failure(s)\n' "$fail_count" >&2
  exit 1
fi

printf 'PASS: CodeGraph bootstrap completed\n'
