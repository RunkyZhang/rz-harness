#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
runner="$root/scripts/harness-sensor-runner.sh"
tmp_dir="$(mktemp -d)"
failures=0
trap 'rm -rf "$tmp_dir"' EXIT

json_string() {
  node - "$1" <<'NODE'
process.stdout.write(JSON.stringify(process.argv[2]));
NODE
}

payload_for_command() {
  local command="$1"
  printf '{"command":%s}\n' "$(json_string "$command")"
}

payload_for_command_with_cwd() {
  local command="$1"
  local cwd="$2"
  printf '{"command":%s,"cwd":%s}\n' "$(json_string "$command")" "$(json_string "$cwd")"
}

payload_for_file() {
  local file="$1"
  printf '{"file_path":%s}\n' "$(json_string "$file")"
}

run_command_check() {
  local command="$1"
  payload_for_command "$command" | "$runner" plain beforeShellExecution >"$tmp_dir/out" 2>"$tmp_dir/err"
}

run_command_check_with_cwd() {
  local command="$1"
  local cwd="$2"
  payload_for_command_with_cwd "$command" "$cwd" | "$runner" plain beforeShellExecution >"$tmp_dir/out" 2>"$tmp_dir/err"
}

run_edit_check() {
  local file="$1"
  payload_for_file "$file" | "$runner" plain afterFileEdit >"$tmp_dir/out" 2>"$tmp_dir/err"
}

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

expect_deny() {
  local command="$1" label="$2"
  if run_command_check "$command"; then
    fail "$label denied"
    return
  fi
  if grep -q 'CODE: HARNESS/DANGEROUS_COMMAND' "$tmp_dir/err"; then
    pass "$label denied"
  else
    fail "$label returned expected dangerous-command code"
  fi
}

expect_allow() {
  local command="$1" label="$2"
  if run_command_check "$command"; then
    if grep -q 'HARNESS: shell command allowed' "$tmp_dir/out"; then
      pass "$label allowed"
    else
      fail "$label returned allow message"
    fi
  else
    fail "$label allowed"
  fi
}

expect_deny_with_cwd() {
  local command="$1" cwd="$2" label="$3" code="${4:-HARNESS/DANGEROUS_COMMAND}"
  if run_command_check_with_cwd "$command" "$cwd"; then
    fail "$label denied"
    return
  fi
  if grep -q "CODE: $code" "$tmp_dir/err"; then
    pass "$label denied"
  else
    fail "$label returned expected code $code"
  fi
}

expect_allow_with_cwd() {
  local command="$1" cwd="$2" label="$3"
  if run_command_check_with_cwd "$command" "$cwd"; then
    if grep -q 'HARNESS: shell command allowed' "$tmp_dir/out"; then
      pass "$label allowed"
    else
      fail "$label returned allow message"
    fi
  else
    fail "$label allowed"
  fi
}

expect_edit_deny() {
  local file="$1" label="$2" code="${3:-HARNESS/CODE_START_BLOCKED}"
  if run_edit_check "$file"; then
    fail "$label denied"
    return
  fi
  if grep -q "CODE: $code" "$tmp_dir/err"; then
    pass "$label denied"
  else
    fail "$label returned expected code $code"
  fi
}

expect_edit_allow() {
  local file="$1" label="$2"
  if run_edit_check "$file"; then
    if grep -q 'HARNESS:' "$tmp_dir/out"; then
      pass "$label allowed"
    else
      fail "$label returned allow message"
    fi
  else
    fail "$label allowed"
  fi
}

expect_deny 'git push -f origin HEAD' 'git push short force'
expect_deny 'git push --force-with-lease origin feature/x' 'git push force-with-lease'
expect_deny 'rm -Rf docs' 'rm recursive force uppercase'
expect_deny 'rm -r -f scripts' 'rm recursive force split flags'
expect_deny 'find . -delete' 'find dot delete'
expect_deny 'xargs rm -f < files.txt' 'xargs rm'
expect_deny 'shred docs/secret.txt' 'shred protected path'
expect_deny 'printf hi > docs/generated.txt' 'truncate protected path'
expect_deny 'git branch -D old && git push origin :old' 'delete branch and remote ref'

expect_allow 'git push origin HEAD' 'normal git push'
expect_allow 'rm -rf node_modules' 'remove node_modules'
expect_allow 'rm -rf /tmp/sfa-harness-test' 'remove tmp path'
expect_allow 'printf hi > /tmp/sfa-harness-test.txt' 'write tmp path'
expect_allow 'printf hi > "$tmp_dir/sfa-harness-test.txt"' 'write tmp variable path'
expect_allow 'ls .harness/generated 2>/dev/null || true' 'stderr redirection to dev null'
expect_allow 'lark-cli docs +update --as user --doc "https://example.feishu.cn/wiki/example" --command append --content '"'"'<p>harness note</p><table><tbody><tr><td>DONE</td></tr></tbody></table>'"'"'' 'lark docs update xml content'
expect_allow "$(cat <<'EOF'
lark-cli docs +update --as user --doc "https://example.feishu.cn/wiki/example" --command append --doc-format xml --content - <<'DOC_EOF'
<title>普通飞书文档</title>
<h1>普通飞书文档</h1>
<p>正文里有 XML/HTML 标签，不应被当成 shell 重定向。</p>
DOC_EOF
EOF
)" 'lark docs update heredoc xml content'
expect_deny "$(cat <<'EOF'
lark-cli docs +update --as user --doc "https://example.feishu.cn/wiki/example" --command append --content - <<'DOC_EOF'
<p>正文</p>
DOC_EOF
rm -rf docs
EOF
)" 'lark docs heredoc followed by dangerous command'
expect_allow 'npm run build:test' 'normal build command'

business_repo="$tmp_dir/business-map-system"
mkdir -p "$business_repo/src"
pending_change="$tmp_dir/change-pending"
ready_change="$tmp_dir/change-ready"
mkdir -p "$pending_change" "$ready_change"
cat >"$pending_change/technical-solution.md" <<'EOF_PENDING'
confirmation_status: PENDING
allowed_next_stage: none
EOF_PENDING
cat >"$ready_change/technical-solution.md" <<'EOF_READY'
confirmation_status: CONFIRMED
allowed_next_stage: code_start
EOF_READY

export SFA_REPO_FRONTEND_MAP_SYSTEM="$business_repo"

unset SFA_ACTIVE_CHANGE_DIR
expect_edit_deny "$business_repo/src/App.vue" 'business edit without active change' 'HARNESS/CODE_START_BLOCKED'
expect_deny_with_cwd 'git add src/App.vue' "$business_repo" 'business git add without active change' 'HARNESS/CODE_START_BLOCKED'
expect_allow_with_cwd 'git add docs/example.md' "$tmp_dir" 'non-business git add'

export SFA_ACTIVE_CHANGE_DIR="$pending_change"
expect_edit_deny "$business_repo/src/App.vue" 'business edit before code_start' 'HARNESS/CODE_START_BLOCKED'
expect_deny_with_cwd 'git commit -m test' "$business_repo" 'business git commit before code_start' 'HARNESS/CODE_START_BLOCKED'

export SFA_ACTIVE_CHANGE_DIR="$ready_change"
expect_edit_allow "$business_repo/src/App.vue" 'business edit after code_start'
expect_allow_with_cwd 'git commit -m test' "$business_repo" 'business git commit after code_start'
expect_allow 'lark-cli docs +update --as user --doc "https://example.feishu.cn/wiki/example" --command append --content '"'"'<p>普通业务过程记录</p>'"'"'' 'business change normal lark doc update'
expect_deny_with_cwd \
  'lark-cli wiki +node-create --as user --parent-node-token PRDNode --title "Demo 技术方案" --obj-type docx' \
  "$ready_change" \
  'business change direct Feishu technical solution child creation' \
  'HARNESS/TECH_SOLUTION_FEISHU_SYNC_REQUIRED'
expect_deny_with_cwd \
  'lark-cli docs +update --as user --doc "https://example.feishu.cn/wiki/solution" --command overwrite --doc-format markdown --content @.harness/tmp/demo-technical-solution-feishu.md' \
  "$ready_change" \
  'business change direct Feishu technical solution overwrite' \
  'HARNESS/TECH_SOLUTION_FEISHU_SYNC_REQUIRED'
expect_allow_with_cwd \
  'scripts/technical-solution-feishu-sync.sh --dry-run changes/demo' \
  "$ready_change" \
  'business change technical solution sync helper'

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: harness sensor runner test had %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: harness sensor runner test passed\n'
