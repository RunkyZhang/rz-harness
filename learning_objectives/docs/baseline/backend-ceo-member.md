# Baseline：backend-ceo-member

日期：2026-06-29
仓库路径变量：`$SFA_REPO_BACKEND_CEO_MEMBER`
当前分支：`master`
仓库类型：Java 后端
本次角色：CEO member 后端，按需求参与会员、费用、库存、活动等业务域改动

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `backend-ceo-member` |
| Codeup 远端 | `want/backend_ceo/backend-ceo-member.git` |
| 技术栈 | Java 8、Maven、Spring Boot、Spring Cloud Alibaba / Nacos、MyBatis Plus、Redis、RabbitMQ、Kafka、XXL-JOB |
| packaging | Maven multi-module root `pom` |
| 本地默认端口 | `9168` |
| 本地 context path | `/backend-ceo-member` |
| Legacy OpenSpec observed | 未发现 |
| 已有 AGENTS.md | 未发现 |

## 2. Maven 模块

| 模块 | 初步职责 |
| --- | --- |
| `backend-ceo-member-openapi` | OpenAPI / Feign 对外契约包 |
| `backend-ceo-member-api` | API / DTO / VO / 公共接口 |
| `backend-ceo-member-service` | service、mapper、业务实现、资源 mapper XML |
| `backend-ceo-member-webapi` | Spring Boot 入口、controller、task、web API |
| `backend-ceo-member-test` | 既有测试样板 |

## 3. 本地配置线索

只读扫描显示：

- `backend-ceo-member-webapi/src/main/resources/config/application-dev.yml`、`application-test-local.yml`、`application-stg-local.yml` 均声明 `server.port: 9168` 和 `server.servlet.context-path: /backend-ceo-member`。
- `bootstrap-*.yml` 中包含 Nacos 配置；真实环境启动前必须在 `environment-readiness.md` 记录 profile、Nacos、DB、Redis、MQ、Kafka、XXL-JOB 和账号来源。
- 线上/测试 gateway 侧可能使用 `/backend/backend-ceo-member` 前缀；本地 proxy 模板会把该前缀转到本地 `/backend-ceo-member`。

## 4. Harness 推荐验证命令

根编译可用性和耗时待实测。优先按模块收窄：

```bash
mvn -DskipTests compile
mvn -pl backend-ceo-member-webapi -am -DskipTests compile
mvn -pl backend-ceo-member-service -am -DskipTests compile
```

候选 targeted test：

```bash
mvn -pl backend-ceo-member-test -Dtest=<TestClass> test
```

## 5. 测试现状

测试集中在：

```text
backend-ceo-member-test/src/test/java
```

样板测试候选：

| 类型 | 路径 |
| --- | --- |
| Mapper / 基础样板 | `com/wantwant/backend/ceo/member/test/mapper/MemberMapperTest.java` |
| 会员上级查询 | `com/wantwant/backend/ceo/member/test/manager/MemberSuperiorQueryManagerTest.java` |
| 活动 / 导购 | `com/wantwant/backend/ceo/member/test/manager/ActShoppingGuideManagerTest.java` |
| 库存 / 异常 | `com/wantwant/backend/ceo/member/test/service/AbnormalInventoryPenaltyTest.java` |
| 会员任务 | `com/wantwant/backend/ceo/member/service/impl/MemberTaskServiceImplTest.java` |

## 6. Controller / 样板候选

可作为接口样板的 Controller：

| 路径 | 说明 |
| --- | --- |
| `backend-ceo-member-webapi/src/main/java/com/wantwant/backend/ceo/member/controller/CustomerVisitRuleController.java` | 客户拜访规则类接口 |
| `backend-ceo-member-webapi/src/main/java/com/wantwant/backend/ceo/member/controller/MemberManagementController.java` | 会员管理类接口 |
| `backend-ceo-member-webapi/src/main/java/com/wantwant/backend/ceo/member/controller/RechargeManagementController.java` | 充值管理类接口 |
| `backend-ceo-member-webapi/src/main/java/com/wantwant/backend/ceo/member/controller/MemberTaskController.java` | 会员任务类接口 |

## 7. 受保护路径

默认禁止 AI 修改，除非 spec 明确允许：

```text
**/application-prod.yml
**/bootstrap-prod.yml
**/.env*
**/db/migration/**
**/src/main/resources/config/**
```

说明：

- `src/main/resources/config` 包含 Nacos / 环境 / 外部依赖配置，真实变更前必须有明确 spec 和人工确认。
- `backend-ceo-member-service/src/main/resources/mapper/**` 属于业务 SQL 改动面；修改时必须跑 Java / XML 机械门禁和 targeted test 或记录阻塞。

## 8. 开工注意

- 新需求默认使用 harness 控制面 `changes/<change-id>/`，不要在业务仓新增 repo-local OpenSpec；业务仓已有 OpenSpec 仅作为 legacy context 读取。
- 该仓业务域较宽，需求进入实现前必须先按 PRD 收窄到具体 controller / service / mapper / test 路径。
- 真实 SIT/UAT/生产 DB 默认只读；任何写入、DDL、job 触发或状态型 API 调用必须走 `AGENTS.md` 的二次确认边界。
