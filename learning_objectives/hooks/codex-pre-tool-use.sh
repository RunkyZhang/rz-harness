#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
exec "$root/scripts/harness-sensor-runner.sh" codex PreToolUse
