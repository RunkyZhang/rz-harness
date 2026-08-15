# Legacy SFA Frontend Rule Pack

这个目录保存用户提供的“大前端 rules”，用于约束旧 SFA 前端系统。

## Activation Model

规则包不作为全局通用规则自动应用，必须由 repo profile 或 lane 显式启用。

| Profile | Status | Applies To | Rules |
| --- | --- | --- | --- |
| `legacy-sfa-web` | active | `frontend-map-system` / `mapSystem` | `web/*.mdc` |
| `legacy-sfa-ios-archive` | archived | none by default | `ios-archive/*.mdc` |
| `legacy-sfa-android-archive` | archived | none by default | `android-archive/*.mdc` |

## Rules

- `web/` 是当前默认可用的旧 SFA Web 规则包，适用于 Vue2 + Element UI 管理后台。
- `ios-archive/` 和 `android-archive/` 只是归档材料。没有新的 App lane、repo registry 和用户确认前，不得用它们约束 Web 需求。
- 所有导入的 `.mdc` 文件都保持 `alwaysApply: false`。是否加载由 `manifest.yml`、`docs/architecture/repo-registry.md` 和具体 lane 决定。

## Usage

当前只有 `frontend-map-system` 默认启用 `legacy-sfa-web`。Frontend Agent 修改 `mapSystem` 页面前，应读取：

1. `rules/frontend-vue2.mdc`
2. `rules/frontends/legacy-sfa/manifest.yml`
3. `rules/frontends/legacy-sfa/web/*.mdc`
4. 当前 change 的 `spec.md`、`plan.md` 和 API contract

如果用户指定了截图、URL 或现有页面路径，用户指定参考页优先于本规则包里的默认样板。
