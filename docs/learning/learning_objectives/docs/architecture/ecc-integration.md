# ECC Optional Integration

> 用途：说明如何把 ECC 作为可选 sidecar 能力接入 `sfa-ai-harness`。本集成不改变当前 harness 主控：`changes/<change-id>`、本地 gates、人工确认和 evidence 仍是唯一交付依据。

## 结论

- ECC 是可选增强，不是必需依赖。
- 团队成员没有安装 ECC 时，`scripts/team-rollout-preflight.sh`、业务仓分析、门禁和本地联调仍应正常工作。
- Codex 调用 ECC 时必须通过 `scripts/ecc/ecc-sidecar.sh`，默认只允许只读或 dry-run 命令。
- 禁止通过本仓 wrapper 执行 ECC apply install、global sync apply、auto-fix、continuous-learning promotion 或部署类动作。

## 推荐安装

把 ECC 放在 ignored 的 `artifacts/` 下，并固定提交：

```bash
mkdir -p artifacts/vendor
git clone https://github.com/affaan-m/ECC artifacts/vendor/ECC
cd artifacts/vendor/ECC
git checkout 5b173d2e6c11b976a0f13b2f59125e08956c1d47
npm ci --ignore-scripts
```

也可以不使用默认目录，改用：

```bash
export SFA_ECC_HOME=/absolute/path/to/ECC
```

## Codex 可调用命令

```bash
scripts/ecc/ecc-sidecar.sh status
scripts/ecc/ecc-sidecar.sh consult "security reviews"
scripts/ecc/ecc-sidecar.sh harness-audit
scripts/ecc/ecc-sidecar.sh observability-ready
scripts/ecc/ecc-sidecar.sh install-plan --profile minimal
scripts/ecc/ecc-sidecar.sh codex-sync-dry-run
```

`install-plan` 会强制加上 `--target codex --dry-run --json`。`codex-sync-dry-run` 只预览全局 Codex 同步，不会修改 `~/.codex`。

## 禁止默认执行

以下动作必须单独二次确认，且需要先列出目标文件、备份路径、回滚方式和预期影响：

- 写入或覆盖 `~/.codex/AGENTS.md`
- 写入或覆盖 `~/.codex/config.toml`
- 安装 ECC global git hooks
- 合并 ECC MCP 配置到用户全局 Codex
- 启用 ECC auto-update / auto-fix / continuous-learning promotion

## 本仓吸收的能力

| ECC 能力 | 本仓落点 | 方式 |
| --- | --- | --- |
| Adapter compliance matrix | `docs/architecture/adapter-compliance.md` | 本地化 |
| Machine-readable status | `scripts/harness-status.sh --json` | 本地化 |
| Observability readiness | `scripts/harness-observability-ready.sh` | 本地化 |
| Personal path scan | `scripts/no-personal-paths.sh` | 本地化 |
| Sidecar dry-run / consult | `scripts/ecc/ecc-sidecar.sh` | wrapper |
| Harness config evaluator fixture | `evals/harness-config-quality/` | 本地化 |

## 回退

移除 ECC sidecar 不影响 harness：

```bash
rm -rf artifacts/vendor/ECC
unset SFA_ECC_HOME
scripts/ecc/ecc-sidecar.sh status
scripts/team-rollout-preflight.sh
```

`status` 应输出 `ECC_STATUS=UNAVAILABLE`，preflight 仍应通过。
