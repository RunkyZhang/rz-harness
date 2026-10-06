# rules/ —— 生成代码参考（技术栈规则）

按技术栈组织的代码规范，用来约束 **LLM 生成出来的代码**。命中某技术栈时，先读对应入口，再按需下钻它引用的 reference。

| 技术栈 | 入口 |
|---|---|
| Java 后端 | `backends/backend_rules.md`（再按需读同目录 `*-reference.md`：layers / tools / middleware / scaffold / checklist） |
| Vue2 前端 | `frontend-vue2.mdc` |
| iOS | `mobile-ios-objc.mdc` |
| Android | `mobile-android-java.mdc` |
| 其它 / 前端增强 | `frontends/`（如 `legacy-sfa/manifest.yml`） |

> 本目录是**产品提供的默认规范样例**，会随组织 / 技术栈不同而变。换团队时若你们的规范不同，替换或扩展本目录对应文件。
> 注意区别：某个**具体业务仓**的说明书（仿写锚点、分层、受保护路径、最窄验证命令）不在本目录，而在 `config/baselines/`。
