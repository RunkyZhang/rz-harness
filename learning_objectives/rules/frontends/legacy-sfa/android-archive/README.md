# SFA Android 项目 Cursor Rules

> Archive note: this directory is preserved as legacy reference material only. The harness does not auto-apply these Android rules unless a future App lane and repo profile explicitly enable them.

本目录包含了 SFA Android 项目的 Cursor AI 规则集，用于指导代码开发和维护。

## 规则文件说明

### 🎯 核心规则
- **[project-overview.mdc](project-overview.mdc)** - 项目总体概览和基础规则（自动应用）
- **[architecture.mdc](architecture.mdc)** - MVP/MVVM 架构规范和最佳实践

### 🔧 技术规则
- **[kotlin-guidelines.mdc](kotlin-guidelines.mdc)** - Kotlin 编码规范（`.kt` 文件自动应用）
- **[android-ui.mdc](android-ui.mdc)** - UI 开发和语义化设计规范
- **[networking-data.mdc](networking-data.mdc)** - 网络请求和数据处理规范

### 📝 质量规则
- **[code-quality.mdc](code-quality.mdc)** - 代码质量和最佳实践
- **[testing.mdc](testing.mdc)** - 测试代码规范（测试文件自动应用）

## 规则应用方式

### 自动应用规则
以下规则会自动应用到所有相关文件：
- `project-overview.mdc` - 所有文件
- `kotlin-guidelines.mdc` - 所有 `.kt` 文件
- `testing.mdc` - 所有测试文件

### 手动应用规则
其他规则需要通过描述手动调用，例如：
- 询问架构问题时会自动引用 `architecture.mdc`
- UI 开发时会参考 `android-ui.mdc`
- 网络开发时会参考 `networking-data.mdc`

## 快速参考

### 常用语义化令牌
```xml
<!-- 颜色 -->
android:textColor="@color/color_text_primary"
android:background="@color/color_bg_section"

<!-- 尺寸 -->
android:layout_width="@dimen/icon_size_md"
app:cardCornerRadius="@dimen/radius_sm"
```

### 架构选择
- **现有功能**: 继续使用 MVP 架构
- **新功能**: 优先使用 MVVM 架构

### API 兼容性
```kotlin
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
    // API 21+ 代码
} else {
    // API 19-20 兼容代码
}
```

## 更新规则

当项目需求或规范发生变化时，请更新对应的规则文件，确保团队开发的一致性。

### 规则文件格式
```markdown
---
 alwaysApply: false # 在本 harness 归档目录中不自动应用
# 或
globs: *.kt,*.java  # 应用到特定文件类型
# 或
description: "规则描述"  # 手动调用规则
---

# 规则内容
规则的具体内容使用 Markdown 格式编写...
```

## 贡献指南

1. 修改规则前请与团队讨论
2. 确保规则内容清晰、可执行
3. 提供具体的代码示例
4. 更新本 README 文件的相关说明
