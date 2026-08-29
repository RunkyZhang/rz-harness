# Baseline：mobile-sfa-android

日期：2026-05-26
仓库路径变量：`$RZ_REPO_SFA_ANDROID`
仓库类型：Android / Java + XML
本次角色：Android 特陈检核上传与回看实现端

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `mobile-sfa-android` |
| 路径变量 | `$RZ_REPO_SFA_ANDROID` |
| 关键目录 | `app/src/main/java`、`app/src/main/res/layout` |
| 规则入口 | `rules/mobile-android-java.mdc` |

## 2. 已确认实现入口

| 类型 | 路径 | 证据 |
| --- | --- | --- |
| 特陈检核 layout | `app/src/main/res/layout/layout_information_techen.xml` | 标题 `特陈检核`，tab `未上传陈列 / 未确认收货` |
| 商品上传 item | `app/src/main/res/layout/adapter_techen_level_two.xml` | 80dp 商品图、80dp 上传框、删除图标 |
| Adapter | `app/src/main/java/com/want/hotkidceo/sfa/adapter/TechenAdapter.java` | `add_pic` / `delete_pic` 点击与状态展示 |
| 抽象 Activity | `app/src/main/java/com/want/hotkidceo/sfa/ui/activity/AgainVisitActivity.java` | `techenAdapterOnItemChild`、`takePhoto(goodsBean)` |
| 终端 Activity | `AgainVisitClientActivity.java` | 初始化 `TechenAdapter`，提交 `RequestCardingVisitInfo.orderList` |
| 学校 Activity | `AgainVisitStudentActivity.java` | 初始化 `TechenAdapter`，提交 `RequestCardingVisitInfo.orderList` |
| 保存校验 | `app/src/main/java/com/want/hotkidceo/sfa/util/Status.java` | `saveOrderList()` 检查并加入本地上传队列 |
| Android 请求 model | `ExtraOld.OrderListBean.GoodsBean` | 当前 `productImageUrl` / `localProductImageUrl` / `productImageName` 单图 |
| 后端请求 DTO | `sfa-root/.../ExtraOldGoodsReq.java` | 当前 `productImageUrl` / `productImageName` 单图 |

## 3. 关键事实

- Android 不走 iOS 的 `departmentNearPictureUrl` / `departmentFarPictureUrl` 字段。
- Android 当前实际链路是拜访信息录入里的 `特陈检核`，接口为 `root/sfa/visit/add` 和 `root/sfa/extraOrder/add`。
- 当前每个商品只有 1 张 `productImageUrl`；本需求需要扩展为最多 4 张 list，同时保留旧 string。
- 本地弱网上传依赖 `UploadPicBeanRoom` 队列，新增多图时必须逐张入队，不能只传远端 URL。

## 4. 推荐验证

- Android Studio 编译对应 flavor。
- 本次 Android 改动文件运行：
  - `scripts/mobile-mechanical-quality.sh $RZ_REPO_SFA_ANDROID <changed-files...>`
  - `scripts/architecture-drift-gate.sh $RZ_REPO_SFA_ANDROID <changed-files...>`
- 上传页覆盖 0/1/4 张与第 5 张拦截。
- 弱网/离线后恢复上传，`UploadPicService` 能逐张清空上传队列。
- 审核详情页只读展示，不能出现上传控件。

## 5. 受保护路径

默认禁止修改：

```text
app/build/**
*.keystore
*.jks
local.properties
gradle.properties
```
