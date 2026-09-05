# Miniapp Local Env：<change-id>

> 小程序本地联调环境记录。用于避免 `bd_owner_env_override`、实际请求 host、重新进入小程序和清理步骤只存在聊天里。

```yaml
status: PENDING
env_override_key: bd_owner_env_override
current_value: -
actual_request_host: -
reentered_miniprogram: no
clear_command: wx.removeStorageSync('bd_owner_env_override')
```

## 操作记录

| Step | Evidence | Notes |
| --- | --- | --- |
| 设置本地环境 | `wx.setStorageSync('bd_owner_env_override', 'local')` | 仅本地联调用 |
| 重新进入小程序 | `<screenshot/log>` | 必须重新进入或重新编译 |
| 请求 host 校验 | `<Network host>` | 记录实际命中本地代理或目标环境 |
| 清理命令 | `wx.removeStorageSync('bd_owner_env_override')` | 结束前执行或明确交给用户 |
