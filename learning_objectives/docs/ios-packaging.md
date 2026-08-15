# SFA iOS 打包工具

本文说明 Harness 何时使用 SFA iOS 打包工具，以及打包产物和签名信息的边界。

## 何时使用

- iOS 代码改动需要真机或 SIT 验证时，使用本工具从本地 `mobile-sfa-ios` 仓生成可安装 `.ipa`。
- Harness 需要可复现的 SFA iOS pak/package 时，使用本工具记录 commit、时间、导出方式和 checksum。
- 本工具不替代模拟器编译检查、代码 review、业务契约确认或常规测试。

## 基本命令

```bash
scripts/sfa-ios-pack.sh --check
scripts/sfa-ios-pack.sh --configuration Debug --method Development --upload none --notes "SIT validation"
```

如需上传蒲公英，只在本地 shell 或 ignored `config/repos.local.sh` 中提供凭据：

```bash
PGYER_U_KEY=... PGYER_API_KEY=... scripts/sfa-ios-pack.sh --upload pgyer --notes "SIT validation"
```

## 本地配置

`config/repos.local.sh` 至少需要配置：

```bash
export SFA_REPO_MOBILE_SFA_IOS="/path/to/want-sfa/sfa-ios"
```

可选签名配置只能放在本地环境或 ignored 配置中：

```bash
export SFA_IOS_DEVELOPMENT_TEAM="..."
export SFA_IOS_CODE_SIGN_IDENTITY="..."
export SFA_IOS_PROVISIONING_PROFILE="..."
export SFA_IOS_BUNDLE_ID="..."
```

开发签名验证必须找 `sfaios` 项目对应同事陈正文确认。只要签名 identity、provisioning profile、设备注册、证书权限或 Apple developer account 权限不清楚，就停止修改签名配置，先找陈正文确认。

## 产物策略

- 不提交 `.ipa`、`.xcarchive`、`Packaging.log`、`.DS_Store` 或 `AutoPacking/build/**`。
- 本工具默认输出到 `artifacts/ios-pack/<timestamp>/`，该目录已被 Harness `.gitignore` 忽略。
- 需要留存或共享可用包时，放到 Pgyer、TestFlight、GitHub Release、CI artifact 或对象存储。
- 共享产物时记录对应 commit、timestamp、export method、`.ipa` 路径或下载地址，以及 SHA-256 checksum。

## 和旧 AutoPacking 的关系

旧 `sfa-ios/FProject/AutoPacking` 目录只作为本地参考，不作为 Harness 上传内容。Harness 只维护可复现打包脚本、文档和本地配置说明，不上传历史打包产物或明文凭据。
