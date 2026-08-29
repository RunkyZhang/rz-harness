# Baseline：backend-sales-management

日期：2026-08-29
仓库路径：`$RZ_REPO_SFA_SALES_MANAGEMENT`（本机值见 `config/runtime_local.sh`）  
当前分支：`codex/harness-self-test-20260519`  
仓库类型：Java 后端  
试点角色：首个 Fullstack CRUD lane 的后端主仓

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `backend-sales-management` |
| Codeup 远端 | `want_sfa/sfa-sales-management.git` |
| 技术栈 | Java 8、Maven、Spring Boot 2.2.5、Spring Cloud Hoxton.SR3、MyBatis Plus |
| packaging | Maven multi-module root `pom` |
| Legacy OpenSpec observed | 有，路径 `openspec/`；只作为历史 context，不作为新需求门禁 |
| 已有 AGENTS.md | 有 |

## 2. Maven 模块

| 模块 | 初步职责 |
| --- | --- |
| `sfa-sales-management-api` | API DTO / 对外包 |
| `sfa-sales-management-infrastructure` | mapper、entity、RPC、基础设施实现 |
| `sfa-sales-management-domain` | domain 层 |
| `sfa-sales-management-application` | application service、request/response、业务编排 |
| `sfa-sales-management-interfaces` | controller、job、配置、测试入口 |

## 3. 自测命令结果

```text
Command: mvn -q -DskipTests help:evaluate -Dexpression=project.artifactId -DforceStdout
Exit: 0
Output: sfa-sales-management
```

```text
Command: mvn -DskipTests compile
Exit: 0
Result: BUILD SUCCESS
Total time: 57.821 s
```

Reactor 结果：

```text
sfa-sales-management SUCCESS
sfa-sales-management-api SUCCESS
sfa-sales-management-infrastructure SUCCESS
sfa-sales-management-domain SUCCESS
sfa-sales-management-application SUCCESS
sfa-sales-management-interfaces SUCCESS
```

## 4. Harness 推荐验证命令

根编译可用，但对每次小改来说偏重。推荐分层使用：

```bash
mvn -DskipTests compile
```

候选模块级命令：

```bash
mvn -pl sfa-sales-management-interfaces -am -DskipTests compile
mvn -pl sfa-sales-management-application -am -DskipTests compile
mvn -pl sfa-sales-management-infrastructure -am -DskipTests compile
```

候选 targeted test：

```bash
mvn -pl sfa-sales-management-interfaces -Dtest=<TestClass> test
```

## 5. 测试现状

测试主要集中在：

```text
sfa-sales-management-interfaces/src/test/java
```

样板测试候选：

| 类型 | 路径 |
| --- | --- |
| Controller 测试 | `sfa-sales-management-interfaces/src/test/java/.../interfaces/controller/*Test.java` |
| 稽核相关测试 | `sfa-sales-management-interfaces/src/test/java/.../interfaces/audit/*Test.java` |
| 终端/客户拜访测试 | `sfa-sales-management-interfaces/src/test/java/.../interfaces/visit/*Test.java` |
| Distribution QR 回归 | `DistributionQrServiceOpenBoxAiRecognitionTest.java`、`DistributionQrServiceScanLimitTest.java` |

## 6. Controller / 样板候选

可作为 CRUD / 列表接口样板的 Controller：

| 路径 | 说明 |
| --- | --- |
| `sfa-sales-management-interfaces/src/main/java/.../controller/CustomerVisitRuleController.java` | `/customerVisitRule`，规则类接口 |
| `sfa-sales-management-interfaces/src/main/java/.../controller/audit/AuditTaskController.java` | `/audit/task`，稽核任务接口 |
| `sfa-sales-management-interfaces/src/main/java/.../controller/audit/AuditBizManageController.java` | `/audit/bizManage`，后台管理类接口 |
| `sfa-sales-management-interfaces/src/main/java/.../controller/CompleteRuleController.java` | `/completeRule`，规则配置接口 |

首个 CRUD 试点应优先选一个已有 Controller + Application service + DTO 结构相近的样板。

## 7. 受保护路径

默认禁止 AI 修改，除非 spec 明确允许：

```text
sfa-sales-management-interfaces/src/main/resources/bootstrap.yml
openspec/changes/*/migration.sql  # legacy path; read-only context
**/application-prod.yml
**/bootstrap-prod.yml
**/.env*
**/db/migration/**
```

说明：

- 当前浅扫发现 `bootstrap.yml` 和多份历史 `migration.sql`。
- 真实需求如需 DB schema，应单独进入用户确认，不作为首个 CRUD 默认路径。

## 8. 已知 warning / baseline 噪声

自测 root compile 通过，但存在已有 warning：

- root / infrastructure POM 中存在重复 `commons-lang3` dependency 声明。
- 多个 Lombok DTO 有 `equals/hashCode` 未显式 `callSuper` warning。
- 多个 `@Builder` 默认值 warning。
- druid POM 存在 `tools` / `jconsole` 的 invalid `systemPath` warning。

这些 warning 当前不阻断 compile。后续 sensor 不能把这些既有 warning 当成新改动失败。

## 9. 首个试点建议

适合作为首个 CRUD 后端主仓。试点前必须确认：

1. 具体 PRD / 需求 ID。
2. 选定 Controller / Application / DTO 样板。
3. 是否需要 DB schema，默认不需要。
4. `mapSystem` 前端契约字段与后端 DTO 字段是否一致。
