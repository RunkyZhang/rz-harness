# Baseline：sfa-data-fusion

日期：2026-10-17  
仓库路径：`$RZ_REPO_SFA_DATA_FUSION`（本机值见 `config/runtime_local.sh`）  
当前分支：扫描时为 `release_main`  
仓库类型：Java 后端  
角色：数据融合 / BI 报表与看板、库存与订单等数据服务

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `sfa-data-fusion` |
| 技术栈 | Java 8、Maven、Spring Boot 2.2.5.RELEASE、Spring Cloud Hoxton.SR3、MyBatis-Plus |
| packaging | Maven multi-module root `pom`，`artifactId: sfa-data-fusion` |
| Legacy OpenSpec observed | 有，路径 `openspec/`；只作为历史 context，不作为本控制面新需求门禁 |
| 已有 AGENTS.md | 未确认（改前先看仓内是否有） |

分层与其它 SFA 后端一致：`interfaces` / `api` / `application` / `domain` / `infrastructure`。Controller 在 `sfa-data-fusion-interfaces`。

关键依赖：`sfa-common-base` / `sfa-common-architecture`、MyBatis-Plus、dynamic-datasource、XXL-JOB、Redisson、Knife4j、fastexcel、PDFBox、`arch-notification-api`。

## 2. Maven 模块

| 模块 | 初步职责 |
| --- | --- |
| `sfa-data-fusion-api` | Feign API、DTO |
| `sfa-data-fusion-infrastructure` | mapper、外部依赖、基础设施 |
| `sfa-data-fusion-domain` | domain 层 |
| `sfa-data-fusion-application` | application service / 业务逻辑 |
| `sfa-data-fusion-interfaces` | Controller、启动与配置、测试入口 |

## 3. 自测命令结果

本次只做只读扫描，**未跑** `mvn -DskipTests compile`。不要把未跑的编译写成已通过。

## 4. Harness 推荐验证命令

```bash
mvn -DskipTests compile
mvn -pl sfa-data-fusion-interfaces -DskipTests compile
mvn -pl sfa-data-fusion-application -DskipTests compile
```

候选 targeted test：

```bash
mvn -pl sfa-data-fusion-interfaces -Dtest=BiDashboardControllerTest test
```

## 5. 测试现状

测试主要在 `sfa-data-fusion-interfaces/src/test/java`（另有部分在 `application` 模块）。已见候选：

| 类型 | 路径（简写） |
| --- | --- |
| Job | `.../handler/PartnerStockJobHandlerTest.java` |
| Service | `.../application/BiServiceTest.java` |
| 报表 Service | `.../service/ProductGroupPerformanceReportServiceTest.java` |
| Controller | `.../interfaces/controller/BiDashboardControllerTest.java` |

## 6. Controller / 样板候选

优先仿写已有 Api + Controller + Application，不要新建另一套分层。已见 Controller：

`WarehouseController`、`ProductInfoDashboardController`、`OrderController`、`QuickBiDashboardConfigController`、`PartnerStockController`、`ProcessAuditDataController`、`BigDataForVisitController`、`TradingOnboardPartnerController`、`BiController`、`BiDashboardController`、`RealTimeInventoryController`、`ProcessManagementReportController`、`BigDataForMapController`、`TransportFeeManagementController`。

`DemoController` 不适合当业务样板。

## 7. 受保护路径

默认禁止 AI 修改，除非 spec 明确允许：

```text
sfa-data-fusion-interfaces/src/main/resources/bootstrap.yml
**/application-prod.yml
**/bootstrap-prod.yml
**/.env*
**/db/migration/**
```

## 8. 已知 warning / baseline 噪声

未做全量 compile，不把未观测到的 warning 写成本仓事实。后续 sensor 只把**本次 diff 引入**的失败当新问题。

## 9. 使用建议

改之前确认：PRD 是否真落在数据融合 / BI / 库存 / 订单等域；选定对应 Controller + Application 样板；默认不改 bootstrap 与生产配置。
