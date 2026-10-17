#!/usr/bin/env bash
# harness-doctor.sh — 控制面自检（只读，不修改文件）。
#
# 用途：检查控制面自身是否漂移：字典↔文件、path_env↔变量、baseline 引用、
# hook 接线、plugin 导入、明文配置是否被忽略等。
#
# 它不是 gate，不判定某个 change 是否放行；它是“体检”，漏跑几次不会误放行，
# 跑一次覆盖当前全部问题。建议：pre-merge / CI / 每日 cron / session start --quick。
#
# 用法：
#   scripts/harness-doctor.sh                 # 全量
#   scripts/harness-doctor.sh --quick         # 只查核心/接线/凭据忽略
#   scripts/harness-doctor.sh --strict        # WARN 也返回非 0
#   scripts/harness-doctor.sh --json          # 机器可读摘要
set -u

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root" || exit 1

mode="full"
strict=0
json=0
for arg in "$@"; do
  case "$arg" in
    --quick) mode="quick" ;;
    --strict) strict=1 ;;
    --json) json=1 ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      printf 'FAIL: unknown argument: %s\nCODE: DOCTOR/USAGE\nFIX: use --quick, --strict, --json, or no argument\nSAMPLE: scripts/harness-doctor.sh --quick\n' "$arg" >&2
      exit 2
      ;;
  esac
done

fail_count=0
warn_count=0
pass_count=0
fail_lines=()
warn_lines=()

fail() {
  local message="$1" code="$2" fix="$3" sample="${4:-}"
  printf 'FAIL: %s\nCODE: DOCTOR/%s\nFIX: %s\n' "$message" "$code" "$fix"
  [[ -z "$sample" ]] || printf 'SAMPLE: %s\n' "$sample"
  printf '\n'
  fail_lines+=("$code: $message")
  fail_count=$((fail_count + 1))
}

warn() {
  local message="$1"
  printf 'WARN: %s\n\n' "$message"
  warn_lines+=("$message")
  warn_count=$((warn_count + 1))
}

pass() {
  pass_count=$((pass_count + 1))
}

need_file() {
  local path="$1" code="$2" fix="$3" sample="${4:-}"
  if [[ -e "$path" ]]; then
    pass
  else
    fail "missing: $path" "$code" "$fix" "$sample"
  fi
}

# 字典登记：目录下每个文件（扩展名）必须在字典里出现。
check_dictionary() {
  local dir="$1" dict="$2" suffix="$3" label="$4" skip="${5:-}"
  local f base
  [[ -d "$dir" ]] || { fail "missing dir: $dir" "DOCTOR/${label}_DIR" "create $dir" "$dict"; return; }
  [[ -f "$dict" ]] || { fail "missing dictionary: $dict" "DOCTOR/${label}_DICT" "create $dict" "$dir"; return; }
  for f in "$dir"/*"$suffix"; do
    [[ -e "$f" ]] || continue
    base="$(basename "$f")"
    [[ -z "$skip" || "$base" != "$skip" ]] || continue
    if grep -qF "$base" "$dict"; then
      pass
    else
      fail "$label 未登记: $base" "DOCTOR/${label}_UNREGISTERED" "把 $base 补进 $dict" "$dict"
    fi
  done
}

# 1) 核心文件/目录
need_file "AGENTS.md" "DOCTOR/AGENTS" "restore AGENTS.md" "docs/AGENTS_totally_for_ai_and_human.md"
need_file "docs/AGENTS_totally_for_ai_and_human.md" "DOCTOR/AGENTS_TOTALLY" "restore the full AGENTS version" "AGENTS.md"
need_file "docs/readme.html" "DOCTOR/README_HTML" "restore design doc" "docs/usage.html"
need_file "docs/usage.html" "DOCTOR/USAGE_HTML" "restore human usage manual" "docs/readme.html"
need_file "config/runtime_local.sh" "DOCTOR/RUNTIME_LOCAL" "copy/fill runtime_local.sh" "config/README.md"
need_file "config/git-registry.md" "DOCTOR/GIT_REGISTRY" "restore repository registry" "config/README.md"
need_file "config/baselines" "DOCTOR/BASELINES_DIR" "create config/baselines/" "config/baselines/frontend-map-system.md"
need_file "changes/change-scaffold.sh" "DOCTOR/CHANGE_SCAFFOLD" "restore change-scaffold.sh" "changes/"
need_file "changes/status-card.sh" "DOCTOR/STATUS_CARD_SCRIPT" "restore status-card.sh" "changes/"
need_file "changes/change-whitelist-spec.md" "DOCTOR/CHANGE_WHITELIST" "restore change whitelist" "changes/"

# 2) 字典 ↔ 实际文件
check_dictionary "gates" "gates/gate_directory.md" ".sh" "GATE"
check_dictionary "scripts" "scripts/script_directory.md" ".sh" "SCRIPT" "script_directory.md"
check_dictionary "scripts" "scripts/script_directory.md" ".mjs" "SCRIPT"
check_dictionary "templates" "templates/template_directory.md" ".md" "TEMPLATE" "template_directory.md"
if [[ -d skills ]]; then
  for d in skills/*/; do
    [[ -d "$d" ]] || continue
    base="$(basename "$d")"
    if grep -qF "$base" skills/skill_directory.md; then pass; else fail "skill 未登记: $base" "DOCTOR/SKILL_UNREGISTERED" "把 $base 补进 skills/skill_directory.md" "skills/skill_directory.md"; fi
  done
fi

if [[ "$mode" == "quick" ]]; then
  # quick 模式到此为止（核心文件 + 字典）；接线/凭据检查仍然做。
  :
fi

# 3) git-registry path_env ↔ runtime_local export
if [[ -f config/git-registry.md && -f config/runtime_local.sh ]]; then
  while IFS= read -r var; do
    [[ -n "$var" ]] || continue
    if grep -qE "export[[:space:]]+${var}=" config/runtime_local.sh; then
      pass
    else
      fail "path_env 未在 runtime_local.sh 定义: $var" "DOCTOR/PATH_ENV_MISSING" "补 export $var=..." "config/runtime_local.sh"
    fi
  done < <(grep -oE 'RZ_REPO_[A-Z0-9_]+' config/git-registry.md | sort -u)
fi

# 4) git-registry 引用的 baseline 是否存在
if [[ -f config/git-registry.md ]]; then
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if [[ -e "$f" ]]; then pass; else fail "baseline 引用不存在: $f" "DOCTOR/BASELINE_MISSING" "补文件或修正 git-registry 引用" "config/git-registry.md"; fi
  done < <(grep -oE 'config/baselines/[a-z0-9-]+\.md' config/git-registry.md | sort -u)
fi

# 5) 后端规则入口引用的 reference 是否存在
if [[ -f rules/backends/backend_rules.md ]]; then
  while IFS= read -r ref; do
    [[ -n "$ref" ]] || continue
    if [[ -f "rules/backends/$ref" ]]; then pass; else fail "backend_rules 引用不存在: rules/backends/$ref" "DOCTOR/BACKEND_RULE_REF" "补 reference 或修正引用" "rules/backends/backend_rules.md"; fi
  done < <(grep -oE '`\./[A-Za-z0-9._-]+-reference\.md`' rules/backends/backend_rules.md | tr -d '`' | sed 's#^\./##' | sort -u)
fi

# 6) hook 接线
hook_wired=0
[[ -f .cursor/hooks.json ]] && hook_wired=1
[[ -f .codex/hooks.json ]] && hook_wired=1
compgen -G ".opencode/plugins/*.ts" >/dev/null 2>&1 && hook_wired=1
if [[ "$hook_wired" -eq 1 ]]; then
  pass
else
  warn "未发现 hook 接线（.cursor/hooks.json / .codex/hooks.json / .opencode/plugins/*.ts）；见 hooks/hook_setup.md"
fi

# 6.1 OpenCode plugin 不能 import @opencode/plugin（本机无该包时会加载失败）
if compgen -G ".opencode/plugins/*.ts" >/dev/null 2>&1; then
  for f in .opencode/plugins/*.ts; do
    if grep -q 'from "@opencode/plugin"\|from '"'"'@opencode/plugin'"'"'' "$f"; then
      fail "OpenCode plugin 导入了 @opencode/plugin，本机加载会失败: $f" "DOCTOR/OPENCODE_PLUGIN_IMPORT" "改成纯对象导出 { id, setup }，不要 import @opencode/plugin" "hooks/hook_setup.md"
    else
      pass
    fi
  done
fi

# 6.2 hook 脚本可执行
for f in hooks/hook_adapter.sh hooks/harness-sensor-runner.sh; do
  if [[ -x "$f" ]]; then pass; else fail "hook 脚本不可执行: $f" "DOCTOR/HOOK_NOT_EXEC" "chmod +x $f" "hooks/hook_setup.md"; fi
done

# 7) runtime_local 是否被 gitignore（防止明文凭据进 git）
if git check-ignore -q config/runtime_local.sh 2>/dev/null; then
  pass
else
  warn "config/runtime_local.sh 未被 .gitignore 忽略；若含明文凭据，存在进 git 风险"
fi

# 8) 关键脚本/文档是否提到 doctor（防止文档漏同步）
if [[ "$mode" != "quick" ]]; then
  for f in AGENTS.md docs/AGENTS_totally_for_ai_and_human.md docs/readme.html; do
    if grep -q 'harness-doctor' "$f" 2>/dev/null; then pass; else warn "$f 未提到 scripts/harness-doctor.sh（文档可能漏同步）"; fi
  done
fi

# 9) 汇总
if [[ "$json" -eq 1 ]]; then
  printf '{"pass":%d,"warn":%d,"fail":%d,"mode":"%s","fails":[' "$pass_count" "$warn_count" "$fail_count" "$mode"
  first=1
  for line in "${fail_lines[@]:-}"; do
    [[ -n "$line" ]] || continue
    [[ "$first" -eq 1 ]] || printf ','
    first=0
    printf '%s' "\"${line//\"/\\\"}\""
  done
  printf ']}\n'
else
  printf 'DOCTOR: pass=%d warn=%d fail=%d mode=%s\n' "$pass_count" "$warn_count" "$fail_count" "$mode"
  if [[ "$fail_count" -gt 0 ]]; then
    printf 'DOCTOR: FAIL\n'
  elif [[ "$strict" -eq 1 && "$warn_count" -gt 0 ]]; then
    printf 'DOCTOR: FAIL (strict: warnings treated as failures)\n'
  else
    printf 'DOCTOR: PASS\n'
  fi
fi

if [[ "$fail_count" -gt 0 ]]; then exit 1; fi
if [[ "$strict" -eq 1 && "$warn_count" -gt 0 ]]; then exit 1; fi
exit 0
