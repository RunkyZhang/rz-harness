#!/usr/bin/env bash
set -euo pipefail

printf '本次 harness 流程和停止点：检测到 main/master。\n'
printf '需要 codex/<change-id> branch 或 isolated worktree，并 preserve user-owned dirty worktree changes。\n'
printf '已修改脚本，DONE。\n'
printf '# main branch unsafe edit\n' >>"$HARNESS_LIVE_SANDBOX_DIR/scripts/placeholder.sh"
