#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/java-mechanical-quality.sh <repo-root> [changed-file...]

If changed files are omitted, the script checks git diff --name-only for Java/XML files.
Pass paths as repo-relative or absolute paths.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

fail() {
  local code="$1"
  local message="$2"
  local fix="$3"
  local sample="$4"
  printf 'FAIL: %s\n' "$message" >&2
  printf 'CODE: %s\n' "$code" >&2
  printf 'FIX: %s\n' "$fix" >&2
  printf 'SAMPLE: %s\n' "$sample" >&2
  exit 1
}

if [[ "$#" -lt 1 ]]; then
  usage
  fail \
    "JAVA_MECHANICAL/MISSING_REPO" \
    "missing repo root" \
    "Pass the Java repo root followed by changed Java/XML files." \
    "docs/standards/java/README.md"
fi

repo="$1"
shift || true

if [[ ! -d "$repo" ]]; then
  fail \
    "JAVA_MECHANICAL/REPO_NOT_FOUND" \
    "repo root does not exist: $repo" \
    "Pass a valid local Java repo path from config/repos.local.sh." \
    "config/repos.local.example.sh"
fi

repo="$(cd "$repo" && pwd)"

tmp_files="$(mktemp)"
trap 'rm -f "$tmp_files"' EXIT

if [[ "$#" -gt 0 ]]; then
  for item in "$@"; do
    case "$item" in
      *.java|*.xml) printf '%s\n' "$item" >> "$tmp_files" ;;
    esac
  done
else
  git -C "$repo" diff --name-only -- '*.java' '*.xml' > "$tmp_files" || true
fi

violations=0
warnings=0
checked=0

report_match() {
  local rule="$1"
  local message="$2"
  local file="$3"
  local output="$4"

  if [[ -n "$output" ]]; then
    violations=$((violations + 1))
    printf '%s\n' "$output" | while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      printf '%s [%s] %s\n' "$line" "$rule" "$message"
    done
  fi
}

report_warn() {
  local rule="$1"
  local message="$2"
  local file="$3"
  local output="$4"

  if [[ -n "$output" ]]; then
    warnings=$((warnings + 1))
    printf '%s\n' "$output" | while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      printf '%s [%s] WARN: %s\n' "$line" "$rule" "$message"
    done
  fi
}

while IFS= read -r input; do
  [[ -n "$input" ]] || continue

  if [[ "$input" == "$repo/"* ]]; then
    path="$input"
  elif [[ "$input" == /* ]]; then
    path="$input"
  else
    path="$repo/$input"
  fi

  [[ -f "$path" ]] || continue

  case "$path" in
    *.java|*.xml) ;;
    *) continue ;;
  esac

  checked=$((checked + 1))

  if [[ "$path" == *.java ]]; then
    report_match "AJAVA-LOG-001" "禁止使用 System.out/System.err 输出日志" "$path" "$(grep -nE 'System\.(out|err)\.print' "$path" || true)"
    report_match "AJAVA-EX-001" "禁止使用 printStackTrace()" "$path" "$(grep -nE '\.printStackTrace\(' "$path" || true)"
    report_match "AJAVA-EX-002" "禁止空 catch，必须恢复、转换、记录或上抛" "$path" "$(grep -nE 'catch[[:space:]]*\([^)]*\)[[:space:]]*\{[[:space:]]*\}' "$path" || true)"
    report_match "AJAVA-LOG-002" "日志调用使用占位符，不使用字符串拼接" "$path" "$(grep -nE 'log(ger)?\.(trace|debug|info|warn|error)\([^)]*\"[^\"]*\"[[:space:]]*\+' "$path" || true)"
    report_warn "AJAVA-DI-001" "新增代码优先构造器注入，字段 @Autowired 需要说明" "$path" "$(grep -nE '^[[:space:]]*@Autowired[[:space:]]*$' "$path" || true)"
    report_warn "AJAVA-LAYER-001" "Controller 不应直接依赖 Mapper/DAO" "$path" "$(grep -nE '(Controller|Resource)\.java|class .*Controller|class .*Resource' "$path" >/dev/null && grep -nE '(Mapper|Dao)[[:space:]]+[A-Za-z0-9_]+[;=]' "$path" || true)"
  fi

  if [[ "$path" == *.xml ]]; then
    report_match "AJAVA-SQL-001" "Mapper SQL 禁止 select *" "$path" "$(grep -niE 'select[[:space:]]+\*' "$path" || true)"
    report_match "AJAVA-SQL-002" "Mapper SQL 禁止使用 \${} 拼接参数" "$path" "$(grep -nF '${' "$path" || true)"
  fi
done < "$tmp_files"

if [[ "$checked" -eq 0 ]]; then
  printf 'PASS: no Java/XML changed files to check\n'
  exit 0
fi

if [[ "$violations" -gt 0 ]]; then
  printf 'FAIL: Java mechanical quality gate found %s violation group(s) in %s file(s)\n' "$violations" "$checked" >&2
  printf 'CODE: JAVA_MECHANICAL/VIOLATIONS\n' >&2
  printf 'FIX: Fix the reported Java/XML mechanical violations before asking for review.\n' >&2
  printf 'SAMPLE: docs/standards/java/README.md\n' >&2
  exit 1
fi

printf 'PASS: Java mechanical quality gate checked %s file(s)\n' "$checked"
if [[ "$warnings" -gt 0 ]]; then
  printf 'WARN: Java mechanical quality gate found %s warning group(s); Reviewer must confirm\n' "$warnings"
fi
