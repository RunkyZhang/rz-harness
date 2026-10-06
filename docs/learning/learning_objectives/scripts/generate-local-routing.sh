#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

if [[ -f "$root/config/repos.local.sh" ]]; then
  # shellcheck source=/dev/null
  source "$root/config/repos.local.sh"
elif [[ -f "$root/config/repos.local.example.sh" ]]; then
  # shellcheck source=/dev/null
  source "$root/config/repos.local.example.sh"
fi

usage() {
  cat >&2 <<'USAGE'
Usage:
  scripts/generate-local-routing.sh \
    --change-id <change-id> \
    --frontend-repo <frontend-repo> \
    --active-backends <backend-repo-id[,backend-repo-id...]> \
    --services <local-backend-services.yml> \
    --output <local-routing.yml> \
    [--env-output <frontend.env>]
USAGE
}

if [[ "$#" -eq 0 ]]; then
  usage
  exit 2
fi

node "$root/scripts/generate-local-routing.mjs" "$@"
