# Agent Candidate Confirmation: <change-id>

> 用途：只在启用 `Backend` / `Frontend` / `Mobile` 等 candidate implementation agent 前填写。该文件不是通用授权书；它只确认本次 change 的具体 agent、业务仓写入边界和禁止动作。

candidate_dispatch_confirmation: PENDING
change_id: <change-id>
allowed_agent_ids: []
business_code_start_gate: PENDING
allowed_paths_confirmed: no
isolated_worktree_required: yes
protected_actions_allowed: no
global_config_write_allowed: no
db_or_release_actions_allowed: no
confirmed_by: -
confirmed_at: -

## 填写要求

- `candidate_dispatch_confirmation` 必须是 `CONFIRMED`。
- `allowed_agent_ids` 只写本次允许派发的 candidate agent，例如 `[Backend]`。
- `business_code_start_gate` 必须是 `PASS`，并在 evidence 中记录已运行的 `gates/business-code-start-gate.sh` 命令。
- `allowed_paths_confirmed` 必须是 `yes`，且对应路径已经写入 `contract.md allowed_paths`。
- `isolated_worktree_required` 必须保持 `yes`；实现 agent 不得写主业务仓工作树。
- `protected_actions_allowed`、`global_config_write_allowed`、`db_or_release_actions_allowed` 必须保持 `no`。

## 证据

| Item | Evidence |
| --- | --- |
| Contract v0.1 | `<path / line / hash>` |
| Allowed paths | `<path list source>` |
| Business code-start gate | `<command + PASS evidence>` |
| Worktree / branch | `<repo id + worktree path + branch>` |
| Stop condition | `触碰 protected/global/DB/release 动作时停止并请求人工确认` |
