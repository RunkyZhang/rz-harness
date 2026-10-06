# UI Confirmation：<change-id>

> 复杂 PC/H5/UI 变更的人工确认记录。正文默认中文；代码标识、路径、URL、接口名保持原样。

## 判定

| Item | Value |
| --- | --- |
| UI scope | `<页面 / 组件 / route>` |
| Complexity | `complex` / `simple` / `not_applicable` |
| Decision source | `PRD / plan / user confirmation / existing page sample` |
| Status | `PENDING` / `CONFIRMED` / `BLOCKED` / `NOT_APPLICABLE` |
| UI rule pack loaded | `<rules/... or N/A>` |
| PRD UI source | `<screenshot / prototype / URL / N/A>` |
| Online baseline | `<screenshot / route / app page / N/A>` |
| Rule gap status | `NONE / CONFIRMED / BLOCKED / NOT_APPLICABLE` |

复杂 UI 判定参考：

- 新增完整页面或核心业务入口。
- 新增多步骤交互、弹窗编辑、批量操作、导出、复杂表格或状态流转。
- 页面行为受权限、角色、待办、审批、任务状态或跨仓 API 影响。
- 目标用户需要扫描、比较、反复处理数据，布局和交互需要人工确认。

## 参考样板

| Source | Path / URL | Reused part |
| --- | --- | --- |
| Existing page | `<repo path or URL>` | `<layout / table / dialog / actions>` |
| Harness rule pack | `<rules/frontends/...>` | `<component / spacing / interaction>` |
| PRD UI | `<screenshot / prototype>` | `<target state>` |
| Online baseline | `<screenshot / route>` | `<current state>` |

## UI 规范缺口

| Gap | Why rules do not cover it | User decision | Status |
| --- | --- | --- | --- |
| `<unknown interaction / layout / spacing / button position>` | `<reason>` | `<confirmed behavior>` | `CONFIRMED / BLOCKED / N/A` |

要求：

- PRD UI / 交互编码前必须先复制并填写 `templates/ui-rule-checklist.md`。
- 运行 `scripts/ui-rule-gate.sh changes/<change-id>` 通过后，才能开始正式 UI 编码。
- Harness 交互规范没有覆盖的内容，不允许 Agent 自行发挥，必须取得用户确认。

## 确认产物

| Artifact | Path / URL | Notes |
| --- | --- | --- |
| Prototype or runnable page | `<artifacts/<change-id>/... or local URL>` | `<how to open>` |
| Initial screenshot | `<artifact path>` | `<state shown>` |
| Main interaction screenshot | `<artifact path>` | `<state shown>` |

大体积截图、录屏、trace 和临时原型草稿放 `artifacts/<change-id>/` 或外部存储；Git 中只保留路径和摘要。

## 覆盖交互

| Scenario | Covered | Evidence | Notes |
| --- | --- | --- | --- |
| Initial render / default query | `yes/no/blocked` | `<path or note>` |  |
| Core filter / search | `yes/no/blocked` | `<path or note>` |  |
| Detail / edit / dialog | `yes/no/blocked` | `<path or note>` |  |
| Empty / error state | `yes/no/blocked` | `<path or note>` |  |
| Permission / disabled action | `yes/no/blocked` | `<path or note>` |  |

## 人工确认

| Reviewer | Decision | Time | Notes |
| --- | --- | --- | --- |
| `<user / reviewer>` | `CONFIRMED / CHANGE_REQUESTED / BLOCKED` | `<yyyy-MM-dd HH:mm>` | `<summary>` |

## 未覆盖项

| Item | Impact | Follow-up |
| --- | --- | --- |
| `<item>` | `<risk>` | `<next step>` |
