#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/architecture-drift-gate.sh <repo-root> [changed-file...]

Checks changed business files for high-signal architecture drift:
  - Java Controller / Resource directly depending on Mapper / DAO
  - Vue page code issuing direct network requests instead of src/api
  - WeChat mini-program pages using wx.request instead of miniprogram/services
  - Android Activity / Adapter / ViewHolder directly creating network clients
  - iOS Controller / View directly creating network clients
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
    "ARCH_DRIFT/MISSING_REPO" \
    "missing repo root" \
    "Pass the repo root followed by changed business files." \
    "templates/pre-pr-review.md"
fi

repo="$1"
shift || true

[[ -d "$repo" ]] || fail \
  "ARCH_DRIFT/REPO_NOT_FOUND" \
  "repo root does not exist: $repo" \
  "Pass a valid local business repo path from config/repos.local.sh." \
  "config/repos.local.example.sh"

repo="$(cd "$repo" && pwd)"
tmp_files="$(mktemp)"
trap 'rm -f "$tmp_files"' EXIT

if [[ "$#" -gt 0 ]]; then
  for item in "$@"; do
    case "$item" in
      *.java|*.kt|*.vue|*.js|*.ts|*.m|*.mm|*.h|*.swift) printf '%s\n' "$item" >> "$tmp_files" ;;
    esac
  done
else
  git -C "$repo" diff --name-only -- '*.java' '*.kt' '*.vue' '*.js' '*.ts' '*.m' '*.mm' '*.h' '*.swift' > "$tmp_files" || true
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

repo_relative() {
  local path="$1"
  if [[ "$path" == "$repo/"* ]]; then
    printf '%s\n' "${path#"$repo/"}"
  else
    printf '%s\n' "$path"
  fi
}

while IFS= read -r input; do
  [[ -n "$input" ]] || continue
  path="$(resolve_path "$input")"
  [[ -f "$path" ]] || continue

  case "$path" in
    *.java|*.kt|*.vue|*.js|*.ts|*.m|*.mm|*.h|*.swift) ;;
    *) continue ;;
  esac

  checked=$((checked + 1))
  rel="$(repo_relative "$path")"
  base="$(basename "$path")"

  case "$path" in
    *.java)
      if [[ "$base" =~ (Controller|Resource)\.java$ ]] || grep -qE 'class[[:space:]]+[A-Za-z0-9_]*(Controller|Resource)\b' "$path"; then
        report_match "ARCH-JAVA-LAYER-001" "Controller / Resource 不得直接依赖 Mapper / DAO；请通过 application/service 层" "$(grep -nE '(Mapper|Dao)[[:space:]]+[A-Za-z0-9_]+[;=]|import[[:space:]].*(Mapper|Dao)[[:space:]]*;' "$path" || true)"
      fi
      if [[ "$base" =~ (Activity|Adapter|ViewHolder)\.java$ ]]; then
        report_match "ARCH-ANDROID-NET-001" "Android Activity / Adapter / ViewHolder 不得直接创建网络客户端；请走既有 repository/service/API 层" "$(grep -nE '(OkHttpClient|HttpURLConnection|Retrofit\.Builder|Volley|AsyncHttpClient)' "$path" || true)"
      fi
      ;;
    *.kt)
      if [[ "$base" =~ (Activity|Adapter|ViewHolder)\.kt$ ]]; then
        report_match "ARCH-ANDROID-NET-001" "Android Activity / Adapter / ViewHolder 不得直接创建网络客户端；请走既有 repository/service/API 层" "$(grep -nE '(OkHttpClient|HttpURLConnection|Retrofit\.Builder|Volley|AsyncHttpClient)' "$path" || true)"
      fi
      ;;
    *.vue)
      if [[ "$rel" == *src/views/* || "$rel" == *src/pages/* ]]; then
        report_match "ARCH-VUE-API-001" "Vue 页面不得直接发起网络请求；请走 src/api 封装" "$(grep -nE '(^|[^A-Za-z0-9_$])(fetch|axios)\s*\(|this\.\$http|this\.\$axios' "$path" || true)"
        report_match "ARCH-VUE-URL-001" "Vue 页面不得硬编码 http/https URL；请走环境配置和 API 封装" "$(grep -nE 'https?://' "$path" || true)"
      fi
      ;;
    *.js)
      if [[ "$rel" == *src/views/* || "$rel" == *src/pages/* ]]; then
        report_match "ARCH-VUE-API-001" "Vue 页面不得直接发起网络请求；请走 src/api 封装" "$(grep -nE '(^|[^A-Za-z0-9_$])(fetch|axios)\s*\(|this\.\$http|this\.\$axios' "$path" || true)"
        report_match "ARCH-VUE-URL-001" "Vue 页面不得硬编码 http/https URL；请走环境配置和 API 封装" "$(grep -nE 'https?://' "$path" || true)"
      fi
      ;;
    *.ts)
      if [[ "$rel" == miniprogram/pages/* ]]; then
        report_match "ARCH-MINIAPP-SERVICE-001" "小程序页面不得直接 wx.request；请走 miniprogram/services" "$(grep -nE 'wx\.request[[:space:]]*\(' "$path" || true)"
        report_match "ARCH-MINIAPP-URL-001" "小程序页面不得硬编码 http/https URL；请走 env/service 封装" "$(grep -nE 'https?://' "$path" || true)"
      fi
      ;;
    *.m|*.mm|*.swift)
      if [[ "$base" =~ (Controller|View)\.(m|mm|swift)$ ]]; then
        report_match "ARCH-IOS-NET-001" "iOS Controller / View 不得直接创建网络客户端；请走既有 API/service 层" "$(grep -nE '(AFHTTPSessionManager|NSURLSession|NSURLConnection|URLSession)' "$path" || true)"
      fi
      ;;
  esac
done < "$tmp_files"

if [[ "$checked" -eq 0 ]]; then
  printf 'PASS: no architecture drift target files to check\n'
  exit 0
fi

if [[ "$violations" -gt 0 ]]; then
  printf 'FAIL: architecture drift gate found %s violation group(s) in %s file(s)\n' "$violations" "$checked" >&2
  printf 'CODE: ARCH_DRIFT/VIOLATIONS\n' >&2
  printf 'FIX: Move the code behind the repo-specific service/API/application boundary, or record an explicit architecture exception in the solution and review evidence.\n' >&2
  printf 'SAMPLE: templates/pre-pr-review.md\n' >&2
  exit 1
fi

printf 'PASS: architecture drift gate checked %s file(s)\n' "$checked"
