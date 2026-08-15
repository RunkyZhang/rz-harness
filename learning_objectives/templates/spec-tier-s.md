# <change-id>

> Tier S 适用于单仓小修或文档/配置外的低风险修复。面向人工 review / 用户确认的正文默认中文；代码标识、命令、API 路径、字段名、错误码、YAML key、日志 key 和引用原文保持原样。

## 一句话目标

[QUESTION] 写清用户确认的目标。

## 范围

### IN

- [QUESTION] Repo:
- [QUESTION] Allowed paths:

### OUT

- [FACT] No production config changes unless explicitly approved.
- [FACT] No deployment changes unless explicitly approved.
- [FACT] No DB migration unless explicitly approved.

## 事实 / 假设 / 问题

- [FACT] 这里只写可追溯事实。
- [ASSUMP] 这里写未确认推断；确认前不得进入实现。
- [QUESTION] 这里写阻塞问题；无阻塞时使用下方 `non_blocking_questions:`。

non_blocking_questions:
  - [QUESTION] None.

## 允许修改路径

```yaml
allowed_paths:
  repo:
    - /absolute/path/to/repo/src/**
forbidden_paths:
  - "**/application-prod.yml"
  - "**/bootstrap-prod.yml"
  - "**/.env*"
  - "**/k8s/prod/**"
  - "**/db/migration/**"
approved_protected_paths: []
```

## 知识引用

> 本次引用了哪些已有知识条目（pitfall / sample / decision）。ARCHIVE 阶段据此更新被引用条目的 `last_referenced` / `referenced_by`。无引用可留空。
> 用 `scripts/knowledge-reference-gate.sh <spec>` 校验引用的 ID 真实存在。

```yaml
knowledge_refs:
  - <SFA-PIT-NNN>   # 引用的已知坑（docs/pitfalls/）
  - <SFA-SMP-NNN>   # 复用的样板（docs/samples/）
```

## 完成标准

- [ ] No unresolved blocking `[QUESTION]`.
- [ ] No `[ASSUMP]` item entered implementation.
- [ ] Changed files stay within `allowed_paths`.
- [ ] Narrow verification evidence is recorded.
- [ ] Rollback note is recorded.

## 回滚

[QUESTION] 写清最小回滚路径。
