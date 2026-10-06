# 脚手架内置功能详细参考

脚手架代码位于 `sfa-common-sdk` 项目，分为两个模块：
- **sfa-common-base**：基础层（注解、DTO、异常、工具类、枚举、校验）
- **sfa-common-architecture**：架构层（切面、拦截器、过滤器、MQ基类、缓存、登录、i18n、RT监控）

**注意**：所有 `@Component`、`@Service`、`@Configuration`、`@Aspect` 类通过组件扫描自动注册，要求业务项目的 `@SpringBootApplication` 扫描到 `com.wantwant.sfa.common` 包。

---

## 一、自动生效功能（无需额外配置）

### 1. HTTP 接口全链路日志采集

**实现方式**：拦截器 + 过滤器  
**核心类**：`ControllerHandlerInterceptor`、`RequestResponseWrapperFilter`、`CachingHttpServletRequestWrapper`、`CopyingHttpServletResponseWrapper`  
**注册配置**：`WebMvcConfigurerImpl`（`@Configuration`）中注册拦截器和过滤器，拦截 `/**`  
**使用方式**：自动生效，无需额外注解。所有 `@RestController` 的接口自动记录 `api-start`、`api-end`、`api-failed` 日志  
**日志采样**：通过 `AccessLogStrategySelector` 控制采样率，Nacos 配置 `accessLog.policies.json` 动态调整，`accessLog.defaultSampleRate:10` 默认 1% 采样  
**日志脱敏**：在 Controller 方法上加 `@LogMask` 可隐藏请求参数或返回结果  
**配置项**：
- `controllerInterceptor.loggedHeaderNames`（记录哪些 HTTP Header）
- `webMvcConfigurer.filter.addUrlPatterns`（过滤器 URL 匹配）
- `restControllerAspect.logSwitch`
- `accessLog.emergencyEnable`（紧急全量日志开关）

---

### 2. 全局异常处理

**实现方式**：`@RestControllerAdvice` + `@ExceptionHandler`  
**核心类**：`ControllerExceptionAdvice`、`ApplicationExceptionFixer`  
**使用方式**：自动生效。所有 Controller 层抛出的异常自动捕获，返回标准 `RpcResult` 格式  
**异常分类**：
- `BusinessException`（业务异常，按 `errorLogLevel` 区分 error/warn 日志级别）
- `MethodArgumentNotValidException`（参数校验异常）
- `ApplicationException`（兼容旧系统）
- 其他未知异常（统一返回"系统异常"）

**i18n 支持**：异常消息支持通过 `LocalizedText` 国际化翻译  
**配置项**：`controllerException.traceMessageSwitch`（是否返回 traceMessage 给前端，默认 false）

---

### 3. 全局数据注入（语言/时区/地区）

**实现方式**：AOP 切面（集成在 `RestControllerAspect` 中）  
**核心类**：`RestControllerAspect`、`GlobalDataProcessor`  
**使用方式**：自动生效。所有 `@RestController` 方法参数中的 `RequestBaseDto`，其 `lsLanguage`、`lsTimezone`、`lsRegion` 字段自动从 HTTP Header 填充  
**默认值**：语言 `zh`、时区 `Asia/Shanghai`、地区 `CN`

---

### 4. HTTP Headers 自动注入

**实现方式**：AOP 切面（集成在 `RestControllerAspect` 中）  
**核心类**：`RestControllerAspect.setRequestHeaders()`  
**使用方式**：自动生效。所有 `@RestController` 方法参数中的 `RequestBaseDto`，其 `httpHeaders` 字段自动填充

---

### 5. Feign 请求拦截器（全链路 Trace 传递）

**实现方式**：Feign `RequestInterceptor`  
**核心类**：`FeignClientRequestInterceptor`  
**使用方式**：自动生效。所有 Feign 请求自动添加 `ww-trace-id`、`ww-remote-application-name`、`ww-region`、`ww-language`、`ww-timezone` Header

---

### 6. Feign 全局重试策略

**实现方式**：`@Configuration` + `@Bean`  
**核心类**：`BeanConfig.retryer()`  
**使用方式**：自动生效。重试间隔 100~1000ms，最多重试 1 次（共 2 次调用）。可通过自定义 `Retryer` Bean 覆盖

---

### 7. Request/Response Body 缓存过滤器

**实现方式**：Servlet `Filter` + Request/Response Wrapper  
**核心类**：`RequestResponseWrapperFilter`、`CachingHttpServletRequestWrapper`、`CopyingHttpServletResponseWrapper`  
**使用方式**：自动生效。使得日志拦截器和防重复提交拦截器能够读取 Request Body

---

### 8. LoadBalanced RestTemplate

**实现方式**：`@Configuration` + `@Bean` + `@LoadBalanced`  
**核心类**：`BeanConfig.restTemplate()`  
**使用方式**：直接注入 `RestTemplate` 使用，支持服务名调用

---

### 9. 全链路 TraceId 管理

**实现方式**：拦截器 + Feign 拦截器 + MQ 基类 + MDC  
**核心类**：`TraceUtils`、`ControllerHandlerInterceptor`（HTTP 入口）、`FeignClientRequestInterceptor`（Feign 出口）、`AbstractRabbitReceiver`/`AbstractKafkaBatchReceiver`（MQ 入口）、`AbstractRabbitSender`/`AbstractKafkaSender`（MQ 出口）  
**使用方式**：`TraceUtils.getTraceId()` 获取当前 traceId  
**传递路径**：HTTP Header `ww-trace-id` -> MDC `traceId` -> Feign Header -> MQ Header

---

### 10. RT 监控统计

**实现方式**：服务类 + 优先队列 + 独立线程池  
**核心类**：`RTMonitor`、`InvokeResult`  
**使用方式**：自动生效（由 `ControllerHandlerInterceptor` 和 `ControllerExceptionAdvice` 自动调用）。每天自动清空并输出日志  
**特性**：
- 按 API 分组统计 Top 100 慢请求
- RT 分桶（1ms/2ms/4ms/.../8192ms）
- 高 RT 请求自动补打 start 日志

**配置项**：
- `rt.monitor.master.switch`（总开关，默认 false）
- `rt.monitor.pool.size`（线程池大小，默认 3）
- `rt.monitor.queue.max.size`（队列大小，默认 50 万）
- `rt.monitor.invoke.result.size`（每个 API 保留 Top N，默认 100）

---

## 二、注解驱动功能

### 1. 方法执行日志采集（@AccessLog）

**实现方式**：AOP 切面 `@Aspect` + `@Around`  
**核心类**：`InvokingLogProcessor`  
**注解定义**：`@AccessLog`（定义在 `sfa-common-base`）  
**注解参数**：
- `sampleRate`（采样率，默认 10/1000）
- `strategyName`（策略名称）
- `prefix`（日志前缀，默认 "rpc"，JOB 用 `prefix="job"`）
- `startAccessEvent`（是否记录开始事件）

**使用方式**：在方法上加 `@AccessLog`，如 `@AccessLog(prefix = "job")` 用于 XXL-JOB，`@AccessLog` 用于 Feign RPC 调用  
**日志格式**：`{prefix}-start({key})`、`{prefix}-end({key})-{rt}`、`{prefix}-failed({key})-{rt}`  
**Trace 支持**：自动检测 `@XxlJob` 注解，作为 Trace 起点生成 traceId

---

### 2. 防重复提交（@Resubmit）

**实现方式**：拦截器 `HandlerInterceptor`  
**核心类**：`ResubmitInterceptor`  
**注解定义**：`@Resubmit`（定义在 `sfa-common-base`）  
**注解参数**：
- `spaceTimeSecond`（间隔时间，默认 3 秒）
- `timeUnit`（时间单位，默认秒）
- `pkId`（自定义主键标识）

**使用方式**：在 Controller 方法上加 `@Resubmit(spaceTimeSecond = 5)`  
**实现原理**：对请求参数 MD5 后作为 Redis Key，通过 `RedissonClient.getBucket().trySet()` 原子操作判断是否重复  
**依赖**：需要 `RedissonClient` Bean（`@Autowired(required = false)`，无 Redis 时自动降级跳过）

---

### 3. 登录状态注入（@AccessLoginStatus）

**实现方式**：AOP 切面 `@Aspect`（集成在 `RestControllerAspect` 中）  
**核心类**：`RestControllerAspect`、`LoginStatusGetterSelector`、`AbstractLoginStatusGetter`、`SfaLoginStatusGetter`、`LoginStatus`  
**注解定义**：`@AccessLoginStatus`（定义在 `sfa-common-base`）  
**注解参数**：`mode`（模式，默认 0 使用 SFA 通用策略）  
**使用方式**：在 Controller 方法上加 `@AccessLoginStatus`，方法参数中 `RequestBaseDto` 的 `lsBusinessGroup`、`lsPositionTypeId`、`lsChannel`、`lsOrganizationType`、`lsLoginUserId` 等字段自动填充  
**扩展方式**：继承 `AbstractLoginStatusGetter`，实现 `getMode()` 返回自定义 mode 值，注册为 Spring Bean 即可  
**Header 字段**：`businessGroup`、`positionTypeId`、`organizationType`、`loginUserId`、`channel`

---

### 4. 全局时区转换（@GlobalTimezone）

**实现方式**：AOP 切面（集成在 `RestControllerAspect` 中）+ 反射  
**核心类**：`RestControllerAspect`、`LocalizedTimezone`、`DtoField`  
**注解定义**：`@GlobalTimezone`（定义在 `sfa-common-base`，可加在字段或方法上）  
**使用方式**：在 Controller 方法上加 `@GlobalTimezone`，在 DTO 的时间类型字段（`Date`、`LocalDateTime`、`LocalTime`、`String`）上加 `@GlobalTimezone` 标记  
**转换逻辑**：入参：从客户端时区转为 `Asia/Shanghai`；出参：从 `Asia/Shanghai` 转为客户端时区  
**配置项**：`restControllerAspect.timezoneSwitch`（总开关，默认 true）

---

### 5. 本地缓存（@LocalCacheable）

**实现方式**：AOP 切面 `@Aspect` + `@Around`  
**核心类**：`LocalCacheProcessor`（切面）、`LocalCache`（缓存实体）、`LocalCacheManager`（管理器）、`KeyBuilder`（SpEL Key 构建）、`ExpressionEvaluator`（SpEL 求值）  
**注解定义**：`@LocalCacheable`（定义在 `sfa-common-architecture`）  
**注解参数**：
- `keyExpression`（SpEL 表达式，支持 `#p0`、`#paramName`、`T(Class).staticField`）
- `expireTime`（过期时间，秒）

**使用方式**：在方法上加 `@LocalCacheable(keyExpression = "#key", expireTime = 300)`  
**特性**：
- 首次调用同步执行并缓存
- 过期后同步刷新
- 刷新失败时返回旧值
- 连续失败超过 3 次触发熔断（重置错误计数，延长刷新时间）

**管理接口**：
- `LocalCacheManager.expireCache(key)`（标记过期）
- `LocalCacheManager.clearCache(key)`（清除）
- `LocalCacheManager.refreshCache(key)`（强制刷新）
- `LocalCacheManager.getKeys()`（查看所有 Key）

---

### 6. 参数校验（@AllowValue）

**实现方式**：JSR 303 自定义校验注解  
**注解定义**：`@AllowValue`（定义在 `sfa-common-base`）  
**使用方式**：在 DTO 字段上加 `@AllowValue({"A", "B", "C"})`，限定字段值必须在指定列表中

---

## 三、MQ 消息基类

### 1. RabbitMQ 消息发送基类

**实现方式**：抽象基类继承  
**核心类**：`AbstractRabbitSender`  
**使用方式**：业务类继承 `AbstractRabbitSender`，注册为 Spring Bean，调用 `sendMessage(exchange, routingKey, messageId, body, headers)` 或 `sendDelayMessage(...)`  
**特性**：
- 自动传递 `ww-trace-id`
- 自动 JSON 序列化（`JacksonHelper`）
- 支持延迟消息（基于消息 TTL）
- `@RefreshScope` 支持配置热更新

**配置项**：`mq.rabbit.sender.logDebug`（调试日志开关，默认 false）

---

### 2. RabbitMQ 消息消费基类（单条）

**实现方式**：抽象基类继承  
**核心类**：`AbstractRabbitReceiver`  
**使用方式**：业务类继承 `AbstractRabbitReceiver`，实现 `process(messageId, body, headers)` 和 `getSampleRate()` 方法。在 `@RabbitListener` 方法中调用 `consumeManualAck(message, channel, body)` 或 `consumeAutoAck(...)`  
**特性**：
- 手动 ACK / 自动 ACK 两种模式
- 自动传递 traceId（从 header 提取）
- 日志采样率可控
- 异常时可选重试（`needRetry()`）
- 自动 MDC 管理

---

### 3. RabbitMQ 消息消费基类（批量）

**实现方式**：抽象基类继承  
**核心类**：`AbstractRabbitBatchReceiver`  
**使用方式**：业务类继承 `AbstractRabbitBatchReceiver`，实现 `process(List<Message> messages)` 和 `getSampleRate()`。在 `@RabbitListener` 中调用 `consumeAutoAck(messages, channel)`  
**配置项**：`mq.rabbit.receiver.logDebug`（调试日志开关）

---

### 4. Kafka 消息发送基类

**实现方式**：抽象基类继承  
**核心类**：`AbstractKafkaSender`  
**使用方式**：业务类继承 `AbstractKafkaSender`，注册为 Spring Bean，调用 `sendMessage(topic, messageId, body, headers)`（同步）或 `sendMessageAsync(...)`（异步）  
**特性**：
- 自动传递 `ww-trace-id`
- 自动 JSON 序列化
- 同步发送超时控制
- `@RefreshScope` 支持

**配置项**：
- `mq.kafka.sender.logDebug`（调试日志）
- `mq.kafka.sender.timeout.millis`（同步超时，默认 550ms）

---

### 5. Kafka 消息消费基类（批量）

**实现方式**：抽象基类继承  
**核心类**：`AbstractKafkaBatchReceiver`  
**使用方式**：业务类继承 `AbstractKafkaBatchReceiver`，实现 `process(List<ConsumerRecord<String, String>> records)` 和 `getSampleRate()`。在 `@KafkaListener` 中调用 `consumeAutoAck(records, ack)`  
**特性**：
- 手动 Acknowledgment
- 日志采样
- `getHeaders(recordHeaders)` 辅助方法提取 Kafka Header

**配置项**：`mq.kafka.receiver.logDebug`（调试日志）

---

## 四、事件日志采集

**实现方式**：服务类 + MQ 发送  
**核心类**：`EventLogger`、`Event`、`RabbitEventSender`、`KafkaEventSender`  
**使用方式**：`eventLogger.buildEvent("e_table_name").with("key1", value1).with("key2", value2).log()`  
**MQ 切换**：`event.kafka.switch:false` 默认走 RabbitMQ（exchange: `arch.event.backend.exchange`），设为 true 走 Kafka（topic: `t_arch_event_backend`）

---

## 五、Nacos 配置中心读取

**实现方式**：服务类 + Nacos SDK  
**核心类**：`RemoteConfigReader`  
**使用方式**：`remoteConfigReader.getConfig(namespace, group, dataId)` 返回 `Map<String, String>`  
**特性**：
- 首次读取后注册 Listener 监听变更
- 14 天超时后重新主动拉取
- 解析 `key=value` 格式的配置

**配置项**：`remoteConfigReader.timeout`（超时时间，默认 14 天）

---

## 六、国际化文本（i18n）

**实现方式**：服务类  
**核心类**：`LocalizedText`  
**使用方式**：`localizedText.getValue("key", "默认值")` 或 `localizedText.getValue("zh", "key", "默认值")`  
**查找顺序**：
1. Spring `MessageSource`（i18n 配置文件）
2. Nacos 配置（`global-text-{language}.properties`）
3. 默认值

**自动语言识别**：无参版本自动从当前 HTTP 请求的 `ww-language` Header 获取语言

---

## 七、异步任务执行器

**实现方式**：服务类 + 线程池  
**核心类**：`AsyncWorker`、`BeanConfig.commonThreadPool()`  
**使用方式**：`asyncWorker.execute(() -> {...})` 或 `asyncWorker.submit(() -> result)`  
**线程池配置**：
- `common.thread.pool.size`（最大线程数，默认 10）
- `common.thread.queue.capacity`（队列容量，默认 10000）
- 核心线程 2、空闲 60s、拒绝策略 AbortPolicy

---

## 八、Spring Bean 静态获取

**实现方式**：`ApplicationContextAware`  
**核心类**：`SpringContextHelper`  
**使用方式**：`SpringContextHelper.getBean(MyService.class)` 或 `SpringContextHelper.getBean("beanName")`

---

## 九、事务工具

**实现方式**：静态工具类  
**核心类**：`TxUtils`  
**使用方式**：
- `TxUtils.isTxActive()` 判断当前是否有事务
- `TxUtils.runAfterTxSuccess(() -> {...})` 事务提交后执行（默认异步）
- `TxUtils.runAfterTxSuccess(() -> {...}, false)` 同步执行

---

## 十、工具类清单

| 工具类 | 所在模块 | 功能 |
|--------|---------|------|
| `JacksonHelper` | sfa-common-base | JSON 序列化/反序列化（统一 ObjectMapper，禁用未知属性报错，支持 JavaTimeModule） |
| `AssertHelper` | sfa-common-base | 断言工具（notNull/notEmpty/notBlank/isTrue/isFalse/equals/isEmpty），失败抛 `BusinessException` |
| `BusinessException` | sfa-common-base | 统一业务异常，含 code/message/traceMessage/errorLogLevel，提供大量静态工厂方法 |
| `Helper` | sfa-common-base | 综合工具：IP 获取、traceId/spanId 生成、SHA1/MD5/SHA256/HMAC256 编码、Base64 编解码、反射字段/方法获取、RPC 结果提取（`getResultData`） |
| `DateTimeUtility` | sfa-common-base | Date 操作（解析/格式化/加减/比较/时区转换），支持多种日期格式 |
| `CommonConstant` | sfa-common-base | 公共常量（日期格式、时区、地区、语言、删除标记等） |
| `BeanUtils` | sfa-common-architecture | 对象拷贝（单个/列表）、Bean 转 Map、默认值填充 |
| `LocalDateTimeUtils` | sfa-common-architecture | LocalDateTime 操作（格式化/加减/日期区间/时区校准/UTC 转换） |
| `StreamCommonUtil` | sfa-common-architecture | 集合操作（toList/toMap/groupToMap/toSet/flatToList/reduce/distinct/filterFirst/subList/distinctByKey/hasMatch） |
| `EnumCommonUtil` | sfa-common-architecture | 枚举工具（按名称查找 StringEnum、按 type 查 desc、枚举转 CommonLabelValueDTO 下拉列表） |
| `TraceUtils` | sfa-common-architecture | 获取当前 traceId（优先从 ThreadLocal，其次从 MDC） |
| `TxUtils` | sfa-common-architecture | 事务判断与事务后执行 |
| `SpringContextHelper` | sfa-common-architecture | 静态获取 Spring Bean |
| `AsyncWorker` | sfa-common-architecture | 异步任务提交 |
| `LocalizedText` | sfa-common-architecture | i18n 文本获取 |

---

## 十一、DTO / 基类清单

| 类 | 所在模块 | 用途 |
|----|---------|------|
| `RpcResult<T>` | sfa-common-base | 统一 RPC 返回结果（code/message/data/traceMessage/extra） |
| `RequestBaseDto` | sfa-common-base | 请求基类（自动注入登录态/时区/语言/地区/Header 信息） |
| `BaseDto` | sfa-common-base | DTO 基类 |
| `PageDto<T>` | sfa-common-base | 分页参数（兼容 MyBatis-Plus IPage 接口），`PageDto.of(current, size)` |
| `PageRequestBaseDto` | sfa-common-base | 分页请求基类 |
| `OrderItemDto` | sfa-common-base | 排序条件 |
| `EventDto` | sfa-common-base | 事件 DTO |
| `CommonLabelValueDTO` | sfa-common-base | 通用下拉选项（label/value） |
| `Tuple2<T1, T2>` / `Tuple3<T1, T2, T3>` | sfa-common-base | 元组 |

---

## 十二、注解清单

| 注解 | 所在模块 | 目标 | 用途 |
|------|---------|------|------|
| `@AccessLog` | sfa-common-base | METHOD | 方法执行日志采集（采样率/前缀/策略） |
| `@AccessLoginStatus` | sfa-common-base | METHOD | 自动注入登录态到 RequestBaseDto |
| `@Resubmit` | sfa-common-base | METHOD | 防重复提交（Redis 锁） |
| `@LogMask` | sfa-common-base | METHOD | 日志脱敏（隐藏参数/结果） |
| `@GlobalTimezone` | sfa-common-base | FIELD, METHOD | 标记需要时区转换的字段/方法 |
| `@LocalCacheable` | sfa-common-architecture | METHOD | 本地缓存（SpEL Key + 过期时间） |
| `@AllowValue` | sfa-common-base | FIELD, PARAMETER | 参数校验（限定允许值列表） |

---

## 十三、中间件集成汇总

| 中间件 | 集成方式 | 核心类/配置 |
|--------|---------|------------|
| **Nacos Config** | Maven 依赖 + `@RefreshScope` + `RemoteConfigReader` | `RemoteConfigReader`、`BeanConfig`（`@RefreshScope`） |
| **Nacos Discovery** | Maven 依赖（自动注册） | POM 引入 `spring-cloud-starter-alibaba-nacos-discovery` |
| **Sentinel** | Maven 依赖 + 持久化 Nacos | POM 引入 `spring-cloud-starter-alibaba-sentinel` + `sentinel-datasource-nacos` |
| **Feign** | `RequestInterceptor` + `Retryer` + `feign-httpclient` | `FeignClientRequestInterceptor`、`BeanConfig.retryer()` |
| **RabbitMQ** | 抽象基类 | `AbstractRabbitSender`、`AbstractRabbitReceiver`、`AbstractRabbitBatchReceiver` |
| **Kafka** | 抽象基类 | `AbstractKafkaSender`、`AbstractKafkaBatchReceiver` |
| **Redis (Redisson)** | 通过 `RedissonClient` 集成 | `ResubmitInterceptor`（防重复提交使用 Redisson） |
| **XXL-JOB** | 切面自动识别 | `InvokingLogProcessor.isTraceStart()` 检测 `@XxlJob` 注解，自动生成 traceId |
| **Swagger** | Maven 依赖 | POM 引入 `springfox-swagger2` |
| **JWT** | Maven 依赖 | POM 引入 `jjwt-api/impl/jackson`（供业务使用） |
| **Hutool** | Maven 依赖 | POM 引入 `hutool-core`、`hutool-crypto`（供业务使用） |

---

## 十四、Nacos 可配置项汇总

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `accessLog.defaultSampleRate` | 10 | 默认日志采样率（/1000） |
| `accessLog.emergencyEnable` | false | 紧急全量日志开关 |
| `accessLog.policies.json` | 空 | 动态日志策略 JSON |
| `controllerInterceptor.loggedHeaderNames` | organizationType,positionTypeId,... | 记录哪些 HTTP Header |
| `controllerException.traceMessageSwitch` | false | 是否向前端返回 traceMessage |
| `restControllerAspect.logSwitch` | true | 登录态日志开关 |
| `restControllerAspect.timezoneSwitch` | true | 时区转换总开关 |
| `webMvcConfigurer.filter.addUrlPatterns` | /* | 过滤器 URL 匹配 |
| `rt.monitor.master.switch` | false | RT 监控总开关 |
| `rt.monitor.pool.size` | 3 | RT 监控线程池大小 |
| `rt.monitor.invoke.result.size` | 100 | 每个 API 保留 Top N 慢请求 |
| `common.thread.pool.size` | 10 | 通用线程池最大线程数 |
| `common.thread.queue.capacity` | 10000 | 通用线程池队列容量 |
| `feign.client.config.default.connect-timeout` | 5000 | Feign 连接超时 |
| `feign.client.config.default.read-timeout` | 1000 | Feign 读取超时 |
| `mq.rabbit.sender.logDebug` | false | RabbitMQ 发送调试日志 |
| `mq.rabbit.receiver.logDebug` | false | RabbitMQ 消费调试日志 |
| `mq.kafka.sender.logDebug` | false | Kafka 发送调试日志 |
| `mq.kafka.sender.timeout.millis` | 550 | Kafka 同步发送超时 |
| `mq.kafka.receiver.logDebug` | false | Kafka 消费调试日志 |
| `event.kafka.switch` | false | 事件日志走 Kafka 开关 |
| `remoteConfigReader.timeout` | 1209600000 (14天) | Nacos 配置兜底拉取间隔 |
