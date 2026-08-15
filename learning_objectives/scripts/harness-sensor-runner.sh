#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness-sensor-runner.sh <cursor|codex|plain> <event>

Reads one JSON hook payload from stdin and runs lightweight, tool-neutral harness checks.

Events:
  beforeShellExecution / PreToolUse   Deny destructive shell commands.
  afterFileEdit / PostToolUse         If SFA_CHANGE_SPEC and a changed file are present, run allowed-paths.
  sessionStart / SessionStart         Emit lightweight harness context.

Notes:
  - This runner is the source of truth; Cursor/Codex/OpenCode adapters should only call it.
  - Heavy checks such as Maven, npm build, PC E2E, and golden eval stay in lane/pre-PR flows.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

adapter="${1:-}"
event="${2:-}"

if [[ "$adapter" == "-h" || "$adapter" == "--help" ]]; then
  usage
  exit 0
fi

[[ -n "$adapter" ]] || fail "missing adapter"
[[ -n "$event" ]] || fail "missing event"

case "$adapter" in
  cursor|codex|plain) ;;
  *) fail "adapter must be cursor, codex, or plain" ;;
esac

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
export SFA_HARNESS_ROOT="${SFA_HARNESS_ROOT:-$root}"
payload_file="$(mktemp)"
trap 'rm -f "$payload_file"' EXIT
cat > "$payload_file"

json_get() {
  local path="$1"
  node - "$payload_file" "$path" <<'NODE'
const fs = require('fs');
const file = process.argv[2];
const path = process.argv[3].split('.');
const raw = fs.readFileSync(file, 'utf8').trim();
if (!raw) process.exit(0);
let value;
try {
  value = JSON.parse(raw);
} catch {
  process.exit(0);
}
for (const key of path) {
  if (value && Object.prototype.hasOwnProperty.call(value, key)) {
    value = value[key];
  } else {
    process.exit(0);
  }
}
if (typeof value === 'string') {
  process.stdout.write(value);
}
NODE
}

first_json_value() {
  local path value
  for path in "$@"; do
    value="$(json_get "$path")"
    if [[ -n "$value" ]]; then
      printf '%s\n' "$value"
      return 0
    fi
  done
  return 1
}

json_emit() {
  node - "$1" <<'NODE'
const value = JSON.parse(process.argv[2]);
process.stdout.write(JSON.stringify(value));
NODE
}

json_escape() {
  node - "$1" <<'NODE'
process.stdout.write(JSON.stringify(process.argv[2]).slice(1, -1));
NODE
}

emit_allow() {
  local message="$1"
  local escaped_message
  escaped_message="$(json_escape "$message")"
  case "$adapter" in
    cursor)
      json_emit "{\"permission\":\"allow\",\"agentMessage\":\"$escaped_message\",\"userMessage\":\"$escaped_message\"}"
      ;;
    codex)
      if [[ "$event" == "PreToolUse" ]]; then
        json_emit "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"$escaped_message\"}}"
      elif [[ "$event" == "PostToolUse" ]]; then
        json_emit "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"systemMessage\":\"$escaped_message\"}}"
      elif [[ "$event" == "SessionStart" ]]; then
        json_emit "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"$escaped_message\"}}"
      else
        json_emit "{\"systemMessage\":\"$escaped_message\"}"
      fi
      ;;
    plain)
      printf 'PASS: %s\n' "$message"
      ;;
  esac
}

emit_deny() {
  local code="$1"
  local message="$2"
  local full_message="$code: $message"
  local escaped_message
  escaped_message="$(json_escape "$full_message")"
  case "$adapter" in
    cursor)
      json_emit "{\"permission\":\"deny\",\"agentMessage\":\"$escaped_message\",\"userMessage\":\"$escaped_message\"}"
      ;;
    codex)
      if [[ "$event" == "PreToolUse" ]]; then
        json_emit "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$escaped_message\"}}"
      else
        json_emit "{\"systemMessage\":\"$escaped_message\",\"continue\":false,\"stopReason\":\"$escaped_message\"}"
      fi
      ;;
    plain)
      printf 'FAIL: %s\n' "$message" >&2
      printf 'CODE: %s\n' "$code" >&2
      exit 1
      ;;
  esac
}

normalize_shell_command() {
  printf '%s' "$1" | tr '\n\t' '  ' | sed 's/[[:space:]]\{1,\}/ /g; s/^ //; s/ $//'
}

lower_shell_command() {
  normalize_shell_command "$1" | tr '[:upper:]' '[:lower:]'
}

strip_heredoc_bodies_for_policy() {
  node - "$1" <<'NODE'
const command = process.argv[2] || '';
const lines = command.split(/\r?\n/);
const output = [];
let pendingDelimiters = [];

function heredocDelimiters(line) {
  const delimiters = [];
  const pattern = /<<-?\s*(?:'([^']+)'|"([^"]+)"|\\?([A-Za-z_][A-Za-z0-9_]*))/g;
  let match;
  while ((match = pattern.exec(line)) !== null) {
    delimiters.push(match[1] || match[2] || match[3]);
  }
  return delimiters;
}

for (const line of lines) {
  if (pendingDelimiters.length > 0) {
    const trimmed = line.trim();
    const before = pendingDelimiters.length;
    pendingDelimiters = pendingDelimiters.filter((delimiter) => delimiter !== trimmed);
    if (before !== pendingDelimiters.length) {
      continue;
    }
    continue;
  }

  output.push(line);
  pendingDelimiters.push(...heredocDelimiters(line));
}

process.stdout.write(output.join('\n'));
NODE
}

strip_shell_quotes() {
  local value="$1"
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"
  printf '%s' "$value"
}

is_low_risk_shell_target() {
  local target
  target="$(strip_shell_quotes "$1")"
  case "$target" in
    /dev/null) return 0 ;;
    node_modules|node_modules/*|./node_modules|./node_modules/*|*/node_modules|*/node_modules/*) return 0 ;;
    /tmp/*|/private/tmp/*|/var/tmp/*) return 0 ;;
    '$tmp'|'$tmp/'*|'${tmp}'|'${tmp}/'*|'$tmp_dir'|'$tmp_dir/'*|'${tmp_dir}'|'${tmp_dir}/'*|'$TMPDIR'|'$TMPDIR/'*|'${TMPDIR}'|'${TMPDIR}/'*) return 0 ;;
  esac
  return 1
}

shell_tokens_for_policy() {
  node - "$1" <<'NODE'
const command = process.argv[2] || '';
const tokens = [];
let token = '';
let quote = null;
let escape = false;

function pushToken() {
  if (token.length > 0) {
    tokens.push(token);
    token = '';
  }
}

for (let index = 0; index < command.length; index += 1) {
  const char = command[index];
  const next = command[index + 1] || '';

  if (quote) {
    if (escape) {
      token += char;
      escape = false;
      continue;
    }
    if (quote === '"' && char === '\\') {
      escape = true;
      continue;
    }
    if (char === quote) {
      quote = null;
      continue;
    }
    token += char;
    continue;
  }

  if (char === '"' || char === "'") {
    quote = char;
    continue;
  }

  if (/\s/.test(char)) {
    pushToken();
    continue;
  }

  if (char === ';' || char === '<') {
    pushToken();
    tokens.push(char);
    continue;
  }

  if (char === '|' || char === '&') {
    pushToken();
    if (next === char) {
      tokens.push(char + next);
      index += 1;
    } else {
      tokens.push(char);
    }
    continue;
  }

  if (char === '>') {
    let op = char;
    if (next === '>') {
      op = '>>';
      index += 1;
    }
    if (/^[0-9]+$/.test(token)) {
      op = token + op;
      token = '';
    } else {
      pushToken();
    }
    tokens.push(op);
    continue;
  }

  token += char;
}

pushToken();
if (tokens.length > 0) {
  process.stdout.write(tokens.join('\n') + '\n');
}
NODE
}

rm_recursive_force_has_unsafe_target() {
  local command="$1"
  local prepared token in_rm recursive force target_count unsafe_target
  local -a tokens

  prepared="${command//&&/ ; }"
  prepared="${prepared//||/ ; }"
  prepared="${prepared//;/ ; }"
  prepared="${prepared//|/ | }"
  prepared="${prepared//</ < }"
  prepared="${prepared//>/ > }"
  read -r -a tokens <<< "$prepared"

  in_rm=0
  recursive=0
  force=0
  target_count=0
  unsafe_target=0

  for token in "${tokens[@]}"; do
    if [[ "$token" == "rm" ]]; then
      in_rm=1
      recursive=0
      force=0
      target_count=0
      unsafe_target=0
      continue
    fi

    if [[ "$in_rm" -eq 0 ]]; then
      continue
    fi

    case "$token" in
      ';'|'|'|'<'|'>')
        if [[ "$recursive" -eq 1 && "$force" -eq 1 && "$unsafe_target" -eq 1 ]]; then
          return 0
        fi
        in_rm=0
        continue
        ;;
      --)
        continue
        ;;
      -*)
        [[ "$token" == *r* ]] && recursive=1
        [[ "$token" == *f* ]] && force=1
        continue
        ;;
    esac

    target_count=$((target_count + 1))
    if ! is_low_risk_shell_target "$token"; then
      unsafe_target=1
    fi
  done

  [[ "$recursive" -eq 1 && "$force" -eq 1 && "$unsafe_target" -eq 1 ]]
}

redirection_has_unsafe_target() {
  local command="$1"
  local prepared token previous next_is_target
  local -a tokens

  tokens=()
  while IFS= read -r token; do
    tokens+=("$token")
  done < <(shell_tokens_for_policy "$command")

  next_is_target=0
  previous=""
  for token in "${tokens[@]}"; do
    if [[ "$next_is_target" -eq 1 ]]; then
      if [[ -n "$token" && "$token" != ">"* ]] && ! is_low_risk_shell_target "$token"; then
        return 0
      fi
      next_is_target=0
    fi

    case "$token" in
      '>'|'1>'|'2>'|'>>'|'1>>'|'2>>')
        next_is_target=1
        ;;
      *)
        if [[ "$previous" == *'>' && "$token" != ">"* ]] && ! is_low_risk_shell_target "$token"; then
          return 0
        fi
        ;;
    esac
    previous="$token"
  done

  return 1
}

dangerous_command_reason() {
  local command="$1"
  local policy_command normalized lower sep end not_sep
  local re_git_reset re_git_clean re_git_checkout re_git_restore re_git_push_force re_git_push_delete
  local re_git_branch_delete re_find_delete re_xargs_rm re_shred re_chmod_777
  policy_command="$(strip_heredoc_bodies_for_policy "$command")"
  normalized="$(normalize_shell_command "$policy_command")"
  lower="$(lower_shell_command "$policy_command")"
  sep='(^|[[:space:];|&])'
  end='([[:space:];|&]|$)'
  not_sep='[^;&|]'

  re_git_reset="${sep}git[[:space:]]+reset[[:space:]]+--hard${end}"
  re_git_clean="${sep}git[[:space:]]+clean[[:space:]]+${not_sep}*-${not_sep}*f${not_sep}*d"
  re_git_checkout="${sep}git[[:space:]]+checkout[[:space:]]+--${end}"
  re_git_restore="${sep}git[[:space:]]+restore[[:space:]]+\\.${end}"
  re_git_push_force="${sep}git[[:space:]]+push[[:space:]]+${not_sep}*(--force|-f|--force-with-lease)"
  re_git_push_delete="${sep}git[[:space:]]+push[[:space:]]+${not_sep}*[[:space:]]:[^[:space:];|&]+"
  re_git_branch_delete="${sep}git[[:space:]]+branch[[:space:]]+-d"
  re_find_delete="${sep}find[[:space:]]+(\\.|[^;&|[:space:]]+)${not_sep}*[[:space:]]-delete${end}"
  re_xargs_rm="${sep}xargs[[:space:]]${not_sep}*rm${end}"
  re_shred="${sep}shred[[:space:]]+"
  re_chmod_777="${sep}chmod[[:space:]]+-r[[:space:]]+777${end}"

  if [[ "$lower" =~ $re_git_reset ]]; then
    printf 'destructive shell command requires explicit human approval outside the agent loop: %s\n' "$command"
    return 0
  fi

  if [[ "$lower" =~ $re_git_clean ]]; then
    printf 'destructive shell command requires explicit human approval outside the agent loop: %s\n' "$command"
    return 0
  fi

  if [[ "$lower" =~ $re_git_checkout || "$lower" =~ $re_git_restore ]]; then
    printf 'destructive shell command requires explicit human approval outside the agent loop: %s\n' "$command"
    return 0
  fi

  if [[ "$lower" =~ $re_git_push_force ]]; then
    printf 'destructive shell command requires explicit human approval outside the agent loop: %s\n' "$command"
    return 0
  fi

  if [[ "$lower" =~ $re_git_push_delete ]]; then
    printf 'destructive shell command requires explicit human approval outside the agent loop: %s\n' "$command"
    return 0
  fi

  if [[ "$lower" =~ $re_git_branch_delete ]]; then
    printf 'destructive shell command requires explicit human approval outside the agent loop: %s\n' "$command"
    return 0
  fi

  if rm_recursive_force_has_unsafe_target "$lower"; then
    printf 'destructive shell command requires explicit human approval outside the agent loop: %s\n' "$command"
    return 0
  fi

  if [[ "$lower" =~ $re_find_delete ]]; then
    if [[ ! "$lower" =~ ${sep}find[[:space:]]+(/tmp/|/private/tmp/|/var/tmp/) ]]; then
      printf 'destructive shell command requires explicit human approval outside the agent loop: %s\n' "$command"
      return 0
    fi
  fi

  if [[ "$lower" =~ $re_xargs_rm ]]; then
    printf 'destructive shell command requires explicit human approval outside the agent loop: %s\n' "$command"
    return 0
  fi

  if [[ "$lower" =~ $re_shred ]]; then
    printf 'destructive shell command requires explicit human approval outside the agent loop: %s\n' "$command"
    return 0
  fi

  if redirection_has_unsafe_target "$normalized"; then
    printf 'destructive shell command requires explicit human approval outside the agent loop: %s\n' "$command"
    return 0
  fi

  if [[ "$lower" =~ $re_chmod_777 ]]; then
    printf 'destructive shell command requires explicit human approval outside the agent loop: %s\n' "$command"
    return 0
  fi

  return 1
}

active_change_dir_for_shell_context() {
  local cwd="$1"
  local ref change_root maybe_change
  for ref in "${SFA_ACTIVE_CHANGE_DIR:-}" "${SFA_CHANGE_DIR:-}" "${SFA_ACTIVE_CHANGE:-}" "${SFA_CHANGE_ID:-}"; do
    if resolve_change_ref "$ref"; then
      return 0
    fi
  done

  change_root="$root/changes"
  maybe_change="$(canonical_path_for_match "$(path_from_cwd "$cwd")")"
  case "$maybe_change" in
    "$change_root"/*)
      maybe_change="${maybe_change#"$change_root/"}"
      maybe_change="${maybe_change%%/*}"
      if [[ -n "$maybe_change" && -d "$change_root/$maybe_change" ]]; then
        (cd "$change_root/$maybe_change" && pwd -P)
        return 0
      fi
      ;;
  esac
  return 1
}

technical_solution_feishu_direct_command() {
  local command="$1"
  local policy_command lower sep not_sep
  policy_command="$(strip_heredoc_bodies_for_policy "$command")"
  lower="$(lower_shell_command "$policy_command")"
  sep='(^|[[:space:];|&])'
  not_sep='[^;&|]*'

  if [[ "$lower" =~ ${sep}lark-cli[[:space:]]+docs[[:space:]]+\+update ]]; then
    if [[ "$lower" == *"technical-solution-feishu"* || "$lower" == *"technical-solution.md"* || "$lower" == *"feishu_solution_"* ]]; then
      return 0
    fi
    if [[ "$lower" == *"--command overwrite"* && "$lower" == *"--doc-format markdown"* && "$command" == *"技术方案"* ]]; then
      return 0
    fi
  fi

  if [[ "$lower" =~ ${sep}lark-cli[[:space:]]+wiki[[:space:]]+\+node-create ]]; then
    if [[ "$command" == *"技术方案"* || "$lower" == *"technical-solution"* ]]; then
      return 0
    fi
  fi

  if [[ "$lower" =~ ${sep}${not_sep}technical-solution-feishu-sync\.sh ]]; then
    return 1
  fi

  return 1
}

technical_solution_feishu_block_reason() {
  local command="$1" cwd="$2"
  local change_dir
  change_dir="$(active_change_dir_for_shell_context "$cwd" || true)"
  [[ -n "$change_dir" ]] || return 1
  [[ -f "$change_dir/technical-solution.md" ]] || return 1
  technical_solution_feishu_direct_command "$command" || return 1

  printf 'direct Feishu technical-solution generation is restricted in active business changes with technical-solution.md; use scripts/technical-solution-feishu-sync.sh %s or --dry-run for preview. Command: %s\n' "$change_dir" "$command"
  return 0
}

load_local_repo_config_once() {
  if [[ "${SFA_SENSOR_REPO_CONFIG_LOADED:-0}" == "1" ]]; then
    return
  fi
  if [[ -f "$root/config/repos.local.sh" ]]; then
    set +u
    # shellcheck source=/dev/null
    source "$root/config/repos.local.sh"
    set -u
  fi
  SFA_SENSOR_REPO_CONFIG_LOADED=1
}

path_from_cwd() {
  local path="$1"
  local cwd="${2:-$PWD}"
  if [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$cwd" "$path"
  fi
}

canonical_existing_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    (cd "$path" && pwd -P)
  else
    printf '%s\n' "$path"
  fi
}

canonical_path_for_match() {
  local path="$1"
  local dir base
  if [[ -d "$path" ]]; then
    (cd "$path" && pwd -P)
    return
  fi
  dir="$(dirname "$path")"
  base="$(basename "$path")"
  if [[ -d "$dir" ]]; then
    printf '%s/%s\n' "$(cd "$dir" && pwd -P)" "$base"
  else
    printf '%s\n' "$path"
  fi
}

business_repo_root_for_path() {
  local path="$1"
  local absolute var value repo_root
  absolute="$(canonical_path_for_match "$(path_from_cwd "$path")")"
  load_local_repo_config_once
  while IFS= read -r var; do
    value="${!var:-}"
    [[ -n "$value" ]] || continue
    repo_root="$(canonical_existing_dir "$value")"
    [[ -n "$repo_root" ]] || continue
    if [[ "$absolute" == "$repo_root" || "$absolute" == "$repo_root/"* ]]; then
      printf '%s\n' "$repo_root"
      return 0
    fi
  done < <(compgen -A variable SFA_REPO_ | sort)
  return 1
}

field_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*:" {
      sub("^[[:space:]]*" key "[[:space:]]*:[[:space:]]*", "")
      sub("[[:space:]]+$", "")
      print
      exit
    }
  ' "$file"
}

resolve_change_ref() {
  local ref="$1"
  [[ -n "$ref" ]] || return 1
  if [[ -d "$ref" ]]; then
    (cd "$ref" && pwd -P)
    return 0
  fi
  if [[ "$ref" == changes/* && -d "$root/$ref" ]]; then
    (cd "$root/$ref" && pwd -P)
    return 0
  fi
  if [[ -d "$root/changes/$ref" ]]; then
    (cd "$root/changes/$ref" && pwd -P)
    return 0
  fi
  return 1
}

active_change_dir_for_repo() {
  local repo_root="$1"
  local ref
  for ref in "${SFA_ACTIVE_CHANGE_DIR:-}" "${SFA_CHANGE_DIR:-}" "${SFA_ACTIVE_CHANGE:-}" "${SFA_CHANGE_ID:-}"; do
    if resolve_change_ref "$ref"; then
      return 0
    fi
  done
  if [[ -n "${SFA_CHANGE_SPEC:-}" && -f "$SFA_CHANGE_SPEC" ]]; then
    (cd "$(dirname "$SFA_CHANGE_SPEC")" && pwd -P)
    return 0
  fi
  for ref_file in "$repo_root/.harness/active-change" "$root/.harness/active-change"; do
    [[ -f "$ref_file" ]] || continue
    ref="$(tr -d '[:space:]' < "$ref_file")"
    if resolve_change_ref "$ref"; then
      return 0
    fi
  done
  return 1
}

code_start_block_reason() {
  local repo_root="$1"
  local change_dir technical_solution confirmation next_stage
  if [[ "${SFA_HOOK_OVERRIDE:-0}" == "1" ]]; then
    return 1
  fi
  change_dir="$(active_change_dir_for_repo "$repo_root" || true)"
  if [[ -z "$change_dir" ]]; then
    printf 'business repo action requires active change before code-start: %s\n' "$repo_root"
    return 0
  fi
  technical_solution="$change_dir/technical-solution.md"
  if [[ ! -f "$technical_solution" ]]; then
    printf 'active change has no technical-solution.md: %s\n' "$change_dir"
    return 0
  fi
  confirmation="$(field_value "$technical_solution" "confirmation_status")"
  next_stage="$(field_value "$technical_solution" "allowed_next_stage")"
  if [[ "$confirmation" != "CONFIRMED" || "$next_stage" != "code_start" ]]; then
    printf 'active change is not approved for code_start: confirmation_status=%s allowed_next_stage=%s change_dir=%s\n' "${confirmation:-missing}" "${next_stage:-missing}" "$change_dir"
    return 0
  fi
  return 1
}

versioning_shell_command() {
  local lower="$1"
  local sep end re_git_versioning
  sep='(^|[[:space:];|&])'
  end='([[:space:];|&]|$)'
  re_git_versioning="${sep}git[[:space:]]+(add|commit|push)${end}"
  [[ "$lower" =~ $re_git_versioning ]]
}

check_shell_command() {
  local command reason cwd repo_root lower
  command="$(first_json_value command cmd tool_input.command tool_input.cmd input.command input.cmd arguments.command arguments.cmd || true)"
  if [[ -z "$command" ]]; then
    emit_deny "HARNESS/MISSING_SHELL_COMMAND" "shell hook payload did not include command/cmd; refusing to skip shell policy"
    return
  fi

  reason="$(dangerous_command_reason "$command" || true)"
  if [[ -n "$reason" ]]; then
    emit_deny "HARNESS/DANGEROUS_COMMAND" "$reason"
    return
  fi

  lower="$(lower_shell_command "$command")"
  cwd="$(first_json_value cwd working_directory tool_input.cwd tool_input.working_directory input.cwd input.working_directory arguments.cwd arguments.working_directory || true)"
  cwd="${cwd:-$PWD}"
  reason="$(technical_solution_feishu_block_reason "$command" "$cwd" || true)"
  if [[ -n "$reason" ]]; then
    emit_deny "HARNESS/TECH_SOLUTION_FEISHU_SYNC_REQUIRED" "$reason"
    return
  fi

  if versioning_shell_command "$lower"; then
    repo_root="$(business_repo_root_for_path "$cwd" || true)"
    if [[ -n "$repo_root" ]]; then
      reason="$(code_start_block_reason "$repo_root" || true)"
      if [[ -n "$reason" ]]; then
        emit_deny "HARNESS/CODE_START_BLOCKED" "$reason"
        return
      fi
    fi
  fi

  emit_allow "HARNESS: shell command allowed"
}

check_changed_file() {
  local changed_file output err detail patch_file cwd normalized_file repo_root reason
  local -a changed_files
  changed_file="$(first_json_value file_path path tool_input.file_path tool_input.path || true)"
  cwd="$(first_json_value cwd working_directory tool_input.cwd tool_input.working_directory input.cwd input.working_directory arguments.cwd arguments.working_directory || true)"
  cwd="${cwd:-$PWD}"

  if [[ -n "$changed_file" ]]; then
    normalized_file="$(path_from_cwd "$changed_file" "$cwd")"
    repo_root="$(business_repo_root_for_path "$normalized_file" || true)"
    if [[ -n "$repo_root" ]]; then
      reason="$(code_start_block_reason "$repo_root" || true)"
      if [[ -n "$reason" ]]; then
        emit_deny "HARNESS/CODE_START_BLOCKED" "$reason"
        return
      fi
    fi
  fi

  if [[ -z "${SFA_CHANGE_SPEC:-}" ]]; then
    if [[ -z "$changed_file" ]]; then
      emit_allow "HARNESS: SFA_CHANGE_SPEC not set; allowed paths skipped because no change spec is active"
      return
    fi
    emit_allow "HARNESS: SFA_CHANGE_SPEC not set; code-start guard checked when applicable; allowed paths skipped for $changed_file"
    return
  fi

  changed_files=()
  if [[ -n "$changed_file" ]]; then
    changed_files+=("$changed_file")
  else
    while IFS= read -r patch_file; do
      [[ -n "$patch_file" ]] && changed_files+=("$patch_file")
    done < <(extract_patch_files)
  fi

  if [[ "${#changed_files[@]}" -eq 0 ]]; then
    emit_deny "HARNESS/MISSING_CHANGED_FILE" "edit hook payload did not include file_path/path or parseable patch file headers"
    return
  fi

  output="$(mktemp)"
  err="$(mktemp)"
  if "$root/scripts/allowed-paths.sh" "$SFA_CHANGE_SPEC" "${changed_files[@]}" >"$output" 2>"$err"; then
    rm -f "$output" "$err"
    emit_allow "HARNESS: allowed paths checked for ${changed_files[*]}"
    return
  fi

  detail="$(tr '\n' ' ' < "$err" | sed 's/[[:space:]]\{1,\}/ /g' | cut -c1-400)"
  rm -f "$output" "$err"
  emit_deny "HARNESS/ALLOWED_PATHS_FAILED" "$detail"
}

extract_patch_files() {
  node - "$payload_file" <<'NODE'
const fs = require('fs');
const raw = fs.readFileSync(process.argv[2], 'utf8').trim();
if (!raw) process.exit(0);
let payload;
try {
  payload = JSON.parse(raw);
} catch {
  process.exit(0);
}

const candidates = [
  payload.patch,
  payload.input,
  payload.command,
  payload.tool_input && payload.tool_input.patch,
  payload.tool_input && payload.tool_input.input,
  payload.tool_input && payload.tool_input.command,
  payload.arguments && payload.arguments.patch,
  payload.arguments && payload.arguments.input,
  payload.arguments && payload.arguments.command,
].filter((value) => typeof value === 'string');

const files = new Set();
for (const text of candidates) {
  for (const line of text.split(/\r?\n/)) {
    let match = line.match(/^\*\*\* (?:Add|Update|Delete) File: (.+)$/);
    if (match) {
      files.add(match[1].trim());
      continue;
    }
    match = line.match(/^\+\+\+ b\/(.+)$/);
    if (match && match[1] !== '/dev/null') {
      files.add(match[1].trim());
    }
  }
}

for (const file of files) {
  process.stdout.write(`${file}\n`);
}
NODE
}

emit_session_context() {
  emit_allow "HARNESS: use AGENTS.md, changes/<change-id>/spec.md, and scripts/harness-sensor-runner.sh as the tool-neutral sensor entrypoint."
}

case "$event" in
  beforeShellExecution|PreToolUse|PermissionRequest)
    check_shell_command
    ;;
  afterFileEdit|PostToolUse)
    check_changed_file
    ;;
  sessionStart|SessionStart)
    emit_session_context
    ;;
  *)
    emit_allow "HARNESS: no runner action configured for event $event"
    ;;
esac
