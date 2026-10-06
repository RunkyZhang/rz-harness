# SFA Android 打包指导

本文说明 Harness 何时使用 SFA Android 云打包，以及权限和产物边界。

## 何时使用

- Android 代码改动需要生成安装包做真机、SIT 或团队共享验证时使用。
- Harness 需要记录某次 Android 包对应的 commit、variant、构建任务和下载位置时使用。
- 本指导不替代本地 Android Studio / Gradle 编译检查、代码 review、业务契约确认或常规测试。

## 云打包入口

SFA Android 打包入口为阿里云 EMAS DevOps Build：

```text
https://emas.console.aliyun.com/emasService/devTool/devopsBuild/build?ProductId=3909886&AppKey=335500513&AppType=2
```

可在 ignored `config/repos.local.sh` 中保留入口变量，便于本地脚本或人工记录引用：

```bash
export SFA_ANDROID_EMAS_BUILD_URL="https://emas.console.aliyun.com/emasService/devTool/devopsBuild/build?ProductId=3909886&AppKey=335500513&AppType=2"
```

## 权限前置

- 进入链接后，先确认当前阿里云账号能看到并运行目标打包任务。
- 如果页面无权限、无法点击运行、无法选择构建配置、无法查看构建结果或下载产物，停止继续操作，找运维支持开通该链接内的打包运行权限。
- 不要把阿里云账号密码、cookie、访问令牌、短信验证码、临时授权链接或截图中的敏感身份信息写入 Harness 文档、evidence、PR、issue 或 memory。

## 打包记录

每次共享 Android 包时，记录以下信息：

- Android repo commit / branch。
- EMAS 构建任务或构建记录 URL。
- build variant / flavor。
- 构建时间。
- 产物下载位置或分发平台。
- `.apk` / `.aab` 的 SHA-256 checksum。
- 是否需要真机能力验证，例如相机、定位、推送、地图、征信或人脸。

## 产物策略

- 不提交 `.apk`、`.aab`、`.apks` 或本地 Android `build/` 产物。
- 需要留存或共享可用包时，放到阿里云 EMAS、企业分发平台、CI artifact、对象存储或其他团队认可的位置。
- Harness 只记录入口、权限前置、构建元数据和验证证据，不保存运行包本体。
