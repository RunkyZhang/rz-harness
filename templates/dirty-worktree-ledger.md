# Dirty Worktree Ledger：<change-id>

> 业务仓存在本轮开始前 dirty diff 时使用。每个 dirty path 必须说明归属和处理决定，避免覆盖用户工作。

dirty_worktree_status: PENDING

| Path | Owner | Decision | Notes |
| --- | --- | --- | --- |
| `<absolute-or-repo-relative-path>` | `user / codex / generated` | `preserve / edit-with-care / ignore / cleanup` | `<reason>` |
