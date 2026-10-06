# Baseline：mobile-sfa-ios

日期：2026-05-26
仓库路径变量：`$SFA_REPO_MOBILE_SFA_IOS`
仓库类型：iOS / Objective-C
本次角色：特陈线下审核区域经理上传与审核详情展示主端

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `mobile-sfa-ios` |
| 路径变量 | `$SFA_REPO_MOBILE_SFA_IOS` |
| 关键模块 | `FProject/FProject/MakeWang/SpecialDisplay` |
| 规则入口 | `rules/mobile-ios-objc.mdc` |
| UI 规范 | 项目 iOS 颜色、按钮、间距规则以本仓规则和当前 PRD / 参考页为准；归档 rules 不默认启用 |

## 2. 本需求入口

| 类型 | 路径 | 证据 |
| --- | --- | --- |
| 详情 Controller | `SFASpecialDisplayDetailController.m` | 上传路径 `/sfa/root/display/departmentUploadPic` |
| model | `models/SFASpecialDisplayDetailModel.h` | 区域经理 string 字段、现场稽核 list 字段 |
| 审核展示 | `views/detailVerifyViews/**` | 近/远景展示混合合伙人、区域经理、现场稽核 |

## 3. 关键事实

- 当前区域经理上传提交 `departmentNearPictureUrl` / `departmentFarPictureUrl`。
- 当前现场稽核上传提交 `checkNearPictureUrlList` / `checkFarPictureUrlList`。
- 本需求应给区域经理补 list 字段；最新 PRD revision 54 上限为 4。
- 审核详情页只读展示，不出现上传、删除、已达上限或上传拦截提示。

## 4. 推荐验证

- Xcode 编译 SpecialDisplay 所属 target。
- 本次 iOS 改动文件运行：
  - `scripts/mobile-mechanical-quality.sh $SFA_REPO_MOBILE_SFA_IOS <changed-files...>`
  - `scripts/architecture-drift-gate.sh $SFA_REPO_MOBILE_SFA_IOS <changed-files...>`
- mock 或测试环境覆盖：
  - 历史单图展示。
  - 近景/远景各 4 张上传。
  - 第 5 张上传页拦截。
  - 审核详情点击预览。

## 5. 受保护路径

默认禁止修改：

```text
Pods/**
*.xcodeproj/project.pbxproj
*.xcworkspace/**
Fastlane/**
```

如确需改工程文件，必须在 spec 中显式写入 allowed paths 并由人工 review。
