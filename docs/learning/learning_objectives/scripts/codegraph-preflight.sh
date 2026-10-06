#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/codegraph-preflight.sh [--sync] [--required] [--all] <repo-id-or-path>...

Checks CodeGraph readiness for the exact business repo paths that will be used
as MCP projectPath values. By default this is non-blocking: missing CLI,
missing .codegraph, or sync failures print WARN and exit 0 because CodeGraph is
an optional sensor. Use --sync only when the watcher is unavailable, stale,
or a script needs a pre-flight refresh. Use --required only for local setup validation.

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
: "${SFA_REPO_BACKEND_CEO_MEMBER:=$SFA_PROJECTS_ROOT/backend-ceo-member}"
: "${SFA_REPO_FRONTEND_MERCHANT_WECHATAPP:=$SFA_PROJECTS_ROOT/merchant-wechatapp}"
: "${SFA_REPO_BACKEND_SFA_ROOT:=$SFA_PROJECTS_ROOT/sfa-root}"
: "${SFA_REPO_FRONTEND_SFAINTL:=$SFA_PROJECTS_ROOT/SfaIntl}"
: "${SFA_REPO_MOBILE_SFA_IOS:=$SFA_PROJECTS_ROOT/sfa-ios}"
: "${SFA_REPO_MOBILE_SFA_ANDROID:=$SFA_PROJECTS_ROOT/sfa-android}"

sync_first=0
required=0
repos=()
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

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --all)
      repos+=("${all_repo_ids[@]}")
      shift
      ;;
    --sync)
      sync_first=1
      shift
      ;;
    --required)
      required=1
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

warn_count=0
warn() {
  warn_count=$((warn_count + 1))
  printf 'WARN: %s\n' "$1"
}

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

if ! command -v codegraph >/dev/null 2>&1; then
  warn "CODEGRAPH_STATUS=UNAVAILABLE codegraph CLI not found; record downgrade and use rg/direct reads/tests."
  [[ "$required" -eq 0 ]] && exit 0
  exit 1
fi

printf 'INFO: codegraph CLI %s\n' "$(codegraph --version 2>/dev/null || printf 'unknown')"

for repo_arg in "${repos[@]}"; do
  repo="$(resolve_repo "$repo_arg")"
  printf 'INFO: repo_arg=%s\n' "$repo_arg"

  if [[ -z "$repo" ]]; then
    warn "CODEGRAPH_STATUS=UNCONFIGURED repo id $repo_arg has no path in config/repos.local.sh"
    continue
  fi

  if [[ "$repo" != /* ]]; then
    repo="$(cd "$repo" 2>/dev/null && pwd || true)"
  fi

  printf 'CODEGRAPH_PROJECT_PATH=%s\n' "$repo"

  if [[ ! -d "$repo" ]]; then
    warn "CODEGRAPH_STATUS=REPO_MISSING projectPath does not exist: $repo"
    continue
  fi

  if [[ ! -d "$repo/.git" ]]; then
    warn "CODEGRAPH_STATUS=NOT_GIT_REPO projectPath is not a git repo: $repo"
    continue
  fi

  if [[ ! -d "$repo/.codegraph" ]]; then
    warn "CODEGRAPH_STATUS=UNINITIALIZED missing $repo/.codegraph; run: codegraph init -i \"$repo\""
    continue
  fi

  if [[ "$sync_first" -eq 1 ]]; then
    if codegraph sync "$repo" >/tmp/sfa-codegraph-sync.out 2>&1; then
      printf 'PASS: CODEGRAPH_SYNC_OK projectPath=%s\n' "$repo"
    else
      warn "CODEGRAPH_STATUS=SYNC_FAILED projectPath=$repo; record downgrade and use rg/direct reads/tests."
      sed -n '1,20p' /tmp/sfa-codegraph-sync.out
      continue
    fi
  fi

  if codegraph status "$repo" >/tmp/sfa-codegraph-status.out 2>&1; then
    printf 'PASS: CODEGRAPH_STATUS_OK projectPath=%s\n' "$repo"
  else
    warn "CODEGRAPH_STATUS=STATUS_FAILED projectPath=$repo; record downgrade and use rg/direct reads/tests."
    sed -n '1,20p' /tmp/sfa-codegraph-status.out
  fi
done

rm -f /tmp/sfa-codegraph-sync.out /tmp/sfa-codegraph-status.out

if [[ "$warn_count" -gt 0 ]]; then
  printf 'WARN: CodeGraph preflight completed with %s warning(s); CodeGraph is optional, so use documented downgrade evidence unless --required is set.\n' "$warn_count"
  [[ "$required" -eq 0 ]] && exit 0
  exit 1
fi

printf 'PASS: CodeGraph preflight passed\n'
