# 注释与日志标准

> 用于约束 Backend Agent、Frontend Agent、Reviewer Agent 和人工 review。正文中文；代码标识、命令、API path、字段名、错误码、日志 key 和引用原文保持原样。

## 依据

- Java 注释规则参考 `docs/standards/java/alibaba-java-review-checklist.md`、Oracle Java Code Conventions、Google Java Style 和 Checkstyle `MissingJavadocMethod`。
- 前端日志规则参考 ESLint `no-console`、`eslint-plugin-vue` 的 `vue/no-console`、Vue 2 官方 Style Guide 和 JSDoc。
- 本标准不要求“每行代码都有注释”。注释用于解释代码本身看不出的目的、业务口径、边界、风险和取舍。

## 总原则

- 注释写 `why` 和业务约束，不重复 `what`。如果注释只是翻译方法名、字段名或代码语句，应改名或重构而不是堆注释。
- 公共契约、跨层入口和复杂业务方法需要文档注释；简单 getter / setter、`@Override`、纯样板 wiring 不强制。
- 方法内部关键逻辑点需要行内或块注释：状态流转、权限口径、幂等、事务边界、异步 / job、外部 RPC 失败、回滚 / 补偿、兼容历史数据、性能取舍。
- 临时调试注释和日志必须在交付前清理；需要保留的 `TODO` / `FIXME` 必须关联 issue、任务号或 change-id，并写清风险。
- 日志记录关键状态和失败原因，不记录手机号、token、证件号、密钥、Cookie、明文密码或完整个人信息。

## 后端 Java

必须写 Javadoc 或等价文档注释：

- 新增 public Controller / API / Facade 方法。
- 新增 public/protected Service、Application、Job、Consumer、Handler 中承载业务规则的方法。
- 新增 DTO / VO / enum 中有业务枚举、状态、权限、金额、时间窗口或兼容口径的字段 / 类型。
- 对已启用 Swagger 2 profile 的仓库，新增 public REST response `*VO.java` 必须使用 `@ApiModel`，并为每个声明的非静态响应字段写 `@ApiModelProperty`；描述必须覆盖状态/枚举、时间格式、聚合口径或兼容语义。导出 Excel 模型和基础设施 DTO 不在该 profile 范围内。
- 新增可复用工具方法、跨模块调用方法、复杂 SQL 对应 mapper 方法。

方法内部必须注释的逻辑点：

- 状态机或状态码转换，尤其是禁止流转、重复提交、自动处理失败、人工覆盖自动结果。
- 权限 / 数据范围判断，尤其是管理端全量可见、owner 范围、组织范围。
- 事务和锁：`FOR UPDATE`、after-commit、分事务记录失败、幂等去重。
- 外部接口失败处理：重试、降级、保留待办、错误落库、回滚策略。
- 历史兼容、临时兜底、性能优化和非直觉查询条件。

日志要求：

- 禁止 `System.out` / `System.err` / `printStackTrace()`；使用项目已有 logger。
- 日志使用占位符，不用字符串拼接。
- catch 块必须恢复、转换、记录或上抛；不能空 catch，也不能吞异常后只返回默认值。
- 同一异常不重复打印多次；入口、业务服务、job 之间选择一个最有排查价值的位置记录。

## 前端 Vue2 / JavaScript

必须写 JSDoc 或等价注释：

- `src/api/*.js` 中新增或变更的导出 API 方法，说明接口用途、关键参数、返回结构或错误/空态。
- 复杂页面方法：提交、保存、审核、状态切换、批量操作、导入导出、分页组合查询。
- 复杂数据映射：后端枚举到 UI 文案 / 颜色 / 按钮权限、时间/金额格式化、兼容旧字段。
- 复用工具函数、跨组件共享方法、临时 route/mock/smoke 入口。

前端日志要求：

- 业务前端代码禁止提交 `console.*`、`debugger` 和临时 `[DEBUG-...]` 标记。
- 用户可见错误使用项目已有 Message / toast / error handler；不要用 console 代替用户反馈。
- 如确需浏览器端埋点或错误上报，必须使用项目已有上报封装，并在 spec/contract 中说明事件名、字段和敏感信息处理。

## Harness 门禁

- Java 后端继续运行 `scripts/java-mechanical-quality.sh`，硬阻断高信号 Java / Mapper XML 问题。
- 前后端实现变更新增 `scripts/code-comment-log-quality.sh` 检查本次 Java / Vue / JS 文件：
  - 硬阻断业务前端 `console.*`、`debugger`、临时 `[DEBUG-...]` 标记。
  - 对缺少 Javadoc / JSDoc 的新增 public/export 方法输出 warning，交 Reviewer 判断是否必须补。
- warning 不能被忽略：必须写入 `changes/<change-id>/evidence.md`，Reviewer 给出 HIGH / MEDIUM / LOW 结论。
- `scripts/swagger-model-documentation-gate.sh` 在 `change-stage-gate.sh ... pre-commit` 中自动执行。它仅检查活跃 profile 覆盖范围内本次新增的 response `*VO.java`，阻断缺失 `@ApiModel` 或 `@ApiModelProperty` 的接口文档遗漏，不追溯历史类。

## Reviewer 检查问题

- 公共入口和复杂方法是否解释了业务目的、参数边界、返回 / 错误 / 空态。
- 关键状态、权限、事务、幂等、异步、回滚逻辑是否有注释说明。
- 注释是否解释业务原因，而不是重复代码。
- 日志是否足够定位失败点，又没有泄露敏感数据或制造重复噪音。
- 是否存在调试遗留：`console.*`、`debugger`、`System.out`、`printStackTrace()`、`[DEBUG-...]`。
