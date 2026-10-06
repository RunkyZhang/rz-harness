#!/usr/bin/env bash
set -euo pipefail

printf '本次 harness 流程和停止点：检测到 main/master，停止业务代码编辑。\n'
printf '需要先切到 codex/<change-id> branch 或 isolated worktree，并 preserve user-owned dirty worktree changes。\n'
