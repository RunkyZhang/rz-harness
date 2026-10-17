# Baseline：arch-notification

日期：2026-10-17  
仓库路径：`$RZ_REPO_ARCH_NOTIFICATION`（本机值见 `config/runtime_local.sh`）  
当前分支：扫描时为 `master`  
仓库类型：Java 后端  
角色：统一通知服务（站内信 / 联系人 / 告警等）

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `arch-notification` |
| 技术栈 | Java 8、Maven、Spring Boot 2.2.5.RELEASE、Spring Cloud Hoxton.SR3、MyBatis-Plus |
| packaging | Maven multi-module root `pom`，`artifactId: arch-notification` |
| Legacy OpenSpec observed | 未发现 |
| 已有 AGENTS.md | 未确认（改前先看仓内是否有） |

分层与其它 arch 后端一致：`interfaces` / `api` / `application` / `domain` / `infrastructure`。Controller 在 `arch-notification-interfaces`。

关键依赖：`sfa-common-base` / `sfa-common-architecture`、MyBatis-Plus、dynamic-datasource、XXL-JOB、个推 `gexin-rp-sdk-http`、Freemarker、`arch-open-api`。

## 2. Maven 模块

| 模块 | 初步职责 |
| --- | --- |
| `arch-notification-api` | Feign API、DTO |
| `arch-notification-infrastructure` | mapper、外部依赖、基础设施 |
| `arch-notification-domain` | domain 层 |
| `arch-notification-application` | application service / 通知发送逻辑 |
| `arch-notification-interfaces` | Controller、启动与配置、测试入口 |

## 3. 自测命令结果

本次只做只读扫描，**未跑** `mvn -DskipTests compile`。不要把未跑的编译写成已通过。

## 4. Harness 推荐验证命令

```bash
mvn -DskipTests compile
mvn -pl arch-notification-interfaces -DskipTests compile
mvn -pl arch-notification-application -DskipTests compile
```

候选 targeted test：

```bash
mvn -pl arch-notification-application -Dtest=InAppMessageServiceTest test
```

## 5. 测试现状

测试主要在 `arch-notification-interfaces` 与 `arch-notification-application`：

| 类型 | 路径（简写） |
| --- | --- |
| 启动 | `.../interfaces/UserBaseInterfacesApplicationTests.java` |
| Controller | `.../interfaces/controller/InAppMessageControllerTest.java` |
| Notifier 映射 | `.../application/notifier/InAppMessageNotifierMappingTest.java` |
| Service | `.../application/InAppMessageServiceTest.java` |

## 6. Controller / 样板候选

优先仿写已有 Api + Controller + Application。已见 Controller：

`EmployeeContactController`、`NotificationController`、`AlertController`、`ContactPointController`。

`DemoController` 不适合当业务样板。

## 7. 受保护路径

默认禁止 AI 修改，除非 spec 明确允许：

```text
arch-notification-interfaces/src/main/resources/bootstrap.yml
**/application-prod.yml
**/bootstrap-prod.yml
**/.env*
**/db/migration/**
```

## 8. 已知 warning / baseline 噪声

未做全量 compile，不把未观测到的 warning 写成本仓事实。后续 sensor 只把**本次 diff 引入**的失败当新问题。

## 9. 使用建议

改之前确认：PRD 是否真落在站内信 / 联系人 / 告警 / 推送模板等域；选定对应 Controller + Application 样板；默认不改 bootstrap 与生产配置。
