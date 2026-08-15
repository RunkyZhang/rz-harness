#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
exec "$root/tools/ios-pack/sfa-ios-pack.sh" "$@"
