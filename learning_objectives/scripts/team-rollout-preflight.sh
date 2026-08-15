#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/team-rollout-preflight.sh [--local] [--no-readiness]

Checks the harness before team rollout.

Default mode validates the shared control plane:
  - shell / node syntax
  - JSON config parse
  - self-audit, which includes readiness

--local additionally validates the current user's local toolchain and business repo paths:
  - config/repos.local.sh
  - scripts/dev-env-check.sh

--no-readiness skips readiness/self-audit recursion. It is intended for
scripts/harness-team-readiness-test.sh only.
USAGE
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

local_mode=0
skip_readiness=0

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --local)
      local_mode=1
      shift
      ;;
    --no-readiness)
      skip_readiness=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'FAIL: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

expect_runner_deny() {
  local label="$1" event="$2" expected_code="$3" payload="$4"
  shift 4
  local out err
  out="$hook_tmp/$label.out"
  err="$hook_tmp/$label.err"
  if printf '%s\n' "$payload" | env "$@" scripts/harness-sensor-runner.sh plain "$event" >"$out" 2>"$err"; then
    fail "hook self-check did not deny $label"
  fi
  if ! grep -q "^CODE: ${expected_code}$" "$err"; then
    sed -n '1,80p' "$out" >&2 || true
    sed -n '1,80p' "$err" >&2 || true
    fail "hook self-check denied $label with unexpected code"
  fi
}

run_hook_self_check() {
  hook_tmp="$(mktemp -d)"
  local business_repo change_dir
  business_repo="$hook_tmp/business-repo"
  change_dir="$hook_tmp/change"
  mkdir -p "$business_repo/src" "$change_dir"
  git -C "$business_repo" init -q -b codex/preflight-hook-self-check
  touch "$business_repo/src/Example.java"
  cat >"$change_dir/technical-solution.md" <<'SPEC'
# Preflight Hook Self Check

confirmation_status: CONFIRMED
allowed_next_stage: prototype
SPEC

  expect_runner_deny \
    "dangerous-command" \
    "beforeShellExecution" \
    "HARNESS/DANGEROUS_COMMAND" \
    '{"command":"git push -f"}'

  expect_runner_deny \
    "business-post-edit" \
    "PostToolUse" \
    "HARNESS/CODE_START_BLOCKED" \
    "{\"file_path\":\"$business_repo/src/Example.java\",\"cwd\":\"$business_repo\"}" \
    "SFA_REPO_PREFLIGHT=$business_repo" \
    "SFA_ACTIVE_CHANGE_DIR=$change_dir"

  expect_runner_deny \
    "business-git-add" \
    "beforeShellExecution" \
    "HARNESS/CODE_START_BLOCKED" \
    "{\"command\":\"git add src/Example.java\",\"cwd\":\"$business_repo\"}" \
    "SFA_REPO_PREFLIGHT=$business_repo" \
    "SFA_ACTIVE_CHANGE_DIR=$change_dir"

  rm -rf "$hook_tmp"
  printf 'PASS: hook end-to-end self-check passed\n'
}

printf 'INFO: team rollout preflight: control-plane checks\n'

bash -n scripts/*.sh scripts/ecc/*.sh scripts/lib/*.sh hooks/*.sh
node --check scripts/harness-local-proxy.mjs >/dev/null
node --check scripts/generate-local-routing.mjs >/dev/null
node -e "for (const f of ['opencode.json','.cursor/hooks.json','.codex/hooks.json']) JSON.parse(require('fs').readFileSync(f,'utf8'))"
run_hook_self_check

if [[ "$skip_readiness" -eq 1 ]]; then
  printf 'INFO: skipped readiness/self-audit recursion\n'
else
  scripts/harness-self-audit.sh
fi

if [[ "$local_mode" -eq 1 ]]; then
  printf 'INFO: team rollout preflight: local user environment checks\n'
  scripts/dev-env-check.sh
else
  printf 'INFO: skipped local user environment checks; rerun with --local after config/repos.local.sh is ready\n'
fi

printf 'PASS: team rollout preflight passed\n'
