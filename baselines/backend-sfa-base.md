# Baseline：sfa-base

日期：2026-08-29  
仓库路径：`$RZ_REPO_SFA_BASE`（本机值见 `config/runtime_local.sh`）  
当前分支：扫描时为 `sit`  
仓库类型：Java 后端  
角色：SFA 基础能力仓（组织、人员、字典、菜单、通知、灰度等）；**不是**首个 CRUD 试点主仓

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `sfa-base` |
| git 远端名 | `sfa-base.git` |
| 技术栈 | Java 8、Maven、Spring Boot 2.2.5.RELEASE、Spring Cloud Hoxton.SR3、MyBatis Plus |
| packaging | Maven multi-module root `pom`，`artifactId: sfa-base` |
| Legacy OpenSpec observed | 有，路径 `openspec/`；只作为历史 context，不作为本控制面新需求门禁 |
| 已有 AGENTS.md | 有（OpenSpec 托管块，指向仓内 `openspec/AGENTS.md`） |

分层与 `sfa-sales-management` 相同：`api` / `application` / `domain` / `infrastructure` / `interfaces`。HTTP 映射写在 `sfa-base-api` 的 Feign `*Api` 上，Controller 实现该接口。

## 2. Maven 模块

| 模块 | 初步职责 |
| --- | --- |
| `sfa-base-api` | Feign API、DTO |
| `sfa-base-infrastructure` | mapper、外部依赖、基础设施 |
| `sfa-base-domain` | domain 层 |
| `sfa-base-application` | application service |
| `sfa-base-interfaces` | Controller、启动与配置、测试入口 |

## 3. 自测命令结果

```text
Command: mvn -q -DskipTests help:evaluate -Dexpression=project.artifactId -DforceStdout
Exit: 0
Output: sfa-base
```

本次未跑全量 `mvn -DskipTests compile`。改该仓后按第 4 节做最窄编译/测试，不要把未跑的编译写成已通过。

## 4. Harness 推荐验证命令

```bash
mvn -DskipTests compile
```

候选模块级：

```bash
mvn -pl sfa-base-interfaces -am -DskipTests compile
mvn -pl sfa-base-application -am -DskipTests compile
mvn -pl sfa-base-infrastructure -am -DskipTests compile
```

候选 targeted test：

```bash
mvn -pl sfa-base-interfaces -Dtest=<TestClass> test
```

## 5. 测试现状

测试主要集中在：

```text
sfa-base-interfaces/src/test/java
```

样板测试候选：

| 类型 | 路径 |
| --- | --- |
| 微信通知 | `.../interfaces/AppWechatNotify*Test.java` |
| 灰度 | `.../interfaces/grayfeature/*Test.java` |

## 6. Controller / 样板候选

优先仿写已有 `*Api` + Controller + Application，不要新建另一套分层。

| 路径 | 说明 |
| --- | --- |
| `sfa-base-api/.../OrganizationApi.java` + `OrganizationController.java` | `@PostMapping("/org/getOrgAndPositionByPerson")`，组织 |
| `sfa-base-api/.../SfaDictCodeApi.java` + `SfaDictCodeController.java` | `@PostMapping("/dict/list")`，字典 |
| `sfa-base-api/.../GrayFeatureApi.java` + `GrayFeatureController.java` | `@PostMapping("/grayFeature/service/check")`，灰度判定 |

`DemoController` 不适合当业务样板。

## 7. 受保护路径

默认禁止 AI 修改，除非 spec 明确允许：

```text
sfa-base-interfaces/src/main/resources/bootstrap.yml
**/application-prod.yml
**/bootstrap-prod.yml
**/.env*
**/db/migration/**
```

浅扫见 `bootstrap.yml`；未发现 `db/migration`。真实 schema 变更须用户二次确认。

## 8. 已知 warning / baseline 噪声

未做全量 compile，不把未观测到的 warning 写成本仓事实。后续 sensor 只把**本次 diff 引入**的失败当新问题。

## 9. 使用建议

按需求启用的基础仓。改之前确认：PRD 是否真落在组织/字典/灰度/通知等域；选定 Api + Controller 样板；默认不改 bootstrap 与生产配置。
