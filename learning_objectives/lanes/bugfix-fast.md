# Bugfix Fast Lane

> 适用于范围清晰、可复现、可回归验证的 bugfix。核心原则：先反馈环，再修复。

## 适用条件

- 用户报告了明确异常、错误结果、性能回退或线上/SIT 问题。
- 能在本地、测试环境、日志、请求报文、单测或脚本中构造反馈环。
- 修改范围可控制在一个主仓或明确的少量文件内。
- 不默认触碰 DB migration、生产配置、部署脚本、权限体系。

## 不适用

- 无法描述症状，也没有日志、请求、截图、录屏或环境信息。
- 涉及复杂状态机、财务/订单/考核口径、生产数据修复。
- 需要产品重新定义业务规则。

## 标准流程

1. 创建 `changes/<change-id>/spec.md`，使用 `templates/spec-tier-s.md` 或 `templates/spec-tier-m.md`。
2. 用 `skills/diagnose/SKILL.md` 建立反馈环。
3. 记录复现命令和结果到 `changes/<change-id>/evidence.md`。
4. 列出 3-5 个可证伪假设。
5. 验证最可能假设，一次只改一个变量。
6. 能写回归测试时，先写失败测试，再修复。
7. 修复后重跑原始反馈环和最窄验证命令。
8. 运行 `scripts/confidence-gate.sh`、`scripts/assumption-leak-gate.sh` 和 `scripts/allowed-paths.sh`。
9. Reviewer Agent 只读审查。
10. 用户人工 review 后再进入 PR / SIT。

## 必须产物

| 文件 | 目的 |
| --- | --- |
| `changes/<change-id>/spec.md` | 症状、范围、假设、允许路径 |
| `changes/<change-id>/evidence.md` | 复现、假设验证、修复后验证 |
| `changes/<change-id>/review.md` | Reviewer 输出和人工复核结论 |
| `changes/<change-id>/pre-pr.md` | PR 前自审 |
| `changes/<change-id>/retro.md` | 如问题有复发风险，记录复盘 |

## 阻断条件

- 没有反馈环。
- 复现的问题不是用户报告的问题。
- `[ASSUMP]` 准备进入实现。
- `assumption-leak-gate.sh` 发现假设标识进入实现文件。
- 修改文件未写入 `allowed_paths`。
- 临时 `[DEBUG-...]` 日志未清理。
- 修复后没有重跑原始反馈环。

## 推荐验证

后端：

```bash
scripts/mvn-targeted-test.sh <repo-path> <module> test <TestClass>
scripts/mvn-targeted-test.sh <repo-path> <module> compile
```

前端：

```bash
scripts/frontend-lint-build.sh <repo-path> lint
scripts/frontend-lint-build.sh <repo-path> build build:test
```

## 输出口径

给人工 review 的结论使用中文。错误日志、命令、API path、字段名、错误码和代码标识保持原样。
