# Frontend Style Profile：<repo-id>

> 用真实仓库代码提炼的仿写锚点。它不是新的设计规范，也不是创新禁令；当画像与当前代码冲突时，以当前仓库代码为准，并记录画像更新任务。

```yaml
style_profile_status: DRAFT
repo_id: <frontend-repo-id>
source_commit: <git-commit>
generated_at: <yyyy-MM-dd>
owner: Orchestrator
```

## Positive Samples

| Scenario | File | Why this is the sample |
| --- | --- | --- |
| list/search page | `<repo/path.vue>` | `<骨架 class、查询、分页、权限、空态等可复用点>` |
| detail page | `<repo/path.vue>` | `<详情布局、按钮区、状态展示等可复用点>` |
| form/dialog | `<repo/path.vue>` | `<表单校验、弹窗、保存反馈等可复用点>` |

## Skeleton / Class Anchors

| UI surface | Existing skeleton / class | Usage rule |
| --- | --- | --- |
| search area | `<class / component>` | `<何时使用>` |
| table/list | `<class / component>` | `<何时使用>` |
| pagination | `<class / component>` | `<何时使用>` |
| action buttons | `<class / component>` | `<何时使用>` |

## API / State Pattern

| Concern | Existing pattern | Do not |
| --- | --- | --- |
| API call | `<src/api/...>` | `<不要在 page 里直接 fetch / request>` |
| loading/error/empty | `<repo pattern>` | `<不要新增不一致状态表达>` |
| route/query | `<repo pattern>` | `<不要硬编码临时入口>` |

## Negative Examples

| Pattern | Why not |
| --- | --- |
| `<反例写法>` | `<原因>` |

## Review Use

Reviewer 的 `style_conformance` 必须引用本 profile 或本次 plan 的 `样板引用` 具体条目；不允许裸写 PASS。
