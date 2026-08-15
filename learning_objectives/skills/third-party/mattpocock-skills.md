# Third-party Skills：mattpocock/skills

日期：2026-05-19

## 来源

- Repository: `https://github.com/mattpocock/skills`
- License: MIT License
- Copyright: Copyright (c) 2026 Matt Pocock

## 引入方式

本控制面没有整包复制 `mattpocock/skills`。当前只引入三个 SFA 本地化 skill：

| 本地 skill | 参考来源 | 本地化点 |
| --- | --- | --- |
| `skills/diagnose/SKILL.md` | `skills/engineering/diagnose/SKILL.md` | 输出证据写入 `changes/<change-id>/evidence.md`；保留 SFA `[FACT] / [ASSUMP] / [QUESTION]` |
| `skills/tdd/SKILL.md` | `skills/engineering/tdd/SKILL.md` | 聚焦 SFA Java / Vue2 的关键行为，不强制所有 CRUD 全量 TDD |
| `skills/handoff/SKILL.md` | `skills/productivity/handoff/SKILL.md` | 交接文档落到 `changes/<change-id>/handoff.md` 或 `docs/decision-log/` |

## 未直接引入

| Skill | 原因 |
| --- | --- |
| `setup-matt-pocock-skills` | 会引入另一套 `docs/agents/`、issue tracker 和 domain docs 约定，和本控制面冲突 |
| `to-prd` / `to-issues` / `triage` | 默认偏 GitHub issue workflow，不直接适配 Feishu + Codeup |
| `git-guardrails-claude-code` | 适合借鉴，但实现绑定 Claude Code hook；本控制面已有 OpenCode / 脚本权限层 |
| `improve-codebase-architecture` | 有价值，但应等真实 CRUD 试点后再进入 Phase 3 |

## 许可要求

如后续复制或分发原始 skill 的实质性内容，必须保留 MIT license 与版权声明。
