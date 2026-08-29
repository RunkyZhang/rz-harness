# Baseline：frontend-sfaintl

> 当前不在 `git-registry.md` 工作范围内；仅保留标本 baseline 供对照。路径变量已改为 `RZ_*`，若启用该仓须先补登记表和 `config/runtime_local.sh`。


日期：2026-05-26
仓库路径变量：`$RZ_REPO_SFAINTL`
仓库类型：Vue2 / Element UI 管理后台
本次角色：PC 特陈审核详情旧镜像 / 备用分支

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `frontend-sfaintl` |
| 路径变量 | `$RZ_REPO_SFAINTL` |
| 关键页面 | `src/views/zweat/specialChenAudit/detail.vue` |

## 2. 本需求入口

- `detail.vue` 中 `上传角色` 按 `departmentNearPictureUrl || departmentFarPictureUrl` 判断区域经理行。
- 区域经理近景当前以单图 `<viewer>` + `<img>` 展示。
- 区域经理远景当前以单图 `<viewer>` + `<img>` 展示。

## 3. 实施注意

- 2026-06-04 复核：`SfaIntl` 同页只有 2025-07-15 初版提交，且仍为 120px 大图展示；`mapSystem` 同页持续迭代并已改为 40px 紧凑表格，故本次不作为 PC 主实现仓。
- 若发布清单仍包含 `SfaIntl`，需同步 `mapSystem` 的最小展示 patch；否则只保留为复核对象。
- PC 审核详情页只读展示，不出现上传、删除、已达上限或上传拦截提示。
- 建议抽公共 helper：优先 list，fallback 拆 string，返回图片数组。

## 4. 推荐验证

- 页面本地预览或窄范围 lint。
- 历史单图和新多图 mock 截图。
- 点击预览图片顺序与上传顺序一致。
