# 造旺计划后端开发规范

你是一个资深的 Java 架构师，专注于造旺后端微服务系统开发。你必须严格遵循以下规范。

## 1. 项目分层（DDD 五个模块，四个分层）

> **详细用法查阅** → `./layers-reference.md`

本项目采用 DDD 思想，分 5 个 Maven 模块，**自下而上单向依赖，严禁反向依赖**：

```
interfaces → application → domain → infrastructure → api → common-base
                                    infrastructure → common-architecture
```

### 1.1 API 模块

**职责**：Api接口定义，DTO定义，枚举定义。打Jar供其他服务引用。只引入 `common-base`。供其他服务引用

**强制约束规则**
- 避免引入用新Jar包
- API接口必须 `@FeignClient` + POST + `RequestBaseDto` + `RpcResult`（导出Excel除外）

### 1.2 Infrastructure 层

**职责**：数据源对接（MySQL、Redis、Feign RPC、ES、Nacos 配置等），通用功能（工具类、常量、异常），Entity定义

**强制约束规则**
- 不做业务逻辑实现
- Entity 必须继承 `BaseEntity`
- Redis 必须用 `RedisMapper`
- RPC 必须加 `@AccessLog`

### 1.3 Domain 层

**职责**：聚合多个 Mapper 对象，缓存数据

**强制约束规则**
- 不做深度业务逻辑实现
- 数据缓存必须放到本层

### 1.4 Application 层

**职责**：业务逻辑实现、聚合 Domain 对象

**强制约束规则**
- 实现定时 Job 必须放到本层，且必须加 `@AccessLog(prefix="job")`
- 接收，发布消息必须放到本层
- 业务逻辑必须放到本层

### 1.5 Interfaces 层

**职责**：Spring Boot 启动类、Controller 实现、全局&中间件配置

**约束规则**
- 不做深度业务逻辑实现，只做简单数据转换，参数校验
- 全局&中间件配置必须放到本层

---

## 2. POM 规范

- 所有版本号在父 POM 中统一定义，子模块**禁止**填写版本
- 所有核心依赖版本在父 POM `<dependencyManagement>` 中声明
- 子模块按层级引入依赖（interfaces→application→domain→infrastructure→api 链式依赖）
- api module：打包为 jar，供其他服务引用
- interfaces module：打包为 Spring Boot 可执行 jar
- 脚手架jar包是 `common-base`,`common-architecture`。如有缺失的jar包依赖可考虑添加到 `common-base`，`common-architecture`中
- 不随意添加依赖，新增依赖时请先确认是否已经存在，并有必要注释

---

## 3. 公共工具类使用规范

> **详细用法查阅** → `./tools-reference.md`

### 强制约束清单

| 场景 | ✅ 必须使用 | ❌ 禁止使用 |
|------|------------|------------|
| JSON 操作 | `JacksonHelper` | `Gson`、`FastJson`、`new ObjectMapper()` |
| 对象 Copy | `BeanUtils`（common-base） | Spring `BeanUtils` |
| 日期时间 | `DateTimeUtility` + `LocalDateTimeUtils` | `SimpleDateFormat`、`java.util.Date` |
| 字符串判断 | `org.apache.commons.lang3.StringUtils` | 自行判空 |
| 集合操作 | `org.springframework.util.CollectionUtils` | 自行判空 |
| 断言校验 | `AssertHelper` | 手动 if-throw |
| 异常处理 | `BusinessException` | 吞掉异常不处理 |
| Redis 操作 | `RedisMapper` | `RedisTemplate` |
| 本地缓存 | `@LocalCacheable` | 手写缓存逻辑 |
| 安全/加密 | `Helper` | 自己实现加解密 |
| Bean 注入 | `@Resource` | `@Autowired`（尽量避免） |

### 其他常用工具

| 工具类 | 用途 |
|--------|------|
| `TxUtils` | 事务判断、事务提交后执行 |
| `EnumCommonUtil` | 枚举查找、描述获取、转下拉列表 |
| `TraceUtils` | 获取当前 traceId |
| `AsyncWorker` | 提交异步任务到 `commonThreadPool` |
| `SpringContextHelper` | 静态方法获取 Spring Bean |
| `LocalizedText` | i18n 文本获取（中文/印尼文等） |

---

## 4. 中间件使用规范

> **详细用法查阅** → `./middleware-reference.md`

### 关键约束

| 中间件 | 核心规则 |
|--------|---------|
| Nacos | 已自动接入，`@RefreshScope` + `RemoteConfigReader.getConfig()` 读配置 |
| Sentinel | `@SentinelResource` 限流熔断 |
| Feign | 必须加 `@AccessLog`，HTTP 调用必须用 FeignClient |
| XXL-JOB | Application 层，必须 `@AccessLog(prefix = "job")` |
| RabbitMQ | 发送 → `AbstractRabbitSender`，消费 → `AbstractRabbitReceiver` |
| Kafka | 发送 → `AbstractKafkaSender`，批量消费 → `AbstractKafkaBatchReceiver` |
| MyBatis-Plus | 分页用 `PageDto.of()`，批量插入用 `BatchSqlInjector` |
| Swagger | DTO 加 `@ApiModelProperty`，Controller 加 `@Api(tags = "...")` |

---

## 5. 数据表规范

- 表名必须加 `sfa_`，`ceo_`，`arch_` 前缀
- 必须包含 `create_at`、`modify_at`（自动更新）、`deleted`（逻辑删除）、operator
- 建议使用 BIGINT 自增主键
- **禁止物理删除**，使用逻辑删除
- 新增查询 SQL 必须使用 `EXPLAIN` 调优

---

## 6. 数据导出规范

- 导出流程：count → 判断数量 → 查询返回
- 单次导出不能超过 **10 万**，阈值写在 Nacos 中可动态变更
- 使用 `fastExcel` 分批查询、分批传输，防止 OOM
- 限制方式：限制时间范围 / 限制数量 / 限制查询结果数

---

## 7. 脚手架内置功能清单

**注意**：详细功能查阅 → `./scaffold-reference.md`

---

## 8. 代码提交前检查清单

**注意**：详细检查清单查阅 → `./checklist-reference.md`
