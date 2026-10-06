# Baseline：arch-event

日期：2026-08-29  
仓库路径：`$RZ_REPO_ARCH_EVENT`（本机值见 `config/runtime_local.sh`）  
当前分支：扫描时为 `master`  
仓库类型：Java 后端  
角色：事件采集服务；体量小于 `sfa-base` / `arch-open`，**不是** CRUD 试点主仓

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `arch-event` |
| git 远端名 | `arch-event.git` |
| 技术栈 | Java 8、Maven、Spring Boot 2.2.5.RELEASE、Spring Cloud Hoxton.SR3、MyBatis Plus |
| packaging | Maven multi-module root `pom`，`artifactId: arch-event` |
| Legacy OpenSpec observed | 未发现 |
| 已有 AGENTS.md | 未发现 |

分层与 `sfa-sales-management` 相同。主入口 `EventApi` `@RequestMapping("event")`，`EventController` 实现该接口。

## 2. Maven 模块

| 模块 | 初步职责 |
| --- | --- |
| `arch-event-api` | Feign API、DTO（含 `CollectEventRequestDto` 等） |
| `arch-event-infrastructure` | 配置（`ConfigSource`）、基础设施 |
| `arch-event-domain` | domain 层 |
| `arch-event-application` | `EventService` 等 |
| `arch-event-interfaces` | `EventController`、`DemoController`、启动与配置 |

## 3. 自测命令结果

```text
Command: mvn -q -DskipTests help:evaluate -Dexpression=project.artifactId -DforceStdout
Exit: 0
Output: arch-event
```

本次未跑全量 `mvn -DskipTests compile`。

## 4. Harness 推荐验证命令

```bash
mvn -DskipTests compile
```

候选模块级：

```bash
mvn -pl arch-event-interfaces -am -DskipTests compile
mvn -pl arch-event-application -am -DskipTests compile
```

浅扫未见 `src/test/java` 下 `*Test.java`。有测试后再补 `-Dtest=`；没有则 evidence 写明 N/A。

## 5. 测试现状

未发现模块测试目录中的 `*Test.java`。新行为必须在 verification map 里写清如何验（编译 + 手工/联调），不能假装已有单测。

## 6. Controller / 样板候选

| 路径 | 说明 |
| --- | --- |
| `arch-event-api/.../EventApi.java` + `EventController.java` | `@RequestMapping("event")`；`collect` / `collectAsync`；批次上限 50；async 校验 `ConfigSource.getCollectAccessKey()` |

只应在此结构上扩展事件采集。`DemoController` 不适合当业务样板。采集 access key 不得写入版本化文档。

## 7. 受保护路径

```text
arch-event-interfaces/src/main/resources/bootstrap.yml
**/application-prod.yml
**/bootstrap-prod.yml
**/.env*
**/db/migration/**
```

## 8. 已知 warning / baseline 噪声

未做全量 compile。后续只把本次 diff 引入的失败当新问题。

## 9. 使用建议

仅当需求明确改事件采集时启用。改之前确认：同步/异步接口、批次限制、key 校验是否仍适用；默认不改 bootstrap。
