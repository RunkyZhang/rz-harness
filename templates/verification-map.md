# Verification Map：<change-id>

> 用途：把关键业务约束、契约、DB、权限、状态、UI、发布和回滚要求映射到可执行验证、人工确认或明确 N/A 原因。Tier M/L 进入业务代码前必须填写。

```yaml
verification_map_status: PENDING
owner: -
updated_at: -
```

`verification_map_status` 可选值：

- `PENDING`：仍有约束未映射验证方式。
- `READY`：每条关键约束已有验证命令、人工确认、证据目标或 N/A 原因，可运行 `gates/verification-map-gate.sh`。
- `BLOCKED`：验证方式缺失或前置条件缺失，不能进入下一阶段。

## Verification runner 约定

`Verification` 列兼容人工描述，但需要被 `scripts/verification-run.sh` 自动执行或判定时，必须显式写 runner: shell/manual/N/A。

- `shell: <command>`：从 harness repo root 执行命令；脚本会设置 `HARNESS_CHANGE_DIR`、`HARNESS_VERIFICATION_ID`、`HARNESS_VERIFICATION_REPORT`。
- `manual: <criteria>`：人工验收项；`scripts/verification-run.sh` 只接受 `Status=PASS`，否则失败。
- `N/A`：不适用项；`Status=N/A` 且 `Evidence` 以 `N/A:` 写明原因。

运行命令：

```bash
scripts/verification-run.sh changes/<change-id>
```

运行后默认生成 `changes/<change-id>/verification-run-report.md`。

## 验证映射

| ID | Constraint | Source | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| VM-001 | `<关键约束，例如：用户只能看到所属组织数据>` | `PRD / 用户确认 / contract / 现有代码` | `shell: <命令、测试、只读 SQL wrapper 或 PC smoke>` | `<evidence 路径、报告章节或 N/A: 原因>` | `PLANNED / PASS / N/A` |
| VM-002 | `<人工视觉/真机/评审约束>` | `PRD / 用户确认` | `manual: <人工判定标准>` | `<evidence 路径>` | `PLANNED / PASS` |
| VM-003 | `<明确不适用约束>` | `PRD / 用户确认` | `N/A` | `N/A: <原因>` | `N/A` |

## 填写规则

- `Constraint` 写“什么叫做对”，不要写实现步骤。
- `Source` 必须能追溯到 PRD、用户确认、contract、现有代码或已确认技术方案。
- `Verification` 优先写 `shell: <command>`；无法自动验证时写 `manual: <criteria>`；不适用时写 `N/A`。
- `Evidence` 写未来或已存在的 evidence/report 位置；`Status` 为 `N/A` 时必须以 `N/A:` 开头写明原因。
- 不得留下 `TODO` / `TBD` / `待补` / `未定`；不得有 `BLOCKED` 行通过 gate。

## Gate

```bash
gates/verification-map-gate.sh changes/<change-id>
scripts/verification-run.sh changes/<change-id>
```
