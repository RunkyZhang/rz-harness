# Third-party Skills：ECC sidecar lens

日期：2026-06-15

## 来源

| Source | URL | 本仓处理方式 |
| --- | --- | --- |
| `affaan-m/ECC` | `https://github.com/affaan-m/ECC` | 作为 optional sidecar 和只读 lens；不整包复制到 `skills/` |

## 总规则

- ECC skill / command 只能作为辅助 lens，不能替代 `docs/skills-routing.md` 中的 harness-local skill。
- ECC 输出不得作为业务事实、实现许可、测试通过或上线结论。
- ECC 缺失时不得阻断普通 harness 使用。
- 使用 ECC lens 必须记录到 `changes/<change-id>/skill-usage.md` 的外部辅助 Lens 表，或在 `evidence.md` 写 N/A 原因。
- 禁止通过 ECC 执行 auto-fix、global install apply、Codex sync apply、deployment 或 continuous-learning promotion。

## 推荐 lens

| ECC lens | 本仓用途 | 使用方式 | 边界 |
| --- | --- | --- | --- |
| `eval-harness` | 评估 harness 自身模板 / gate 变更 | `scripts/ecc/ecc-sidecar.sh consult "eval harness"` | 只读建议，最终以本仓 eval fixture 为准 |
| `verification-loop` | 检查验证闭环是否完整 | `scripts/ecc/ecc-sidecar.sh consult "verification loop"` | 不替代 `verification-map-gate.sh` |
| `security-review` | 安全检查思路 | `scripts/ecc/ecc-sidecar.sh consult "security review"` | 不授权 DB / 生产 / stateful API |
| `api-design` | API 契约参考 | `scripts/ecc/ecc-sidecar.sh consult "api design"` | 不替代本仓 contract 和现有业务样板 |

## 禁用

| 能力 | 禁用原因 |
| --- | --- |
| ECC full/developer install apply | 会修改全局或项目配置，和本仓主控边界冲突 |
| ECC hooks runtime 作为硬门禁 | Codex hook parity 不等于本仓 gate；本仓 scripts 仍是准入依据 |
| ECC continuous learning auto promotion | 可能把未确认业务经验写成规则 |
| ECC multi-agent auto execution | 可能绕过 `technical-solution` / `code_start` / AI test report 停止点 |
