# 代码确认：<change-id>

> 用途：阶段 B「代码人审」的唯一产物。用户逐轮确认代码 diff；未 `CONFIRMED` 前不得启动 Tester / Reviewer / 全量门禁。
> 只主 Agent 写；用户意见按轮次追加，不覆盖历史。
> 正文中文；commit、文件路径、gate 名、字段名保持原文。

## 确认状态

```yaml
change_id: <change-id>
code_confirmation_status: PENDING
diff_base: -
diff_head: -
confirmed_by: -
confirmed_at: -
confirmed_scope: -
na_reason: -
```

`code_confirmation_status` 可选值：

- `PENDING`：尚未交用户确认，或正在改。
- `CHANGE_REQUESTED`：用户提出修改，代码调整中。
- `CONFIRMED`：用户确认当前 diff 没问题，允许进入阶段 C（Tester / Reviewer / 全量门禁）。
- `NOT_APPLICABLE`：本 change 不需要人审代码（例如纯文档），必须在 `na_reason` 写明来源。

## 阶段规则

| 阶段 | 允许做什么 | 禁止做什么 |
| --- | --- | --- |
| A 完整自检 | 编译 + **完整测试**：后端模块全量单测（`mvn -pl <module> test`）+ 本次定向测试；前端 lint + build。既有历史失败先记录基线噪声，不得当成新失败 | 不派 Tester / Reviewer，不跑全量测试门禁 |
| B 代码确认（5b） | 按用户意见反复调整代码细节（文件增删、方法选择、参数签名、核心逻辑实现方式等）；**只要求编译通过** | 不跑测试、不派 Tester / Reviewer、不跑全量门禁 |
| C 完整验收 | `code-confirmation-gate` PASS 后，跑 Tester、Reviewer、全量门禁 | 代码再改必须回到 B |

## 逐轮确认记录

| Round | 日期 | 交付内容（文件 / 关键点） | 用户意见 | 处理结果 |
| --- | --- | --- | --- | --- |
| 1 | `<yyyy-MM-dd HH:mm>` | `<文件清单 / 关键实现点>` | `<确认 / 要改什么>` | `<已改 / 待改>` |

## 确认范围

- [ ] diff 覆盖本次所有改动文件，且都在 `spec.md` 的 `allowed_paths` 内。
- [ ] 用户已确认关键设计点（接口签名、状态流转、异常处理、配置来源、通知文案）。
- [ ] 遗留问题已登记到 `handoff.md`，并有明确归属。

## 生命周期与交接

| 时机 | 动作 | 谁做 |
| --- | --- | --- |
| 建包 | scaffold 生成 `code-confirmation.md`（`PENDING`） | `changes/change-scaffold.sh` |
| 阶段 A 完成 | 记录完整测试命令与结果（`evidence.md` 同步一行） | 主 Agent |
| 进入阶段 B | 填 `diff_base` / `diff_head`，把 diff 交给用户 | 主 Agent |
| 每轮修改 | 追加「逐轮确认记录」，状态保持 `PENDING` 或 `CHANGE_REQUESTED` | 主 Agent |
| 用户确认 | 写 `CONFIRMED` + `confirmed_by` / `confirmed_at` / `confirmed_scope`，跑 gate | 主 Agent |
| 派发前 | `code-confirmation-gate` 必须 PASS；未过不得派 Tester / Reviewer | 主 Agent |
| 代码再改（阶段 C） | 状态改回 `CHANGE_REQUESTED`，Tester / Reviewer 旧结论作废，退回阶段 B | 主 Agent |
| 暂停 / 换线程 / 换 runtime | 在 `handoff.md` 写明 `code_confirmation_status` 与「未确认勿派 Tester」 | 主 Agent |
| 新 session 接手 | 先读 `status-card.md`（阶段是否为 `代码待确认`）→ 本文件 → `handoff.md`，不从零重跑 | 接手 Agent |
| 收口 | `status-card.md` 保留最终 `code_confirmation_status`；整包不进 git | 主 Agent |

场景适配：

- 纯文档 / 纯配置说明、无业务代码改动：`NOT_APPLICABLE` + `na_reason`（写用户确认来源），gate 放行。
- S 档小修：同样走 A/B，用户可显式豁免为 `NOT_APPLICABLE`；不要默认豁免。
- 只改控制面（例如本次 harness 规则调整）：按普通代码处理，`CONFIRMED` 后才进入验收。

## 使用方式

```bash
# 阶段 C 启动前
gates/code-confirmation-gate.sh changes/<change-id>
```

- `CONFIRMED` 或 `NOT_APPLICABLE`（带 `na_reason`）→ `exit 0`。
- 其他状态 → `exit 1`，禁止派发 Tester / Reviewer。
- 代码在阶段 C 再改：把 `code_confirmation_status` 改回 `CHANGE_REQUESTED`，重新走阶段 B；Tester / Reviewer 旧结论作废。
