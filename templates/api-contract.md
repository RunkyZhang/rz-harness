# API 契约：<change-id>

> 面向人工 review / 用户确认的正文默认中文；API path、field、enum、error code、HTTP method、JSON key 保持原样。

## 基本信息

| Item | Value |
| --- | --- |
| Change | `<change-id>` |
| Frontend repo | `$RZ_REPO_MAP_SYSTEM` |
| Backend repo | `$RZ_REPO_SFA_SALES_MANAGEMENT` |
| Owner | [QUESTION] |
| Backward compatible | [QUESTION] |

## Endpoint

| Method | Path | Purpose | Auth / Permission |
| --- | --- | --- | --- |
| [QUESTION] | [QUESTION] | [QUESTION] | [QUESTION] |

## Request

### Query / Path

| Field | Type | Required | Meaning | Source |
| --- | --- | --- | --- | --- |
| [QUESTION] | [QUESTION] | [QUESTION] | [QUESTION] | [QUESTION] |

### Body

| Field | Type | Required | Meaning | Source |
| --- | --- | --- | --- | --- |
| [QUESTION] | [QUESTION] | [QUESTION] | [QUESTION] | [QUESTION] |

## Response

| Field | Type | Nullable | Meaning | Frontend mapping |
| --- | --- | --- | --- | --- |
| [QUESTION] | [QUESTION] | [QUESTION] | [QUESTION] | [QUESTION] |

## Enum / Status

| Field | Value | Meaning | UI display |
| --- | --- | --- | --- |
| [QUESTION] | [QUESTION] | [QUESTION] | [QUESTION] |

## Error / Empty State

| Scenario | Backend behavior | Frontend behavior |
| --- | --- | --- |
| Empty list | [QUESTION] | [QUESTION] |
| Validation failed | [QUESTION] | [QUESTION] |
| Permission denied | [QUESTION] | [QUESTION] |

## Pagination / Sorting

- Pagination: [QUESTION]
- Default sort: [QUESTION]
- Maximum page size: [QUESTION]

## Compatibility

- [QUESTION] 是否影响已有调用方？
- [QUESTION] 是否新增字段且旧前端可忽略？
- [QUESTION] 是否需要 feature flag 或灰度？

## Data Model Link

如接口依赖新增或变更表结构，填写：

| Item | Value |
| --- | --- |
| Data model doc | `changes/<change-id>/data-model.md` |
| ER diagram included? | [QUESTION] |
| Executable DDL/DML included? | [QUESTION] |
| Field comments self-contained? | [QUESTION] |
| Normalization exceptions justified? | [QUESTION] |
