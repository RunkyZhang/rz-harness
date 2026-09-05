# Temporary State Ledger：<change-id>

> 本地联调 / SIT 自测期间所有临时状态的收口台账。结束前必须清理、转用户负责，或写明保留原因。
> Lifecycle tooling must not automatically create or update this ledger; operators maintain it manually with evidence.

ledger_status: PENDING

| Category | Resource | Owner | Cleanup | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| local-service | `pid`, `port`, `JAR_MTIME`, `HEALTH=UP`, `LOG` | `主 Agent / user` | `<stop command>` | `<pid/port/JAR_MTIME/HEALTH=UP/LOG evidence>` | `OPEN / CLEARED / USER_OWNED / RETAINED / N/A` |
| miniapp-storage | `bd_owner_env_override` | `主 Agent / user` | `wx.removeStorageSync('bd_owner_env_override')` | `OPEN / CLEARED / USER_OWNED / RETAINED / N/A` |
| test-data | `<taskId/qrToken/db row summary>` | `主 Agent / user` | `<cleanup SQL/API or N/A>` | `OPEN / CLEARED / USER_OWNED / RETAINED / N/A` |
| debug-tool | `<vConsole/log flag>` | `主 Agent / user` | `<disable command>` | `OPEN / CLEARED / USER_OWNED / RETAINED / N/A` |

## Notes

- 不记录明文 token、cookie、密码、完整手机号。
- 真实 SIT/UAT/生产写操作必须另走 DB/API 二次确认流程。
