# 代码提交前检查清单

提交代码前，请逐项检查以下规范是否已遵守：

## 架构分层

- [ ] 严格遵循 5 模块分层，各层只依赖下层，无反向依赖
- [ ] API Module 中 FeignClient 使用 POST + 单一入参 + `RpcResult` 出参
- [ ] 不在 Interface 层写复杂业务逻辑，只做简单数据转换，参数校验

## POM 规范

- [ ] 版本号在父 POM 中统一管理，子模块不硬编码

## 工具类使用

- [ ] JSON 操作使用 `JacksonHelper`，不使用 Gson/FastJson
- [ ] 对象复制使用 base-common `BeanUtils`，不使用 Spring `BeanUtils`
- [ ] 日期时间使用 `DateTimeUtility` + `LocalDateTimeUtils`
- [ ] 字符串判断使用 `org.apache.commons.lang3.StringUtils`
- [ ] 集合空判断使用 `org.springframework.util.CollectionUtils`
- [ ] 断言使用 `AssertHelper` 或 `org.springframework.util.Assert`
- [ ] 异常使用 `BusinessException`
- [ ] Redis 使用 `RedisMapper`，不直接使用 `RedisTemplate`
- [ ] 本地缓存使用 `@LocalCacheable`
- [ ] Bean 注入使用 `@Resource`

## 中间件使用

- [ ] MQ 发送继承 `AbstractRabbitSender`，`AbstractKafkaSender`。消费继承 `AbstractRabbitReceiver`，`AbstractKafkaBatchReceiver`
- [ ] XXL-JOB 方法加 `@AccessLog(prefix = "job")`
- [ ] RPC 调用加 `@AccessLog`

## 数据表规范

- [ ] 数据表含 created_at、modify_at、deleted、operator + （sfa_，ceo_，arch_）前缀
- [ ] 禁止物理删除，使用逻辑删除
- [ ] 新增 SQL 使用 EXPLAIN 调优

## 数据导出

- [ ] 数据导出不超 10 万，分批查询分批传输

## API 文档

- [ ] DTO 字段加 `@ApiModelProperty("说明")`
