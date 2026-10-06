#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

run_expect_pass() {
  local name="$1"
  shift
  if "$@" >"$out" 2>"$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,50p' "$out" >&2 || true
    sed -n '1,50p' "$err" >&2 || true
  fi
}

run_expect_fail_with_code() {
  local name="$1"
  local expected_code="$2"
  shift 2
  if "$@" >"$out" 2>"$err"; then
    fail "$name"
    sed -n '1,50p' "$out" >&2 || true
    return
  fi

  if grep -q "^CODE: ${expected_code}$" "$err"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,50p' "$out" >&2 || true
    sed -n '1,50p' "$err" >&2 || true
  fi
}

assert_out_contains() {
  local name="$1" pattern="$2"
  if grep -Eq "$pattern" "$out"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,80p' "$out" >&2 || true
  fi
}

assert_file_contains() {
  local name="$1" file="$2" pattern="$3"
  if grep -Eq "$pattern" "$file"; then
    pass "$name"
  else
    fail "$name"
    sed -n '1,80p' "$file" >&2 || true
  fi
}

assert_file_not_contains() {
  local name="$1" file="$2" pattern="$3"
  if grep -Eq "$pattern" "$file"; then
    fail "$name"
    sed -n '1,80p' "$file" >&2 || true
  else
    pass "$name"
  fi
}

hash_solution_file() {
  grep -Ev '^[[:space:]]*(feishu_solution_doc_url|feishu_solution_sync_status|feishu_solution_synced_at|feishu_solution_source_sha256)[[:space:]]*:' "$1" \
    | openssl dgst -sha256 -r \
    | awk '{print $1}'
}

write_solution() {
  local dir="$1" source_type="$2" source_url="$3" node_token="$4" doc_url="$5" sync_status="$6" sync_hash="$7"
  mkdir -p "$dir"
  cat >"$dir/technical-solution.md" <<MARKDOWN
# Demo 技术方案

\`\`\`yaml
change_id: demo
confirmation_status: CONFIRMED
confirmed_by: product-owner
confirmed_at: 2026-07-02 10:00
confirmed_scope: 技术方案完整确认
allowed_next_stage: code_start
residual_risks_accepted: N/A
prd_source_type: ${source_type}
prd_source_url: ${source_url}
prd_source_node_token: ${node_token}
feishu_solution_doc_url: ${doc_url}
feishu_solution_sync_status: ${sync_status}
feishu_solution_synced_at: 2026-07-02 10:10
feishu_solution_source_sha256: ${sync_hash}
\`\`\`

## PRD 端到端覆盖矩阵

| PRD 项 | 影响端 | 实现仓/模块 | 技术方案章节 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Demo 页面保存 | Backend / PC Web / APP | sample | 全栈实现设计 | shell: demo-test | IN |
| Export | N/A | N/A | N/A | PRD 不涉及导出 | N/A |
| Analytics | N/A | N/A | N/A | PRD 不涉及埋点/分析 | N/A |

## 全栈技术方案

本方案覆盖 Backend、PC Web、APP；H5、小程序、导出、埋点/分析为 N/A。

## 主流程

\`\`\`mermaid
flowchart TD
  A["开始"] --> B["完成"]
\`\`\`

## 前端/客户端页面方案

PC Web 提供保存入口，APP 只读展示。H5、小程序为 N/A，来源为 PRD 不涉及。
MARKDOWN
}

tmpdir="$(mktemp -d)"
out="$tmpdir/out"
err="$tmpdir/err"
trap 'rm -rf "$tmpdir"' EXIT

local_dir="$tmpdir/local-change"
write_solution "$local_dir" "local" "N/A" "N/A" "N/A" "N/A" "-"
run_expect_pass "technical solution gate keeps local PRD behavior unchanged" \
  "$root/scripts/technical-solution-gate.sh" "$local_dir"

missing_doc_dir="$tmpdir/missing-feishu-doc-$$"
write_solution "$missing_doc_dir" "feishu" "https://ycnh94bfa482.feishu.cn/wiki/PRDNodeToken" "PRDNodeToken" "N/A" "PENDING" "-"
run_expect_fail_with_code "technical solution gate blocks confirmed Feishu PRD without solution child doc sync" \
  "TECH_SOLUTION_FEISHU/MISSING_DOC_URL" \
  "$root/scripts/technical-solution-gate.sh" "$missing_doc_dir"

synced_dir="$tmpdir/synced-feishu-doc"
write_solution "$synced_dir" "feishu" "https://ycnh94bfa482.feishu.cn/wiki/PRDNodeToken" "PRDNodeToken" "https://ycnh94bfa482.feishu.cn/wiki/SolutionNodeToken" "SYNCED" "PENDING_HASH"
current_hash="$(hash_solution_file "$synced_dir/technical-solution.md")"
sed "s/feishu_solution_source_sha256: PENDING_HASH/feishu_solution_source_sha256: $current_hash/" \
  "$synced_dir/technical-solution.md" >"$synced_dir/technical-solution.md.tmp"
mv "$synced_dir/technical-solution.md.tmp" "$synced_dir/technical-solution.md"
run_expect_pass "technical solution gate accepts confirmed Feishu PRD with current child doc sync" \
  "$root/scripts/technical-solution-gate.sh" "$synced_dir"

stale_dir="$tmpdir/stale-feishu-doc"
cp -R "$synced_dir" "$stale_dir"
printf '\n## 后续修改\n\n本地技术方案已变更，但尚未重新同步飞书子文档。\n' >>"$stale_dir/technical-solution.md"
run_expect_fail_with_code "technical solution gate blocks stale Feishu child doc sync after local solution change" \
  "TECH_SOLUTION_FEISHU/STALE_SYNC" \
  "$root/scripts/technical-solution-gate.sh" "$stale_dir"

run_expect_pass "Feishu sync helper dry-run produces create and update commands" \
  "$root/scripts/technical-solution-feishu-sync.sh" --dry-run "$missing_doc_dir"
assert_out_contains "dry-run creates child wiki doc when missing" 'lark-cli wiki \+node-create'
assert_out_contains "dry-run updates solution doc as markdown" 'lark-cli docs \+update .*--doc-format markdown'
assert_out_contains "dry-run prints source hash metadata" 'feishu_solution_source_sha256: [0-9a-f]{64}'
payload_file=".harness/tmp/$(basename "$missing_doc_dir")-technical-solution-feishu.md"
assert_file_contains "dry-run payload converts mermaid to Feishu whiteboard" "$payload_file" '<whiteboard type="mermaid">'
assert_file_not_contains "dry-run payload does not leave mermaid fenced block" "$payload_file" '```mermaid'
rm -f "$payload_file"

if grep -q 'scripts/technical-solution-feishu-sync.sh' docs/README.md \
  && grep -q 'scripts/technical-solution-feishu-sync-test.sh' docs/README.md \
  && grep -q 'feishu_solution_source_sha256' templates/technical-solution.md \
  && grep -q 'technical-solution-feishu-sync-gate.sh' scripts/technical-solution-gate.sh; then
  pass "docs, template, and technical solution gate reference Feishu solution sync"
else
  fail "docs, template, and technical solution gate reference Feishu solution sync"
fi

if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: technical solution Feishu sync test failed with %s failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'PASS: technical solution Feishu sync test passed\n'
