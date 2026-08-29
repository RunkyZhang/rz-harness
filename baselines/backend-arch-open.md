# Baseline：arch-open

日期：2026-08-29  
仓库路径：`$RZ_REPO_ARCH_OPEN`（本机值见 `config/runtime_local.sh`）  
当前分支：扫描时为 `sit`  
仓库类型：Java 后端  
角色：开放平台 / 第三方能力聚合（地图、短信、企微、AI、推送等）；**不是**后台 CRUD 主仓

## 1. 仓库识别

| 项 | 内容 |
| --- | --- |
| Repo ID | `arch-open` |
| git 远端名 | `arch-open.git` |
| 技术栈 | Java 8、Maven、Spring Boot 2.2.5.RELEASE、Spring Cloud Hoxton.SR3、MyBatis Plus |
| packaging | Maven multi-module root `pom`，`artifactId: arch-open` |
| Legacy OpenSpec observed | 有，路径 `openspec/`；只作为历史 context |
| 已有 AGENTS.md | 有（OpenSpec 托管块） |

分层与 `sfa-sales-management` 相同。路径写在 `arch-open-api` 的 `*Api` `@RequestMapping` 上，Controller 实现接口。

## 2. Maven 模块

| 模块 | 初步职责 |
| --- | --- |
| `arch-open-api` | Feign API、DTO |
| `arch-open-infrastructure` | 第三方客户端、配置、基础设施 |
| `arch-open-domain` | domain 层 |
| `arch-open-application` | application service |
| `arch-open-interfaces` | Controller、启动与配置 |

## 3. 自测命令结果

```text
Command: mvn -q -DskipTests help:evaluate -Dexpression=project.artifactId -DforceStdout
Exit: 0
Output: arch-open
```

本次未跑全量 `mvn -DskipTests compile`。

## 4. Harness 推荐验证命令

```bash
mvn -DskipTests compile
```

候选模块级：

```bash
mvn -pl arch-open-interfaces -am -DskipTests compile
mvn -pl arch-open-application -am -DskipTests compile
```

测试很少，targeted test 仅在确有对应用例时使用：

```bash
mvn -pl arch-open-api -Dtest=BlTerminalOrderImageRecognitionResponseDtoTest test
```

## 5. 测试现状

浅扫几乎只有：

```text
arch-open-api/src/test/java/.../BlTerminalOrderImageRecognitionResponseDtoTest.java
```

新行为不要只靠「没有单测」。能补模块测试则补；否则在 evidence 写明 N/A 原因。

## 6. Controller / 样板候选

仿写同一供应商的 `*Api` + Controller + Application + `ConfigSource` 密钥读取方式，不要把密钥写进代码或版本化文档。

| 路径 | 说明 |
| --- | --- |
| `AMapApi` `@RequestMapping("/amap")` + `AMapController` | 高德 |
| `WeComImApi` `@RequestMapping("/wecom/im")` + `WeComImController` | 企微 IM |
| `SfaAiApi` `@RequestMapping("/sfa/ai")` + `SfaAiController` | SFA AI |
| `GetuiAppPushApi` `@RequestMapping("/getui/appPush")` | 个推 |

`DemoController` 不适合当业务样板。第三方密钥、回调 token 只来自本机配置或钥匙串。

## 7. 受保护路径

```text
arch-open-interfaces/src/main/resources/bootstrap.yml
**/application-prod.yml
**/bootstrap-prod.yml
**/.env*
**/db/migration/**
```

## 8. 已知 warning / baseline 噪声

未做全量 compile。后续只把本次 diff 引入的失败当新问题。

## 9. 使用建议

按外部系统接入需求启用。改之前确认：调用的是哪个供应商路径；样板是否同一套 Assert + `RpcResult` + `ConfigSource`；禁止把第三方凭据写入 spec/evidence。
