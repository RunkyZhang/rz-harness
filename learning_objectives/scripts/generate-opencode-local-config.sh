#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/generate-opencode-local-config.sh [--output <path|-] [--projects-root <path>]

Generates a local OpenCode config with concrete external_directory paths.

Defaults:
  --output config/opencode.local.json
  --projects-root $SFA_PROJECTS_ROOT, after sourcing config/repos.local.sh when present

Use with:
  OPENCODE_CONFIG=config/opencode.local.json opencode .
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

output="config/opencode.local.json"
projects_root=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --output)
      output="${2:-}"
      [[ -n "$output" ]] || fail "--output requires a value"
      shift 2
      ;;
    --projects-root)
      projects_root="${2:-}"
      [[ -n "$projects_root" ]] || fail "--projects-root requires a value"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

arg_projects_root="$projects_root"
env_projects_root="${SFA_PROJECTS_ROOT:-}"

if [[ -f config/repos.local.sh ]]; then
  # shellcheck disable=SC1091
  source config/repos.local.sh
fi

projects_root="${arg_projects_root:-${env_projects_root:-${SFA_PROJECTS_ROOT:-}}}"
[[ -n "$projects_root" ]] || fail "SFA_PROJECTS_ROOT is not set; pass --projects-root or source config/repos.local.sh"

case "$projects_root" in
  /*) ;;
  "~"*) projects_root="${HOME}${projects_root#\~}" ;;
  *) projects_root="$root/$projects_root" ;;
esac

projects_root="$(cd "$projects_root" 2>/dev/null && pwd -P || printf '%s\n' "$projects_root")"

node - "$root/opencode.json" "$projects_root" "$output" <<'NODE'
const fs = require('fs');
const path = require('path');

const [, , sourcePath, projectsRoot, outputPath] = process.argv;
const config = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));

function replaceEnv(value) {
  if (typeof value === 'string') {
    return value
      .split('{env:SFA_PROJECTS_ROOT}').join(projectsRoot)
      .split('${SFA_PROJECTS_ROOT}').join(projectsRoot);
  }
  if (Array.isArray(value)) return value.map(replaceEnv);
  if (value && typeof value === 'object') {
    const result = {};
    for (const [key, item] of Object.entries(value)) {
      result[replaceEnv(key)] = replaceEnv(item);
    }
    return result;
  }
  return value;
}

const rendered = replaceEnv(config);
rendered.permission = rendered.permission || {};
rendered.permission.external_directory = {
  [`${projectsRoot}/**`]: 'allow',
};
rendered.agent = rendered.agent || {};
for (const agentName of ['sfa-harness-explorer', 'sfa-harness-reviewer']) {
  rendered.agent[agentName] = rendered.agent[agentName] || {};
  rendered.agent[agentName].permission = rendered.agent[agentName].permission || {};
  rendered.agent[agentName].permission.external_directory = {
    [`${projectsRoot}/**`]: 'allow',
  };
}
const json = `${JSON.stringify(rendered, null, 2)}\n`;

if (outputPath === '-') {
  process.stdout.write(json);
} else {
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, json);
  process.stderr.write(`PASS: wrote ${outputPath}\n`);
}
NODE
