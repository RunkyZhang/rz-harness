#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/mobile-mechanical-quality.sh <repo-root> [changed-file...]

Checks changed iOS / Android files for high-signal mechanical quality issues.
If changed files are omitted, checks git diff --name-only for common mobile file types.
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
    "MOBILE_MECHANICAL/MISSING_REPO" \
    "missing repo root" \
    "Pass the mobile repo root followed by changed mobile files." \
    "docs/baseline/mobile-sfa-ios.md"
fi

repo="$1"
shift || true

[[ -d "$repo" ]] || fail \
  "MOBILE_MECHANICAL/REPO_NOT_FOUND" \
  "repo root does not exist: $repo" \
  "Pass a valid local mobile repo path from config/repos.local.sh." \
  "config/repos.local.example.sh"

repo="$(cd "$repo" && pwd)"
tmp_files="$(mktemp)"
trap 'rm -f "$tmp_files"' EXIT

if [[ "$#" -gt 0 ]]; then
  for item in "$@"; do
    case "$item" in
      *.java|*.kt|*.xml|*.m|*.mm|*.h|*.swift) printf '%s\n' "$item" >> "$tmp_files" ;;
    esac
  done
else
  git -C "$repo" diff --name-only -- '*.java' '*.kt' '*.xml' '*.m' '*.mm' '*.h' '*.swift' > "$tmp_files" || true
fi

violations=0
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

resolve_path() {
  local input="$1"
  if [[ "$input" == "$repo/"* || "$input" == /* ]]; then
    printf '%s\n' "$input"
  else
    printf '%s/%s\n' "$repo" "$input"
  fi
}

while IFS= read -r input; do
  [[ -n "$input" ]] || continue
  path="$(resolve_path "$input")"
  [[ -f "$path" ]] || continue

  case "$path" in
    *.java|*.kt|*.xml|*.m|*.mm|*.h|*.swift) ;;
    *) continue ;;
  esac

  checked=$((checked + 1))

  case "$path" in
    *.java|*.kt)
      report_match "MOBILE-ANDROID-LOG-001" "Android 业务代码禁止 System.out/System.err 调试输出" "$(grep -nE 'System\.(out|err)\.print' "$path" || true)"
      report_match "MOBILE-ANDROID-EX-001" "Android 业务代码禁止 printStackTrace()" "$(grep -nE '\.printStackTrace\(' "$path" || true)"
      report_match "MOBILE-ANDROID-LOG-002" "Android 提交代码禁止 Log.d/Log.v 调试日志" "$(grep -nE '(^|[^A-Za-z0-9_])Log\.(d|v)\(' "$path" || true)"
      report_match "MOBILE-ANDROID-URL-001" "Android 业务代码禁止硬编码 http/https URL" "$(grep -nE 'https?://' "$path" || true)"
      ;;
    *.m|*.mm|*.h|*.swift)
      report_match "MOBILE-IOS-LOG-001" "iOS 业务代码禁止 NSLog/print 调试输出" "$(grep -nE '(^|[^A-Za-z0-9_])(NSLog|print)[[:space:]]*\(' "$path" || true)"
      report_match "MOBILE-IOS-URL-001" "iOS 业务代码禁止硬编码 http/https URL" "$(grep -nE 'https?://' "$path" || true)"
      ;;
    *.xml)
      report_match "MOBILE-XML-URL-001" "移动端 XML 布局/配置禁止硬编码 http/https URL" "$(grep -nE 'https?://' "$path" || true)"
      ;;
  esac
done < "$tmp_files"

if [[ "$checked" -eq 0 ]]; then
  printf 'PASS: no mobile changed files to check\n'
  exit 0
fi

if [[ "$violations" -gt 0 ]]; then
  printf 'FAIL: mobile mechanical quality gate found %s violation group(s) in %s file(s)\n' "$violations" "$checked" >&2
  printf 'CODE: MOBILE_MECHANICAL/VIOLATIONS\n' >&2
  printf 'FIX: Remove debug output, hardcoded URLs, or exception dumping before asking for review.\n' >&2
  printf 'SAMPLE: rules/mobile-android-java.mdc and rules/mobile-ios-objc.mdc\n' >&2
  exit 1
fi

printf 'PASS: mobile mechanical quality gate checked %s file(s)\n' "$checked"
