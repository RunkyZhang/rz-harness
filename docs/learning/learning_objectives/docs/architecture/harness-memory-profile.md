# Harness Memory Profile And Instinct Promotion Contract

> Phase 5D docs-and-validator contract for SFA harness memory isolation and instinct promotion. This file does not authorize hook runtime changes, automatic rule edits, or writes to global memory.

```yaml
contract_status: DOCS_AND_VALIDATOR
runtime_changes_allowed: false
auto_promotion_allowed: false
human_review_required: true
owner: Orchestrator
last_verified: 2026-06-26
```

## 1. Purpose

SFA harness needs long-term learning, but learning must not turn one local observation into a global rule. This contract separates:

- raw local observations,
- sanitized `instinct_candidate` records,
- project memory,
- global memory,
- manual promotion decisions.

Phase 5D only creates the contract and a local candidate validator. It does not modify AGENTS, hooks, `skill-usage-gate.sh`, skills, or business repositories.

## 2. Scope Boundaries

| Scope | Meaning | Allowed content | Not allowed |
| --- | --- | --- | --- |
| `repo` | A rule or pitfall that applies to one repo id, such as `sfa-ai-harness` or `mapSystem`. | Repo-specific commands, paths, known pitfalls, validation notes. | Cross-repo defaults or global behavior rules. |
| `project` | SFA harness project memory across SFA control-plane work. | Sanitized patterns proven by SFA changes, Feishu trace conventions, harness stop points. | Raw prompts, raw Feishu bodies, credentials, customer data, DB results. |
| `global` | General agent behavior that is safe beyond SFA. | Source-backed process rules with OSS or official references and multi-context evidence. | SFA-only business rules, one-off local observations, unreviewed AI inference. |

Machine-readable aliases used by tests:

```yaml
repo_memory_scope: repo
project_memory_scope: project
global_memory_scope: global
```

## 3. Record Types

### 3.1 Raw Observation

Raw observations are local scratch only. They may exist in ignored telemetry or temporary agent work files, but they must not be committed and must not be copied into Feishu.

Allowed raw storage:

- ignored `.harness/telemetry/`
- ignored `.harness/agent-work/`
- temporary `mktemp` directories

Forbidden raw storage:

- versioned docs
- Feishu docs
- global memory
- committed evidence files

### 3.2 `instinct_candidate`

An `instinct_candidate` is a sanitized JSONL row that proposes a future rule or memory entry.

Required fields:

| Field | Meaning |
| --- | --- |
| `candidate_id` | Stable id, for example `SFA-INST-001`. |
| `change_id` | Source change, for example `harness-evolution-architecture`. |
| `repo_id` | Repo or control-plane id that produced the observation. |
| `target_scope` | One of `repo`, `project`, `global`. |
| `promotion_state` | One of `candidate`, `promoted_project`, `promoted_global`, `rejected`, `expired`. |
| `confidence` | Decimal from `0` to `1`. |
| `source_type` | One of `local_fact`, `ecc_source`, `sp_source`, `official_doc`, `multi_project_evidence`, `ai_inference`. |
| `issue_category` | Short category, such as `hook-lifecycle` or `memory-isolation`. |
| `proposed_rule` | Sanitized proposed memory or instinct, max 280 characters. |
| `evidence_ref` | Local doc or public source reference that reviewers can inspect. |

`instinct_candidate` records must not contain tokens, cookies, DB passwords, private keys, raw SQL result text, customer data, raw prompts, or private Feishu document bodies.

## 4. Promotion Gates

| Target | Minimum evidence | Required review | Validator rule |
| --- | --- | --- | --- |
| `repo` candidate | One local fact and an evidence reference. | Orchestrator review before use. | `target_scope=repo`, any allowed `source_type`, `confidence` in `[0,1]`. |
| `project` candidate | SFA local fact, OSS source, or official source. | Human or Reviewer Agent approval before writing to versioned docs. | `target_scope=project`, any allowed `source_type`, `confidence` in `[0,1]`. |
| `promoted_project` | Repeated SFA evidence or a high-value reviewed finding. | Reviewer Agent plus Orchestrator approval. | `promotion_state=promoted_project` requires `target_scope=project` and `confidence>=0.70`. |
| `global` candidate | OSS source, official source, or multi-project evidence. | Human review before global memory write. | `target_scope=global` rejects `local_fact` and `ai_inference`; requires `confidence>=0.80`. |
| `promoted_global` | At least external source-backed or multi-project evidence, plus stable behavior eval or equivalent review. | Human review required. | `promotion_state=promoted_global` requires `target_scope=global` and `confidence>=0.85`. |

No record can promote itself. A validated candidate is only evidence for a later human decision.

## 5. Project / Global Isolation Rules

- SFA business rules stay in repo or project memory, not global memory.
- One local correction can create a project candidate, but cannot create a global candidate unless it is backed by OSS, official docs, or multi-project evidence.
- `[AI-INFERENCE]` can explain why a candidate is useful, but cannot be the sole source for global memory.
- Global memory must be phrased as a general agent behavior rule, not as an SFA-specific operating rule.
- Demotion or expiry must be possible when a later review shows the rule is stale, too broad, or duplicative.

## 6. Validator

Use the local validator before recording or reviewing candidate rows:

```bash
scripts/harness-instinct-candidate-check.sh path/to/instinct-candidates.jsonl
bash scripts/harness-memory-profile-test.sh
```

The validator checks required fields, allowed states, allowed scopes, confidence thresholds, global-source restrictions, and sensitive value rejection.

## 7. Stop Points

Phase 5D stops at docs and local validation.

Not allowed in this phase:

- editing `.codex/hooks.json` or `.cursor/hooks.json`
- editing `scripts/harness-sensor-runner.sh`
- editing `scripts/skill-usage-gate.sh`
- automatically writing global memory
- automatically editing AGENTS, skills, or reviewer prompts from candidates
- touching business repositories

Future runtime learning requires a separate technical solution, AI test plan, privacy review, rollback plan, Feishu child doc, and Test Agent verification.

## 8. Source Attribution

| Source | Usage |
| --- | --- |
| `[LOCAL-FACT]` `docs/harness-diagnosis-and-remediation.md` | Uses the local diagnosis that harness needs measurement, convergence, and retirement instead of endless rule growth. |
| `[ECC-SOURCE]` `continuous-learning-v2` and memory persistence docs | Adapts observation-to-instinct and project/global promotion concepts, but rejects raw transcript persistence and automatic promotion. |
| `[SP-SOURCE]` evidence-before-completion and skill behavior patterns | Requires evidence and review before claiming a rule should become durable behavior. |
| `[OFFICIAL]` OpenAI / Anthropic eval, tracing, hook, and skill principles | Uses source-backed, bounded behavior changes rather than implicit prompt memory. |
| `[AI-INFERENCE]` SFA isolation policy | Adds stricter SFA boundaries for Feishu, DB, credentials, customer data, and repo-specific business rules. |

## 9. Verification

```bash
bash scripts/harness-memory-profile-test.sh
scripts/harness-instinct-candidate-check.sh <jsonl>
```
