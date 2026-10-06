# sfa-common-sdk（后端公共工具包）

后端服务都依赖这个包。仓在 `$RZ_REPO_SFA_COMMON_SDK`（本机路径见 `config/runtime_local.sh`）。

Maven 父工程 `com.wantwant:sfa-common`，两个模块：

| 模块 | artifactId | 包名 | 放什么 |
|---|---|---|---|
| base | `sfa-common-base` | `com.wantwant.sfa.common.base` | 无 Spring 业务框架也能用的类型：JSON、断言、异常、DTO、枚举、注解 |
| architecture | `sfa-common-architecture` | `com.wantwant.sfa.common.architecture` | 接到 Spring 上的能力：Web、缓存、MQ、登录态、配置、异步、事务 |

方法级写法见 `./tools-reference.md`、`./middleware-reference.md`。本文件只列能力边界。

## 必须遵守

写 Java 后端前先在本包里找。**已经有的能力直接调用，不要在业务仓再写一份同功能的工具类、拦截器、分页对象或异常类型。**

只有本包没有、且这次 spec 允许时，才在业务仓新增。新增前在 `evidence.md` 写一句：查过 `sfa-common-sdk` 的哪个类，为什么不够用。

## base：类型与工具

| 要做的事 | 用 | 不要另写 |
|---|---|---|
| JSON 序列化 / 反序列化 | `JacksonHelper` | `Gson`、`FastJson`、`new ObjectMapper()` |
| 断言，失败即业务异常 | `AssertHelper` | 手写 `if` 后 `throw` |
| 业务异常 | `BusinessException`、错误码 `StatusCode` | 自定义平行的业务异常体系 |
| RPC / HTTP 统一返回 | `RpcResult` | 自己的 `Result` / `Response` 包装 |
| 入参基类 | `RequestBaseDto`、`BaseDto` | 每个接口再造一套空基类 |
| 分页请求 / 结果 | `PageRequestBaseDto`、`PageDto`、`IPageDto`、`OrderItemDto` | 自己的 page/size 包装 |
| 下拉项 | `CommonLabelValueDTO` | 自己的 label/value DTO |
| 日期 `Date` 解析、加减、比较、时区 | `DateTimeUtility` | `SimpleDateFormat` |
| 摘要、Base64、traceId / spanId | `Helper` | 自己包一层 MD5 / SHA / Base64 |
| 枚举契约 | `IEnum`、`BaseEnum`、`StringEnum`、`JacksonEnumInterface` | 每个枚举各写一套 code/desc 查找 |
| 允许值校验 | `@AllowValue` | 手写 `@Pattern` 或 if 判断枚举白名单 |
| 二元 / 三元返回 | `Tuple2`、`Tuple3` | 只为带两个字段再造一个类 |

## architecture：接到 Spring 的能力

| 要做的事 | 用 | 不要另写 |
|---|---|---|
| 对象拷贝、Bean 转 Map、默认值 | `com.wantwant.sfa.common.architecture.utils.BeanUtils` | Spring `BeanUtils`、手写 set |
| `LocalDateTime` 转换、区间、重叠、时区修正 | `LocalDateTimeUtils` | 另一套日期工具 |
| 集合转换、过滤、分组、去重、分页切分 | `StreamCommonUtil` | 每个调用点重写 stream 模板 |
| 枚举转描述、转下拉 | `EnumCommonUtil` | 手写 switch 列表 |
| 当前 traceId | `TraceUtils` | 自己从 MDC 取再封一层 |
| 事务是否开启、提交后再执行 | `TxUtils` | 自己注册 `TransactionSynchronization` |
| 异步任务 | `AsyncWorker`（`commonThreadPool`） | 随手 `new Thread` / 自建线程池 |
| 静态拿 Bean | `SpringContextHelper` | 自己写 `ApplicationContextAware` 工具 |
| 本地缓存 | `@LocalCacheable` | 手写 `ConcurrentHashMap` 缓存 |
| Nacos 配置 | `RemoteConfigReader.getConfig()` | 自己读配置文件再缓存 |
| 访问日志 | `@AccessLog`；策略在 `log` 包，默认 `DefaultAccessLogStrategy` | 每个 Controller 打一套入参出参日志 |
| 审计日志 | `@AuditLog` | 业务里拼审计字段 |
| 登录态 | `@AccessLoginStatus`，读取走 `LoginStatus` / `SfaLoginStatusGetter` | 各接口自己解析 token |
| 防重复提交 | `@Resubmit`（拦截器 `ResubmitInterceptor`） | 自己用 Redis 做一套防重 |
| 日志脱敏 | `@LogMask` | 手写替换手机号、证件号 |
| 时区字段 | `@GlobalTimezone`，处理在 `GlobalDataProcessor`、`LocalizedTimezone` | 接口里散落 `ZoneId` 转换 |
| 多语言文案 | `LocalizedText` | 自己拼中文 / 印尼文 |
| Feign 调用日志与头 | `FeignClientRequestInterceptor`、`InvokingLogProcessor`；Feign 方法加 `@AccessLog` | 自己写 `RequestInterceptor` 打日志 |
| 统一异常响应 | `ControllerExceptionAdvice`、`ApplicationExceptionFixer` | 每个 Controller 一个 `@ExceptionHandler` |
| Rabbit 发送 / 消费 | `AbstractRabbitSender`、`AbstractRabbitReceiver`、`AbstractRabbitBatchReceiver` | 自己 `RabbitTemplate` 样板 |
| Kafka 发送 / 批量消费 | `AbstractKafkaSender`、`AbstractKafkaBatchReceiver` | 自己 `KafkaTemplate` 样板 |
| 领域事件 | `Event`，发送 `RabbitEventSender` / `KafkaEventSender` | 自己定义一套事件信封 |
| 环境属性 | `EnvProperties` | 各处 `@Value` 读同一组环境名 |

Controller 入参出参体的重复读取、全局拦截器由 `RequestResponseWrapperFilter`、`ControllerHandlerInterceptor`、`WebMvcConfigurerImpl`、`RestControllerAspect` 提供。业务 Controller 不要再包一层同样的 Filter。

## 依赖怎么引

- 只需要 DTO、异常、JSON、断言：依赖 `sfa-common-base`。
- 需要 Web、MQ、缓存、登录态、Feign 日志：再依赖 `sfa-common-architecture`。
- 版本跟父 POM，业务模块不要自己写这个包的版本号。
