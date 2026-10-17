# Baseline：sfa-common-sdk

日期：2026-10-17  
仓库路径：`$RZ_REPO_SFA_COMMON_SDK`（本机值见 `config/runtime_local.sh`）  
当前分支：扫描时为 `master`  
仓库类型：Java 基础 jar 包（**不是服务、不部署、无启动类**）  
角色：给后端服务提供标准化与公共工具

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `sfa-common-sdk` |
| 技术栈 | Java 8、Maven、Spring Boot 2.2.5.RELEASE、Spring Cloud Alibaba（Nacos / Sentinel） |
| packaging | multi-module pom，`artifactId: sfa-common`；产出 **jar**，不是可执行应用 |
| 使用方式 | 后端服务以 Maven 依赖引入（`sfa-common-base` / `sfa-common-architecture`） |
| Legacy OpenSpec observed | 未发现 |
| 已有 AGENTS.md | 无 |

> 注意：改这里不是"改一个服务"，而是改**所有依赖它的后端服务的公共底座**。公共 API / DTO / 注解 / 拦截器 / 自动配置的变更都可能影响下游，必须先评估影响面。

## 2. Maven 模块

| 模块 | 初步职责 |
| --- | --- |
| `sfa-common-base` | 基础 DTO、`RpcResult`、注解、枚举、断言、加解密、异常等 |
| `sfa-common-architecture` | 本地缓存、Feign 拦截、日志、MQ、事件、登录、Controller 支撑、Spring 工具等 |

## 3. 包 / 关键类（扫描所见）

`sfa-common-base`：

- dto：`BaseDto`、`RequestBaseDto`、`RpcResult`、`PageDto`、`PageRequestBaseDto`、`OrderItemDto`、`CommonLabelValueDTO`、`EventDto`、`BinlogDto`
- `Helper`、`AssertHelper`、`JacksonEnumInterface`
- enums：`BaseEnum`、`StringEnum`
- annotation：`AccessLog`、`AuditLog`、`GlobalTimezone`、`Resubmit`、`AccessLoginStatus`

`sfa-common-architecture`：

- cache：`LocalCacheable`、`LocalCache`、`LocalCacheManager`、`LocalCacheProcessor`、`KeyBuilder`、`ExpressionEvaluator`
- invoking：`FeignClientRequestInterceptor`、`InvokingLogProcessor`
- utils：`BeanUtils`、`TxUtils`、`EnumCommonUtil`、`LocalDateTimeUtils`
- `SpringContextHelper`、`ComponentHelper`、`RemoteConfigReader`
- controller：body / error / interceptor
- log / mq / event / global / login / rt

## 4. Harness 推荐验证命令

```bash
mvn -DskipTests compile
mvn -pl sfa-common-base -DskipTests compile
mvn -pl sfa-common-architecture -DskipTests compile
```

## 5. 测试现状

未发现 `src/test`。公共 jar 的改动没有现成单测兜底，必须做**下游编译验证**：至少挑一个依赖它的服务（如 `sfa-sales-management` / `sfa-backend`）跑 `mvn -DskipTests compile`。

## 6. 受保护路径 / 兼容性

默认禁止 AI 修改，除非 spec 明确允许：

```text
pom.xml                                          # 版本 / 依赖管理
**/src/main/resources/META-INF/spring.factories  # 自动配置注册
```

兼容性约束：

- public 类 / 方法 / 注解 / 常量属于下游契约；改名、删字段、改签名都要按契约变更处理。
- 新增能力优先用新增类 / 新增方法实现，不破坏既有调用方。

## 7. 使用建议

适合作为"标准化能力"变更仓，不适合作为业务 CRUD 主仓。改前确认：影响哪些下游服务、是否需要同步升级依赖版本、是否有兼容性回退方案。
