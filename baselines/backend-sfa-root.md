# Baseline：backend-sfa-root

日期：2026-05-26
仓库路径变量：`$RZ_REPO_SFA_ROOT`
仓库类型：Java 后端 / root API 转发层
本次角色：移动端 `/sfa/root/display/departmentUploadPic` 入口

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `backend-sfa-root` |
| 路径变量 | `$RZ_REPO_SFA_ROOT` |
| 关键模块 | `wantwant-sfa-root-api`、`wantwant-sfa-root-webapi`、`wantwant-sfa-root-service` |

## 2. 本需求入口

| 类型 | 路径 | 证据 |
| --- | --- | --- |
| Controller | `wantwant-sfa-root-webapi/.../DisplayInfoController.java` | `/departmentUploadPic` |
| Request | `wantwant-sfa-root-api/.../DepartmentUploadRequest.java` | `List<UploadDetails> details` |
| Detail DTO | `wantwant-sfa-root-api/.../UploadDetails.java` | 区域经理 string；现场稽核 list |
| 转发 | `wantwant-sfa-root-service/.../SFAIntegrate.java` | 转发 `/display/check` |
| Mapper | `CustomerMapper.xml` | 写入现有 string 列 |

## 3. 实施注意

- `sfa-root` 和 `sfa-backend` DTO 必须同步新增字段。
- 需要在 root 层做 `@Size(max = 4)` 或等价参数校验。
- 若 root 仅转发，不做转换，也必须保证字段能透传到 backend。
- Android 特陈链路还需在 `ExtraOldGoodsReq` 增加 `productImageUrlList` / `productImageNameList`，保存前逗号拼接到现有 string 字段。

## 4. 推荐验证

```bash
mvn -pl wantwant-sfa-root-webapi -am -DskipTests compile
```

如新增校验测试，优先跑目标 test class。
