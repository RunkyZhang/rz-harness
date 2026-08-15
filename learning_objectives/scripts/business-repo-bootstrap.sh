#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/business-repo-bootstrap.sh <business-repo> <change-id>
  scripts/business-repo-bootstrap.sh --check <business-repo>
  scripts/business-repo-bootstrap.sh --remove <business-repo>

Installs local-only harness hook files into a business repo. Generated files are
ignored via .git/info/exclude and must not be committed to the business repo.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
harness_root="$(cd "$script_dir/.." && pwd -P)"
template="$harness_root/templates/business-repo-agents-stub.md"
runner="$harness_root/scripts/harness-sensor-runner.sh"
repo_registry="$harness_root/docs/architecture/repo-registry.md"

mode="install"
case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  --check)
    mode="check"
    shift
    ;;
  --remove)
    mode="remove"
    shift
    ;;
esac

if [[ "$mode" == "install" ]]; then
  [[ "$#" -eq 2 ]] || { usage; exit 2; }
else
  [[ "$#" -eq 1 ]] || { usage; exit 2; }
fi

repo_arg="$1"
change_id="${2:-}"

[[ -d "$repo_arg" ]] || fail "business repo not found: $repo_arg"
[[ -x "$runner" ]] || fail "harness sensor runner is not executable: $runner"
if [[ "$mode" == "install" ]]; then
  [[ "$change_id" =~ ^[A-Za-z0-9._-]+$ ]] || fail "change-id contains unsupported characters: $change_id"
fi

repo_root="$(git -C "$repo_arg" rev-parse --show-toplevel 2>/dev/null)" \
  || fail "not inside a git repository: $repo_arg"
repo_root="$(cd "$repo_root" && pwd -P)"

agents_path="$repo_root/AGENTS.md"
cursor_hooks="$repo_root/.cursor/hooks.json"
codex_hooks="$repo_root/.codex/hooks.json"
harness_dir="$repo_root/.harness"
active_change="$harness_dir/active-change"
bootstrap_status="$harness_dir/bootstrap-status.env"
local_exclude="$repo_root/.git/info/exclude"
marker="sfa-ai-harness business repo bootstrap"
repo_id="unknown"
repo_type="unknown"
rule_entrypoint="rules/unknown.mdc"
baseline_doc="N/A"
agent_candidates="sfa-harness-explorer,sfa-harness-reviewer,sfa-test-agent"

is_tracked() {
  git -C "$repo_root" ls-files --error-unmatch "$1" >/dev/null 2>&1
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

shell_quote() {
  printf '%q' "$1"
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[&|]/\\&/g'
}

repo_type_for_id() {
  case "$1" in
    backend-*) printf 'backend' ;;
    frontend-*) printf 'frontend' ;;
    mobile-*) printf 'mobile' ;;
    *) printf 'unknown' ;;
  esac
}

repo_id_from_basename() {
  case "$1" in
    sfa-sales-management) printf 'backend-sales-management' ;;
    sfa-backend) printf 'backend-sfa-backend' ;;
    sfa-root) printf 'backend-sfa-root' ;;
    backend-ceo-member) printf 'backend-ceo-member' ;;
    mapSystem) printf 'frontend-map-system' ;;
    sign-up) printf 'frontend-sign-up' ;;
    merchant-wechatapp) printf 'frontend-merchant-wechatapp' ;;
    SfaIntl) printf 'frontend-sfaintl' ;;
    sfa-ios) printf 'mobile-sfa-ios' ;;
    sfa-android) printf 'mobile-sfa-android' ;;
    *) printf 'unknown' ;;
  esac
}

rule_for_repo() {
  local id="$1" type="$2"
  case "$id" in
    frontend-merchant-wechatapp) printf 'rules/frontend-wechat-miniprogram.mdc' ;;
    mobile-sfa-android) printf 'rules/mobile-android-java.mdc' ;;
    mobile-sfa-ios) printf 'rules/mobile-ios-objc.mdc' ;;
    frontend-*) printf 'rules/frontend-vue2.mdc' ;;
    backend-*) printf 'rules/backend-java.mdc' ;;
    *)
      case "$type" in
        frontend) printf 'rules/frontend-vue2.mdc' ;;
        backend) printf 'rules/backend-java.mdc' ;;
        mobile) printf 'rules/mobile.mdc' ;;
        *) printf 'rules/unknown.mdc' ;;
      esac
      ;;
  esac
}

agent_candidates_for_type() {
  case "$1" in
    backend) printf 'sfa-backend-agent(candidate),sfa-harness-reviewer,sfa-test-agent' ;;
    frontend) printf 'sfa-frontend-agent(candidate),sfa-harness-reviewer,sfa-test-agent' ;;
    mobile) printf 'sfa-mobile-agent(candidate),sfa-harness-reviewer,sfa-test-agent' ;;
    *) printf 'sfa-harness-explorer,sfa-harness-reviewer,sfa-test-agent' ;;
  esac
}

load_local_repo_config() {
  local local_config="$harness_root/config/repos.local.sh"
  if [[ -f "$local_config" ]]; then
    # shellcheck disable=SC1090
    source "$local_config"
  fi
}

detect_repo_metadata() {
  load_local_repo_config
  local row id_cell env_cell type_cell id env_name env_value env_root basename_id
  if [[ -f "$repo_registry" ]]; then
    while IFS='|' read -r _ id_cell env_cell type_cell _; do
      id="$(trim "${id_cell//\`/}")"
      env_name="$(trim "${env_cell//\`/}")"
      env_name="${env_name#\$}"
      [[ "$id" == *"-"* && "$env_name" == SFA_REPO_* ]] || continue
      env_value="${!env_name:-}"
      [[ -n "$env_value" && -d "$env_value" ]] || continue
      env_root="$(cd "$env_value" && pwd -P)"
      if [[ "$env_root" == "$repo_root" ]]; then
        repo_id="$id"
        repo_type="$(repo_type_for_id "$repo_id")"
        break
      fi
    done <"$repo_registry"
  fi

  if [[ "$repo_id" == "unknown" ]]; then
    basename_id="$(repo_id_from_basename "$(basename "$repo_root")")"
    if [[ "$basename_id" != "unknown" ]]; then
      repo_id="$basename_id"
      repo_type="$(repo_type_for_id "$repo_id")"
    fi
  fi

  rule_entrypoint="$(rule_for_repo "$repo_id" "$repo_type")"
  agent_candidates="$(agent_candidates_for_type "$repo_type")"
  if [[ -f "$harness_root/docs/baseline/$repo_id.md" ]]; then
    baseline_doc="\$SFA_HARNESS_ROOT/docs/baseline/$repo_id.md"
  else
    baseline_doc="N/A"
  fi
}

write_bootstrap_status() {
  mkdir -p "$harness_dir"
  cat >"$bootstrap_status" <<EOF
BOOTSTRAP_STATUS=PASS
CHANGE_ID=$change_id
REPO_ROOT=$repo_root
REPO_ID=$repo_id
REPO_TYPE=$repo_type
RULE_ENTRYPOINT=$rule_entrypoint
BASELINE_DOC=$baseline_doc
AGENT_CANDIDATES=$agent_candidates
HARNESS_ROOT=$harness_root
EOF
}

emit_bootstrap_status() {
  if [[ -f "$bootstrap_status" ]]; then
    cat "$bootstrap_status"
  else
    printf 'BOOTSTRAP_STATUS=PASS\n'
    printf 'REPO_ROOT=%s\n' "$repo_root"
    printf 'REPO_ID=%s\n' "$repo_id"
    printf 'REPO_TYPE=%s\n' "$repo_type"
    printf 'RULE_ENTRYPOINT=%s\n' "$rule_entrypoint"
    printf 'BASELINE_DOC=%s\n' "$baseline_doc"
    printf 'AGENT_CANDIDATES=%s\n' "$agent_candidates"
  fi
}

ensure_exclude() {
  mkdir -p "$(dirname "$local_exclude")"
  touch "$local_exclude"
  local begin="# BEGIN sfa-ai-harness business repo bootstrap"
  local end="# END sfa-ai-harness business repo bootstrap"
  local tmp
  tmp="$(mktemp)"
  awk -v begin="$begin" -v end="$end" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    skip != 1 { print }
  ' "$local_exclude" >"$tmp"
  cat >>"$tmp" <<'EOF'
# BEGIN sfa-ai-harness business repo bootstrap
AGENTS.md
.cursor/hooks.json
.codex/hooks.json
.harness/.gitignore
.harness/active-change
.harness/bootstrap-status.env
.harness/agent-work/
# END sfa-ai-harness business repo bootstrap
EOF
  mv "$tmp" "$local_exclude"
}

write_agents_stub() {
  if is_tracked "AGENTS.md"; then
    return 0
  fi
  if [[ -f "$agents_path" ]] && ! grep -q "$marker" "$agents_path"; then
    fail "untracked AGENTS.md already exists and is not generated by harness: $agents_path"
  fi
  [[ -f "$template" ]] || fail "missing business repo AGENTS template: $template"
  local escaped_change escaped_repo_id escaped_repo_type escaped_rule escaped_baseline escaped_agents
  escaped_change="$(escape_sed_replacement "$change_id")"
  escaped_repo_id="$(escape_sed_replacement "$repo_id")"
  escaped_repo_type="$(escape_sed_replacement "$repo_type")"
  escaped_rule="$(escape_sed_replacement "$rule_entrypoint")"
  escaped_baseline="$(escape_sed_replacement "$baseline_doc")"
  escaped_agents="$(escape_sed_replacement "$agent_candidates")"
  {
    printf '<!-- %s -->\n\n' "$marker"
    printf '> Local bootstrap root: `%s`\n\n' "$harness_root"
    sed \
      -e "s|<change-id>|$escaped_change|g" \
      -e "s|<repo-id>|$escaped_repo_id|g" \
      -e "s|<repo-type>|$escaped_repo_type|g" \
      -e "s|<rule-entrypoint>|$escaped_rule|g" \
      -e "s|<baseline-doc>|$escaped_baseline|g" \
      -e "s|<agent-candidates>|$escaped_agents|g" \
      "$template"
  } >"$agents_path"
}

write_cursor_hooks() {
  mkdir -p "$(dirname "$cursor_hooks")"
  local quoted_root quoted_runner before after
  quoted_root="$(shell_quote "$harness_root")"
  quoted_runner="$(shell_quote "$runner")"
  before="SFA_HARNESS_ROOT=$quoted_root bash $quoted_runner cursor beforeShellExecution"
  after="SFA_HARNESS_ROOT=$quoted_root bash $quoted_runner cursor afterFileEdit"
  cat >"$cursor_hooks" <<EOF
{
  "version": 1,
  "hooks": {
    "beforeShellExecution": [
      {
        "command": "$(json_escape "$before")"
      }
    ],
    "afterFileEdit": [
      {
        "command": "$(json_escape "$after")"
      }
    ]
  }
}
EOF
}

write_codex_hooks() {
  mkdir -p "$(dirname "$codex_hooks")"
  local quoted_root quoted_runner pre post
  quoted_root="$(shell_quote "$harness_root")"
  quoted_runner="$(shell_quote "$runner")"
  pre="SFA_HARNESS_ROOT=$quoted_root bash $quoted_runner codex PreToolUse"
  post="SFA_HARNESS_ROOT=$quoted_root bash $quoted_runner codex PostToolUse"
  cat >"$codex_hooks" <<EOF
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$(json_escape "$pre")",
            "statusMessage": "Checking harness shell policy"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "apply_patch|Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$(json_escape "$post")",
            "statusMessage": "Checking harness changed-file policy"
          }
        ]
      }
    ]
  }
}
EOF
}

write_active_change() {
  mkdir -p "$harness_dir"
  cat >"$harness_dir/.gitignore" <<'EOF'
active-change
bootstrap-status.env
agent-work/
EOF
  printf '%s\n' "$change_id" >"$active_change"
  write_bootstrap_status
}

ignored_or_tracked() {
  local path="$1"
  if is_tracked "$path"; then
    return 0
  fi
  git -C "$repo_root" check-ignore -q "$path"
}

check_install() {
  [[ -f "$cursor_hooks" ]] || fail "missing Cursor hooks: $cursor_hooks"
  [[ -f "$codex_hooks" ]] || fail "missing Codex hooks: $codex_hooks"
  [[ -s "$active_change" ]] || fail "missing active change: $active_change"
  [[ -f "$bootstrap_status" ]] || fail "missing bootstrap status: $bootstrap_status"
  grep -q 'harness-sensor-runner.sh' "$cursor_hooks" || fail "Cursor hooks do not call harness sensor runner"
  grep -q 'harness-sensor-runner.sh' "$codex_hooks" || fail "Codex hooks do not call harness sensor runner"
  if [[ -f "$agents_path" ]] && ! is_tracked "AGENTS.md"; then
    grep -q "$marker" "$agents_path" || fail "generated AGENTS.md is missing harness marker"
  fi
  ignored_or_tracked "AGENTS.md" || fail "AGENTS.md is not locally ignored"
  ignored_or_tracked ".cursor/hooks.json" || fail ".cursor/hooks.json is not locally ignored"
  ignored_or_tracked ".codex/hooks.json" || fail ".codex/hooks.json is not locally ignored"
  ignored_or_tracked ".harness/active-change" || fail ".harness/active-change is not locally ignored"
  ignored_or_tracked ".harness/bootstrap-status.env" || fail ".harness/bootstrap-status.env is not locally ignored"
  emit_bootstrap_status
}

remove_install() {
  rm -f "$cursor_hooks" "$codex_hooks" "$active_change" "$bootstrap_status"
  if [[ -f "$agents_path" ]] && ! is_tracked "AGENTS.md" && grep -q "$marker" "$agents_path"; then
    rm -f "$agents_path"
  fi
}

detect_repo_metadata

case "$mode" in
  install)
    ensure_exclude
    write_agents_stub
    write_cursor_hooks
    write_codex_hooks
    write_active_change
    check_install
    pass "business repo bootstrap installed for $repo_root"
    ;;
  check)
    check_install
    pass "business repo bootstrap check passed for $repo_root"
    ;;
  remove)
    remove_install
    pass "business repo bootstrap remove passed for $repo_root"
    ;;
esac
