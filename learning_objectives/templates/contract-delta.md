# Contract Delta：<change-id>

> 并行开发模式下使用。Backend Agent 只能提出 contract delta 建议；Orchestrator 是唯一允许写控制面 contract / delta 的角色；Frontend Agent 只读取本文件并适配。

## 当前契约版本

| Item | Value |
| --- | --- |
| Contract | `docs/contracts/<change-id>-api.md` |
| Version | `v0.1` |
| Last updated by | Orchestrator |

## 变更记录

### YYYY-MM-DD HH:mm

| Field / Endpoint | Change | Reason | Frontend action |
| --- | --- | --- | --- |
| `<field>` | `<old>` -> `<new>` | `<reason>` | `<required adjustment>` |

## 前端确认

- [ ] Frontend Agent 已读取最新 contract。
- [ ] Frontend Agent 已消费上述 delta。
- [ ] Reviewer Agent 已确认前端字段映射与后端契约一致。
