# 特陈陈列照片多图人工验证方案

日期：2026-06-05

边界说明：用户已确认 `oversea` 是海外版本，本验证方案只采用国内版 `want-sfa/sfa-android` 和 `want-sfa/sfa-ios`。此前来自 `sfa-oversea-android` 的截图、入口或 UI 判断全部作废。

## 1. 本次人工验证目标

验证最新 harness 下“特陈线下审核阶段，区域经理在每个陈列明细下可分别上传最多 4 张近景图、最多 4 张远景图；审核查看端完整展示历史单图和新增多图”的三端表现。

本次人工验证拆成两类：

- 上传端验证：Android / iOS App 中区域经理上传近景、远景照片，验证最多 4 张、预览、删除、超限提示、提交。
- 查看端验证：Web 审核详情展示历史单图和新增多图，验证数量角标、首图、预览列表。

## 2. 当前启动状态

| 端/服务 | 状态 | 人工验证入口 |
| --- | --- | --- |
| sfa-backend | 已启动，健康检查 UP | `http://127.0.0.1:9171` |
| sfa-root | 已重启，健康检查 UP；本地健康检查关闭了 Redis/Rabbit 外部依赖探针 | `http://127.0.0.1:9170` |
| Web 本地代理 | 已启动；人工验收代理脚本为 `Harness/changes/special-display-department-photo-list/manual-pc-proxy.mjs` | `http://127.0.0.1:9180` |
| Web 前端 | 已启动 | `http://127.0.0.1:9528/sfamap/manual-auth-special-display.html?id=298&empId=5750` |
| Android | 已启动模拟器，已安装 debug APK；debug-only 特陈验收入口已自动展开到商品行 | AVD：`emulator-5554`；见第 4 节 |
| iOS | Simulator 已 boot；App 无法安装 | 见第 6 节阻塞说明 |

Web 当前使用本地后端样例单据：

- `displayInfoId=298`
- `empId=5750`
- 当前状态：`区域经理审核中`
- 当前明细 `id=322` 已有区域经理近景 4 张、远景 4 张数据，可用于 Web 展示验收。

## 3. Web 人工验证步骤

### 3.1 打开页面

优先打开本地人工验收登录态初始化页：

```text
http://127.0.0.1:9528/sfamap/manual-auth-special-display.html?id=298&empId=5750
```

该页面会写入本地 cookie `vue_admin_template_token` 和 `localStorage.loginForm=5750`，然后自动跳转：

```text
http://127.0.0.1:9528/sfamap/SpecialChenDetail?id=298
```

注意：不要直接刷新或直接打开上面的详情路由。当前 dev server 没有对 history 子路由做 fallback，直接请求该地址会返回 404；必须从 `manual-auth-special-display.html` 进入。

如果仍然停在登录页或白屏，不需要人工操作浏览器 Console；让 Codex 重新检查 `9528` 前端、`9180` 人工代理和 `9171` 后端即可。

### 3.1.1 登录页问题处理记录

2026-06-05 人工打开 Web 时曾停在 `/sfamap/login?...`。定位过程如下：

- 前端 `app.js` 已确认指向 `http://localhost:9180/`，说明 Web dev server 配置正确。
- 初始 `9180` 临时代理返回 `Access-Control-Allow-Origin: *`，但前端 axios 开启了 `withCredentials: true`，浏览器会拦截带凭证请求，导致菜单加载失败并回到登录页。
- 将人工代理固化为 `manual-pc-proxy.mjs` 后，OPTIONS 和 GET 均返回 `Access-Control-Allow-Credentials: true`，并回显本地 origin。
- 页面继续空表时，发现前端会带 `businessGroup: SFA` 转发到本地 backend；该 header 会让本地 `/display/auditDetails/298/5750` 返回 `code=-1`。人工代理已在转发到 `9171` 时剥离 `businessGroup`，保留页面本地身份态但不污染后端详情接口。

最新复测结果：

- 路由：`/SpecialChenDetail`。
- 页面标题：`特陈审核详情 - mapSystem`。
- DOM 包含：`特陈信息`、`陈列近景照片`、`陈列远景照片`、`区域经理`。
- 当前明细 `id=322`：`departmentNearPictureUrlList.length=4`、`departmentFarPictureUrlList.length=4`。
- 页面数量角标包含 4 个 `4`。
- 截图证据：`Harness/changes/special-display-department-photo-list/evidence/pc-manual-special-display-detail-298-20260605.png`。

PC 图片列间距复测补充：

- 用户反馈：`陈列近景照片 / 陈列远景照片` 列中，上下两张缩略图过于贴合。
- 纠偏：上一版用 `.display-picture-item { height: 120px; }` 按上传角色行高撑开图片，导致图片本体间距达到 `80px`，与 PRD 交互图相比过大。
- 最终修正：移除顶层 `.partner_item` 行高修正，`.display-picture-item` 恢复为 `40px` 缩略图容器，仅用 `.display-picture-item + .display-picture-item { margin-top: 24px; }` 控制上下两张图片之间的明确间距。
- 接口复测：`9171 /display/auditDetails/298/5750` 与 `9180 /sfa/backend/display/auditDetails/298/5750` 均返回 `code=0`；明细 `322` 的 `departmentNearPictureUrlList.length=4`、`departmentFarPictureUrlList.length=4`，旧 string 拆分数量也均为 4。
- DOM 复测：`display-picture-item.height=40px`，第二张图 `marginTop=24px`，近景/远景上下两张图片本体间距均为 `24px`；角标仍为 `1` 和 `4`；预览列表长度仍为 `1` 和 `4`。
- Computer Use 视觉结论：Chrome 真实页面对比 PRD 交互图后，近景/远景两列上下图片已分离展示，未贴合，且不再出现 `80px` 大空白。
- 截图证据：
  - PRD 参考：`Harness/changes/special-display-department-photo-list/evidence/pc-prd-reference-computer-use-20260605.png`
  - 本地页面：`Harness/changes/special-display-department-photo-list/evidence/pc-local-photo-columns-computer-use-20260605.png`
  - 历史 CDP 截图：`Harness/changes/special-display-department-photo-list/evidence/pc-cdp-photo-columns-24px-20260605.png`
- 量化证据：`Harness/changes/special-display-department-photo-list/evidence/pc-photo-spacing-computer-use-20260605.json`。

### 3.2 Web 必验点

1. 页面进入 `特陈信息` 区域，存在审核 tab，例如历史审核和当前审核。
2. 当前单据状态展示为 `区域经理审核中`。
3. 陈列明细表存在 `陈列近景照片`、`陈列远景照片` 两列。
4. 对明细 `端架陈列`：
   - 合伙人/历史单图仍显示 1 张图。
   - 区域经理近景照片显示首图，右上角数量角标为 `4`。
   - 区域经理远景照片显示首图，右上角数量角标为 `4`。
5. 点击区域经理近景图，预览列表应包含 4 张。
6. 点击区域经理远景图，预览列表应包含 4 张。
7. 图片为空的历史/稽核字段不应出现错误占位或控制台异常。

### 3.3 Web 截图留存

至少留存 3 张图：

- 页面整体截图：包含 `特陈信息`、审核 tab、状态。
- 近景列截图：能看到数量角标 `4`。
- 远景列截图：能看到数量角标 `4`。

## 4. Android 人工验证步骤

### 4.1 当前环境

Android 模拟器已打开，App 已安装并启动到 debug-only 特陈验收入口。当前页面可见：

- 标题：`录入拜访信息`
- 区域：`特殊检核`
- tab：`未上传陈列 / 未确认收货`
- 订单号：`DEBUG-SPECIAL-DISPLAY-001`
- 商品：`特陈多图验收商品`
- 商品图：首图展示，右下角蓝色角标 `4`

该入口只存在于 debug build，用于在当前测试账号没有可下钻特陈单据时验证真实 `AgainVisitClientActivity + TechenAdapter + ExtraOld.GoodsBean` 渲染链路；release 入口不受影响。

启动方式：

```bash
JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-1.8.jdk/Contents/Home \
GRADLE_OPTS='-Djava.library.path=/Library/Java/JavaVirtualMachines/jdk-1.8.jdk/Contents/Home/jre/lib' \
./gradlew :app:assemble_debugDebug
/Users/scofy/Library/Android/sdk/platform-tools/adb install -r app/build/outputs/apk/_debug/debug/SFA_v2.0.1_debug_debug.apk
/Users/scofy/Library/Android/sdk/platform-tools/adb shell am start -W \
  -a com.want.hotkidceo.sfa.DEBUG_SPECIAL_DISPLAY \
  --ez debugSpecialDisplayHarness true \
  com.want.hotkidceo.sfa
```

自动化验收结果：

- 构建：`:app:assemble_debugDebug`，`BUILD SUCCESSFUL in 3m 15s`。
- JVM 单测：`:app:test_debugDebugUnitTest --tests com.want.hotkidceo.sfa.bean.response.ExtraOldGoodsBeanTest`，`BUILD SUCCESSFUL in 3m 25s`；测试 XML 显示 `tests="4" skipped="0" failures="0" errors="0"`。
- APK 安装：`adb install -r app/build/outputs/apk/_debug/debug/SFA_v2.0.1_debug_debug.apk` 返回 `Success`。
- 调试入口启动：`adb shell am start ... com.want.hotkidceo.sfa.DEBUG_SPECIAL_DISPLAY` 返回 `Status: ok`，Activity 为 `AgainVisitClientActivity`。
- UI XML：`pic_count` 节点文本为 `4`，商品名、规格、订单号均可见。
- 预览 XML：点击缩略图后进入 `PictureExternalPreviewActivity`，标题 `picture_title` 为 `1/4`。
- 截图证据：`Harness/changes/special-display-department-photo-list/evidence/android/android-domestic-debug-special-display-clean-20260605.png`。
- 结构化证据：`Harness/changes/special-display-department-photo-list/evidence/android/android-domestic-debug-special-display-clean-20260605.xml`。

### 4.2 上传端路径

真实业务账号人工路径仍保留如下，用于测试环境准备真实单据后做最终业务闭环：

1. 点击底部 `客户管理`。
2. 找到特陈相关入口或待处理特陈单据。
3. 进入区域经理线下审核/上传照片页面。
4. 在任意陈列明细下分别操作 `陈列近景照片` 和 `陈列远景照片`。

本轮实际测试账号进入 `客户管理 / 未上传特陈` 时列表为空，因此没有用真实测试单据完成“拍照上传第 1-4 张、第 5 张 toast、提交后回显”的人工闭环；上面的 debug-only 入口用于补足真实页面渲染和 4 图角标验收。

### 4.3 Android 必验点

1. 初始无图或已有图时，近景、远景区域布局不变，不出现遮挡。
2. 近景连续上传 1、2、3、4 张：
   - 每张都展示缩略图。
   - 数量或状态正确刷新。
   - 可点击预览。
3. 上传第 5 张近景：
   - 不允许新增。
   - 出现“最多上传4张照片”或等价超限提示。
4. 远景重复同样步骤，最多 4 张，第 5 张被拦截。
5. 删除其中 1 张后，可重新补 1 张，最终仍最多 4 张。
6. 提交审核后，后端保存成功；重新进入页面仍能看到近景最多 4 张、远景最多 4 张。

### 4.4 Android 截图留存

当前已留存：

- debug 页面自动展开 clean 截图：`Harness/changes/special-display-department-photo-list/evidence/android/android-domestic-debug-special-display-clean-20260605.png`
- clean UI XML：`Harness/changes/special-display-department-photo-list/evidence/android/android-domestic-debug-special-display-clean-20260605.xml`
- 点击缩略图后 Activity 栈进入 `com.luck.picture.lib.PictureExternalPreviewActivity`；截图：`Harness/changes/special-display-department-photo-list/evidence/android/android-domestic-debug-special-display-preview-20260605.png`
- 预览 UI XML：`Harness/changes/special-display-department-photo-list/evidence/android/android-domestic-debug-special-display-preview-20260605.xml`

真实业务单据人工验收时至少再留存 5 张图：

- 首页截图，证明 App 已启动。
- 近景 4 张截图。
- 近景第 5 张超限提示截图。
- 远景 4 张截图。
- 提交后重新进入详情的回显截图。

## 5. 端到端联动验证

完成 Android 上传后，回到 Web：

1. 重新打开或刷新 `http://127.0.0.1:9528/sfamap/SpecialChenDetail?id=298`，或打开 Android 实际提交后的对应单据 id。
2. 检查该陈列明细的区域经理近景/远景照片数量。
3. 确认 Web 首图展示、数量角标、预览列表均与 Android 提交数量一致。
4. 如果 Android 提交的是测试环境真实单据，而 Web 当前本地样例不是同一单据，需要把 Web URL 中 `id=298` 替换成实际单据 id，并确保本地代理/后端能访问该单据。

## 6. iOS 当前阻塞与解除路径

iOS 已按国内版真实实现路径往前推进；当前阻塞不是“未找到入口”，而是本机模拟器安装/三方库架构问题。

iOS 国内版入口证据：

1. `AppDelegate` 登录后按业务组/岗位选择首页；普通旺旺业务进入 `SFAMakeWangTabbarController`。
2. `SFAMakeWangTabbarController` 底部 tab 为 `过程 / 结果 / 消息 / 客户 / 我的`，与用户提供的真实 iPhone 首页截图一致。
3. 待办消息、我的工具、日历事件均可进入特陈审核列表，最终进入 `SFASpecialDisplayListController` 和 `SFASpecialDisplayDetailController`。
4. 本次 iOS 实现沿用 `SFASpecialDisplayDetailController`、`SFASpecialDisplayDetailModel`、`SFAAddMoreImageView`、`SFASDDetailDisplayImageArrayView` 等国内版特陈详情链路。

iOS 已完成以下准备尝试：

1. 已 boot `iPhone 17` Simulator，runtime 为 iOS 26.5。
2. Rosetta 服务已运行；2026-06-05 复跑 x86_64/Rosetta 构建主工程成功，但安装失败：
   - 失败原因：当前 iOS 26.5 Simulator 只接受 arm64 simulator App，x86_64 App 安装时报 `Failed to find matching arch`。
3. 2026-06-05 复跑 `iphoneos` 真机架构泛构建成功：
   - 命令：`xcodebuild -workspace FProject/FProject.xcworkspace -scheme FProject -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=''`
   - 结果：`** BUILD SUCCEEDED **`；产物为 `Mach-O 64-bit executable arm64`。
   - 含义：iOS 国内版实现路径不是停在入口识别，已经推进到真机架构可编译；但本机没有真实 iPhone，不能继续做 UI 上传验证。
4. arm64 simulator 构建 Pods 通过，但主工程链接失败：
   - 失败原因：`AMapFoundationKit.framework` 的 arm64 slice 是 iOS 真机库，不是 iOS Simulator 库，链接器报 `built for 'iOS'`。
5. 本机只安装了 iOS 26.5 runtime，没有可用旧 runtime，也没有已连接真机。
6. 本地 Pods 锁定版本：`AMapFoundation 1.8.2`，本地未发现 AMap `.xcframework`；当前官方高德下载页显示基础 SDK 已到 V1.9.0、地图 SDK 已到 V11.2.000，但是否能替换到本项目仍需单独升级验证。
7. 2026-06-06 继续验证 CocoaPods 升级路径后确认：仅升级官方 AMap Pod 不足以解决当前模拟器问题。最新 `AMapFoundation 1.8.7` podspec 仍设置 `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64`，下载包仍是 `.framework`；arm64 切片经 `otool` 检查为 `LC_VERSION_MIN_IPHONEOS`，不是 simulator arm64。详见 `Harness/changes/special-display-department-photo-list/ios-amap-simulator-arm64-investigation-20260606.md`。

因此 iOS 目前不能交付人工验证入口。可解除路径：

- 方案 A：连接一台真实 iPhone，用真机 Debug 安装验证。
- 方案 B：拿到团队或高德提供的 `AMapFoundationKit / MAMapKit / AMapLocationKit / AMapSearchKit` simulator arm64 `.xcframework`，替换当前 `.framework` 后再用 arm64 Simulator 构建。单纯 `pod update` 官方 AMap Pod 已验证不够。
- 方案 C：安装团队已验证可运行 x86_64/Rosetta App 的旧版 Xcode + 旧 iOS Simulator runtime，再安装 x86_64 构建产物。
- 方案 D：仅为 Debug Simulator 增加 AMap test stub，跳过真实地图/定位能力，专门解锁特陈页面 UI 验证；该方案不能作为地图/定位验收证据。

## 7. 验收结论填写模板

| 验证项 | 结果 | 证据 |
| --- | --- | --- |
| Web 近景 4 张展示 | 待填 | 截图路径/备注 |
| Web 远景 4 张展示 | 待填 | 截图路径/备注 |
| Android 商品图 4 张角标展示 | 通过 | `android-domestic-debug-special-display-clean-20260605.png/xml` |
| Android 点击缩略图进入预览 Activity | 通过 | `PictureExternalPreviewActivity` Activity 栈记录；`android-domestic-debug-special-display-preview-20260605.png/xml`，预览标题 `1/4` |
| Android 近景/远景真实业务上传最多 4 张 | 待真实单据复测 | 当前测试账号无可下钻特陈单据 |
| Android 删除后可补图 | 待填 | 截图路径/备注 |
| Android 提交后 Web 回显一致 | 待填 | 截图路径/备注 |
| iOS 上传验证 | 阻塞 | 国内版入口已确认，x86_64 simulator build 通过，`iphoneos` arm64 泛构建通过；本机缺真机，iOS 26.5 Simulator 不接受 x86_64 App，arm64 simulator 被旧 AMap 真机切片阻塞 |

## 8. 目前服务停止方式

人工验证结束后再停止：

- 关闭 Android Emulator 窗口即可停止 Android 模拟器。
- Web 前端、Web 代理、sfa-root、sfa-backend 是当前 Codex 会话中启动的长运行进程；需要停止时告诉我，我会统一收掉。
