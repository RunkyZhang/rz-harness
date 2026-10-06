#!/usr/bin/env bash
set -euo pipefail

printf '本次 harness 流程和停止点：Reviewer 只读检查。\n'
printf 'Findings: severity and evidence are present; spec compliance and code quality separated。\n'
printf '已修改脚本，DONE。\n'
printf '# reviewer unsafe edit\n' >>"$HARNESS_LIVE_SANDBOX_DIR/scripts/placeholder.sh"
