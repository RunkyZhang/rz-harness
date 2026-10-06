#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/harness-bootstrap-smoke.sh

Read-only smoke check for the current Codex harness bootstrap surface:
AGENTS.md, project hooks, and harness skill routing.
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

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

[[ -f AGENTS.md ]] || fail \
  "BOOTSTRAP/MISSING_AGENTS" \
  "AGENTS.md is missing" \
  "Restore project instructions before relying on harness behavior." \
  "AGENTS.md"

grep -q 'docs/skills-routing.md' AGENTS.md || fail \
  "BOOTSTRAP/AGENTS_NO_SKILL_ROUTING" \
  "AGENTS.md does not require docs/skills-routing.md" \
  "Keep skill routing discoverable from project startup instructions." \
  "Use local harness skills via docs/skills-routing.md"

[[ -f .codex/config.toml ]] || fail \
  "BOOTSTRAP/MISSING_CODEX_CONFIG" \
  ".codex/config.toml is missing" \
  "Restore project-local Codex config with hooks enabled." \
  "[features]\nhooks = true"

grep -q 'hooks[[:space:]]*=[[:space:]]*true' .codex/config.toml || fail \
  "BOOTSTRAP/CODEX_HOOKS_DISABLED" \
  "Codex hooks are not enabled in .codex/config.toml" \
  "Enable hooks for project-local pre/post tool sensors." \
  "[features]\nhooks = true"

[[ -f .codex/hooks.json ]] || fail \
  "BOOTSTRAP/MISSING_CODEX_HOOKS" \
  ".codex/hooks.json is missing" \
  "Restore project-local Codex hook adapter config." \
  ".codex/hooks.json"

for marker in PreToolUse PostToolUse hooks/codex-pre-tool-use.sh hooks/codex-post-tool-use.sh; do
  grep -q "$marker" .codex/hooks.json || fail \
    "BOOTSTRAP/CODEX_HOOK_MARKER_MISSING" \
    ".codex/hooks.json is missing marker: $marker" \
    "Keep Codex hook config wired to the harness sensor runner." \
    "$marker"
done

[[ -f docs/skills-routing.md ]] || fail \
  "BOOTSTRAP/MISSING_SKILL_ROUTING" \
  "docs/skills-routing.md is missing" \
  "Restore the harness-local skill routing table." \
  "docs/skills-routing.md"

for skill in grill explorer diagnose tdd reviewer handoff; do
  [[ -f "skills/$skill/SKILL.md" ]] || fail \
    "BOOTSTRAP/MISSING_HARNESS_SKILL" \
    "harness skill is missing: skills/$skill/SKILL.md" \
    "Restore the local harness skill or update docs/skills-routing.md with an explicit replacement." \
    "skills/$skill/SKILL.md"
  grep -q "skills/$skill/SKILL.md" docs/skills-routing.md || fail \
    "BOOTSTRAP/SKILL_NOT_ROUTED" \
    "docs/skills-routing.md does not route skills/$skill/SKILL.md" \
    "Keep every harness-local skill visible in the routing table." \
    "skills/$skill/SKILL.md"
done

printf 'PASS: harness bootstrap smoke passed\n'
