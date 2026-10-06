#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/code-comment-log-quality.sh <repo-root> [changed-file...]

Checks Java / Vue / JavaScript changed files for high-signal comment and logging issues.
If changed files are omitted, checks git diff --name-only for *.java, *.vue and *.js.
EOF
}

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

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$#" -lt 1 ]]; then
  usage
  fail \
    "CODE_COMMENT_LOG/MISSING_REPO" \
    "missing repo root" \
    "Pass the repo root followed by changed Java/Vue/JS files." \
    "docs/standards/comment-logging.md"
fi

repo="$1"
shift || true

if [[ ! -d "$repo" ]]; then
  fail \
    "CODE_COMMENT_LOG/REPO_NOT_FOUND" \
    "repo root does not exist: $repo" \
    "Pass a valid local repo path from config/repos.local.sh." \
    "config/repos.local.example.sh"
fi

repo="$(cd "$repo" && pwd)"
tmp_files="$(mktemp)"
trap 'rm -f "$tmp_files"' EXIT

if [[ "$#" -gt 0 ]]; then
  for item in "$@"; do
    case "$item" in
      *.java|*.vue|*.js) printf '%s\n' "$item" >> "$tmp_files" ;;
    esac
  done
else
  git -C "$repo" diff --name-only -- '*.java' '*.vue' '*.js' > "$tmp_files" || true
fi

violations=0
warnings=0
checked=0

report_match() {
  local rule="$1"
  local message="$2"
  local output="$3"

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
  local output="$3"

  if [[ -n "$output" ]]; then
    warnings=$((warnings + 1))
    printf '%s\n' "$output" | while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      printf '%s [%s] WARN: %s\n' "$line" "$rule" "$message"
    done
  fi
}

resolve_path() {
  local input="$1"
  if [[ "$input" == "$repo/"* || "$input" == /* ]]; then
    printf '%s\n' "$input"
  else
    printf '%s/%s\n' "$repo" "$input"
  fi
}

java_public_method_without_javadoc() {
  awk '
    function has_doc(start, i) {
      for (i = start - 1; i >= start - 5 && i >= 1; i--) {
        if (lines[i] ~ /\/\*\*/ || lines[i] ~ /\{@inheritDoc\}/ || lines[i] ~ /@Override/) {
          return 1
        }
      }
      return 0
    }
    {
      lines[NR] = $0
    }
    END {
      for (i = 1; i <= NR; i++) {
        line = lines[i]
        if (line ~ /^[[:space:]]*(public|protected)[^;=]*[[:space:]][A-Za-z0-9_]+[[:space:]]*\([^;]*\)[[:space:]]*(throws[^{]+)?\{?[[:space:]]*$/ &&
            line !~ / (get|set|is)[A-ZA-Za-z0-9_]*[[:space:]]*\(/ &&
            line !~ / (equals|hashCode|toString)[[:space:]]*\(/ &&
            !has_doc(i)) {
          print i ":" line
        }
      }
    }
  ' "$1"
}

js_export_without_doc() {
  awk '
    function has_doc(start, i) {
      for (i = start - 1; i >= start - 4 && i >= 1; i--) {
        if (lines[i] ~ /^[[:space:]]*\/\*\*/ || lines[i] ~ /^[[:space:]]*\/\//) {
          return 1
        }
      }
      return 0
    }
    {
      lines[NR] = $0
    }
    END {
      for (i = 1; i <= NR; i++) {
        line = lines[i]
        if (line ~ /^[[:space:]]*export[[:space:]]+(function|const|let|var)[[:space:]][A-Za-z0-9_]+/ && !has_doc(i)) {
          print i ":" line
        }
      }
    }
  ' "$1"
}

while IFS= read -r input; do
  [[ -n "$input" ]] || continue
  path="$(resolve_path "$input")"
  [[ -f "$path" ]] || continue

  case "$path" in
    *.java|*.vue|*.js) ;;
    *) continue ;;
  esac

  checked=$((checked + 1))

  report_match "DOCLOG-DEBUG-001" "禁止提交临时 [DEBUG-...] 标记" "$(grep -nF '[DEBUG-' "$path" || true)"

  case "$path" in
    *.vue|*/src/*.js)
      report_match "DOCLOG-FE-001" "业务前端代码禁止 console.*，请使用项目已有错误处理、提示或上报封装" "$(grep -nE '(^|[^A-Za-z0-9_$])console\.[A-Za-z]+' "$path" || true)"
      report_match "DOCLOG-FE-002" "业务前端代码禁止 debugger" "$(grep -nE '(^|[^A-Za-z0-9_$])debugger[[:space:]]*;?' "$path" || true)"
      report_warn "DOCLOG-FE-003" "导出 API / 工具方法建议补 JSDoc 或等价注释" "$(js_export_without_doc "$path" || true)"
      ;;
    *.java)
      report_warn "DOCLOG-JAVA-001" "public/protected 复杂方法建议补 Javadoc 或等价注释；getter/setter/@Override 可豁免" "$(java_public_method_without_javadoc "$path" || true)"
      ;;
  esac
done < "$tmp_files"

if [[ "$checked" -eq 0 ]]; then
  printf 'PASS: no Java/Vue/JS changed files to check\n'
  exit 0
fi

if [[ "$violations" -gt 0 ]]; then
  printf 'FAIL: code comment/log quality gate found %s violation group(s) in %s file(s)\n' "$violations" "$checked" >&2
  printf 'CODE: CODE_COMMENT_LOG/VIOLATIONS\n' >&2
  printf 'FIX: Remove debug logs or use the project logging/error handling pattern, then rerun this gate.\n' >&2
  printf 'SAMPLE: docs/standards/comment-logging.md\n' >&2
  exit 1
fi

printf 'PASS: code comment/log quality gate checked %s file(s)\n' "$checked"
if [[ "$warnings" -gt 0 ]]; then
  printf 'WARN: code comment/log quality gate found %s warning group(s); Reviewer must confirm\n' "$warnings"
fi
