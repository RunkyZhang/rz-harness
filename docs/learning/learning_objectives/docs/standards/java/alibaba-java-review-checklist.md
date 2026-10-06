# 阿里 Java 规范 Review 清单

> 用于 Backend Agent 自查、Reviewer Agent 审查和人工 review。规则来源为 `alibaba-java-songshan-fulltext.txt`。本清单不是替代原文，而是把原文转成 SFA harness 可执行检查点。

## 结论规则

- `[MACHINE]` 由脚本或编译硬阻断。
- `[REVIEW]` 由 Backend Agent 和 Reviewer Agent 逐项审查。
- `[HUMAN]` 由用户或人工 reviewer 最终确认。
- 任一 HIGH / MEDIUM 风险未处理，不得进入 PR 或人工验收。

## 编程规约

- `[MACHINE]` 不得出现 `System.out`、`System.err`、`printStackTrace()`。
- `[REVIEW]` 类名、方法名、字段名、常量名符合 Java 习惯，不使用中文命名，不使用拼音与英文混用。
- `[REVIEW]` 常量有明确命名和边界，不把魔法值散落在业务逻辑中。
- `[REVIEW]` 新增代码风格跟随所在模块，不为局部改动引入大范围格式化。
- `[REVIEW]` 集合、字符串、日期、金额、布尔值处理有空值和边界判断。
- `[REVIEW]` `equals`、包装类型比较、`BigDecimal` 比较、日期时间转换不引入常见 Java 语义错误。
- `[REVIEW]` 循环、分支和条件表达式可读，不把复杂业务条件压缩成难审查的一行。
- `[REVIEW]` public/complex 方法有 Javadoc 或等价文档注释；简单 getter / setter、`@Override` 和纯样板 wiring 可豁免。
- `[REVIEW]` 关键状态、权限、事务、幂等、异步、回滚、兼容和性能取舍有必要注释；注释解释业务原因，不重复代码。

## 异常与日志

- `[MACHINE]` 不得空 `catch`。
- `[MACHINE]` 日志调用不得用字符串拼接替代占位符。
- `[REVIEW]` 不吞异常；捕获异常必须有明确恢复、转换或上抛策略。
- `[REVIEW]` 不重复记录同一异常导致日志噪音。
- `[REVIEW]` 错误码、异常信息和用户提示稳定、可排查，不暴露内部实现细节。
- `[REVIEW]` 日志不输出手机号、token、证件号、密钥、Cookie 等敏感信息，除非 spec 明确授权并有脱敏策略。

## 分层与接口

- `[MACHINE]` Controller 直接依赖 Mapper / DAO 必须至少提示，新增代码原则上阻断。
- `[REVIEW]` Controller 只做参数接收、基础校验、调用服务和返回结果。
- `[REVIEW]` 核心业务逻辑在 application/service 层，不写进 Job / Consumer / Handler 入口类。
- `[REVIEW]` Controller 不直接暴露 persistence entity。
- `[REVIEW]` 新 API 使用明确 Request / Response DTO，不直接返回 `Map` 或数据库实体。
- `[REVIEW]` API 字段、分页、空态、错误码与 `docs/contracts/<change-id>-api.md` 一致。

## 单元测试与验证

- `[REVIEW]` 新增或变更核心业务分支时，有正常、空数据、异常、边界场景验证。
- `[REVIEW]` 如果没有补测试，`evidence.md` 必须说明原因和残余风险。
- `[MACHINE]` Maven compile 或 targeted test 失败时不得进入 review。

## 安全规约

- `[MACHINE]` Mapper XML 不得使用 `${}` 拼接外部输入。
- `[REVIEW]` 查询接口必须确认权限边界、数据范围和敏感字段展示策略。
- `[REVIEW]` 请求参数进入 SQL、RPC、日志、文件路径、URL 时必须有校验或安全封装。
- `[REVIEW]` 管理端“全量可见”等规则必须来自 `[FACT]`，不能由 Agent 猜测。

## MySQL 与 ORM

- `[MACHINE]` Mapper XML 不得出现 `select *`。
- `[REVIEW]` 新 SQL 只查所需字段，where 条件和排序字段符合索引预期。
- `[REVIEW]` 分页查询必须有稳定排序。
- `[REVIEW]` 批量查询避免 N+1；循环内查库必须说明原因。
- `[REVIEW]` 新增 DDL、索引或迁移必须有用户确认，并升级风险等级。
- `[REVIEW]` MyBatis 参数绑定使用 `#{}`，不得把外部输入拼接到 SQL。

## 设计规约

- `[REVIEW]` 变更范围小、可回滚，不把无关重构混入需求实现。
- `[REVIEW]` 领域概念使用 `docs/domain-glossary.md`，避免同一业务对象多个叫法。
- `[REVIEW]` 新增抽象必须能减少真实复杂度，不能为了“显得架构化”引入多余层。
- `[HUMAN]` 权限、状态机、数据口径、展示口径和回滚策略由用户最终确认。

## Reviewer 输出要求

Reviewer Agent 输出必须包含：

1. 是否已读取本清单和原文路径。
2. `java-mechanical-quality.sh` 是否有证据。
3. HIGH / MEDIUM / LOW 风险。
4. 需要人工确认的 Java 规范或业务语义问题。
5. 是否建议进入人工 review。
