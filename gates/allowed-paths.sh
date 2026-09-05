#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/allowed-paths.sh <spec-file> <changed-file> [changed-file...]

Checks changed files against absolute path prefixes listed under:
  ```yaml
  allowed_paths:
    group:
      - /absolute/path/**
      - /absolute/file.md
  ```

Also blocks files matching forbidden_paths entries in the same spec.
Also blocks built-in protected paths unless explicitly listed under:
  ```yaml
  approved_protected_paths:
    - /absolute/path/to/approved/protected/file
  ```

Notes:
  - allowed_paths may be absolute paths or environment-variable paths such as $SFA_REPO/src/**.
  - forbidden_paths may be absolute or glob-style patterns such as **/.env*.
  - built-in protected paths include .env*, production config, prod k8s paths, and DB migrations.
  - Non-file markers such as branch_only are ignored.
USAGE
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

spec_file="${1:-}"
[[ -n "$spec_file" ]] || fail \
  "ALLOWED_PATHS/MISSING_SPEC_FILE" \
  "missing spec file" \
  "Pass the active change spec path before the changed files." \
  "templates/spec-tier-s.md"
[[ -f "$spec_file" ]] || fail \
  "ALLOWED_PATHS/SPEC_FILE_NOT_FOUND" \
  "spec file not found: $spec_file" \
  "Create the active change spec first, then rerun with that path." \
  "templates/spec-tier-s.md"
shift || true
[[ "$#" -gt 0 ]] || fail \
  "ALLOWED_PATHS/MISSING_CHANGED_FILES" \
  "missing changed files" \
  "Pass every changed file path after the spec path." \
  "templates/spec-tier-s.md"

expand_path_rule() {
  local rule="$1"
  local var_name=""
  local suffix=""

  if [[ "$rule" =~ ^\$\{([A-Za-z_][A-Za-z0-9_]*)\}(.*)$ ]]; then
    var_name="${BASH_REMATCH[1]}"
    suffix="${BASH_REMATCH[2]}"
  elif [[ "$rule" =~ ^\$([A-Za-z_][A-Za-z0-9_]*)(.*)$ ]]; then
    var_name="${BASH_REMATCH[1]}"
    suffix="${BASH_REMATCH[2]}"
  fi

  if [[ -n "$var_name" ]]; then
    local value="${!var_name:-}"
    [[ -n "$value" ]] || fail \
      "ALLOWED_PATHS/ENV_NOT_SET" \
      "environment variable not set for allowed path: $var_name" \
      "Source config/runtime_local.sh or replace the allowed path with an absolute path." \
      "config/runtime_local.sh"
    printf '%s%s\n' "$value" "$suffix"
    return
  fi

  printf '%s\n' "$rule"
}

allowed_rules=()
while IFS= read -r rule; do
  expanded_rule="$(expand_path_rule "$rule")"
  [[ "$expanded_rule" = /* ]] || continue
  allowed_rules+=("$expanded_rule")
done < <(
  awk '
    /^allowed_paths:/ { in_allowed=1; next }
    /^forbidden_paths:/ { in_allowed=0 }
    in_allowed && /^[[:space:]]*-[[:space:]]*(\/|\$)/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      gsub(/^"|"$/, "", line)
      gsub(/^'\''|'\''$/, "", line)
      print line
    }
  ' "$spec_file"
)

[[ "${#allowed_rules[@]}" -gt 0 ]] || fail \
  "ALLOWED_PATHS/NO_ALLOWED_PATHS" \
  "no absolute allowed_paths found in $spec_file" \
  "Add absolute allowed_paths, or env-var paths that expand to absolute paths, before editing." \
  "templates/spec-tier-s.md"

forbidden_rules=()
while IFS= read -r rule; do
  forbidden_rules+=("$rule")
done < <(
  awk '
    /^forbidden_paths:/ { in_forbidden=1; next }
    in_forbidden && /^[^[:space:]]/ { in_forbidden=0 }
    in_forbidden && /^[[:space:]]*-[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      gsub(/^"|"$/, "", line)
      gsub(/^'\''|'\''$/, "", line)
      print line
    }
  ' "$spec_file"
)

default_protected_rules=(
  '**/.env*'
  '**/application-prod.yml'
  '**/bootstrap-prod.yml'
  '**/k8s/prod/**'
  '**/db/migration/**'
)

approved_protected_rules=()
while IFS= read -r rule; do
  if [[ "$rule" == \$* ]]; then
    rule="$(expand_path_rule "$rule")"
  fi
  approved_protected_rules+=("$rule")
done < <(
  awk '
    /^approved_protected_paths:/ { in_approved=1; next }
    in_approved && /^[^[:space:]]/ { in_approved=0 }
    in_approved && /^[[:space:]]*-[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      gsub(/^"|"$/, "", line)
      gsub(/^'\''|'\''$/, "", line)
      print line
    }
  ' "$spec_file"
)

normalize_path() {
  local path="$1"
  if [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$PWD" "$path"
  fi
}

to_relative_path() {
  local path="$1"
  if [[ "$path" == "$PWD/"* ]]; then
    printf '%s\n' "${path#"$PWD/"}"
  else
    printf '%s\n' "$path"
  fi
}

matches_rule() {
  local file="$1"
  local rule="$2"

  if [[ "$rule" == *'/**' ]]; then
    local prefix="${rule%/**}"
    [[ "$file" == "$prefix" || "$file" == "$prefix/"* ]]
  elif [[ "$rule" == *'*' ]]; then
    [[ "$file" == $rule ]]
  else
    [[ "$file" == "$rule" ]]
  fi
}

matches_forbidden_rule() {
  local file="$1"
  local rule="$2"
  local relative_file
  relative_file="$(to_relative_path "$file")"

  if [[ "$rule" = /* ]]; then
    matches_rule "$file" "$rule"
    return
  fi

  case "$rule" in
    '**/'*)
      local suffix="${rule#**/}"
      [[ "$relative_file" == $suffix || "$relative_file" == */$suffix || "$file" == $suffix || "$file" == */$suffix ]]
      ;;
    *)
      [[ "$relative_file" == $rule || "$file" == $rule ]]
      ;;
  esac
}

is_approved_protected_path() {
  local file="$1"
  local rule
  for rule in "${approved_protected_rules[@]:-}"; do
    [[ -n "$rule" ]] || continue
    if [[ "$rule" = /* ]]; then
      if matches_rule "$file" "$rule"; then
        return 0
      fi
    elif matches_forbidden_rule "$file" "$rule"; then
      return 0
    fi
  done
  return 1
}

violations=()
forbidden_violations=()
protected_violations=()

for changed in "$@"; do
  file="$(normalize_path "$changed")"
  allowed=0

  for rule in "${allowed_rules[@]}"; do
    if matches_rule "$file" "$rule"; then
      allowed=1
      break
    fi
  done

  if [[ "$allowed" -ne 1 ]]; then
    violations+=("$file")
    continue
  fi

  for rule in "${default_protected_rules[@]}"; do
    if matches_forbidden_rule "$file" "$rule"; then
      if ! is_approved_protected_path "$file"; then
        protected_violations+=("$file matched protected path $rule")
      fi
      break
    fi
  done

  for rule in "${forbidden_rules[@]:-}"; do
    [[ -n "$rule" ]] || continue
    if matches_forbidden_rule "$file" "$rule"; then
      forbidden_violations+=("$file matched $rule")
      break
    fi
  done
done

if [[ "${#violations[@]}" -gt 0 ]]; then
  printf 'FAIL: changed files outside allowed_paths:\n' >&2
  printf 'CODE: ALLOWED_PATHS/OUT_OF_SCOPE\n' >&2
  printf 'FIX: Add the path to allowed_paths only if the spec explicitly approves it; otherwise revert or move the change back inside scope.\n' >&2
  printf 'SAMPLE: templates/spec-tier-s.md\n' >&2
  printf ' - %s\n' "${violations[@]}" >&2
  exit 1
fi

if [[ "${#forbidden_violations[@]}" -gt 0 ]]; then
  printf 'FAIL: changed files match forbidden_paths:\n' >&2
  printf 'CODE: ALLOWED_PATHS/FORBIDDEN_PATH\n' >&2
  printf 'FIX: Remove the forbidden-path change, or record explicit approval in the spec before rerunning this gate.\n' >&2
  printf 'SAMPLE: templates/spec-tier-s.md\n' >&2
  printf ' - %s\n' "${forbidden_violations[@]}" >&2
  exit 1
fi

if [[ "${#protected_violations[@]}" -gt 0 ]]; then
  printf 'FAIL: changed files match built-in protected paths without approved_protected_paths:\n' >&2
  printf 'CODE: ALLOWED_PATHS/PROTECTED_PATH\n' >&2
  printf 'FIX: Remove the protected-path change, or record explicit user approval under approved_protected_paths before rerunning this gate.\n' >&2
  printf 'SAMPLE: templates/spec-tier-s.md\n' >&2
  printf ' - %s\n' "${protected_violations[@]}" >&2
  exit 1
fi

if [[ "${#approved_protected_rules[@]}" -gt 0 ]]; then
  printf 'NOTICE: approved_protected_paths present; ensure user approval is recorded in spec\n'
fi

printf 'PASS: allowed paths check passed for %s file(s)\n' "$#"
