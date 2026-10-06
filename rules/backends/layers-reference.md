# 项目分层（DDD 五个模块，四个分层）详细用法参考

本项目采用 DDD 思想，分 5 个 Maven 模块，**自下而上单向依赖，严禁反向依赖**：

```
interfaces → application → domain → infrastructure → api → common-base
                                    infrastructure → common-architecture
```

### 1.1 API 模块

**职责**：定义 `@FeignClient` 接口 + DTO + 枚举。只引入 `common-base`。供其他服务引用

**规则**：
- 接口必须用 `POST` 方法，入参继承 `RequestBaseDto`，出参为 `RpcResult<T>`（导出Excel接口除外）
- 入参 DTO 命名格式：`{接口名}RequestDto`
- 出参 DTO 命名格式：`{接口名}ResponseDto`
- `@FeignClient` 必须指定 `contextId`
- 供其他服务引用，提供 RPC 接口和 DOT 定义 jar 包，所以尽可能少引入无关 jar 包
- jar 包发布后**接口/对象/枚举不可修改**，只能新增字段或枚举项

### 1.2 Infrastructure 层

**职责**：数据源对接（MySQL Mapper、Redis、Feign RPC、ES、Nacos 配置）、通用功能（工具类、常量、异常、Entity）

**规则**：
- Entity 必须继承 `BaseEntity`（获得 `deleted`、`createAt`、`modifyAt`、`operator`）
- Redis 操作必须用 `RedisMapper`，如果要使用RedisTemplate也需要封装到 `RedisMapper`中
- 业务异常常量定义在 `constants/ExceptionConstants.java`
- 本项目的工具类定义在`Helper.java`
- XXXMapper.java定义在 `mapper/` 子包中
- FeignClient 调用封装在 `rpc/` 子包中
- XXXMapper.xml 定义在 `resources/mapper`
- RPC 调用必须加 `@AccessLog`，用来打印RPC调用日志prefix默认是"rpc"

### 1.3 Domain 层

**职责**：领域服务，聚合多个 Mapper，处理缓存和分布式锁。**不做业务逻辑编排**

**规则**：
- 数据缓存在本层处理，使用 `@LocalCacheable`（本地缓存）， `RedisMapper`（redis缓存）
- 分布式锁使用 Redisson `RLock`

### 1.4 Application 层

**职责**：业务逻辑编排、聚合 Domain 对象、XXL-JOB 定时任务、MQ 消息消费/发送、Excel 处理

**规则**：
- 定时 Job 必须加 `@AccessLog(prefix = "job")`，用来打印Job调用日志
- MQ 发送继承 `AbstractRabbitSender`，`AbstractKafkaSender`。消费继承 `AbstractRabbitReceiver`，`AbstractKafkaBatchReceiver`

### 1.5 Interfaces 层

**职责**：Spring Boot 启动类、Controller 实现、全局及中间件配置。**不做任何业务逻辑**

**规则**：
- Controller 实现 API Module 中定义的 `@FeignClient` 接口
- 只做参数校验、对象转换、数据聚合、Bean 定义
- 通过 `@AccessLoginStatus` 获取用户登录态
- 通过 `@Resubmit` 防重复提交
- 通过 `@LogMask` 日志脱敏
- 通过 `@GlobalTimezone` 标记需要时区转换的字段
- Controller 返回值必须用 `RpcResult<T>`。**注意**导出Excel文件接口无需使用`RpcResult<T>`返回值，需要使用void
- 全局及中间件配置包括：
    - `Application.java` — 启动类，加 `@MapperScan`、`@EnableFeignClients`、`@EnableSwagger2`、`@EnableAspectJAutoProxy`
    - `MyBatisPlusConfig` — 分页插件 `PaginationInnerInterceptor` + 批量插入 `BatchSqlInjector`
    - `RedisConfig` — Redisson `RedissonClient` 配置，从 Nacos 读取连接信息
    - `XxlJobConfig` — XXL-JOB 调度器配置，从 Nacos 读取
    - `SwaggerConfig` — Swagger/Knife4j 文档配置（API 分组、鉴权等）
    - `HttpConfig` — CORS 跨域配置
    - `LogConfig` — `@AccessLog` 采样策略配置（登记 API URL、采样率）