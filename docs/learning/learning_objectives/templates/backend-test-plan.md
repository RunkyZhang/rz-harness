# Backend Test Plan：<change-id>

> Java 后端变更的 targeted test 矩阵。正文默认中文；类名、方法名、命令、错误码保持原样。

## 判定

| Item | Value |
| --- | --- |
| Backend scope | `<repo / module / service / job / controller>` |
| Behavior changed | `yes/no` |
| Status | `PENDING` / `PASS` / `BLOCKED` / `NOT_APPLICABLE` |
| Test command | `<mvn -pl ... -Dtest=... test>` |

如果 `Behavior changed = yes`，不能只用 compile 替代 targeted test。确实无法写测试时，必须写明原因、风险和用户是否接受。

## 测试矩阵

| Category | Scenario | Test class / method | Status | Notes |
| --- | --- | --- | --- | --- |
| Validation | `<参数、数量、必填、时间窗口>` | `<TestClass#method>` | `pending/pass/blocked/n/a` |  |
| Permission | `<owner / role / data scope>` | `<TestClass#method>` | `pending/pass/blocked/n/a` |  |
| State transition | `<status old -> new>` | `<TestClass#method>` | `pending/pass/blocked/n/a` |  |
| Idempotency | `<duplicate request / duplicate job>` | `<TestClass#method>` | `pending/pass/blocked/n/a` |  |
| Async / job | `<after commit / scheduled job / MQ>` | `<TestClass#method>` | `pending/pass/blocked/n/a` |  |
| Adapter / RPC failure | `<external service throws / returns failed>` | `<TestClass#method>` | `pending/pass/blocked/n/a` |  |
| Rollback / error persistence | `<transaction rollback / failure status>` | `<TestClass#method>` | `pending/pass/blocked/n/a` |  |
| Mapper / query contract | `<custom SQL / update count>` | `<TestClass#method>` | `pending/pass/blocked/n/a` |  |

## 命令证据

```text
Command: <mvn command>
Repo: <absolute repo path>
Result: PENDING / PASS / FAIL / BLOCKED
Key output:
- <summary>
```

## 未覆盖项

| Item | Reason | Risk | Follow-up / User decision |
| --- | --- | --- | --- |
| `<item>` | `<why not covered>` | `<risk>` | `<next step>` |
