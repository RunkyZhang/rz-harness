# Baseline：backend-sfa-backend

日期：2026-05-19  
仓库路径：`/Users/00555733/codex/sfa-projects/sfa-backend`  
当前分支：`codex/harness-self-test-20260519`  
仓库类型：Java 后端  
试点角色：纳入 registry 和 baseline，暂不作为首个 CRUD 主仓

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `backend-sfa-backend` |
| Codeup 远端 | `want_sfa/sfa-backend.git` |
| 技术栈 | Java 8、Maven、Spring Boot 2.2.5、Spring Cloud、MyBatis Plus、Nacos、XXL-JOB |
| packaging | Maven multi-module root `pom` |
| Legacy OpenSpec observed | 有，路径 `openspec/`；只作为历史 context，不作为新需求门禁 |
| 已有 AGENTS.md | 未发现 |

## 2. Maven 模块

| 模块 | 初步职责 |
| --- | --- |
| `wantwant-sfa-backend-openapi` | OpenAPI / 对外契约包 |
| `wantwant-sfa-backend-api` | API / DTO / 公共接口 |
| `wantwant-sfa-backend-service` | service、mapper、业务实现 |
| `wantwant-sfa-backend-webapi` | controller、web API、测试入口 |

## 3. 自测命令结果

```text
Command: mvn -q -DskipTests help:evaluate -Dexpression=project.artifactId -DforceStdout
Exit: 0
Output: sfa-backend
```

```text
Command: mvn -DskipTests compile
Exit: 0
Result: BUILD SUCCESS
Total time: 01:52 min
```

Reactor 结果：

```text
sfa-backend SUCCESS
wantwant-sfa-backend-openapi SUCCESS
wantwant-sfa-backend-api SUCCESS
wantwant-sfa-backend-service SUCCESS
wantwant-sfa-backend-webapi SUCCESS
```

## 4. Harness 推荐验证命令

根编译可用，但耗时较长。推荐后续按模块收窄：

```bash
mvn -DskipTests compile
```

候选模块级命令：

```bash
mvn -pl wantwant-sfa-backend-webapi -am -DskipTests compile
mvn -pl wantwant-sfa-backend-service -am -DskipTests compile
mvn -pl wantwant-sfa-backend-openapi -am -DskipTests compile
```

候选 targeted test：

```bash
mvn -pl wantwant-sfa-backend-webapi -Dtest=<TestClass> test
```

## 5. 测试现状

测试主要集中在：

```text
wantwant-sfa-backend-webapi/src/test/java
```

样板测试候选：

| 类型 | 路径 |
| --- | --- |
| BD 导入验证 | `businessBd/BdControlImportServiceTest.java` |
| 客户 / 终端相关 | `customer/**`、`customerMaintain/**` |
| 钱包 / 业务流程 | `wallet/**`、`mockTest/**` |
| 地图 / 组织 | `map/**`、`organization/**` |

## 6. Controller / 样板候选

可作为接口样板的 Controller：

| 路径 | 说明 |
| --- | --- |
| `wantwant-sfa-backend-webapi/src/main/java/.../businessBd/controller/BusinessBdControlController.java` | `/businessBdControl`，BD 控制类接口 |
| `wantwant-sfa-backend-webapi/src/main/java/.../customer/controller/TradingCustomerController.java` | `/tradingCustomer`，客户类接口 |
| `wantwant-sfa-backend-webapi/src/main/java/.../controller/DisplayQuotaRuleController.java` | `/displayQuotaRule`，规则类接口 |
| `wantwant-sfa-backend-webapi/src/main/java/.../notify/NotifyController.java` | `/notify`，通知接口 |

## 7. 受保护路径

默认禁止 AI 修改，除非 spec 明确允许：

```text
**/application-prod.yml
**/bootstrap-prod.yml
**/.env*
**/db/migration/**
**/src/main/resources/**
```

说明：

- 当前浅扫未发现明显 prod 配置文件，但后续 baseline 应更细查 `src/main/resources`。
- 首个 CRUD 试点不建议修改此仓；如涉及 downstream 依赖，只做只读影响分析。

## 8. 已知 warning / baseline 噪声

自测 root compile 通过，但存在已有 warning：

- `wantwant-sfa-backend-service` 的 `mybatis-generator-maven-plugin` 未指定 version；Maven 因 Java 8 选择兼容的 `1.4.2`。
- `wantwant-sfa-backend-openapi` 的 version 使用 expression。
- 存在 deprecated / unchecked API warning。

这些 warning 当前不阻断 compile。后续 sensor 不能把这些既有 warning 当成新改动失败。

## 9. 试点关系

Phase 0-2 只做 baseline 和影响分析。首个 CRUD 试点不建议同时改 `backend-sales-management` 和本仓；如必须跨后端，需先更新 spec 并由用户确认。 

## 10. 特陈线下审核照片多图需求补充

来源：`changes/special-display-department-photo-list`，2026-05-26 只读扫描。

关键路径：

```text
wantwant-sfa-backend-api/src/main/java/com/wantwant/sfa/backend/display/request/UploadDetails.java
wantwant-sfa-backend-service/src/main/java/com/wantwant/sfa/backend/service/impl/DisplayProcessServiceImpl.java
wantwant-sfa-backend-service/src/main/java/com/wantwant/sfa/backend/service/impl/DisplayInfoServiceImpl.java
wantwant-sfa-backend-service/src/main/resources/mapper/displayInfoMapper.xml
```

本需求证据：

- 区域经理近/远景当前为 `departmentNearPictureUrl` / `departmentFarPictureUrl` string 字段。
- 现场稽核已有 `checkNearPictureUrlList` / `checkFarPictureUrlList` 和隐藏 string 落库字段。
- 当前已有现场稽核 list 转逗号 string、string 转 list 的 service 方法。
- mapper 写入现有 `department_near_picture_url`、`department_far_picture_url` 列。

实施注意：

- 推荐沿用现场稽核转换模式，新增区域经理 list/string 双向转换。
- 新增 list 字段上限为 4，不影响现场稽核最多 10 张规则。
- 不需要 DB migration。
