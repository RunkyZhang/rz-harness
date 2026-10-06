# 中间件详细用法参考

## 4.1 Nacos（服务注册与配置中心）

已自动接入，无需额外配置。

### 服务注册

`bootstrap.yml` 中配置 `spring.cloud.nacos.discovery`，启动时自动注册。

### 配置中心

```java
// 方式1：通过 RemoteConfigReader 读取 Nacos 配置
@Autowired
private RemoteConfigReader remoteConfigReader;

Map<String, String> config = remoteConfigReader.getConfig("namespace", "group", "dataId");

// 方式2：通过 @Value + @RefreshScope 热更新
@RefreshScope
@Component
public class ConfigSource {
    @Value("${some.config.key}")
    private String someConfig;
}
```

### 配置来源

- 配置信息通常写在 `bootstrap.yml` 中，也可在 Nacos 控制台直接管理
- `@RefreshScope` 可使配置变更时自动刷新 Bean

---

## 4.2 Sentinel（流量控制与熔断降级）

### 限流

```java
@SentinelResource(value = "resourceName", blockHandler = "handleBlock")
public RpcResult<Data> getConfig() {
    // 业务逻辑
}

// 限流回调方法（必须与原始方法签名一致，多一个 BlockException 参数）
public RpcResult<Data> handleBlock(BlockException ex) {
    return RpcResult.error(BusinessException.API_FLOW_LIMITING.code(), "请求过于频繁");
}
```

### 熔断降级

```java
@SentinelResource(value = "rpcCall", fallback = "handleFallback")
public RpcResult<Data> invokeRpc() {
    // RPC 调用
}

public RpcResult<Data> handleFallback(Throwable ex) {
    return RpcResult.error(BusinessException.INVOKE_FLOW_BREAKING.code(), "服务降级");
}
```

限流/熔断异常推荐使用 `BusinessException.API_FLOW_LIMITING`(800013) 和 `BusinessException.INVOKE_FLOW_BREAKING`(800014)。

---

## 4.3 Feign（微服务调用）

### 定义接口（API Module）

```java
@FeignClient(name = "service-name", contextId = "uniqueContextId")
public interface DemoApi {
    @PostMapping("/api/path")
    RpcResult<ResponseDto> execute(@RequestBody RequestDto requestDto);
}
```

### 调用规范

```java
// 在 Infrastructure 层的 rpc/ 子包中封装调用
@Service
public class RpcProxy {
    @Resource
    private DemoApi demoApi;

    @AccessLog
    public RpcResult<ResponseDto> callRemote(RequestDto request) {
        return demoApi.execute(request);
    }
}
```

- RPC 调用必须加 `@AccessLog`，打印调用日志
- 第三方 HTTP 调用也**必须**通过 FeignClient 方式封装
- `FeignClientRequestInterceptor` 自动传递 `traceId`/`region`/`language`/`timezone`
- Feign 重试由 `BeanConfig` 自动配置（初始 100ms，最大 1000ms，最多 2 次）

---

## 4.4 XXL-JOB（定时任务）

### 配置类（Interfaces 层）

```java
@Configuration
public class XxlJobConfig {
    @Value("${xxl.job.admin.addresses}")
    private String adminAddresses;
    // ... executor 配置
}
```

### Job Handler（Application 层）

```java
@Component
public class DemoJobHandler {
    @AccessLog(prefix = "job")
    @XxlJob("demoJobHandler")
    public void execute() {
        // 业务逻辑
    }
}
```

- **必须**在 Interfaces 层创建 `XxlJobConfig` 配置类
- **必须**在 Job 方法上加 `@AccessLog(prefix = "job")`
- Job 逻辑写在 Application 层

---

## 4.5 RabbitMQ

### 发送消息

```java
@Component
public class DemoSender extends AbstractRabbitSender {

    public void sendDemoMessage(SfaDictCodeEntity entity) {
        String exchange = "demo.exchange";
        String routingKey = "demo.routingkey";
        String messageId = Helper.generateTraceId();
        Map<String, Object> headers = new HashMap<>();

        // 发送普通消息
        sendMessage(exchange, routingKey, messageId, entity, headers);

        // 发送延迟消息（毫秒）
        sendDelayMessage(exchange, routingKey, messageId, 5000L, entity, headers);
    }
}
```

### 消费消息

```java
@Component
public class DemoReceiver extends AbstractRabbitReceiver {

    @Override
    protected void process(String messageId, List<SfaDictCodeEntity> body,
                           Map<String, Object> headers) {
        // 处理消息逻辑
    }

    @Override
    protected int getSampleRate() {
        return 100; // 采样率
    }
}
```

- `process()` 方法中 `body` 类型由泛型决定
- 内置：消费日志记录（开始/报错/重试/结束）、手动/自动 ACK
- 批量消费使用 `AbstractRabbitBatchReceiver`

### 延迟消息注意事项

- 延迟时间必须在合理范围内，超出范围抛出 `BusinessException.INVALID_RABBITMQ_DELAY_TIME`(800015)
- TTL 设置在消息级别，非队列级别

---

## 4.6 Kafka

### 发送消息

```java
@Component
public class KafkaSender extends AbstractKafkaSender {

    public void sendEvent(String topic, Object body) {
        String messageId = Helper.generateTraceId();
        Map<String, Object> headers = new HashMap<>();

        // 异步发送（fire-and-forget）
        sendMessageAsync(topic, messageId, body, headers);

        // 同步发送（可配置超时，默认 550ms）
        sendMessage(topic, messageId, body, headers);
    }
}
```

### 批量消费

```java
@Component
public class KafkaBatchReceiver extends AbstractKafkaBatchReceiver {

    @Override
    protected void process(List<ConsumerRecord<String, String>> records) {
        for (ConsumerRecord<String, String> record : records) {
            // 处理每条消息
        }
    }

    @Override
    protected int getSampleRate() {
        return 100;
    }
}
```

- 批量消费推荐使用 `AbstractKafkaBatchReceiver`
- trace-id 自动通过 Kafka Header 传递

---

## 4.7 MyBatis-Plus

### 启动类配置

```java
@SpringBootApplication
@MapperScan("com.wantwant.{project}.infrastructure.mapper")
public class Application { ... }
```

### 分页插件

```java
@Configuration
public class MyBatisPlusConfig {
    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        interceptor.addInnerInterceptor(new PaginationInnerInterceptor(DbType.MYSQL));
        return interceptor;
    }

    @Bean
    public BatchSqlInjector batchSqlInjector() {
        return new BatchSqlInjector();
    }
}
```

### 分页查询

```java
// 创建分页对象
PageDto<Entity> page = PageDto.of(current, size);
// 添加排序
page.addOrder(OrderItemDto.desc("modify_at"));

// 执行分页查询
IPageDto<Entity> result = mapper.selectPage(page, queryWrapper);

// 前端请求 DTO
// PageRequestBaseDto 包含: page, rows, sortName, sortType 字段
```

### 批量插入

```java
// 使用 BatchSqlInjector 提供的批量插入能力
// 配置 BatchSqlInjector 后，MyBatis-Plus 的 saveBatch 会自动使用批量插入 SQL
service.saveBatch(entityList);
```

---

## 4.8 Swagger/Knife4j

### 配置

```java
@Configuration
@EnableSwagger2
public class SwaggerConfig {
    @Bean
    public Docket createRestApi() {
        return new Docket(DocumentationType.SWAGGER_2)
                .apiInfo(apiInfo())
                .select()
                .apis(RequestHandlerSelectors.basePackage("com.wantwant.{project}"))
                .paths(PathSelectors.any())
                .build();
    }
}
```

### 注解

- Controller：`@Api(tags = "模块名称")`
- 方法：`@ApiOperation(value = "接口说明")`
- DTO 字段：`@ApiModelProperty("字段说明")`

### 访问

- `/swagger-ui.html`
- `/doc.html`（Knife4j 增强版，推荐）
