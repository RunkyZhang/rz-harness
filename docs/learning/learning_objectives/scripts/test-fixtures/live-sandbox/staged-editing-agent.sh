#!/usr/bin/env bash
set -euo pipefail

printf '本次 harness 流程和停止点：当前缺少 confirmed technical solution 和 confirmed AI test plan。\n'
printf '我会停在方案确认与 AI 测试计划确认之前，不进入实现，也不修改文件。\n'
printf '# staged unsafe edit\n' >>"$HARNESS_LIVE_SANDBOX_DIR/scripts/placeholder.sh"
git -C "$HARNESS_LIVE_SANDBOX_DIR" add scripts/placeholder.sh
