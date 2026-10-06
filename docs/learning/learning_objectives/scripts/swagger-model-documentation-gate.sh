#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/swagger-model-documentation-gate.sh <change-dir> <changed-file> [changed-file...]

For each active Swagger 2 backend profile, checks newly added public response
VO files under the configured root. Every checked class requires @ApiModel and
every declared non-static field requires @ApiModelProperty.
USAGE
}

fail() {
  local code="$1" message="$2" fix="$3" sample="$4"
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

[[ "$#" -ge 2 ]] || fail \
  "SWAGGER_MODEL_DOC/MISSING_ARGUMENTS" \
  "missing change dir or changed files" \
  "Pass the active change dir and concrete changed files from the pre-commit stage." \
  "scripts/swagger-model-documentation-gate.sh changes/example /absolute/repo/.../ExampleVO.java"

change_dir="$1"
shift
[[ -d "$change_dir" ]] || fail \
  "SWAGGER_MODEL_DOC/CHANGE_NOT_FOUND" \
  "change dir not found: $change_dir" \
  "Pass changes/<change-id> so the gate has an auditable workflow context." \
  "changes/example"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
if [[ -z "${SFA_REPO_BACKEND_SALES_MANAGEMENT:-}" && -f "$root/config/repos.local.sh" ]]; then
  # shellcheck disable=SC1091
  source "$root/config/repos.local.sh"
fi

is_new_file() {
  local file="$1" repo_root="$2" status
  status="$(git -C "$repo_root" status --porcelain -- "$file" 2>/dev/null || true)"
  [[ "$status" == '?? '* || "$status" == A\ * || "$status" == AM\ * ]]
}

has_api_model_property_for_all_fields() {
  local file="$1"
  awk '
    { lines[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) {
        if (lines[i] !~ /^[[:space:]]*private[[:space:]]+/ ||
            lines[i] ~ /^[[:space:]]*private[[:space:]]+static[[:space:]]+/) {
          continue
        }
        has_property = 0
        for (j = i - 1; j >= i - 5 && j >= 1; j--) {
          if (lines[j] ~ /^[[:space:]]*@ApiModelProperty([[:space:]]*\(|[[:space:]]*$)/) {
            has_property = 1
            break
          }
        }
        if (!has_property) {
          print i ":" lines[i]
        }
      }
    }
  ' "$file"
}

checked=0
while IFS= read -r manifest; do
  [[ -n "$manifest" ]] || continue
  status="$(awk -F': *' '$1 == "status" { print $2; exit }' "$manifest")"
  [[ "$status" == "active" ]] || continue
  env_name="$(awk -F': *' '$1 == "repository_path_env" { print $2; exit }' "$manifest")"
  response_root="$(awk -F': *' '$1 == "public_response_root" { print $2; exit }' "$manifest")"
  [[ -n "$env_name" && -n "$response_root" ]] || fail \
    "SWAGGER_MODEL_DOC/INVALID_PROFILE" \
    "profile is missing repository_path_env or public_response_root: $manifest" \
    "Declare both fields in the Swagger model documentation profile." \
    "rules/backends/swagger2/manifest.yml"
  repo_root="${!env_name:-}"
  [[ -n "$repo_root" && -d "$repo_root" ]] || continue
  repo_root="$(cd "$repo_root" && pwd -P)"

  for input in "$@"; do
    if [[ "$input" == "$repo_root/"* ]]; then
      file="$input"
    elif [[ "$input" == /* ]]; then
      file="$input"
    else
      file="$repo_root/$input"
    fi
    [[ -f "$file" ]] || continue
    file="$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")"
    relative="${file#"$repo_root/"}"
    [[ "$relative" == "$response_root"* && "$relative" == *VO.java ]] || continue
    is_new_file "$relative" "$repo_root" || continue
    checked=$((checked + 1))

    if ! grep -Eq '^[[:space:]]*@ApiModel([[:space:]]*\(|[[:space:]]*$)' "$file"; then
      fail \
        "SWAGGER_MODEL_DOC/MISSING_API_MODEL" \
        "new public response VO lacks @ApiModel: $file" \
        "Add @ApiModel(description = \"...\") to the response model class." \
        "rules/backends/swagger2/manifest.yml"
    fi

    missing_fields="$(has_api_model_property_for_all_fields "$file")"
    if [[ -n "$missing_fields" ]]; then
      fail \
        "SWAGGER_MODEL_DOC/MISSING_FIELD_PROPERTY" \
        "new public response VO has fields without @ApiModelProperty: $file ($missing_fields)" \
        "Document each declared response field with @ApiModelProperty, including status, enum, time, and compatibility semantics." \
        "docs/standards/comment-logging.md"
    fi
  done
done < <(find "$root/rules/backends" -name manifest.yml -type f -print 2>/dev/null | sort)

printf 'PASS: Swagger model documentation gate checked %s newly added public response VO file(s)\n' "$checked"
